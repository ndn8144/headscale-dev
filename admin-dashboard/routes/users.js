const express = require('express');
const axios = require('axios');
const config = require('../config/config');
const router = express.Router();

// Middleware to check if user is authenticated
const requireAuth = (req, res, next) => {
  if (req.session.user) {
    next();
  } else {
    res.redirect('/auth/login');
  }
};

// List all users
router.get('/', requireAuth, async (req, res) => {
  try {
    const response = await axios.get(`${config.headscale.url}/api/v1/user`, {
      headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
    });

    const users = response.data.map(user => ({
      ...user,
      createdAt: user.createdAt ? new Date(user.createdAt).toLocaleString() : 'Unknown'
    }));

    res.render('users/index', { 
      title: 'Manage Users',
      user: req.session.user,
      users,
      config
    });
  } catch (error) {
    console.error('Users list error:', error);
    req.flash('error_msg', 'Failed to load users');
    res.render('users/index', { 
      title: 'Manage Users',
      user: req.session.user,
      users: [],
      config
    });
  }
});

// Show user details
router.get('/:id', requireAuth, async (req, res) => {
  try {
    const [userResponse, nodesResponse, preauthKeysResponse] = await Promise.allSettled([
      axios.get(`${config.headscale.url}/api/v1/user/${req.params.id}`, {
        headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
      }),
      axios.get(`${config.headscale.url}/api/v1/user/${req.params.id}/node`, {
        headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
      }),
      axios.get(`${config.headscale.url}/api/v1/user/${req.params.id}/preauthkey`, {
        headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
      })
    ]);

    const user = userResponse.status === 'fulfilled' ? userResponse.value.data : null;
    const nodes = nodesResponse.status === 'fulfilled' ? nodesResponse.value.data : [];
    const preauthKeys = preauthKeysResponse.status === 'fulfilled' ? preauthKeys.value.data : [];

    if (!user) {
      req.flash('error_msg', 'User not found');
      return res.redirect('/users');
    }

    user.createdAt = user.createdAt ? new Date(user.createdAt).toLocaleString() : 'Unknown';

    res.render('users/show', { 
      title: `User: ${user.name}`,
      user: req.session.user,
      userData: user,
      nodes,
      preauthKeys,
      config
    });
  } catch (error) {
    console.error('User details error:', error);
    req.flash('error_msg', 'Failed to load user details');
    res.redirect('/users');
  }
});

// Create user form
router.get('/create', requireAuth, (req, res) => {
  res.render('users/create', { 
    title: 'Create New User',
    user: req.session.user,
    config
  });
});

// Create user
router.post('/', requireAuth, async (req, res) => {
  try {
    const { name } = req.body;
    
    if (!name || !name.trim()) {
      req.flash('error_msg', 'User name is required');
      return res.redirect('/users/create');
    }

    await axios.post(`${config.headscale.url}/api/v1/user`, {
      name: name.trim()
    }, {
      headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
    });

    req.flash('success_msg', 'User created successfully');
    res.redirect('/users');
  } catch (error) {
    console.error('User creation error:', error);
    req.flash('error_msg', 'Failed to create user');
    res.redirect('/users/create');
  }
});

// Edit user form
router.get('/:id/edit', requireAuth, async (req, res) => {
  try {
    const response = await axios.get(`${config.headscale.url}/api/v1/user/${req.params.id}`, {
      headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
    });

    res.render('users/edit', { 
      title: `Edit User: ${response.data.name}`,
      user: req.session.user,
      userData: response.data,
      config
    });
  } catch (error) {
    console.error('User edit error:', error);
    req.flash('error_msg', 'Failed to load user for editing');
    res.redirect('/users');
  }
});

// Update user
router.post('/:id', requireAuth, async (req, res) => {
  try {
    const { name } = req.body;
    
    if (!name || !name.trim()) {
      req.flash('error_msg', 'User name is required');
      return res.redirect(`/users/${req.params.id}/edit`);
    }

    await axios.put(`${config.headscale.url}/api/v1/user/${req.params.id}`, {
      name: name.trim()
    }, {
      headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
    });

    req.flash('success_msg', 'User updated successfully');
    res.redirect(`/users/${req.params.id}`);
  } catch (error) {
    console.error('User update error:', error);
    req.flash('error_msg', 'Failed to update user');
    res.redirect(`/users/${req.params.id}/edit`);
  }
});

// Delete user
router.post('/:id/delete', requireAuth, async (req, res) => {
  try {
    await axios.delete(`${config.headscale.url}/api/v1/user/${req.params.id}`, {
      headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
    });

    req.flash('success_msg', 'User deleted successfully');
    res.redirect('/users');
  } catch (error) {
    console.error('User delete error:', error);
    req.flash('error_msg', 'Failed to delete user');
    res.redirect(`/users/${req.params.id}`);
  }
});

// Create preauth key for user
router.post('/:id/preauthkey', requireAuth, async (req, res) => {
  try {
    const { expiration, reusable, tags } = req.body;
    
    const response = await axios.post(`${config.headscale.url}/api/v1/preauthkey`, {
      user: req.params.id,
      expiration: expiration || '24h',
      reusable: reusable === 'true',
      tags: tags ? tags.split(',').map(tag => tag.trim()) : []
    }, {
      headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
    });

    req.flash('success_msg', 'Preauth key created successfully');
    res.redirect(`/users/${req.params.id}`);
  } catch (error) {
    console.error('Preauth key creation error:', error);
    req.flash('error_msg', 'Failed to create preauth key');
    res.redirect(`/users/${req.params.id}`);
  }
});

module.exports = router;
