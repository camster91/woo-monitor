# 🚀 WooMonitor - Start Here

> **⚠️ IMPORTANT**: Old Coolify application deleted. You must create a new application via Coolify dashboard.
> - **Patched plugin** (version 1.1.1) ready with all bug fixes
> - **DNS** already configured (`woo.ashbi.ca` → `187.77.26.99`)
> - **SMTP password** required for email alerts

## Quick Start for woo.ashbi.ca Deployment

### 🎯 What's Ready:
1. **Node.js Monitoring Server** - Complete, Dockerized, ready for Coolify (✅ GitHub updated)
2. **WordPress Plugin** - **Patched version 1.1.1** with all critical bugs fixed
3. **Documentation** - Step-by-step deployment guides (✅ Updated)
4. **Test Scripts** - Verify everything works (✅ Updated)

### 📁 Key Files:

#### Server (Node.js) - Deploy to Coolify:
- `Dockerfile` - Production container configuration
- `server.js` - Main application with webhook & cron jobs
- `.env.example` → Copy to `.env` and add SMTP password
- `sites.json` - Configure WooCommerce stores to monitor

#### WordPress Plugin - Install on stores:
- `../woo-monitor-plugin-patched/woo-monitor-patched.zip` - **Patched version 1.1.1** (✅ All bugs fixed)
- `woo-monitor.php` - Main plugin file with timeout handling
- **Bug fixes included**: Enabled checks, tracking options, 5-second timeout

### 🚀 Deployment Steps (30 minutes):

#### Step 1: Configure Email
1. Get SMTP password for `alerts@ashbi.ca` (cPanel)
2. Edit `C:\Users\camst\woo-monitor\.env`:
   ```env
   SMTP_PASS=your_actual_password_here
   ```

#### Step 2: Deploy to Coolify
1. **Coolify Dashboard:** http://187.77.26.99:8000
2. Create Application → GitHub → `camster91/woo-monitor`
3. Domain: `woo.ashbi.ca`
4. Build Pack: Dockerfile
5. Add environment variables (copy from `.env`)
6. **Save & Deploy**

#### Step 3: Configure DNS (Cloudflare)
1. Add A record: `woo` → `187.77.26.99`
2. Wait for SSL certificate (auto via Let's Encrypt)

#### Step 4: Install WordPress Plugin (✅ Use Patched Version)
1. Upload `woo-monitor-patched.zip` to WordPress (version 1.1.1)
2. Activate plugin
3. Settings → WooCommerce Monitor
4. Webhook URL: `https://woo.ashbi.ca/api/track-woo-error`
5. Configure tracking options (recommended: all enabled)
6. Save settings
7. **Verify bug fixes**: Enabled checkbox works, timeout handling

#### Step 5: Configure Stores
1. Get WooCommerce API keys (Read permission)
2. Edit `sites.json` on server via SSH
3. Add store details

#### Step 6: Test System
```bash
# Test health
curl https://woo.ashbi.ca/api/health

# Test email (on server)
docker exec <container> node test-email.js

# Test plugin (trigger error on WooCommerce site)
# Check email at cameron@ashbi.ca
```

### 📚 Detailed Guides:

| Guide | Purpose | File |
|-------|---------|------|
| **Quick Deployment** | woo.ashbi.ca on Coolify | `deploy-woo-ashbi-ca.md` |
| **Complete System** | Full deployment guide | `COMPLETE_DEPLOYMENT_GUIDE.md` |
| **Coolify General** | Coolify deployment details | `deploy-coolify.md` |
| **ashbi.ca Setup** | Email configuration | `setup-ashbi-ca.md` |
| **README** | Project overview | `README.md` |

### 🧪 Test Scripts:

| Script | Purpose | Run with |
|--------|---------|----------|
| `test-system.ps1` | Windows system test | PowerShell |
| `test-system.sh` | Linux/Mac system test | Bash |
| `test-email.js` | Email configuration test | `node test-email.js` |
| `test-webhook.js` | Webhook endpoint test | `node test-webhook.js` |

### 🔧 Troubleshooting:

#### Common Issues:
1. **Email not sending** → Run `node test-email.js` on server
2. **Plugin not tracking** → Check browser console, verify WooCommerce page
3. **SSL not working** → Check DNS propagation, Traefik logs
4. **Health check failing** → Verify container running, check logs

#### Quick Checks:
```bash
# Application health
curl https://woo.ashbi.ca/api/health

# Container status (SSH to server)
ssh root@187.77.26.99 "docker ps | grep woo-monitor"

# Recent logs
ssh root@187.77.26.99 "docker logs coolify-application-* --tail 20"
```

### 📞 Support:

- **Coolify Dashboard:** http://187.77.26.99:8000
- **GitHub Server:** https://github.com/camster91/woo-monitor
- **Health Endpoint:** https://woo.ashbi.ca/api/health (after deployment)
- **Email:** cameron@ashbi.ca

### ⏱️ Estimated Timeline:

| Task | Time |
|------|------|
| Configure email | 5 min |
| Deploy to Coolify | 10 min |
| DNS configuration | 5 min |
| Install plugin | 5 min |
| Configure stores | 5 min |
| Testing | 5 min |
| **Total** | **~35 min** |

### ✅ Success Checklist:

- [ ] `https://woo.ashbi.ca/api/health` returns "ok"
- [ ] Email test succeeds (`node test-email.js`)
- [ ] WordPress plugin sends test error
- [ ] Email alert received at `cameron@ashbi.ca`
- [ ] Backend health checks running (check logs)

---

**Status:** 🟢 READY FOR DEPLOYMENT  
**Last Updated:** February 23, 2026  
**Domain:** `woo.ashbi.ca`  
**Server:** Coolify VPS (187.77.26.99)