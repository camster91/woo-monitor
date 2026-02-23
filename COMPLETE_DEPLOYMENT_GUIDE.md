# Complete WooMonitor Deployment Guide

This guide covers deploying the entire WooCommerce monitoring system:
1. **Node.js Monitoring Server** → Deploy to Coolify
2. **WordPress Plugin** → Install on WooCommerce stores
3. **Configuration** → Set up email and store monitoring

## Quick Start Timeline

| Step | Task | Time | Status |
|------|------|------|--------|
| 1 | Get ashbi.ca SMTP password | 5 min | ⚠️ Required |
| 2 | Deploy Node.js server to Coolify | 10 min | 🚀 Ready |
| 3 | Create GitHub repo for plugin | 5 min | 📝 Instructions below |
| 4 | Install plugin on WordPress sites | 2 min/site | 🔌 Ready |
| 5 | Configure stores in sites.json | 5 min/store | ⚙️ Ready |
| 6 | Test complete system | 5 min | ✅ Instructions below |

## Part 1: Node.js Monitoring Server

### Already Done:
- ✅ Code committed to GitHub: https://github.com/camster91/woo-monitor
- ✅ Dockerfile and docker-compose.yml created
- ✅ Comprehensive deployment guide: `deploy-coolify.md`
- ✅ Health check endpoint implemented
- ✅ Test scripts for email and webhook

### Immediate Action Required:

#### 1. Get ashbi.ca SMTP Credentials
Edit `C:\Users\camst\woo-monitor\.env`:
```env
SMTP_HOST=mail.ashbi.ca
SMTP_PORT=587
SMTP_USER=alerts@ashbi.ca
SMTP_PASS=your_actual_password_here  # ← REQUIRED
ALERT_EMAIL=cameron@ashbi.ca
```

**How to get credentials:**
1. Log into ashbi.ca cPanel
2. Go to Email Accounts
3. Create `alerts@ashbi.ca` account
4. Note SMTP settings (usually mail.ashbi.ca:587)

#### 2. Deploy to Coolify

**Coolify Dashboard**: http://187.77.26.99:8000  
**API Token**: `2|OyUt8feqoaBUVu1Uvvkq59CCqNjIdj4j2Vf0OXYf`

**Steps:**
1. Login to Coolify dashboard
2. Create New Resource → Application
3. Source: GitHub → camster91/woo-monitor
4. Build Pack: Dockerfile
5. Port: 3000
6. Add environment variables (copy from .env)
7. Domain: `monitor.ashbi.ca`
8. Click "Save & Deploy"

**Detailed instructions**: See `deploy-coolify.md`

#### 3. Verify Deployment
```bash
# Test health endpoint
curl https://monitor.ashbi.ca/api/health

# Test email
ssh root@187.77.26.99 "docker exec <container_id> node test-email.js"

# Test webhook
curl -X POST https://monitor.ashbi.ca/api/track-woo-error \
  -H "Content-Type: application/json" \
  -d '{"site":"test.com","type":"test","error_message":"test"}'
```

## Part 2: WordPress Plugin

### Plugin Files Location:
`C:\Users\camst\woo-monitor-plugin-improved\`

### Files Ready:
- `woo-monitor.php` - Main plugin file
- `admin/admin-settings.php` - Admin interface
- `readme.txt` - WordPress plugin description
- `woo-monitor-plugin.zip` - Ready-to-install zip
- `LICENSE`, `composer.json`, `.gitignore`, `README.md`

### Option A: Create GitHub Repository (Recommended)

#### 1. Create New GitHub Repository
1. Go to https://github.com/new
2. Repository name: `woo-monitor-plugin`
3. Description: "WordPress plugin for WooCommerce error monitoring"
4. Public repository
5. Don't initialize with README (we have one)
6. Click "Create repository"

#### 2. Push Plugin to GitHub
```bash
cd "C:\Users\camst\woo-monitor-plugin-improved"

