# WooMonitor System Test for Windows PowerShell
# Run this after deployment to verify everything works

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "      WOOCOMMERCE MONITOR SYSTEM TEST" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host

# 1. Test Health Endpoint
Write-Host "1. Testing Health Endpoint..." -ForegroundColor Yellow
$healthUrl = "https://monitor.ashbi.ca/api/health"
try {
    $response = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 10
    Write-Host "   ✅ Health endpoint accessible" -ForegroundColor Green
    Write-Host "   Status: $($response.status)"
    Write-Host "   Version: $($response.version)"
    Write-Host "   Sites monitored: $($response.features.sites_monitored)"
} catch {
    Write-Host "   ❌ Health endpoint not accessible" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
    Write-Host "   Try: curl $healthUrl" -ForegroundColor Gray
}

Write-Host

# 2. Test Webhook Endpoint
Write-Host "2. Testing Webhook Endpoint..." -ForegroundColor Yellow
$webhookUrl = "https://monitor.ashbi.ca/api/track-woo-error"
$testPayload = @{
    site = "test-system.com"
    url = "https://test.com/checkout"
    type = "System Test"
    error_message = "This is a test error from PowerShell deployment script"
    time = "2024-01-01T00:00:00Z"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $testPayload -ContentType "application/json" -TimeoutSec 10
    Write-Host "   ✅ Webhook endpoint accessible" -ForegroundColor Green
    Write-Host "   Test error sent to monitoring server" -ForegroundColor Gray
    Write-Host "   Check server logs for receipt" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ Webhook endpoint not accessible" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
    Write-Host "   Try manually: curl -X POST $webhookUrl -H 'Content-Type: application/json' -d '$testPayload'" -ForegroundColor Gray
}

Write-Host

# 3. Test Email Configuration
Write-Host "3. Testing Email Configuration..." -ForegroundColor Yellow
Write-Host "   Requires SSH access to server:" -ForegroundColor Gray
Write-Host "   ssh root@187.77.26.99 'docker exec \$(docker ps -q --filter name=woo-monitor) node test-email.js'" -ForegroundColor Gray

Write-Host

# 4. Test WordPress Plugin
Write-Host "4. Testing WordPress Plugin..." -ForegroundColor Yellow
Write-Host "   Manual test steps:" -ForegroundColor Gray
Write-Host "   1. Go to WooCommerce product page" -ForegroundColor Gray
Write-Host "   2. Open browser console (F12)" -ForegroundColor Gray
Write-Host "   3. Trigger error (e.g., add to cart without selection)" -ForegroundColor Gray
Write-Host "   4. Check console for 'WooMonitor: Sent error alert'" -ForegroundColor Gray
Write-Host "   5. Check email at cameron@ashbi.ca" -ForegroundColor Gray

Write-Host

# 5. Test Backend Health Checks
Write-Host "5. Testing Backend Health Checks..." -ForegroundColor Yellow
Write-Host "   Backend checks run every 15 minutes via cron" -ForegroundColor Gray
Write-Host "   Check logs via SSH:" -ForegroundColor Gray
Write-Host "   ssh root@187.77.26.99 'docker logs \$(docker ps -q --filter name=woo-monitor) | grep -i \"\[Cron\]\" | tail -5'" -ForegroundColor Gray

Write-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "              TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host

Write-Host "Next actions:" -ForegroundColor Yellow
Write-Host "1. Configure ashbi.ca SMTP password in .env (if not done)" -ForegroundColor Gray
Write-Host "2. Add WooCommerce stores to sites.json" -ForegroundColor Gray
Write-Host "3. Install plugin on WordPress sites" -ForegroundColor Gray
Write-Host "4. Test with real checkout errors" -ForegroundColor Gray

Write-Host
Write-Host "Documentation:" -ForegroundColor Yellow
Write-Host "- Complete guide: COMPLETE_DEPLOYMENT_GUIDE.md" -ForegroundColor Gray
Write-Host "- Coolify deployment: deploy-coolify.md" -ForegroundColor Gray
Write-Host "- Plugin README: ..\woo-monitor-plugin-improved\README.md" -ForegroundColor Gray

Write-Host
Write-Host "Support:" -ForegroundColor Yellow
Write-Host "- Coolify Dashboard: http://187.77.26.99:8000" -ForegroundColor Gray
Write-Host "- GitHub Server: https://github.com/camster91/woo-monitor" -ForegroundColor Gray
Write-Host "- Health Endpoint: https://monitor.ashbi.ca/api/health" -ForegroundColor Gray

Write-Host
Write-Host "Run this test after each deployment to verify system health." -ForegroundColor Green