# Deploy WooMonitor to woo.ashbi.ca on Coolify

## Quick Deployment Checklist

### Before You Start:
- [ ] SMTP password for `alerts@ashbi.ca` obtained
- [ ] GitHub repository: https://github.com/camster91/woo-monitor (ready)
- [ ] Coolify dashboard access: http://187.77.26.99:8000
- [ ] Cloudflare DNS access for `ashbi.ca` domain

### Deployment Steps:
1. **Configure Email** → Edit `.env` with SMTP password
2. **Deploy to Coolify** → Create application with domain `woo.ashbi.ca`
3. **Configure DNS** → Point `woo.ashbi.ca` to `187.77.26.99`
4. **Install Plugin** → Upload to WordPress, set webhook URL
5. **Configure Stores** → Add WooCommerce API keys to `sites.json`

## Step-by-Step Deployment

### Step 1: Configure Email Settings

Edit `C:\Users\camst\woo-monitor\.env`:

```env
# Server Port
PORT=3000

# ashbi.ca Email Settings
SMTP_HOST=mail.ashbi.ca
SMTP_PORT=587
SMTP_USER=alerts@ashbi.ca
SMTP_PASS=your_actual_password_here  # ← REQUIRED

# Alert recipient
ALERT_EMAIL=cameron@ashbi.ca
```

**How to get SMTP password:**
1. Log into ashbi.ca cPanel
2. Email Accounts → Create `alerts@ashbi.ca`
3. Use password or generate app-specific password
4. SMTP settings: `mail.ashbi.ca:587` with STARTTLS

### Step 2: Deploy to Coolify

**Coolify Dashboard:** http://187.77.26.99:8000  
**API Token:** `2|OyUt8feqoaBUVu1Uvvkq59CCqNjIdj4j2Vf0OXYf`

#### 2.1 Create Application:
1. **Login** to Coolify dashboard
2. Click **"Create New Resource"** → **"Application"**
3. Select **"GitHub"** as source
4. Choose **"camster91/woo-monitor"** repository
5. Select branch: **"master"**

#### 2.2 Configure Application:
- **Application Name:** `woo-monitor` (or `woocommerce-monitor`)
- **Project:** Select "GitHub Projects" (UUID: `hc4ocwo0sc4o8kkkwcogssgk`)
- **Build Pack:** **Dockerfile** (auto-detected)
- **Port:** `3000`
- **Exposed Port:** `3000`

#### 2.3 Environment Variables:
Add these variables in Coolify:

| Variable | Value | Description |
|----------|-------|-------------|
| `PORT` | `3000` | Application port |
| `NODE_ENV` | `production` | Environment |
| `SMTP_HOST` | `mail.ashbi.ca` | SMTP server |
| `SMTP_PORT` | `587` | SMTP port |
| `SMTP_USER` | `alerts@ashbi.ca` | Email sender |
| `SMTP_PASS` | `[your_password]` | Email password |
| `ALERT_EMAIL` | `cameron@ashbi.ca` | Recipient email |

#### 2.4 Domain Configuration:
- **Domain:** `woo.ashbi.ca`
- **SSL:** Enable (Let's Encrypt auto-configuration)
- **HTTPS Redirect:** Enable
- **Path:** `/` (root)

#### 2.5 Advanced Settings:
- **Dockerfile Location:** `/` (root)
- **Docker Context:** `/` (root)
- **Health Check Path:** `/api/health`
- **Health Check Port:** `3000`
- **Health Check Timeout:** `30` seconds

#### 2.6 Deploy:
Click **"Save & Deploy"** and monitor build logs.

### Step 3: Configure DNS (Cloudflare)

1. Log into Cloudflare dashboard
2. Select `ashbi.ca` domain
3. Go to **DNS** → **Records**
4. Add A record:
   - **Type:** A
   - **Name:** `woo`
   - **IPv4 Address:** `187.77.26.99`
   - **Proxy status:** DNS only (gray cloud)
   - **TTL:** Auto

**Note:** SSL certificate will auto-generate via Let's Encrypt once DNS propagates (may take 5-30 minutes).

### Step 4: Verify Deployment

#### 4.1 Check Health Endpoint:
```bash
curl https://woo.ashbi.ca/api/health
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

#### 4.2 Test Email Configuration:
```bash
# SSH to server
ssh root@187.77.26.99

# Find container ID
CONTAINER_ID=$(docker ps -q --filter "name=woo-monitor")

# Test email
docker exec $CONTAINER_ID node test-email.js
```

#### 4.3 Test Webhook:
```bash
curl -X POST https://woo.ashbi.ca/api/track-woo-error \
  -H "Content-Type: application/json" \
  -d '{
    "site": "test-store.com",
    "url": "https://test-store.com/checkout",
    "type": "Test Error",
    "error_message": "Deployment test successful",
    "time": "2024-01-01T00:00:00Z"
  }'
```

### Step 5: Install WordPress Plugin

#### 5.1 Plugin Files:
- **Location:** `C:\Users\camst\woo-monitor-plugin-improved\`
- **Ready ZIP:** `woo-monitor-plugin.zip`

#### 5.2 Installation:
1. WordPress Admin → Plugins → Add New → Upload
2. Upload `woo-monitor-plugin.zip`
3. Activate plugin

#### 5.3 Configuration:
1. Go to **Settings → WooCommerce Monitor**
2. Set **Monitoring Server URL:** `https://woo.ashbi.ca/api/track-woo-error`
3. Configure tracking options (recommended: all enabled)
4. Click **Save Settings**

