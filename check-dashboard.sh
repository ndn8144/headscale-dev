#!/bin/bash

# Script to check Headscale Admin Dashboard status

echo "🔍 Checking Headscale Admin Dashboard Status..."
echo "🌐 Domain: dashboard.tailnet.work"
echo ""

# Check if containers are running
echo "📊 Container Status:"
docker-compose ps admin-dashboard
echo ""

# Check if dashboard is accessible locally
echo "🏠 Local Access Test:"
if curl -s http://localhost:3001 > /dev/null; then
    echo "✅ Dashboard accessible locally on port 3001"
else
    echo "❌ Dashboard not accessible locally"
fi
echo ""

# Check Traefik status
echo "🚦 Traefik Status:"
docker-compose ps traefik
echo ""

# Check Traefik logs for dashboard routing
echo "📝 Recent Traefik Logs (dashboard related):"
docker-compose logs --tail 20 traefik | grep -i dashboard || echo "No dashboard-related logs found"
echo ""

# Check dashboard logs
echo "📝 Recent Dashboard Logs:"
docker-compose logs --tail 20 admin-dashboard
echo ""

# Check network connectivity
echo "🌐 Network Test:"
if ping -c 1 dashboard.tailnet.work > /dev/null 2>&1; then
    echo "✅ Domain resolves to IP"
    nslookup dashboard.tailnet.work | grep "Address:"
else
    echo "❌ Domain does not resolve"
fi
echo ""

# Check SSL certificate
echo "🔒 SSL Certificate Test:"
if curl -s -I https://dashboard.tailnet.work > /dev/null 2>&1; then
    echo "✅ HTTPS accessible"
else
    echo "❌ HTTPS not accessible"
fi
echo ""

echo "🎯 Summary:"
echo "- Dashboard should be accessible at: https://dashboard.tailnet.work"
echo "- Local access: http://localhost:3001"
echo "- Login credentials: admin / password"
echo ""
echo "📋 If dashboard is not accessible:"
echo "1. Check DNS records for dashboard.tailnet.work"
echo "2. Verify Traefik is running and configured"
echo "3. Check firewall settings"
echo "4. Review container logs above"
