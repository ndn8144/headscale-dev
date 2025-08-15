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

// List all nodes
router.get('/', requireAuth, async (req, res) => {
  try {
    const response = await axios.get(`${config.headscale.url}/api/v1/node`, {
      headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
    });

    const nodes = response.data.map(node => ({
      ...node,
      lastSeen: node.lastSeen ? new Date(node.lastSeen).toLocaleString() : 'Never',
      createdAt: node.createdAt ? new Date(node.createdAt).toLocaleString() : 'Unknown'
    }));

    res.render('nodes/index', { 
      title: 'Manage Nodes',
      user: req.session.user,
      nodes,
      config
    });
  } catch (error) {
    console.error('Nodes list error:', error);
    req.flash('error_msg', 'Failed to load nodes');
    res.render('nodes/index', { 
      title: 'Manage Nodes',
      user: req.session.user,
      nodes: [],
      config
    });
  }
});

// Show node details
router.get('/:id', requireAuth, async (req, res) => {
  try {
    const response = await axios.get(`${config.headscale.url}/api/v1/node/${req.params.id}`, {
      headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
    });

    const node = response.data;
    node.lastSeen = node.lastSeen ? new Date(node.lastSeen).toLocaleString() : 'Never';
    node.createdAt = node.createdAt ? new Date(node.createdAt).toLocaleString() : 'Unknown';

    res.render('nodes/show', { 
      title: `Node: ${node.name}`,
      user: req.session.user,
      node,
      config
    });
  } catch (error) {
    console.error('Node details error:', error);
    req.flash('error_msg', 'Failed to load node details');
    res.redirect('/nodes');
  }
});

// Edit node form
router.get('/:id/edit', requireAuth, async (req, res) => {
  try {
    const response = await axios.get(`${config.headscale.url}/api/v1/node/${req.params.id}`, {
      headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
    });

    res.render('nodes/edit', { 
      title: `Edit Node: ${response.data.name}`,
      user: req.session.user,
      node: response.data,
      config
    });
  } catch (error) {
    console.error('Node edit error:', error);
    req.flash('error_msg', 'Failed to load node for editing');
    res.redirect('/nodes');
  }
});

// Update node
router.post('/:id', requireAuth, async (req, res) => {
  try {
    const { name, tags } = req.body;
    
    await axios.post(`${config.headscale.url}/api/v1/node/${req.params.id}/tags`, {
      tags: tags.split(',').map(tag => tag.trim())
    }, {
      headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
    });

    req.flash('success_msg', 'Node updated successfully');
    res.redirect(`/nodes/${req.params.id}`);
  } catch (error) {
    console.error('Node update error:', error);
    req.flash('error_msg', 'Failed to update node');
    res.redirect(`/nodes/${req.params.id}/edit`);
  }
});

// Delete node
router.post('/:id/delete', requireAuth, async (req, res) => {
  try {
    await axios.delete(`${config.headscale.url}/api/v1/node/${req.params.id}`, {
      headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
    });

    req.flash('success_msg', 'Node deleted successfully');
    res.redirect('/nodes');
  } catch (error) {
    console.error('Node delete error:', error);
    req.flash('error_msg', 'Failed to delete node');
    res.redirect(`/nodes/${req.params.id}`);
  }
});

// Expire node
router.post('/:id/expire', requireAuth, async (req, res) => {
  try {
    await axios.post(`${config.headscale.url}/api/v1/node/${req.params.id}/expire`, {}, {
      headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
    });

    req.flash('success_msg', 'Node expired successfully');
    res.redirect(`/nodes/${req.params.id}`);
  } catch (error) {
    console.error('Node expire error:', error);
    req.flash('error_msg', 'Failed to expire node');
    res.redirect(`/nodes/${req.params.id}`);
  }
});

// Rename node
router.post('/:id/rename', requireAuth, async (req, res) => {
  try {
    const { name } = req.body;
    
    await axios.post(`${config.headscale.url}/api/v1/node/${req.params.id}/rename`, {
      name: name.trim()
    }, {
      headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
    });

    req.flash('success_msg', 'Node renamed successfully');
    res.redirect(`/nodes/${req.params.id}`);
  } catch (error) {
    console.error('Node rename error:', error);
    req.flash('error_msg', 'Failed to rename node');
    res.redirect(`/nodes/${req.params.id}`);
  }
});

module.exports = router;
