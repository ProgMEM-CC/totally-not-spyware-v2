// ngrok Bypass Script
function bypassNgrokWarning() {
    // Method 1: Try to set custom headers via fetch
    if (window.location.hostname.includes('ngrok')) {
        console.log('ngrok detected, attempting bypass...');
        
        // Try to bypass with custom headers
        fetch(window.location.href, {
            headers: {
                'ngrok-skip-browser-warning': 'true',
                'User-Agent': 'TotallyNotSpyware-v2-PWA'
            }
        }).then(response => {
            if (response.ok) {
                console.log('ngrok bypass successful');
                window.location.reload();
            }
        }).catch(error => {
            console.log('ngrok bypass failed:', error);
        });
    }
}

// Auto-run bypass
bypassNgrokWarning();