# Initialize Git
git init
git add .
git commit -m "Initial commit: WooCommerce Error Monitor plugin v1.1.0"

# Add remote and push
git remote add origin https://github.com/camster91/woo-monitor-plugin.git
git branch -M main
git push -u origin main
```

#### 3. Create Releases
1. Go to repository → Releases
2. "Create a new release"
3. Tag: `v1.1.0`
4. Title: "Version 1.1.0"
5. Attach `woo-monitor-plugin.zip`
6. Publish release

### Option B: Manual Installation (No GitHub)

1. Use `woo-monitor-plugin.zip` directly
2. Upload to WordPress → Plugins → Add New → Upload
3. No version control needed

## Part 3: Install & Configure Plugin

### Installation:
1. WordPress Admin → Plugins → Add New → Upload
2. Upload `woo-monitor-plugin.zip`
3. Activate plugin

### Configuration:
1. Go to Settings → WooCommerce Monitor
2. Set **Monitoring Server URL**: `https://monitor.ashbi.ca/api/track-woo-error`
3. Configure tracking options (all enabled by default)
4. Save settings

### Testing Plugin:
1. Go to WooCommerce product page
2. Open browser console (F12)
3. Trigger error (e.g., add to cart without selection)
4. Check console for "WooMonitor: Sent error alert"
5. Verify email alert received at cameron@ashbi.ca

## Part 4: Configure WooCommerce Stores

### Edit `sites.json` on Server:
```bash
# SSH to Coolify server
ssh root@187.77.26.99

# Find application directory
cd /var/lib/docker/volumes/coolify-application-*/_data

# Edit sites.json
nano sites.json
```

### Example Configuration:
```json
[
  {
    "id": 1,
    "name": "Ashbi Store",
    "url": "https://ashbi.ca",
    "consumerKey": "ck_your_woocommerce_key",
    "consumerSecret": "cs_your_woocommerce_secret",
    "maxHoursWithoutOrders": 24
  }
]
```

### Get WooCommerce API Keys:
1. WooCommerce → Settings → Advanced → REST API
2. "Add Key"
3. Name: "WooMonitor"
4. Permissions: "Read"
5. Generate and copy Consumer Key/Secret

## Part 5: Test Complete System

### Test 1: Frontend Error Flow
```bash
# 1. Trigger error on WooCommerce site
# 2. Check server logs
ssh root@187.77.26.99 "docker logs coolify-application-* --tail 20"

# 3. Check email received
# Email should arrive at cameron@ashbi.ca
```

### Test 2: Backend Health Checks
```bash
# Check cron job logs (runs every 15 minutes)
ssh root@187.77.26.99 "docker logs coolify-application-* | grep -A5 -B5 '\[Cron\]'"
```

### Test 3: Health Endpoint
```bash
curl https://monitor.ashbi.ca/api/health | python -m json.tool
```

## Part 6: Maintenance & Monitoring

### Regular Checks:
- **Daily**: Check email alerts at cameron@ashbi.ca
- **Weekly**: Review server logs for errors
- **Monthly**: Update dependencies, test full system

### Log Monitoring:
```bash
# View recent logs
ssh root@187.77.26.99 "docker logs coolify-application-* --tail 50"

# Follow logs in real-time
ssh root@187.77.26.99 "docker logs coolify-application-* -f"
```

### Restart Application:
```bash
# Via Coolify API
curl -H "Authorization: Bearer 2|OyUt8feqoaBUVu1Uvvkq59CCqNjIdj4j2Vf0OXYf" \
  http://187.77.26.99:8000/api/v1/applications/{UUID}/restart
```

## Troubleshooting

### Common Issues:

#### 1. Emails Not Sending
```bash
# Test SMTP configuration
ssh root@187.77.26.99 "docker exec <container> node test-email.js"
```

