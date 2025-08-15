# 🌐 DNS Configuration for Dashboard

## Domain: `dashboard.tailnet.work`

### DNS Records to Add:

#### A Record (IPv4)
```
Type: A
Name: dashboard
Value: YOUR_SERVER_IP
TTL: 300 (5 minutes)
```

#### AAAA Record (IPv6) - Optional
```
Type: AAAA
Name: dashboard
Value: YOUR_SERVER_IPv6
TTL: 300 (5 minutes)
```

#### CNAME Record (Alternative)
```
Type: CNAME
Name: dashboard
Value: tailnet.work
TTL: 300 (5 minutes)
```

### Example DNS Configuration:

#### Cloudflare DNS:
1. Login to Cloudflare dashboard
2. Select domain: `tailnet.work`
3. Go to DNS section
4. Add new record:
   - **Type**: A
   - **Name**: dashboard
   - **IPv4 address**: `YOUR_SERVER_IP`
   - **Proxy status**: DNS only (gray cloud)
   - **TTL**: Auto

#### Other DNS Providers:
- **Namecheap**: Add A record in Advanced DNS
- **GoDaddy**: Add A record in DNS Management
- **AWS Route53**: Create A record in Hosted Zone

### Verification:

After adding DNS records, verify with:
```bash
# Check A record
nslookup dashboard.tailnet.work

# Check with dig
dig dashboard.tailnet.work

# Check with curl
curl -I http://dashboard.tailnet.work
```

### SSL Certificate:

The dashboard will automatically get SSL certificate from Traefik + Cloudflare integration.

### Testing:

1. **HTTP**: http://dashboard.tailnet.work (will redirect to HTTPS)
2. **HTTPS**: https://dashboard.tailnet.work
3. **Login**: admin / password

### Troubleshooting:

If dashboard is not accessible:
1. Check DNS propagation (can take up to 24 hours)
2. Verify server IP is correct
3. Check firewall settings
4. Verify Traefik is running
5. Check container logs: `docker-compose logs admin-dashboard`
