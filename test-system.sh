#!/bin/bash
# WooMonitor System Test
# Run this after deployment to verify everything works

echo "========================================"
echo "      WOOCOMMERCE MONITOR SYSTEM TEST"
echo "========================================"
echo

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo "❌ curl is required but not installed"
    exit 1
fi

echo "1. Testing Health Endpoint..."
HEALTH_URL="https://monitor.ashbi.ca/api/health"
if curl -s --max-time 10 "$HEALTH_URL" > /dev/null; then
    echo "   ✅ Health endpoint accessible"
    curl -s "$HEALTH_URL" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(f'   Status: {data.get(\"status\", \"unknown\")}')
    print(f'   Version: {data.get(\"version\", \"unknown\")}')
    print(f'   Sites monitored: {data[\"features\"][\"sites_monitored\"]}')
except:
    print('   ❌ Invalid JSON response')
" 2>/dev/null || echo "   ⚠️ Could not parse JSON (Python may not be available)"
else
    echo "   ❌ Health endpoint not accessible"
    echo "   Try: curl $HEALTH_URL"
fi

echo
echo "2. Testing Webhook Endpoint..."
WEBHOOK_URL="https://monitor.ashbi.ca/api/track-woo-error"
TEST_PAYLOAD='{"site":"test-system.com","url":"https://test.com/checkout","type":"System Test","error_message":"This is a test error from the deployment script","time":"2024-01-01T00:00:00Z"}'
if curl -s --max-time 10 -X POST "$WEBHOOK_URL" \
   -H "Content-Type: application/json" \
   -d "$TEST_PAYLOAD" > /dev/null; then
    echo "   ✅ Webhook endpoint accessible"
    echo "   Test error sent to monitoring server"
    echo "   Check server logs for receipt"
else
    echo "   ❌ Webhook endpoint not accessible"
    echo "   Try: curl -X POST $WEBHOOK_URL -H 'Content-Type: application/json' -d '$TEST_PAYLOAD'"
fi

echo
echo "3. Testing Email Configuration (requires SSH)..."
echo "   Run on server: docker exec <container_id> node test-email.js"
echo "   Or: ssh root@187.77.26.99 'docker exec \$(docker ps -q --filter name=woo-monitor) node test-email.js'"

echo
echo "4. Testing WordPress Plugin..."
echo "   Steps to test manually:"
echo "   1. Go to WooCommerce product page"
echo "   2. Open browser console (F12)"
echo "   3. Trigger error (e.g., add to cart without selection)"
echo "   4. Check console for 'WooMonitor: Sent error alert'"
echo "   5. Check email at cameron@ashbi.ca"

echo
echo "5. Testing Backend Health Checks..."
echo "   Backend checks run every 15 minutes via cron"
echo "   Check logs: ssh root@187.77.26.99 'docker logs \$(docker ps -q --filter name=woo-monitor) | grep -i \"\\[Cron\\]\" | tail -5'"

echo
echo "========================================"
echo "              TEST SUMMARY"
echo "========================================"
echo
echo "Next actions:"
echo "1. Configure ashbi.ca SMTP password in .env (if not done)"
echo "2. Add WooCommerce stores to sites.json"
echo "3. Install plugin on WordPress sites"
echo "4. Test with real checkout errors"
echo
echo "Documentation:"
echo "- Complete guide: COMPLETE_DEPLOYMENT_GUIDE.md"
echo "- Coolify deployment: deploy-coolify.md"
echo "- Plugin README: ../woo-monitor-plugin-improved/README.md"
echo
echo "Support:"
echo "- Coolify Dashboard: http://187.77.26.99:8000"
echo "- GitHub Server: https://github.com/camster91/woo-monitor"
echo "- Health Endpoint: https://monitor.ashbi.ca/api/health"