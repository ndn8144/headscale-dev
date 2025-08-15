#!/bin/bash

echo "🔧 Fixing HTTPS Dashboard Access..."
echo "=================================="

echo ""
echo "📋 Current Status:"
docker-compose ps

echo ""
echo "🔍 Checking Traefik Configuration..."
echo "Network configuration:"
grep -n "traefik.docker.network" docker-compose.yml

echo ""
echo "🌐 Testing Current Access:"
echo "Local access:"
curl -I http://localhost:3001 2>/dev/null | head -1

echo ""
echo "HTTPS access:"
curl -I -k https://dashboard.tailnet.work 2>/dev/null | head -1

echo ""
echo "🔄 Fixing Network Configuration..."

# Stop all services
echo "Stopping all services..."
docker-compose down

# Remove old containers and networks
echo "Cleaning up old containers and networks..."
docker system prune -f

# Start fresh
echo "Starting services with correct configuration..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to start..."
sleep 20

echo ""
echo "📊 Final Status Check:"
docker-compose ps

echo ""
echo "🌐 Testing HTTPS Access:"
echo "Local access:"
curl -I http://localhost:3001 2>/dev/null | head -1

echo ""
echo "HTTPS access:"
curl -I -k https://dashboard.tailnet.work 2>/dev/null | head -1

echo ""
echo "🔍 Checking Traefik Logs:"
docker-compose logs --tail 5 traefik | grep -E "(Starting provider|docker|admin-dashboard|dashboard|WARN|ERR)"

echo ""
echo "✅ Fix completed!"
echo "If HTTPS still doesn't work, check the logs above for errors."
