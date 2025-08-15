#!/bin/bash

echo "🔧 Fixing Headscale Domain Conflict..."

# Stop headscale
docker-compose stop headscale

# Fix config - Change base_domain to avoid conflict
echo "📝 Updating Headscale config..."
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
  # FIXED: Use different subdomain to avoid conflict
  base_domain: devices.tailnet.work
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

echo "✅ Updated config - base_domain changed to: devices.tailnet.work"

# Alternative approach - change server_url instead
echo "📝 Creating alternative config (if needed)..."
cat > config/headscale/config-alt.yaml << 'EOFALTCONFIG'
# Alternative: Change server_url instead
server_url: https://control.tailnet.work
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
EOFALTCONFIG

echo "🚀 Starting Headscale with fixed config..."
docker-compose up -d headscale

echo "⏳ Checking Headscale..."
sleep 10

for i in {1..10}; do
    if docker-compose logs headscale --tail 5 | grep -q "FTL.*Error initializing"; then
        echo "❌ Still has error, trying alternative config..."
        
        # Use alternative config
        mv config/headscale/config-alt.yaml config/headscale/config.yaml
        
        # Update docker-compose for new server_url
        sed -i 's/headscale.tailnet.work/control.tailnet.work/g' docker-compose.yml
        
        echo "🔄 Restarting with alternative config..."
        docker-compose restart headscale
        sleep 10
        break
    elif docker-compose exec -T headscale headscale nodes list >/dev/null 2>&1; then
        echo "✅ Headscale is working with devices.tailnet.work!"
        break
    else
        echo "⏳ Waiting... ($i/10)"
        sleep 3
    fi
done

# Check final status
echo ""
echo "📊 Final check:"
if docker-compose exec -T headscale headscale nodes list >/dev/null 2>&1; then
    echo "✅ Headscale is working!"
    echo "🎯 Configuration used:"
    grep "server_url\|base_domain" config/headscale/config.yaml
    
    # Start other services
    echo "🚀 Starting remaining services..."
    docker-compose up -d
    
else
    echo "❌ Still has issues. Let's check logs:"
    docker-compose logs headscale --tail 10
fi

echo ""
echo "🌐 Access URLs (updated):"
echo "  Headscale API: $(grep server_url config/headscale/config.yaml | cut -d' ' -f2)"
echo "  Admin UI: https://admin.tailnet.work"
echo "  Client domains: $(grep base_domain config/headscale/config.yaml | cut -d' ' -f2)"
