#!/bin/bash

# SSL Setup Script for Headscale Infrastructure
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 SSL Setup Script for Headscale Infrastructure${NC}"

cd /opt/headscale-infrastructure

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}📝 Creating .env file from example...${NC}"
    cp env.example .env
    echo -e "${RED}⚠️  IMPORTANT: Edit .env file and add your Cloudflare API token!${NC}"
    echo -e "${YELLOW}   Get it from: https://dash.cloudflare.com/profile/api-tokens${NC}"
    echo -e "${YELLOW}   Then run this script again.${NC}"
    exit 1
fi

# Load environment variables
source .env

# Check if Cloudflare API token is set
if [ "$CF_DNS_API_TOKEN" = "your_cloudflare_api_token_here" ]; then
    echo -e "${RED}❌ Please set your Cloudflare API token in .env file first!${NC}"
    echo -e "${YELLOW}   Edit .env file and set CF_DNS_API_TOKEN=your_actual_token${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Cloudflare API token configured${NC}"

# Create necessary directories
echo -e "${YELLOW}📁 Creating SSL directories...${NC}"
mkdir -p data/traefik
chmod 600 data/traefik

# Set proper permissions for acme.json
if [ -f data/traefik/acme.json ]; then
    chmod 600 data/traefik/acme.json
else
    touch data/traefik/acme.json
    chmod 600 data/traefik/acme.json
fi

echo -e "${GREEN}✅ SSL directories created with proper permissions${NC}"

# Check DNS records
echo -e "${YELLOW}🌐 Checking DNS configuration...${NC}"
echo -e "${BLUE}   Make sure these DNS records exist in Cloudflare:${NC}"
echo -e "${BLUE}   - headscale.${DOMAIN} → A record → ${YOUR_PUBLIC_IP}${NC}"
echo -e "${BLUE}   - admin.${DOMAIN} → A record → ${YOUR_PUBLIC_IP}${NC}"
echo -e "${BLUE}   - traefik.${DOMAIN} → A record → ${YOUR_PUBLIC_IP}${NC}"
echo -e "${BLUE}   - monitor.${DOMAIN} → A record → ${YOUR_PUBLIC_IP}${NC}"
echo -e "${BLUE}   - grafana.${DOMAIN} → A record → ${YOUR_PUBLIC_IP}${NC}"

# Restart Traefik to apply SSL configuration
echo -e "${YELLOW}🔄 Restarting Traefik with SSL configuration...${NC}"
docker-compose restart traefik

# Wait for Traefik to start
echo -e "${YELLOW}⏳ Waiting for Traefik to start...${NC}"
sleep 15

# Check Traefik logs for SSL
echo -e "${YELLOW}📋 Checking Traefik SSL status...${NC}"
docker-compose logs --tail 20 traefik | grep -E "(SSL|TLS|certificate|ACME)" || echo "No SSL logs found yet"

echo -e "${GREEN}🎉 SSL setup completed!${NC}"
echo -e "${BLUE}📋 Next steps:${NC}"
echo -e "${BLUE}   1. Wait for SSL certificates to be generated (may take 5-10 minutes)${NC}"
echo -e "${BLUE}   2. Check Traefik logs: docker-compose logs -f traefik${NC}"
echo -e "${BLUE}   3. Test HTTPS access: https://headscale.${DOMAIN}${NC}"
echo -e "${BLUE}   4. Restart Headscale: docker-compose restart headscale${NC}"

# Show current status
echo -e "${GREEN}📊 Current Status:${NC}"
docker-compose ps traefik
