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

// Dashboard home page
router.get('/', requireAuth, async (req, res) => {
  try {
    // Get Headscale statistics
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

    res.render('dashboard', { 
      title: 'Dashboard',
      user: req.session.user,
      stats,
      config
    });
  } catch (error) {
    console.error('Dashboard error:', error);
    req.flash('error_msg', 'Failed to load dashboard data');
    res.render('dashboard', { 
      title: 'Dashboard',
      user: req.session.user,
      stats: { totalNodes: 0, totalUsers: 0, totalPreauthKeys: 0, onlineNodes: 0 },
      config
    });
  }
});

// System status page
router.get('/status', requireAuth, async (req, res) => {
  try {
    const statusResponse = await axios.get(`${config.headscale.url}/api/v1/status`, {
      headers: { 'Authorization': `Bearer ${config.headscale.apiKey}` }
    });

    res.render('status', { 
      title: 'System Status',
      user: req.session.user,
      status: statusResponse.data,
      config
    });
  } catch (error) {
    console.error('Status error:', error);
    req.flash('error_msg', 'Failed to load system status');
    res.redirect('/');
  }
});

// Monitoring page
router.get('/monitoring', requireAuth, async (req, res) => {
  try {
    // Get Prometheus metrics if available
    let metrics = null;
    try {
      const metricsResponse = await axios.get(`${config.prometheus.url}/api/v1/query?query=up`);
      metrics = metricsResponse.data;
    } catch (metricsError) {
      console.log('Prometheus metrics not available');
    }

    res.render('monitoring', { 
      title: 'Monitoring',
      user: req.session.user,
      metrics,
      config
    });
  } catch (error) {
    console.error('Monitoring error:', error);
    req.flash('error_msg', 'Failed to load monitoring data');
    res.redirect('/');
  }
});

module.exports = router;
