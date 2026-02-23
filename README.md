# WooCommerce Monitoring System

A comprehensive monitoring system for WooCommerce stores that tracks:
- Frontend checkout errors, JavaScript crashes, and broken buttons
- Backend WooCommerce health (Stripe gateway, failed orders, subscription renewals, ShipStation sync)
- Sends email alerts when issues are detected

## Architecture

This system has two components:

1. **WordPress Plugin** (`woo-monitor-plugin/`): Installed on each WooCommerce site to track frontend errors
2. **Node.js Monitoring Server** (`woo-monitor/`): Central server that receives error reports and performs deep health checks

## Quick Start

### 1. Deploy the Node.js Monitoring Server

1. Clone or upload the `woo-monitor` directory to your server
2. Install dependencies:
   ```bash
   npm install
   ```
3. Configure environment variables by copying `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
4. Edit `.env` with your email settings:
   ```
   PORT=3000
   SMTP_HOST=smtp.yourwebsite.com
   SMTP_PORT=587
   SMTP_USER=alerts@yourwebsite.com
   SMTP_PASS=your_smtp_password
   ALERT_EMAIL=your-email@domain.com
   ```
5. Configure sites to monitor in `sites.json`:
   ```json
   [
     {
       "id": 1,
       "name": "Your Store Name",
       "url": "https://yourstore.com",
       "consumerKey": "ck_your_woocommerce_key",
       "consumerSecret": "cs_your_woocommerce_secret",
       "maxHoursWithoutOrders": 24
     }
   ]
   ```
6. Start the server:
   ```bash
   npm start
   ```
   Or use PM2 for production:
   ```bash
   pm2 start server.js --name "woo-monitor"
   ```

### 2. Install the WordPress Plugin

1. Use the `woo-monitor.zip` file from the `woo-monitor-plugin` directory
2. Upload to WordPress via Plugins → Add New → Upload Plugin
3. Activate the plugin
4. **IMPORTANT**: Before using, edit the plugin file `woo-monitor.php` and change the webhook URL:
   ```php
   define('WOO_MONITOR_WEBHOOK_URL', 'https://YOUR_SERVER_URL/api/track-woo-error');
   ```
   Replace `YOUR_SERVER_URL` with your Node.js server URL (e.g., `https://woo.ashbi.ca`)

5. Re-zip the plugin if you modified it locally before uploading

## Features

### Frontend Error Tracking (WordPress Plugin)
- Catches WooCommerce UI error banners (e.g., "Invalid Card", "No shipping options")
- Detects AJAX "Add to Cart" or "Checkout" failures
- Captures JavaScript crashes that might break buttons
- Only loads on checkout, cart, and product pages
- Sends errors to the central monitoring server

### Backend Health Monitoring (Node.js Server)
- **System & Cron Health**: Checks Action Scheduler for failed background tasks (critical for subscription renewals)
- **Stripe Gateway Health**: Verifies Stripe payment gateway is enabled
- **Stripe Webhook Health**: Detects orders stuck in "Pending Payment" (indicates webhook failures)
- **Failed Orders & Subscription Renewals**: Alerts on failed orders within last 15 minutes
- **ShipStation Sync Health**: Identifies orders stuck in Processing without ShipStation export
- **API Connectivity**: Verifies WooCommerce REST API is accessible

### Alerting System
- Email alerts sent via configured SMTP
- Console logging for development/testing
- Mocked alerts when email not configured (for testing)

## Configuration Details

### WooCommerce API Keys
To monitor a site, you need WooCommerce REST API keys:
1. Go to WooCommerce → Settings → Advanced → REST API
2. Create a new key with Read permission
3. Add the Consumer Key and Consumer Secret to `sites.json`

### Email Configuration
For ashbi.ca email using cPanel hosting:
```
SMTP_HOST=mail.ashbi.ca
SMTP_PORT=587
SMTP_USER=alerts@ashbi.ca
SMTP_PASS=your_email_password
ALERT_EMAIL=cameron@ashbi.ca
```

### Testing
1. Test the Node.js server: `node test-webhook.js`
2. Test email alerts by triggering a frontend error on your WooCommerce site
3. Check server logs for monitoring activity

## Deployment Options

### Option A: Single Server (Simplest)
- Deploy Node.js server on same server as ashbi.ca website
- Use subdomain like `woo.ashbi.ca`
- Configure reverse proxy (Nginx/Apache) to forward to port 3000

### Option B: Separate Monitoring Server
- Deploy on separate VPS/dedicated server
- Better isolation but more complex

### Option C: Cloud Platform
- Deploy to Heroku, Railway, or DigitalOcean App Platform
- May need to adjust for cron jobs and file storage

## Maintenance
- Monitor server logs regularly
- Keep WooCommerce API keys updated
- Test alert system periodically
- Update `sites.json` when adding/removing stores

## Security Notes
- Keep `.env` file secure (never commit to Git)
- Use HTTPS for the monitoring server
- Restrict API key permissions to Read-only
- Consider IP whitelisting for the `/api/track-woo-error` endpoint
- Regularly rotate WooCommerce API keys

## Troubleshooting
- **Server not starting**: Check port 3000 is available, Node.js is installed
- **No emails sent**: Verify SMTP settings, check spam folder
- **API connection errors**: Verify WooCommerce REST API is enabled, keys are correct
- **Plugin not tracking errors**: Check browser console for JavaScript errors, verify webhook URL