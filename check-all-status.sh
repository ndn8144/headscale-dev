#!/bin/bash

echo "🔍 Headscale Infrastructure Status Check"
echo "========================================"

echo ""
echo "📊 Container Status:"
docker-compose ps

echo ""
echo "👥 Users:"
docker exec headscale headscale users list 2>/dev/null || echo "❌ Cannot access Headscale"

echo ""
echo "🖥️  Nodes:"
docker exec headscale headscale nodes list 2>/dev/null || echo "❌ Cannot access Headscale"

echo ""
echo "🔑 API Keys:"
docker exec headscale headscale apikeys list 2>/dev/null || echo "❌ Cannot access Headscale"

echo ""
echo "🌐 Dashboard Status:"
echo "Local: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/)"
echo "HTTPS: $(curl -s -o /dev/null -w "%{http_code}" -k https://dashboard.tailnet.work/)"

echo ""
echo "🔧 Traefik Status:"
echo "API: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/http/routers)"

echo ""
echo "🗄️  Database Status:"
docker exec postgres pg_isready -U headscale 2>/dev/null && echo "✅ PostgreSQL: Healthy" || echo "❌ PostgreSQL: Unhealthy"

echo ""
echo "🌍 Network Status:"
echo "Dashboard IP: $(docker inspect admin-dashboard | grep IPAddress | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)"
echo "Headscale IP: $(docker inspect headscale | grep IPAddress | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)"

echo ""
echo "✅ Status check completed!"
