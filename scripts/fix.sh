#!/bin/bash

# Quick Fix Script for Headscale Issues
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}🚨 URGENT FIX for Headscale Command Issue${NC}"

cd /opt/headscale-infrastructure

# 1. Stop all services immediately
echo -e "${YELLOW}🛑 Stopping all services...${NC}"
docker-compose down --remove-orphans

# 2. Create missing directories FIRST
echo -e "${YELLOW}📁 Creating missing directories...${NC}"
mkdir -p config/headscale
mkdir -p config/headplane  
mkdir -p config/traefik
mkdir -p config/prometheus
mkdir -p config/grafana
mkdir -p data/{headscale,postgres,prometheus,grafana,traefik,headplane}

# 3. Create ACL file FIRST
echo -e "${YELLOW}📋 Creating ACL policy...${NC}"
cat > config/headscale/acl.yaml << 'EOFACL'
# Basic ACL Policy
acls:
  - action: accept
    src: ["*"]
    dst: ["*:*"]

groups:
  group:admins:
    - admin@tailnet.work
  group:employees:
    - "*@tailnet.work"

tagOwners:
  tag:server:
    - group:admins
  tag:client:
    - group:employees

autoApprovers:
  routes:
    "10.0.0.0/8":
      - tag:server
    "192.168.0.0/16":
      - tag:server

ssh:
  - action: accept
    src: ["group:admins"]
    dst: ["tag:server"]
    users: ["root", "ubuntu"]
EOFACL

# 4. Create FIXED docker-compose.yml (corrected command format)
echo -e "${YELLOW}🔧 Creating fixed Docker Compose...${NC}"
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
    # FIXED COMMAND - Use string format, not array
    command: headscale serve
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      - HEADSCALE_CONFIG_FILE=/etc/headscale/config.yaml
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=headscale-infrastructure_headscale-network"
      - "traefik.http.routers.headscale.rule=Host(\`headscale.tailnet.work\`)"
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
      - "traefik.http.routers.headplane.rule=Host(\`admin.tailnet.work\`)"
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
      - "traefik.http.routers.traefik.rule=Host(\`traefik.tailnet.work\`)"
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
      - "traefik.http.routers.prometheus.rule=Host(\`monitor.tailnet.work\`)"
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
      - "traefik.http.routers.grafana.rule=Host(\`grafana.tailnet.work\`)"
      - "traefik.http.services.grafana.loadbalancer.server.port=3000"
EOFDOCKER

# 5. Create minimal working headscale config
echo -e "${YELLOW}⚙️ Creating minimal Headscale config...${NC}"
cat > config/headscale/config.yaml << 'EOFCONFIG'
server_url: https://headscale.tailnet.work
listen_addr: 0.0.0.0:8080
metrics_listen_addr: 0.0.0.0:9090

grpc_listen_addr: 0.0.0.0:50443
grpc_allow_insecure: false

database:
  type: postgres
  postgres:
    host: 172.20.0.10
    port: 5432
    name: headscale
    user: headscale
    pass: changeme123
    ssl_mode: disable

private_key_path: /var/lib/headscale/private.key
noise:
  private_key_path: /var/lib/headscale/noise_private.key

prefixes:
  v4: 100.64.0.0/10
  v6: fd7a:115c:a1e0::/48

derp:
  server:
    enabled: false
  urls:
    - https://controlplane.tailscale.com/derpmap/default

dns:
  magic_dns: true
  base_domain: tailnet.work
  nameservers:
    global:
      - 1.1.1.1
      - 8.8.8.8

policy:
  mode: file
  path: /etc/headscale/acl.yaml

log:
  level: info

unix_socket: /var/run/headscale/headscale.sock
unix_socket_permission: "0770"
EOFCONFIG

# 6. Create simple headplane config
echo -e "${YELLOW}🎛️ Creating Headplane config...${NC}"
cat > config/headplane/config.yaml << 'EOFHEADPLANE'
server:
  host: "0.0.0.0"
  port: 3000
  cookie_secret: "supersecretcookiekey32characterslong"
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
  format: "text"

features:
  enable_registration: false
  enable_machine_approval: true
  enable_route_approval: true
EOFHEADPLANE

# 7. Create prometheus config
echo -e "${YELLOW}📊 Creating Prometheus config...${NC}"
mkdir -p config/prometheus
cat > config/prometheus/prometheus.yml << 'EOFPROM'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'headscale'
    static_configs:
      - targets: ['172.20.0.20:9090']
    scrape_interval: 30s

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOFPROM

# 8. Set permissions
echo -e "${YELLOW}🔐 Setting permissions...${NC}"
    chown -R 1000:1000 data/grafana
    chown -R 65534:65534 data/prometheus
    chmod -R 755 config/

# 9. Start services step by step
echo -e "${GREEN}🚀 Starting services in correct order...${NC}"

echo -e "${BLUE}1. Starting PostgreSQL...${NC}"
docker-compose up -d postgres
sleep 10

echo -e "${BLUE}2. Checking database...${NC}"
for i in {1..5}; do
    if docker-compose exec -T postgres pg_isready -U headscale; then
        echo -e "${GREEN}✅ Database ready${NC}"
        break
    else
        echo -e "${YELLOW}⏳ Waiting for database... ($i/5)${NC}"
        sleep 5
    fi
done

echo -e "${BLUE}3. Starting Headscale...${NC}"
docker-compose up -d headscale
sleep 15

echo -e "${BLUE}4. Checking Headscale...${NC}"
for i in {1..10}; do
    if docker-compose exec -T headscale headscale nodes list >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Headscale ready${NC}"
        break
    else
        echo -e "${YELLOW}⏳ Waiting for Headscale... ($i/10)${NC}"
        sleep 3
    fi
done

echo -e "${BLUE}5. Creating API key for Headplane...${NC}"
sleep 5
API_KEY=$(docker-compose exec -T headscale headscale apikeys create --expiration 8760h | tail -1 | awk '{print $NF}')
if [ ! -z "$API_KEY" ] && [ "$API_KEY" != "" ]; then
    echo -e "${GREEN}✅ Generated API key: ${API_KEY}${NC}"
    # Update headplane config with API key
    sed -i "s/api_key: \"\"/api_key: \"$API_KEY\"/" config/headplane/config.yaml
    echo -e "${GREEN}✅ Updated Headplane config${NC}"
else
    echo -e "${RED}❌ Failed to generate API key, will use manual setup${NC}"
fi

echo -e "${BLUE}6. Starting remaining services...${NC}"
docker-compose up -d

echo -e "${BLUE}7. Waiting for all services...${NC}"
sleep 20

# 10. Show final status
echo -e "${GREEN}📊 Final Status:${NC}"
docker-compose ps

echo -e "${GREEN}🎉 Quick fix completed!${NC}"

# 11. Test basic functionality
echo -e "${BLUE}🧪 Testing Headscale functionality...${NC}"
docker-compose exec headscale headscale users create admin 2>/dev/null || echo "User admin already exists"
docker-compose exec headscale headscale users list

echo -e "${GREEN}✅ Headscale is working! Access at: https://admin.tailnet.work${NC}"

# 12. Show useful commands
echo -e "${YELLOW}📋 Useful commands:${NC}"
echo "docker-compose logs headscale --tail 10"
echo "docker-compose logs headplane --tail 10" 
echo "docker-compose exec headscale headscale nodes list"
echo "docker-compose exec headscale headscale users list"