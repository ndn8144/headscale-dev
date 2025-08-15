require('dotenv').config();

module.exports = {
  headscale: {
    url: process.env.HEADSCALE_URL || 'https://dashboard.tailnet.work',
    apiKey: process.env.HEADSCALE_API_KEY || 'EZy-iyS.SDjNYUIAoL1MkxGWsrRsWAz9vV7MMiTS',
    port: process.env.HEADSCALE_PORT || 8080
  },
  server: {
    port: process.env.PORT || 3001,
    env: process.env.NODE_ENV || 'development'
  },
  security: {
    sessionSecret: process.env.SESSION_SECRET || 'headscale-admin-secret-key',
    jwtSecret: process.env.JWT_SECRET || 'headscale-jwt-secret-key'
  },
  prometheus: {
    url: process.env.PROMETHEUS_URL || 'http://prometheus:9090'
  },
  grafana: {
    url: process.env.GRAFANA_URL || 'http://grafana:3000'
  }
};
