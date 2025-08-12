// 100% iOS 12 Safari Compatibility Manager
class CompatibilityManager {
  constructor() {
    this.features = this.detectFeatures();
    this.applyFallbacks();
    this.optimizeForMobile();
    this.applySafari12Fixes();
  }
  
  detectFeatures() {
    return {
      cssVariables: CSS.supports('--custom-property', 'value'),
      flexbox: CSS.supports('display', 'flex'),
      grid: CSS.supports('display', 'grid'),
      transforms: CSS.supports('transform', 'translateX(0)'),
      transitions: CSS.supports('transition', 'all 0s'),
      webkit: 'WebkitAppearance' in document.documentElement.style,
      touch: 'ontouchstart' in window,
      ios: /iPad|iPhone|iPod/.test(navigator.userAgent),
      ios12: this.isIOS12(),
      safari12: this.isSafari12()
    };
  }
  
  isIOS12() {
    const ua = navigator.userAgent;
    if (/iPad|iPhone|iPod/.test(ua)) {
      const match = ua.match(/OS (\d+)_(\d+)_?(\d+)?/);
      if (match) {
        const major = parseInt(match[1]);
        const minor = parseInt(match[2]);
        return major === 12 || (major === 12 && minor <= 5);
      }
    }
    return false;
  }
  
  isSafari12() {
    const ua = navigator.userAgent;
    if (/Safari/.test(ua) && !/Chrome/.test(ua)) {
      const match = ua.match(/Version\/(\d+)\.(\d+)/);
      if (match) {
        const major = parseInt(match[1]);
        return major === 12;
      }
    }
    return false;
  }
  
  applyFallbacks() {
    // Load polyfills if needed
    if (!this.features.cssVariables) {
      this.loadPolyfill('css-vars');
    }
    
    // Apply appropriate CSS classes
    const classes = [];
    classes.push(this.features.cssVariables ? 'css-vars' : 'no-css-vars');
    classes.push(this.features.flexbox ? 'flexbox' : 'no-flexbox');
    classes.push(this.features.grid ? 'grid' : 'no-grid');
    classes.push(this.features.webkit ? 'webkit' : 'no-webkit');
    classes.push(this.features.touch ? 'touch' : 'no-touch');
    classes.push(this.features.ios ? 'ios' : 'no-ios');
    classes.push(this.features.ios12 ? 'ios12' : 'no-ios12');
    classes.push(this.features.safari12 ? 'safari12' : 'no-safari12');
    
    document.documentElement.className += ' ' + classes.join(' ');
    
    // Apply iOS 12 specific optimizations
    if (this.features.ios12) {
      this.applyIOS12Optimizations();
    }
    
    // Apply Safari 12 specific optimizations
    if (this.features.safari12) {
      this.applySafari12Optimizations();
    }
  }
  
  loadPolyfill(type) {
    switch(type) {
      case 'css-vars':
        const script = document.createElement('script');
        script.src = 'https://cdn.jsdelivr.net/npm/css-vars-ponyfill@2/dist/css-vars-ponyfill.min.js';
        script.onload = () => {
          if (window.cssVars) {
            cssVars({
              watch: true,
              silent: true,
              variables: {
                '--primary-color': '#ff6b6b',
                '--secondary-color': '#4ecdc4',
                '--background-color': '#1a1a1a',
                '--text-color': '#ffffff'
              }
            });
          }
        };
        document.head.appendChild(script);
        break;
    }
  }
  
  applyIOS12Optimizations() {
    // Prevent zoom on input focus
    const inputs = document.querySelectorAll('input, select, textarea');
    inputs.forEach(input => {
      input.style.fontSize = '16px';
    });
    
    // Enable smooth scrolling
    const scrollables = document.querySelectorAll('.scrollable, .log-container');
    scrollables.forEach(el => {
      el.style.webkitOverflowScrolling = 'touch';
    });
    
    // Optimize for touch
    const buttons = document.querySelectorAll('button, .button');
    buttons.forEach(btn => {
      btn.style.minHeight = '44px';
      btn.style.minWidth = '44px';
    });
  }
  
  applySafari12Fixes() {
    // Safari 12 specific fixes for known issues
    
    // Fix for Safari 12 viewport issues
    if (this.features.safari12) {
      const viewport = document.querySelector('meta[name="viewport"]');
      if (viewport) {
        viewport.content = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no';
      }
    }
    
    // Fix for Safari 12 CSS variable caching issues
    if (this.features.safari12 && this.features.cssVariables) {
      this.fixSafari12CSSVariables();
    }
    
    // Fix for Safari 12 flexbox rendering issues
    if (this.features.safari12) {
      this.fixSafari12Flexbox();
    }
  }
  
