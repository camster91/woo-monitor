# WooMonitor Coolify Deployment Guide

## Prerequisites

1. **Coolify Dashboard Access**: http://187.77.26.99:8000
2. **API Token**: `2|OyUt8feqoaBUVu1Uvvkq59CCqNjIdj4j2Vf0OXYf`
3. **GitHub Repository**: https://github.com/camster91/woo-monitor
4. **ashbi.ca Domain Access**: For creating subdomain (monitor.ashbi.ca)

## Deployment Options

### Option A: Deploy from GitHub (Recommended)
Connect Coolify to your GitHub repository for automatic deployments.

### Option B: Manual Upload
Upload the project files directly to Coolify.

## Step-by-Step Deployment

### 1. Prepare Your Repository
Ensure your `woo-monitor` repository contains:
- `Dockerfile` (for containerized deployment)
- `docker-compose.yml` (optional, for local testing)
- `package.json` with `start` script
- `server.js` (main application)
- `sites.json` (template for WooCommerce stores)
- `.env.example` (environment template)

### 2. Create New Application in Coolify

1. **Login** to Coolify dashboard: http://187.77.26.99:8000
2. Click **"Create New Resource"** → **"Application"**
3. Select **"GitHub"** as source
4. Choose **"camster91/woo-monitor"** repository
5. Select branch: **"master"**

### 3. Configure Application Settings

#### General Settings:
- **Application Name**: `woo-monitor` (or `woocommerce-monitor`)
- **Project**: Select "GitHub Projects" (UUID: `hc4ocwo0sc4o8kkkwcogssgk`)
- **Build Pack**: **Dockerfile** (since we have a Dockerfile)
- **Port**: `3000`
- **Exposed Port**: `3000`

#### Environment Variables:
Add the following environment variables in Coolify:

| Variable | Value | Description |
|----------|-------|-------------|
| `PORT` | `3000` | Application port |
| `NODE_ENV` | `production` | Environment |
| `SMTP_HOST` | `mail.ashbi.ca` | SMTP server |
| `SMTP_PORT` | `587` | SMTP port |
| `SMTP_USER` | `alerts@ashbi.ca` | Email sender |
| `SMTP_PASS` | `[your_password]` | Email password |
| `ALERT_EMAIL` | `cameron@ashbi.ca` | Recipient email |

**Note**: Replace `[your_password]` with the actual password for `alerts@ashbi.ca`.

#### Build Settings:
- **Build Command**: (Leave empty - Dockerfile handles build)
- **Start Command**: (Leave empty - Dockerfile handles start)
- **Install Command**: (Leave empty - Dockerfile handles install)

#### Advanced Settings:
- **Dockerfile Location**: `/` (root)
- **Docker Context**: `/` (root)
- **Health Check Path**: `/api/health`
- **Health Check Port**: `3000`

### 4. Configure Domain & SSL