#### 5.4 Test Plugin:
1. Go to WooCommerce product page
2. Open browser console (F12)
3. Trigger error (add to cart without required options)
4. Check console for "WooMonitor: Sent error alert"
5. Verify email received at `cameron@ashbi.ca`

### Step 6: Configure WooCommerce Stores

#### 6.1 Get WooCommerce API Keys:
1. WooCommerce → Settings → Advanced → REST API
2. Click **"Add Key"**
3. Name: "WooMonitor"
4. Permissions: **Read only**
5. Click **Generate**
6. Copy **Consumer Key** and **Consumer Secret**

#### 6.2 Edit `sites.json` on Server:
```bash
# SSH to Coolify server
ssh root@187.77.26.99

# Find application directory
cd /var/lib/docker/volumes/coolify-application-*/_data

# Edit sites.json
nano sites.json
```

#### 6.3 Example Configuration:
```json
[
  {
    "id": 1,
    "name": "Ashbi Store",
    "url": "https://ashbi.ca",
    "consumerKey": "ck_your_woocommerce_key",
    "consumerSecret": "cs_your_woocommerce_secret",
    "maxHoursWithoutOrders": 24
  },
  {
    "id": 2,
    "name": "Another Store",
    "url": "https://anotherstore.com",
    "consumerKey": "ck_another_key",
    "consumerSecret": "cs_another_secret",
    "maxHoursWithoutOrders": 12
  }
]
```

#### 6.4 Restart Application (if needed):
```bash
# Via Coolify dashboard or API
curl -H "Authorization: Bearer 2|OyUt8feqoaBUVu1Uvvkq59CCqNjIdj4j2Vf0OXYf" \
  http://187.77.26.99:8000/api/v1/applications/{APP_UUID}/restart
```

## Monitoring & Maintenance

### Daily Checks:
- Check email alerts at `cameron@ashbi.ca`
- Monitor application health: `https://woo.ashbi.ca/api/health`

### Weekly Checks:
- Review server logs for errors
- Verify cron jobs running (every 15 minutes)
- Check SSL certificate validity

### Monthly Checks:
- Update dependencies: `npm update`
- Test full system workflow
- Backup `sites.json` configuration

### Log Access:
```bash
# View recent logs
ssh root@187.77.26.99 "docker logs coolify-application-* --tail 50"

# Follow logs in real-time
ssh root@187.77.26.99 "docker logs coolify-application-* -f"
```

## Troubleshooting

### Common Issues:

#### 1. Build Fails
**Error:** Docker build fails
**Solution:** Check build logs in Coolify, ensure Dockerfile syntax correct

#### 2. SSL Certificate Not Issued
**Error:** HTTPS not working
**Solution:** 
- Verify DNS propagated (`dig woo.ashbi.ca`)
- Check Traefik logs: `docker logs coolify-proxy`
- Ensure port 80 accessible for Let's Encrypt challenge

#### 3. Email Not Sending
**Error:** SMTP authentication failed
**Solution:**
- Test with `node test-email.js`
- Verify SMTP credentials
- Check ashbi.ca SMTP allows connections from VPS

#### 4. Plugin Not Tracking Errors
**Error:** No console messages
**Solution:**
- Verify on WooCommerce page (checkout/cart/product)
- Check browser console for JavaScript errors
- Confirm webhook URL in plugin settings

#### 5. Health Check Failing
**Error:** 404 on `/api/health`
**Solution:**
- Verify application running
- Check Docker container logs
- Confirm port mapping correct

## API Endpoints

### Production URLs:
- **Health:** `https://woo.ashbi.ca/api/health`
- **Webhook:** `https://woo.ashbi.ca/api/track-woo-error`
- **Server Logs:** Coolify dashboard or Docker logs

### WordPress Plugin Webhook URL:
```
https://woo.ashbi.ca/api/track-woo-error
```

## Quick Test Script

Run on Windows (PowerShell):
```powershell
cd C:\Users\camst\woo-monitor
.\test-system.ps1
```

Run on Linux/Mac:
```bash
cd ~/woo-monitor
chmod +x test-system.sh
./test-system.sh
```

## Success Metrics

Deployment successful when:
- [ ] `https://woo.ashbi.ca/api/health` returns status "ok"
- [ ] Email test succeeds (`node test-email.js`)
- [ ] WordPress plugin sends test error
- [ ] Email alert received at `cameron@ashbi.ca`
- [ ] Backend health checks run (check logs for `[Cron]`)

## Support Resources

- **Coolify Dashboard:** http://187.77.26.99:8000
- **GitHub Repository:** https://github.com/camster91/woo-monitor
- **Health Endpoint:** https://woo.ashbi.ca/api/health
- **Complete Guide:** `COMPLETE_DEPLOYMENT_GUIDE.md`
- **Coolify Deployment:** `deploy-coolify.md`

---

**Estimated Deployment Time:** 15-30 minutes  
**Domain:** `woo.ashbi.ca`  
**Server:** Coolify VPS (187.77.26.99)  
**Status:** 🚀 READY FOR DEPLOYMENT