#!/bin/bash

# Script to restart Headscale Admin Dashboard with new configuration

echo "🔄 Restarting Headscale Admin Dashboard..."
echo "🌐 New domain: dashboard.tailnet.work"

# Stop existing containers
echo "⏹️  Stopping existing containers..."
docker-compose stop admin-dashboard

# Remove old container
echo "🗑️  Removing old container..."
docker-compose rm -f admin-dashboard

# Build new image
echo "🔨 Building new image..."
docker-compose build admin-dashboard

# Start dashboard
echo "🚀 Starting dashboard..."
docker-compose up -d admin-dashboard

# Check status
echo "📊 Checking dashboard status..."
sleep 5
docker-compose ps admin-dashboard

echo ""
echo "✅ Dashboard restarted successfully!"
echo "🌐 Access URL: https://dashboard.tailnet.work"
echo "🔑 Login: admin / password"
echo ""
echo "📝 Note: Make sure to update your DNS records to point dashboard.tailnet.work to this server"
