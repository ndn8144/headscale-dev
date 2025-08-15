#!/bin/bash

echo "🚨 ULTIMATE FIX - Fixing Headscale Command & Headplane Cookie"

# Stop all services
docker-compose down --remove-orphans

# 1. Fix Headscale command - Use entrypoint override instead
echo "🔧 Fixing Headscale command format..."
cat > docker-compose.yml << 'EOFDOCKER'
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
    # FIXED: Use entrypoint override - this is the correct way
    entrypoint: ["/ko-app/headscale"]
    command: ["serve"]
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
EOFDOCKER

# 2. Fix Headplane config - Generate exactly 32 char cookie secret
echo "🍪 Fixing Headplane cookie secret (exactly 32 chars)..."
COOKIE_SECRET=$(openssl rand -hex 16)  # 16 bytes = 32 hex chars
cat > config/headplane/config.yaml << EOFHEADPLANE
server:
  host: "0.0.0.0"
  port: 3000
  cookie_secret: "$COOKIE_SECRET"
  cookie_secure: false
  cookie_same_site: "lax"
  cookie_http_only: true

headscale:
  url: "http://172.20.0.20:8080"
  api_key: ""
  config_strict: false
  timeout: "30s"

auth:
  type: "api_key"

database:
  type: "memory"

logging:
  level: "info"

features:
  enable_registration: false
  enable_machine_approval: true
  enable_route_approval: true
EOFHEADPLANE

echo "✅ Cookie secret generated: $COOKIE_SECRET (length: ${#COOKIE_SECRET})"

# 3. Start services step by step
echo "🚀 Starting services..."

echo "Starting PostgreSQL..."
docker-compose up -d postgres
sleep 10

echo "Checking database..."
if docker-compose exec -T postgres pg_isready -U headscale; then
    echo "✅ Database ready"
else
    echo "❌ Database not ready"
    exit 1
fi

echo "Starting Headscale with FIXED entrypoint..."
docker-compose up -d headscale
sleep 15

# Check headscale multiple times
echo "Checking Headscale..."
for i in {1..15}; do
    if docker-compose exec -T headscale headscale nodes list >/dev/null 2>&1; then
        echo "✅ Headscale is working!"
        break
    else
        echo "⏳ Waiting for Headscale... ($i/15)"
        if [ $i -eq 15 ]; then
            echo "❌ Headscale failed to start"
            echo "📋 Headscale logs:"
            docker-compose logs headscale --tail 10
            exit 1
        fi
        sleep 2
    fi
done

# Generate API key
echo "Generating API key..."
API_KEY=$(docker-compose exec -T headscale headscale apikeys create --expiration 8760h | tail -1 | awk '{print $NF}')

if [ ! -z "$API_KEY" ] && [ "$API_KEY" != "" ]; then
    echo "✅ API Key: $API_KEY"
    # Update headplane config
    sed -i "s/api_key: \"\"/api_key: \"$API_KEY\"/" config/headplane/config.yaml
    echo "✅ Updated Headplane config with API key"
else
    echo "❌ Failed to generate API key"
fi

echo "Starting Headplane with FIXED cookie secret..."
docker-compose up -d headplane
sleep 10

# Check headplane
echo "Checking Headplane..."
for i in {1..10}; do
    if [ "$(docker-compose ps headplane --format '{{.Status}}')" = "Up" ]; then
        echo "✅ Headplane is running!"
        break
    else
        echo "⏳ Waiting for Headplane... ($i/10)"
        if [ $i -eq 10 ]; then
            echo "❌ Headplane failed to start"
            echo "📋 Headplane logs:"
            docker-compose logs headplane --tail 10
        fi
        sleep 2
    fi
done

echo "Starting remaining services..."
docker-compose up -d

sleep 10

echo ""
echo "🎉 ULTIMATE FIX COMPLETED!"
echo "📊 Service status:"
docker-compose ps

echo ""
echo "🧪 Testing functionality:"
echo "Headscale users:"
docker-compose exec headscale headscale users list

echo ""
echo "🌐 Access URLs:"
echo "  Admin UI: https://admin.tailnet.work"
echo "  Grafana: https://grafana.tailnet.work" 
echo "  Prometheus: https://monitor.tailnet.work"
echo "  Traefik: https://traefik.tailnet.work"

echo ""
echo "📋 Debug commands:"
echo "docker-compose logs headscale --tail 10"
echo "docker-compose logs headplane --tail 10"
echo "docker-compose exec headscale headscale nodes list"
