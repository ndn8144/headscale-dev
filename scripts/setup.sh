#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting Headscale Infrastructure Setup${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed${NC}"
    exit 1
fi

# Create data directories
echo -e "${YELLOW}📁 Creating data directories...${NC}"
mkdir -p data/{headscale,postgres,prometheus,grafana,traefik}

# Set permissions
chown -R 1000:1000 data/grafana
chown -R 65534:65534 data/prometheus

# Generate API Key
if [ ! -f .env ]; then
    echo -e "${YELLOW}🔑 Generating API key...${NC}"
    API_KEY=$(openssl rand -hex 32)
    echo "HEADSCALE_API_KEY=$API_KEY" >> .env
    echo -e "${GREEN}✅ API key generated and saved to .env${NC}"
fi

# Start services
echo -e "${YELLOW}🐳 Starting Docker services...${NC}"
docker-compose up -d

# Wait for services to start
echo -e "${YELLOW}⏳ Waiting for services to initialize...${NC}"
sleep 30

# Create initial user
echo -e "${YELLOW}👤 Creating initial admin user...${NC}"
docker-compose exec headscale headscale users create admin

# Generate pre-auth key
echo -e "${YELLOW}🔐 Generating pre-auth key...${NC}"
docker-compose exec headscale headscale --user admin preauthkeys create --reusable --expiration 24h

echo -e "${GREEN}🎉 Setup completed successfully!${NC}"
echo -e "${GREEN}Access your services at:${NC}"
echo -e "  🌐 Headscale Admin: https://admin.tailnet.work"
echo -e "  📊 Grafana: https://grafana.tailnet.work"
echo -e "  📈 Prometheus: https://monitor.tailnet.work"
echo -e "  🔧 Traefik: https://traefik.tailnet.work"