#### 2. Plugin Not Tracking Errors
- Check browser console for JavaScript errors
- Verify on WooCommerce page (checkout/cart/product)
- Confirm webhook URL in plugin settings

#### 3. Health Check Failing
- Verify `/api/health` endpoint responds
- Check application is running
- Review Docker container logs

#### 4. CORS Errors
- Ensure server has CORS enabled (already configured)
- Verify webhook URL uses HTTPS
- Check browser console for specific errors

## Automation Scripts

### Quick Deployment Script:
Save as `deploy-woomonitor.sh`:
```bash
#!/bin/bash
# WooMonitor Quick Deployment

echo "=== WooMonitor Deployment ==="
echo "1. Deploying Node.js server to Coolify..."
echo "   Dashboard: http://187.77.26.99:8000"
echo "   Repository: https://github.com/camster91/woo-monitor"
echo ""
echo "2. WordPress Plugin:"
echo "   Files: C:\\Users\\camst\\woo-monitor-plugin-improved"
echo "   ZIP: woo-monitor-plugin.zip"
echo ""
echo "3. Configuration needed:"
echo "   - ashbi.ca SMTP password in .env"
echo "   - WooCommerce API keys in sites.json"
echo "   - Plugin webhook URL: https://monitor.ashbi.ca/api/track-woo-error"
```

### Health Check Script:
Save as `check-woomonitor.sh`:
```bash
#!/bin/bash
# Health check for WooMonitor

echo "Checking WooMonitor health..."
curl -s https://monitor.ashbi.ca/api/health | python -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print('✅ Status:', data.get('status', 'unknown'))
    print('✅ Version:', data.get('version', 'unknown'))
    print('✅ Sites monitored:', data['features']['sites_monitored'])
except:
    print('❌ Health check failed')
"
```

## Next Steps After Deployment

### Short-term (Week 1):
1. Install plugin on 1-2 test stores
2. Verify error tracking works
3. Confirm email alerts received
4. Adjust alert thresholds if needed

### Medium-term (Month 1):
1. Install on all WooCommerce stores
2. Configure `sites.json` for all stores
3. Set up monitoring alerts for the monitor itself
4. Create dashboard for error visualization (optional)

### Long-term (Quarterly):
1. Add database for error storage
2. Implement web dashboard
3. Add advanced analytics
4. Create Slack/Teams integrations

## Support Resources

### Documentation:
- **Server**: `README.md` in woo-monitor directory
- **Coolify Deployment**: `deploy-coolify.md`
- **Plugin**: `README.md` in plugin directory

### Quick Reference:
- **Coolify Dashboard**: http://187.77.26.99:8000
- **GitHub Server**: https://github.com/camster91/woo-monitor
- **GitHub Plugin**: https://github.com/camster91/woo-monitor-plugin (to be created)
- **Health Endpoint**: https://monitor.ashbi.ca/api/health

### Contact:
- **Email**: cameron@ashbi.ca
- **Server Access**: SSH root@187.77.26.99
- **Coolify API Token**: `2|OyUt8feqoaBUVu1Uvvkq59CCqNjIdj4j2Vf0OXYf`

## Success Metrics

### Deployment Complete When:
- [ ] Node.js server deployed to Coolify
- [ ] `monitor.ashbi.ca` accessible with SSL
- [ ] Email alerts working (test with test-email.js)
- [ ] WordPress plugin installed on at least 1 store
- [ ] Error tracking functional (trigger test error)
- [ ] Backend health checks running (cron job)
- [ ] `sites.json` configured with at least 1 store

### Monitoring Effective When:
- [ ] Receive email within 5 minutes of checkout error
- [ ] No false positives (adjust tracking settings if needed)
- [ ] Backend issues detected (Stripe, subscriptions, etc.)
- [ ] System requires minimal maintenance

---

**Deployment Status**: 🚀 READY FOR DEPLOYMENT  
**Last Updated**: February 23, 2026  
**Estimated Completion Time**: 30-60 minutes