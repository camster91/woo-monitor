# WooMonitor Setup for ashbi.ca

This guide explains how to set up the WooCommerce monitoring system to work with ashbi.ca email.

## Overview

The system consists of:
1. **WordPress Plugin**: Installed on each WooCommerce store
2. **Node.js Monitoring Server**: Receives error reports and sends email alerts
3. **ashbi.ca Email**: Used to send alerts from `alerts@ashbi.ca` to `cameron@ashbi.ca`

## Step 1: Deploy Node.js Server on ashbi.ca

### Option A: Deploy on ashbi.ca hosting (if Node.js is supported)
1. Check if your ashbi.ca hosting supports Node.js (many shared hosts don't)
2. If supported, upload the `woo-monitor` directory to your hosting
3. Install dependencies: `npm install`
4. Configure environment (see Step 2)
5. Start server: `npm start`

### Option B: Deploy on separate VPS/server
1. Get a VPS (DigitalOcean, Linode, Vultr) or use a free tier (Railway, Render, Heroku)
2. Upload the `woo-monitor` directory
3. Install Node.js and npm
4. Install dependencies: `npm install`
5. Configure environment
6. Start with PM2: `pm2 start server.js --name woo-monitor`
7. Set up domain `woo.ashbi.ca` to point to this server

### Option C: Use Coolify (if you have Coolify installed)
1. Create new application in Coolify
2. Upload the `woo-monitor` directory or connect to Git repository
3. Set build command: `npm install`
4. Set start command: `node server.js`
5. Configure environment variables
6. Deploy

## Step 2: Configure Email for ashbi.ca

### ashbi.ca SMTP Settings (typical cPanel hosting)
Create a `.env` file in the `woo-monitor` directory:

```env
# Server Port
PORT=3000

# ashbi.ca Email Settings
SMTP_HOST=mail.ashbi.ca
SMTP_PORT=587
SMTP_USER=alerts@ashbi.ca
SMTP_PASS=your_email_password_here

# Where alerts are sent
ALERT_EMAIL=cameron@ashbi.ca
```

### How to get ashbi.ca SMTP credentials:
1. Log into cPanel for ashbi.ca
2. Go to Email Accounts
3. Create a new email account: `alerts@ashbi.ca`
4. Set a secure password
5. Note the SMTP settings (usually mail.ashbi.ca, port 587 with STARTTLS)
6. If using cPanel, you may need to use "SMTP Authentication" with the full email and password

### Alternative: Use Transactional Email Service
If ashbi.ca SMTP doesn't work reliably, use a service like:
- **SendGrid**: Free tier available
- **Mailgun**: Free tier available  
- **Amazon SES**: Pay-as-you-go
- **Brevo (formerly Sendinblue)**: Free tier

Example with SendGrid:
```env
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=your_sendgrid_api_key
```

## Step 3: Configure WooCommerce Stores to Monitor

Edit `sites.json` in the `woo-monitor` directory:

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

### How to get WooCommerce API Keys:
1. Go to WooCommerce → Settings → Advanced → REST API
2. Click "Add Key"
3. Name: "WooMonitor"
4. Permissions: "Read"
5. Click "Generate"
6. Copy Consumer Key and Consumer Secret

## Step 4: Install WordPress Plugin

### Use the improved plugin (recommended):
1. Use `woo-monitor-plugin-improved/woo-monitor-improved.zip`
2. Upload to WordPress: Plugins → Add New → Upload Plugin
3. Activate the plugin
4. Go to Settings → WooCommerce Monitor
5. Set Monitoring Server URL: `https://woo.ashbi.ca/api/track-woo-error`
   (Replace with your actual server URL)
6. Configure tracking options
7. Save settings

### Or use the original plugin:
1. Edit `woo-monitor-plugin/woo-monitor.php`
2. Change the webhook URL: `https://woo.ashbi.ca/api/track-woo-error`
3. Zip the file: `woo-monitor.php`
4. Upload to WordPress

## Step 5: Test the System

### Test 1: Node.js Server
```bash
cd woo-monitor
node test-webhook.js
```
This should send a test error to your server.

### Test 2: Email Configuration
1. Start the server: `npm start`
2. Wait for cron job to run (or trigger manually)
3. Check if emails arrive at cameron@ashbi.ca
4. Check server logs for errors

### Test 3: WordPress Plugin
1. Go to a product page on your WooCommerce site
2. Open browser console (F12)
3. Trigger an error (e.g., try to add to cart without selecting required options)
4. Check console for "WooMonitor: Sent error alert" messages
5. Check server logs for received errors
6. Check email for alert

## Step 6: Production Deployment

### For reliable 24/7 monitoring:
1. **Use PM2** to keep server running:
   ```bash
   npm install -g pm2
   pm2 start server.js --name woo-monitor
   pm2 save
   pm2 startup
   ```

2. **Set up SSL/TLS** for security:
   - Use Let's Encrypt with Nginx/Apache reverse proxy
   - Or use Cloudflare SSL

3. **Configure logging**:
   ```bash
   pm2 logs woo-monitor --lines 100
   ```

4. **Monitor server health**:
   - Set up uptime monitoring (UptimeRobot, etc.)
   - Monitor disk space and memory usage

## Troubleshooting

### Emails not sending:
1. Check SMTP credentials are correct
2. Test with telnet: `telnet mail.ashbi.ca 587`
3. Check server logs for SMTP errors
4. Try different port (465 for SSL, 25 for unencrypted)
5. Check spam folder

### Server not receiving errors:
1. Check CORS is enabled in server.js (already included)
2. Verify webhook URL in plugin settings
3. Check browser console for CORS errors
4. Test with curl:
   ```bash
   curl -X POST https://woo.ashbi.ca/api/track-woo-error \
     -H "Content-Type: application/json" \
     -d '{"site":"test.com","url":"https://test.com","type":"test","error_message":"test","time":"2024-01-01T00:00:00Z"}'
   ```

### Plugin not loading:
1. Verify WooCommerce is active
2. Check you're on checkout, cart, or product page
3. Check browser console for JavaScript errors
4. Verify plugin is activated

## Security Considerations

1. **Protect `.env` file**: Never commit to Git, keep permissions strict
2. **Use HTTPS**: Essential for production
3. **Restrict WooCommerce API keys**: Read-only permission only
4. **Consider IP whitelisting**: Restrict `/api/track-woo-error` to known IPs
5. **Regular updates**: Keep Node.js and dependencies updated
6. **Monitor logs**: Regularly check for suspicious activity

## Maintenance

1. **Weekly**: Check server logs, verify emails are sending
2. **Monthly**: Update dependencies, rotate API keys if needed
3. **Quarterly**: Test full system, update documentation
4. **As needed**: Add/remove stores from `sites.json`

## Support

For issues with ashbi.ca setup:
1. Check ashbi.ca hosting provider documentation
2. Contact hosting support for SMTP configuration
3. Review server logs for specific error messages
4. Test with alternative email service if needed