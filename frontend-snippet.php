<?php
/**
 * WooCommerce & Stripe Frontend Error Tracker
 * Deploy this code via ManageWP to your functions.php or Code Snippets on all 25 sites.
 * 
 * Make sure to replace YOUR_SERVER_URL with the actual URL where your Node.js monitoring server is running.
 */
add_action('wp_footer', 'woocommerce_error_tracker_script');
function woocommerce_error_tracker_script() {
    if ( !is_checkout() && !is_cart() && !is_product() ) return;
    ?>
    <script>
    document.addEventListener("DOMContentLoaded", function() {
        const webhookUrl = "https://YOUR_SERVER_URL.com/api/track-woo-error"; // <-- REPLACE THIS!
        const siteName = window.location.hostname;

        // 1. Catch WooCommerce UI Error Banners (e.g., "Invalid Card", "No shipping options")
        const observer = new MutationObserver(function(mutations) {
            mutations.forEach(function(mutation) {
                const errorNodes = document.querySelectorAll('.woocommerce-error, .woocommerce-NoticeGroup-checkout');
                errorNodes.forEach(node => {
                    // Prevent duplicate sending
                    if (!node.dataset.reported) {
                        node.dataset.reported = "true";
                        sendErrorAlert("WooCommerce UI Error", node.innerText.trim());
                    }
                });
            });
        });
        observer.observe(document.body, { childList: true, subtree: true });

        // 2. Catch AJAX "Add to Cart" or "Checkout" Failures
        if (typeof jQuery !== 'undefined') {
            jQuery(document).ajaxError(function(event, jqxhr, settings, thrownError) {
                if (settings.url && (settings.url.includes('wc-ajax=add_to_cart') || settings.url.includes('wc-ajax=checkout'))) {
                    sendErrorAlert("AJAX Checkout/Cart Failure", `Failed URL: ${settings.url} | Error: ${jqxhr.statusText}`);
                }
            });
        }

        // 3. Catch Global JavaScript Errors (This catches broken/unclickable buttons from cached JS/Themes)
        window.addEventListener('error', function(e) {
            // Ignore benign third-party errors, focus on main thread that might break checkout
            if (e.filename && e.filename.includes(siteName)) {
                sendErrorAlert("JavaScript Crash (Might break buttons)", `${e.message} at ${e.filename}:${e.lineno}`);
            }
        });

        function sendErrorAlert(type, message) {
            fetch(webhookUrl, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    site: siteName,
                    url: window.location.href,
                    type: type,
                    error_message: message,
                    time: new Date().toISOString()
                })
            }).catch(console.error); // Silently catch errors if monitor is down
        }
    });
    </script>
    <?php
}