1. **Domain**: `monitor.ashbi.ca`
2. **SSL**: Enable (Coolify/Traefik will auto-configure Let's Encrypt)
3. **HTTPS Redirect**: Enable

**DNS Configuration** (in Cloudflare):
```
monitor.ashbi.ca → A record → 187.77.26.99
```

### 5. Deploy Application

1. Click **"Save & Deploy"**
2. Monitor build logs for errors
3. Check deployment status

## Post-Deployment Verification

### 1. Check Application Health
```bash
curl https://monitor.ashbi.ca/api/health
```
Expected response:
```json
{
  "status": "ok",
  "timestamp": "...",
  "version": "1.0.0",
  "features": {
    "frontend_monitoring": true,
    "backend_health_checks": true,
    "email_alerts": true,
    "sites_monitored": 0
  }
}
```

### 2. Test Email Configuration
SSH into the server and run:
```bash
# Get container ID
docker ps | grep woo-monitor

# Execute test command
docker exec -it <container_id> node test-email.js
```

### 3. Test Webhook Endpoint
```bash
curl -X POST https://monitor.ashbi.ca/api/track-woo-error \
  -H "Content-Type: application/json" \
  -d '{
    "site": "test-store.com",
    "url": "https://test-store.com/checkout",
    "type": "Test Error",
    "error_message": "This is a test error",
    "time": "2024-01-01T00:00:00Z"
  }'
```

## Configuration Files

### 1. Configure WooCommerce Stores
Edit `sites.json` on the server or mount as volume:

```bash
# SSH to server
ssh root@187.77.26.99

# Navigate to application directory
cd /var/lib/docker/volumes/coolify-application-<uuid>/_data

# Edit sites.json
nano sites.json
```

Example `sites.json`:
```json
[
  {
    "id": 1,
    "name": "Your Store",
    "url": "https://yourstore.com",
    "consumerKey": "ck_your_key",
    "consumerSecret": "cs_your_secret",
    "maxHoursWithoutOrders": 24
  }
]
```

### 2. Update Environment Variables
To update SMTP password or other settings:

1. Go to Coolify dashboard
2. Select `woo-monitor` application
3. Click "Environment Variables"
4. Update values
5. Click "Save & Redeploy"

## Monitoring & Maintenance

### 1. View Logs
```bash
# Via Coolify dashboard
# OR via SSH
ssh root@187.77.26.99 "docker logs coolify-application-<uuid> --tail 100"

# Follow logs
ssh root@187.77.26.99 "docker logs coolify-application-<uuid> -f"
```

### 2. Restart Application
```bash
# Via Coolify API
curl -s -H "Authorization: Bearer 2|OyUt8feqoaBUVu1Uvvkq59CCqNjIdj4j2Vf0OXYf" \
  http://187.77.26.99:8000/api/v1/applications/{APP_UUID}/restart
```

### 3. Check Resource Usage
```bash
ssh root@187.77.26.99 "docker stats coolify-application-<uuid>"
```

## Troubleshooting

### Common Issues

#### 1. Build Fails
**Error**: `npm ERR!` during build
**Solution**: Check Dockerfile and ensure all dependencies are listed in package.json

#### 2. Application Won't Start
**Error**: `Error: Cannot find module`
**Solution**: Rebuild application, ensure node_modules is properly installed

#### 3. Email Not Sending
**Error**: SMTP authentication failed
**Solution**:
1. Verify SMTP credentials
2. Test with `node test-email.js`
3. Check if ashbi.ca SMTP allows connections from VPS

#### 4. Health Check Failing
**Error**: 404 on `/api/health`
**Solution**: Ensure server.js has the health endpoint configured

#### 5. Domain Not Accessible
**Error**: DNS resolution failed
**Solution**:
1. Check Cloudflare DNS settings
2. Verify SSL certificate is issued
3. Check Traefik proxy configuration

## Automated Deployment (CI/CD)

### Connect GitHub Webhook
1. In Coolify, enable **"Auto Deploy"**
2. Coolify will automatically deploy on push to master

### Manual Deployment Trigger
```bash
# Deploy via API
curl -X POST \
  -H "Authorization: Bearer 2|OyUt8feqoaBUVu1Uvvkq59CCqNjIdj4j2Vf0OXYf" \
  http://187.77.26.99:8000/api/v1/applications/{APP_UUID}/deploy
```

## Backup & Recovery

### 1. Backup Configuration
```bash
# Backup sites.json
ssh root@187.77.26.99 "docker cp coolify-application-<uuid>:/usr/src/app/sites.json /backup/sites.json.backup"

# Backup environment variables
# Export from Coolify dashboard
```

### 2. Restore Application
1. Re-deploy from GitHub
2. Restore `sites.json`
3. Set environment variables in Coolify

## Scaling (If Needed)

### Increase Resources
1. In Coolify dashboard, edit application
2. Adjust CPU/Memory limits
3. Redeploy

### Database Integration (Future)
For persistent error storage, consider adding:
1. PostgreSQL/MySQL database
2. Redis for caching
3. File storage for logs

## Security Considerations

### 1. Environment Variables
- Never commit `.env` to GitHub
- Use Coolify's secure environment variable storage
- Rotate SMTP passwords periodically

### 2. Network Security
- Application runs in isolated Docker network
- Traefik handles SSL termination
- Only port 3000 exposed internally

### 3. API Security
- Webhook endpoint is public (needs to receive from WordPress sites)
- Consider IP whitelisting for `/api/track-woo-error`
- Implement rate limiting if needed

## Cost & Resource Estimation

### Resource Usage:
- **CPU**: ~5-10% average
- **Memory**: ~100-200MB
- **Storage**: ~500MB (including Docker layers)

### Domain Cost:
- `monitor.ashbi.ca` (subdomain of existing domain)
- SSL certificates: Free (Let's Encrypt)

## Next Steps After Deployment

1. **Install WordPress Plugin** on your WooCommerce stores
2. **Configure `sites.json`** with your store API keys
3. **Test complete flow**: Error → Monitor → Email alert
4. **Set up monitoring alerts** for the monitor itself
5. **Regular maintenance**: Update dependencies, check logs

## Support

### Quick Checks:
```bash
# Application status
curl -s https://monitor.ashbi.ca/api/health

# Container status
ssh root@187.77.26.99 "docker ps | grep woo-monitor"

# Recent logs
ssh root@187.77.26.99 "docker logs coolify-application-<uuid> --tail 50"
```

### Coolify Resources:
- Dashboard: http://187.77.26.99:8000
- API Documentation: https://coolify.io/docs/api
- Community Support: https://discord.gg/coolify