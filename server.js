require("dotenv").config();
const express = require("express");
const cors = require("cors");
const nodemailer = require("nodemailer");
const cron = require("node-cron");
const WooCommerceRestApi = require("@woocommerce/woocommerce-rest-api").default;
const sites = require("./sites.json");

const app = express();
app.use(cors());
app.use(express.json());

// ==========================================
// 1. EMAIL ALERTING SYSTEM
// ==========================================
async function sendAlert(subject, message) {
  // Fallback: If SMTP is not configured in .env, just log it to the console.
  if (!process.env.SMTP_HOST || process.env.SMTP_HOST === "smtp.gmail.com") {
    console.log("\n" + "=".repeat(50));
    console.log(`🔕 [MOCKED ALERT - EMAIL NOT CONFIGURED]`);
    console.log(`SUBJECT: ${subject}`);
    console.log(`MESSAGE:\n${message}`);
    console.log("=".repeat(50) + "\n");
    return;
  }

  try {
    const transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: process.env.SMTP_PORT,
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });

    await transporter.sendMail({
      from: `"WooMonitor Alert" <${process.env.SMTP_USER}>`,
      to: process.env.ALERT_EMAIL,
      subject: `🚨 ${subject}`,
      text: message,
    });
    console.log(`[Alert Sent via Email] ${subject}`);
  } catch (error) {
    console.error("Failed to send email alert:", error.message);
  }
}

// ==========================================
// 2. FRONTEND UI & JS ERROR WEBHOOK LISTENER
// ==========================================
app.post("/api/track-woo-error", async (req, res) => {
  const { site, url, type, error_message, time } = req.body;
  console.log(`[Frontend Error] Site: ${site} | Type: ${type}`);
  
  const subject = `Frontend Issue on ${site}: ${type}`;
  const message = `A customer just hit a frontend issue!\nSite: ${site}\nURL: ${url}\nError Type: ${type}\nError Message: ${error_message}\nTime: ${time}`;

  await sendAlert(subject, message);
  res.status(200).json({ success: true });
});

// ==========================================
// 3. THE "DEEP HEALTH" WOOCOMMERCE MONITOR
// ==========================================
async function checkWooCommerceAPI() {
  console.log(`[Cron] Starting Deep Health checks for ${sites.length} sites...`);

  for (const site of sites) {
    try {
      const api = new WooCommerceRestApi({
        url: site.url,
        consumerKey: site.consumerKey,
        consumerSecret: site.consumerSecret,
        version: "wc/v3",
      });

      // ---------------------------------------------------------
      // A. SYSTEM & CRON HEALTH (Crucial for Subscriptions)
      // ---------------------------------------------------------
      const { data: systemStatus } = await api.get("system_status");
      
      // Check Action Scheduler (WP-Cron). If tasks are failing, subscriptions won't renew.
      const actionScheduler = systemStatus.environment.action_scheduler_status;
      if (actionScheduler && actionScheduler.failed > 50) {
        await sendAlert(
          `CRITICAL: Background Tasks Failing on ${site.name}`,
          `There are ${actionScheduler.failed} failed background tasks. This usually means WP-Cron is broken, which will stop WooCommerce Subscriptions from renewing automatically! Please check WooCommerce -> Status -> Scheduled Actions.`
        );
      }

      // ---------------------------------------------------------
      // B. STRIPE GATEWAY HEALTH
      // ---------------------------------------------------------
      const { data: gateways } = await api.get("payment_gateways");
      const stripeGateway = gateways.find(g => g.id === "stripe");
      if (stripeGateway && stripeGateway.enabled === false) {
        await sendAlert(
          `STRIPE DISCONNECTED on ${site.name}`,
          `The Stripe payment gateway is currently DISABLED. Customers cannot check out.`
        );
      }

      // ---------------------------------------------------------
      // C. STRIPE WEBHOOK HEALTH (Stuck "Pending Payment" Orders)
      // ---------------------------------------------------------
      // If Stripe charges the card but fails to tell WooCommerce, the order gets stuck in Pending.
      const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();
      const threeHoursAgo = new Date(Date.now() - 3 * 60 * 60 * 1000).toISOString();
      
      const { data: pendingOrders } = await api.get("orders", { 
        status: "pending", 
        before: oneHourAgo, 
        after: threeHoursAgo 
      });

      if (pendingOrders.length > 0) {
        await sendAlert(
          `Possible Stripe Webhook Failure on ${site.name}`,
          `${pendingOrders.length} order(s) have been stuck in "Pending Payment" for over an hour. This usually means Stripe charged the customer but the webhook to WooCommerce was blocked (often by caching or security plugins).`
        );
      }

      // ---------------------------------------------------------
      // D. FAILED ORDERS & FAILED SUBSCRIPTION RENEWALS
      // ---------------------------------------------------------
      const fifteenMinsAgo = new Date(Date.now() - 15 * 60 * 1000).toISOString();
      const { data: failedOrders } = await api.get("orders", { status: "failed", after: fifteenMinsAgo });
      
      for (const order of failedOrders) {
        const isSubscriptionRenewal = order.created_via === 'subscription';
        const typeStr = isSubscriptionRenewal ? "Subscription Renewal" : "Standard Order";
        
        await sendAlert(
          `${typeStr} Failed on ${site.name}`,
          `Order #${order.id} failed.\nType: ${typeStr}\nCustomer: ${order.billing.email}\nTotal: $${order.total}\nPlease check Stripe for the decline reason.`
        );
      }

      // ---------------------------------------------------------
      // E. SHIPSTATION SYNC HEALTH (Order Progression)
      // ---------------------------------------------------------
      const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
      const { data: processingOrders } = await api.get("orders", { status: "processing", after: oneDayAgo });

      let stuckInProcessingCount = 0;
      for (const order of processingOrders) {
        const orderAgeHours = (new Date() - new Date(order.date_created)) / (1000 * 60 * 60);
        const isExported = order.meta_data.some((m) => m.key === "_shipstation_exported");

        if (!isExported && orderAgeHours > 2) {
          stuckInProcessingCount++;
        }
      }

      if (stuckInProcessingCount > 0) {
        await sendAlert(
          `ShipStation Sync Failing on ${site.name}`,
          `${stuckInProcessingCount} order(s) have been stuck in Processing for >2 hours and haven't synced to ShipStation. Verify the ShipStation plugin is connected and API keys are valid.`
        );
      }

    } catch (error) {
      console.error(`[API Error] ${site.name}:`, error.message);
      await sendAlert(
        `API Disconnected on ${site.name}`,
        `Could not connect to the WooCommerce API on ${site.url}.\nError: ${error.message}\nCheck if the site is down or if a firewall is blocking the REST API.`
      );
    }
  }
}

// Run the deep health check every 15 minutes
cron.schedule("*/15 * * * *", checkWooCommerceAPI);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 WooCommerce Monitoring Server running on port ${PORT}`);
  console.log(`Deep Health Cron job scheduled to run every 15 minutes.`);
});
