#!/bin/bash

# Fix YAML Escape Character Issue
echo "🔧 Fixing YAML escape character issue..."

cd /opt/headscale-infrastructure

# Stop all services
docker-compose down --remove-orphans 2>/dev/null || true

# Create clean docker-compose.yml without escape characters
cat > docker-compose.yml << 'EOF'
networks:
  headscale-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

volumes:
  postgres_data:
  headscale_data:
  prometheus_data:
  grafana_data:

services:
  postgres:
    image: postgres:15-alpine
    container_name: postgres
    restart: unless-stopped
    networks:
      headscale-network:
        ipv4_address: 172.20.0.10
    environment:
      POSTGRES_DB: headscale
      POSTGRES_USER: headscale
      POSTGRES_PASSWORD: changeme123
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U headscale"]
      interval: 10s
      timeout: 5s
      retries: 5
    labels:
      - "traefik.enable=false"

  headscale:
    image: headscale/headscale:latest
    container_name: headscale
    restart: unless-stopped
    networks:
      headscale-network:
        ipv4_address: 172.20.0.20
    volumes:
      - ./config/headscale:/etc/headscale:ro
      - headscale_data:/var/lib/headscale
    command: headscale serve
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      - HEADSCALE_CONFIG_FILE=/etc/headscale/config.yaml
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=headscale-infrastructure_headscale-network"
      - "traefik.http.routers.headscale.rule=Host('headscale.tailnet.work')"
      - "traefik.http.routers.headscale.tls=true"
      - "traefik.http.routers.headscale.tls.certresolver=cloudflare"
      - "traefik.http.services.headscale.loadbalancer.server.port=8080"

  headplane:
    image: ghcr.io/tale/headplane:latest
    container_name: headplane
    restart: unless-stopped
    networks:
      headscale-network:
        ipv4_address: 172.20.0.30
    volumes:
      - ./config/headplane:/etc/headplane:ro
      - ./data/headplane:/data
    environment:
      - HEADPLANE_CONFIG_FILE=/etc/headplane/config.yaml
      - HEADPLANE_LOG_LEVEL=debug
    depends_on:
      - headscale
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=headscale-infrastructure_headscale-network"
      - "traefik.http.routers.headplane.rule=Host('admin.tailnet.work')"
      - "traefik.http.routers.headplane.tls=true"
      - "traefik.http.routers.headplane.tls.certresolver=cloudflare"
      - "traefik.http.services.headplane.loadbalancer.server.port=3000"

  traefik:
    image: traefik:v3.0
    container_name: traefik
    restart: unless-stopped
    networks:
      headscale-network:
        ipv4_address: 172.20.0.5
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./config/traefik:/etc/traefik:ro
      - ./data/traefik:/data
    environment:
      - CF_DNS_API_TOKEN=your_token_here
    command:
      - --api.dashboard=true
      - --log.level=INFO
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --providers.docker.network=headscale-infrastructure_headscale-network
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --entrypoints.web.http.redirections.entrypoint.to=websecure
      - --entrypoints.web.http.redirections.entrypoint.scheme=https
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.rule=Host('traefik.tailnet.work')"
      - "traefik.http.routers.traefik.service=api@internal"

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    networks:
      headscale-network:
        ipv4_address: 172.20.0.40
    volumes:
      - ./config/prometheus:/etc/prometheus:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.enable-lifecycle'
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=headscale-infrastructure_headscale-network"
      - "traefik.http.routers.prometheus.rule=Host('monitor.tailnet.work')"
      - "traefik.http.services.prometheus.loadbalancer.server.port=9090"

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    networks:
      headscale-network:
        ipv4_address: 172.20.0.50
    volumes:
      - grafana_data:/var/lib/grafana
      - ./config/grafana:/etc/grafana/provisioning:ro
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_SERVER_DOMAIN=grafana.tailnet.work
      - GF_SERVER_ROOT_URL=https://grafana.tailnet.work
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=headscale-infrastructure_headscale-network"
      - "traefik.http.routers.grafana.rule=Host('grafana.tailnet.work')"
      - "traefik.http.services.grafana.loadbalancer.server.port=3000"
EOF

# Test YAML syntax
echo "Testing YAML syntax..."
docker-compose config >/dev/null 2>&1 && echo "✅ YAML syntax is valid" || echo "❌ YAML syntax error"

# Start services
echo "🚀 Starting services..."
docker-compose up -d postgres
sleep 10

echo "Database status:"
docker-compose exec -T postgres pg_isready -U headscale && echo "✅ Database ready"

echo "Starting Headscale..."
docker-compose up -d headscale
sleep 15

echo "Testing Headscale..."
if docker-compose exec -T headscale headscale nodes list >/dev/null 2>&1; then
    echo "✅ Headscale is working!"
    
    # Generate API key
    echo "Generating API key..."
    API_KEY=$(docker-compose exec -T headscale headscale apikeys create --expiration 8760h | tail -1 | awk '{print $NF}')
    
    if [ ! -z "$API_KEY" ] && [ "$API_KEY" != "" ]; then
        echo "✅ API Key: $API_KEY"
        # Update headplane config
        sed -i "s/api_key: \"\"/api_key: \"$API_KEY\"/" config/headplane/config.yaml
        echo "✅ Updated Headplane config"
    fi
else
    echo "❌ Headscale not working yet"
fi

echo "Starting all services..."
docker-compose up -d

echo ""
echo "🎉 All fixed! Service status:"
docker-compose ps

echo ""
echo "📋 Test commands:"
echo "docker-compose logs headscale --tail 5"
echo "docker-compose logs headplane --tail 5"
echo "docker-compose exec headscale headscale users list"