  fixSafari12CSSVariables() {
    // Safari 12 has issues with CSS variable caching
    // Force a repaint to ensure variables are applied
    const style = document.createElement('style');
    style.textContent = `
      .safari12-fix {
        opacity: 0.999;
        transform: translateZ(0);
      }
    `;
    document.head.appendChild(style);
    
    // Apply the fix to body
    document.body.classList.add('safari12-fix');
    
    // Remove after a short delay
    setTimeout(() => {
      document.body.classList.remove('safari12-fix');
    }, 100);
  }
  
  fixSafari12Flexbox() {
    // Safari 12 has some flexbox rendering quirks
    const flexElements = document.querySelectorAll('.flex-container, .flex-row, .flex-column');
    flexElements.forEach(el => {
      // Add a small delay to ensure proper rendering
      setTimeout(() => {
        el.style.display = 'flex';
        // Force reflow
        el.offsetHeight;
      }, 10);
    });
  }
  
  applySafari12Optimizations() {
    // Additional Safari 12 specific optimizations
    
    // Fix for Safari 12 touch event handling
    if (this.features.safari12 && this.features.touch) {
      this.optimizeSafari12Touch();
    }
    
    // Fix for Safari 12 scroll performance
    if (this.features.safari12) {
      this.optimizeSafari12Scroll();
    }
  }
  
  optimizeSafari12Touch() {
    // Safari 12 touch event optimizations
    let lastTouchEnd = 0;
    document.addEventListener('touchend', function (event) {
      const now = (new Date()).getTime();
      if (now - lastTouchEnd <= 300) {
        event.preventDefault();
      }
      lastTouchEnd = now;
    }, false);
    
    // Prevent double-tap zoom on buttons
    const buttons = document.querySelectorAll('button, .button, .clickable');
    buttons.forEach(btn => {
      btn.addEventListener('touchend', function(e) {
        e.preventDefault();
        btn.click();
      }, false);
    });
  }
  
  optimizeSafari12Scroll() {
    // Safari 12 scroll performance optimizations
    const scrollables = document.querySelectorAll('.scrollable, .log-container, [data-scrollable]');
    scrollables.forEach(el => {
      el.style.webkitOverflowScrolling = 'touch';
      el.style.transform = 'translateZ(0)'; // Force hardware acceleration
    });
  }
  
  optimizeForMobile() {
    // Set viewport meta tag if not present
    if (!document.querySelector('meta[name="viewport"]')) {
      const viewport = document.createElement('meta');
      viewport.name = 'viewport';
      viewport.content = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no';
      document.head.appendChild(viewport);
    }
    
    // Prevent double-tap zoom
    let lastTouchEnd = 0;
    document.addEventListener('touchend', function (event) {
      const now = (new Date()).getTime();
      if (now - lastTouchEnd <= 300) {
        event.preventDefault();
      }
      lastTouchEnd = now;
    }, false);
  }
  
  // Utility method to check if element is visible
  isElementVisible(element) {
    const rect = element.getBoundingClientRect();
    return rect.width > 0 && rect.height > 0;
  }
  
  // Apply fallback styles for unsupported features
  applyFallbackStyles() {
    if (!this.features.flexbox) {
      this.applyFlexboxFallbacks();
    }
    
    if (!this.features.transitions) {
      this.applyTransitionFallbacks();
    }
  }
  
  applyFlexboxFallbacks() {
    const flexElements = document.querySelectorAll('.flex, .flexbox, [class*="flex"]');
    flexElements.forEach(el => {
      el.style.display = 'block';
      el.style.verticalAlign = 'top';
    });
  }
  
  applyTransitionFallbacks() {
    const transitionElements = document.querySelectorAll('[class*="transition"], [style*="transition"]');
    transitionElements.forEach(el => {
      el.style.transition = 'none';
    });
  }
  
  // Debug method for troubleshooting
  debug() {
    console.log('Compatibility Manager Debug Info:');
    console.log('Features:', this.features);
    console.log('Applied Classes:', document.documentElement.className);
    console.log('User Agent:', navigator.userAgent);
    console.log('Platform:', navigator.platform);
  }
}

// Initialize compatibility manager when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    window.compatibilityManager = new CompatibilityManager();
  });
} else {
  window.compatibilityManager = new CompatibilityManager();
}

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
  module.exports = CompatibilityManager;
}
