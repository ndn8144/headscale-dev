const express = require('express');
const axios = require('axios');
const config = require('../config/config');
const router = express.Router();

// Middleware to check if user is authenticated
const requireAuth = (req, res, next) => {
  if (req.session.user) {
    next();
  } else {
    res.status(401).json({ error: 'Unauthorized' });
  }
};

// Get dashboard statistics
router.get('/stats', requireAuth, async (req, res) => {
  try {
    const [nodesResponse, usersResponse, preauthKeysResponse] = await Promise.allSettled([
      axios.get(`${config.headscale.url}/api/v1/node`, {
        headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
      }),
      axios.get(`${config.headscale.url}/api/v1/user`, {
        headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
      }),
      axios.get(`${config.headscale.url}/api/v1/preauthkey`, {
        headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
      })
    ]);

    const stats = {
      totalNodes: nodesResponse.status === 'fulfilled' ? nodesResponse.value.data.length : 0,
      totalUsers: usersResponse.status === 'fulfilled' ? usersResponse.value.data.length : 0,
      totalPreauthKeys: preauthKeysResponse.status === 'fulfilled' ? preauthKeysResponse.value.data.length : 0,
      onlineNodes: nodesResponse.status === 'fulfilled' ? 
        nodesResponse.value.data.filter(node => node.online).length : 0
    };

    res.json(stats);
  } catch (error) {
    console.error('Stats API error:', error);
    res.status(500).json({ error: 'Failed to fetch statistics' });
  }
});

// Get all nodes
router.get('/nodes', requireAuth, async (req, res) => {
  try {
    const response = await axios.get(`${config.headscale.url}/api/v1/node`, {
      headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
    });

    const nodes = response.data.map(node => ({
      ...node,
      lastSeen: node.lastSeen ? new Date(node.lastSeen).toISOString() : null,
      createdAt: node.createdAt ? new Date(node.createdAt).toISOString() : null
    }));

    res.json(nodes);
  } catch (error) {
    console.error('Nodes API error:', error);
    res.status(500).json({ error: 'Failed to fetch nodes' });
  }
});

// Get node by ID
router.get('/nodes/:id', requireAuth, async (req, res) => {
  try {
    const response = await axios.get(`${config.headscale.url}/api/v1/node/${req.params.id}`, {
      headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
    });

    const node = response.data;
    node.lastSeen = node.lastSeen ? new Date(node.lastSeen).toISOString() : null;
    node.createdAt = node.createdAt ? new Date(node.createdAt).toISOString() : null;

    res.json(node);
  } catch (error) {
    console.error('Node API error:', error);
    res.status(500).json({ error: 'Failed to fetch node' });
  }
});

// Get all users
router.get('/users', requireAuth, async (req, res) => {
  try {
    const response = await axios.get(`${config.headscale.url}/api/v1/user`, {
      headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
    });

    const users = response.data.map(user => ({
      ...user,
      createdAt: user.createdAt ? new Date(user.createdAt).toISOString() : null
    }));

    res.json(users);
  } catch (error) {
    console.error('Users API error:', error);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// Get user by ID
router.get('/users/:id', requireAuth, async (req, res) => {
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
    const preauthKeys = preauthKeysResponse.status === 'fulfilled' ? preauthKeysResponse.value.data : [];

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    user.createdAt = user.createdAt ? new Date(user.createdAt).toISOString() : null;

    res.json({ user, nodes, preauthKeys });
  } catch (error) {
    console.error('User API error:', error);
    res.status(500).json({ error: 'Failed to fetch user' });
  }
});

// Get system status
router.get('/status', requireAuth, async (req, res) => {
  try {
    const response = await axios.get(`${config.headscale.url}/api/v1/status`, {
      headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
    });

    res.json(response.data);
  } catch (error) {
    console.error('Status API error:', error);
    res.status(500).json({ error: 'Failed to fetch system status' });
  }
});

// Get Prometheus metrics
router.get('/metrics', requireAuth, async (req, res) => {
  try {
    const { query } = req.query;
    
    if (!query) {
      return res.status(400).json({ error: 'Query parameter is required' });
    }

    const response = await axios.get(`${config.prometheus.url}/api/v1/query?query=${encodeURIComponent(query)}`);
    res.json(response.data);
  } catch (error) {
    console.error('Metrics API error:', error);
    res.status(500).json({ error: 'Failed to fetch metrics' });
  }
});

// Get real-time updates (WebSocket endpoint)
router.get('/realtime', requireAuth, (req, res) => {
  // This would be handled by Socket.IO in the main app
  res.json({ message: 'Real-time updates available via WebSocket' });
});

module.exports = router;
