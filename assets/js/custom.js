/** * Function to add Google Analytics tag dynamically
 */

function addGoogleAnalyticsTag(trackingId) {
  // Load the gtag.js script asynchronously
  const script = document.createElement('script');
  script.async = true;
  script.src = `https://www.googletagmanager.com/gtag/js?id=${trackingId}`;
  document.head.appendChild(script);

  // Initialize the dataLayer and gtag function
  window.dataLayer = window.dataLayer || [];
  function gtag() {
    dataLayer.push(arguments);
  }

  // Initialize gtag
  gtag('js', new Date());
  gtag('config', trackingId);
}

// Call the function with your tracking ID
addGoogleAnalyticsTag('G-81E77KGMGF');


/**
 * Enhanced Cookie Consent Manager
 * Handles cookie consent banner with modern Google Analytics 4 (gtag.js)
 */
class CookieConsent {
  constructor(options = {}) {
    // Configuration with defaults
    this.config = {
      trackingId: 'G-81E77KGMGF',
      bannerDelay: 1000,
      fadeOutDuration: 300,
      ...options,
    };

    // Storage keys
    this.storageKeys = {
      bannerDisplayed: 'cookieBannerDisplayed',
      analyticsAllowed: 'analyticsIsAllowed',
      consentTimestamp: 'consentTimestamp',
    };

    this.cookieContainer = null;
    this.isInitialized = false;

    this.init();
  }

  /**
   * Inject optimized CSS styles with better responsive design
   */
  injectStyles() {
    // Prevent duplicate style injection
    if (document.getElementById('cookie-consent-styles')) return;

    const styles = `
      .cookie-container {
        position: fixed;
        z-index: 10010;
        background: var(--cookie-bg, #262626);
        color: var(--cookie-fg, #e2e8f0);
        border-radius: 0.375rem;
        box-shadow: 0 2px 8px rgba(0,0,0,0.10), 0 1.5px 4px rgba(0,0,0,0.08);
        padding: 1rem 2rem 1rem 1rem;
        bottom: 1rem;
        right: 1rem;
        max-width: 28rem;
        transition: all 0.3s cubic-bezier(0.4,0,0.2,1);
        opacity: 0;
        pointer-events: none;
      }
      .cookie-container.active {
        opacity: 1;
        pointer-events: auto;
      }
      @media (max-width: 640px) {
        .cookie-container {
          left: 0.5rem;
          right: 0.5rem;
          max-width: 98vw;
        }
      }
      .cookie-content {
        display: flex;
        flex-direction: column;
        gap: 1rem;
      }
      .cookie-message {
        font-size: 0.95rem;
        line-height: 1.5;
        margin: 0;
        word-break: break-word;
      }
      .cookie-message a {
        color: #6366f1;
        text-decoration: underline;
        transition: color 0.2s;
      }
      .cookie-message a:hover {
        color: #4f46e5;
      }
      .cookie-buttons {
        display: flex;
        gap: 0.5rem;
        justify-content: flex-end;
      }
      .cookie-btn, .nope-cookie-btn {
        padding: 0.4rem 1rem;
        border-radius: 0.5rem;
        font-size: 0.9rem;
        font-weight: 500;
        border: none;
        cursor: pointer;
        transition: background 0.2s, color 0.2s;
      }
      .cookie-btn {
        background: #6366f1;
        color: #fff;
      }
      .cookie-btn:hover {
        background: #4f46e5;
      }
      .nope-cookie-btn {
        background: transparent;
        color: #64748b;
        border: 1px solid #64748b;
      }
      .nope-cookie-btn:hover {
        background: #e2e8f0;
        color: #334155;
      }
      .cookie-btn:focus, .nope-cookie-btn:focus {
        outline: 2px solid #6366f1;
        outline-offset: 2px;
      }
      @media (prefers-color-scheme: dark) {
        .cookie-container {
          --cookie-bg: #f5f5f5;
          --cookie-fg: #334155;
        }
        .cookie-btn {
          background: #6366f1;
          color: #fff;
        }
        .cookie-btn:hover {
          background: #4f46e5;
        }
        .nope-cookie-btn {
          color: #475569;
          border-color: #cbd5e1;
        }
        .nope-cookie-btn:hover {
          background: #f1f5f9;
          color: #334155;
        }
      }
      .dark .cookie-container {
        --cookie-bg: #f5f5f5;
        --cookie-fg: #334155;
      }
      .dark .cookie-btn {
        background: #6366f1;
        color: #fff;
      }
      .dark .cookie-btn:hover {
        background: #4f46e5;
      }
      .dark .nope-cookie-btn {
        color: #475569;
        border-color: #cbd5e1;
      }
      .dark .nope-cookie-btn:hover {
        background: #f1f5f9;
        color: #334155;
      }
    `;

    const styleElement = document.createElement('style');
    styleElement.id = 'cookie-consent-styles';
    styleElement.textContent = styles;
    document.head.appendChild(styleElement);
  }

  /**
   * Create enhanced cookie banner with better accessibility
   */
  createCookieBanner() {
    const cookieContainer = document.createElement('div');
    cookieContainer.className = 'cookie-container';
    cookieContainer.setAttribute('role', 'banner');
    cookieContainer.setAttribute('aria-label', 'Cookie consent banner');

    const content = document.createElement('div');
    content.className = 'cookie-content';

    const message = document.createElement('p');
    message.className = 'cookie-message';
    message.innerHTML = 'Hello there cookie wizard 🧙‍♂️✨!<br>Can you be so kind and share some 🍪 ?';

    const buttonContainer = document.createElement('div');
    buttonContainer.className = 'cookie-buttons';

    const acceptButton = document.createElement('button');
    acceptButton.className = 'cookie-btn';
    acceptButton.textContent = "Sure bud, I'll help you out!";
    acceptButton.setAttribute('aria-label', 'Accept cookies');

    // const rejectButton = document.createElement('button');
    // rejectButton.className = 'nope-cookie-btn';
    // rejectButton.textContent = "Nah, I'm good";
    // rejectButton.setAttribute('aria-label', 'Decline cookies');

    buttonContainer.appendChild(acceptButton);
    // buttonContainer.appendChild(rejectButton);

    content.appendChild(message);
    content.appendChild(buttonContainer);
    cookieContainer.appendChild(content);

    document.body.appendChild(cookieContainer);

    return cookieContainer;
  }

  /**
   * Modern Google Analytics 4 implementation with gtag.js
   */
  initializeAnalytics() {
    if (window.gtag) return; // Prevent duplicate initialization

    // Load gtag.js script
    const script = document.createElement('script');
    script.async = true;
    script.src = `https://www.googletagmanager.com/gtag/js?id=${this.config.trackingId}`;
    document.head.appendChild(script);

    // Initialize dataLayer and gtag function
    window.dataLayer = window.dataLayer || [];
    window.gtag = function () {
      dataLayer.push(arguments);
    };

    // Configure Google Analytics
    gtag('js', new Date());
    gtag('config', this.config.trackingId, {
      anonymize_ip: true,
      allow_google_signals: false,
      allow_ad_personalization_signals: false,
    });

    // Track consent acceptance
    this.trackConsentEvent('accept');
  }

  /**
   * Track consent events for analytics
   */
  trackConsentEvent(action) {
    if (window.gtag) {
      gtag('event', 'cookie_consent', {
        event_category: 'engagement',
        event_label: action,
        value: 1,
      });
    }
  }

  /**
   * Handle accept button click with enhanced tracking
   */
  handleAccept() {
    const timestamp = new Date().toISOString();

    localStorage.setItem(this.storageKeys.bannerDisplayed, 'true');
    localStorage.setItem(this.storageKeys.analyticsAllowed, 'true');
    localStorage.setItem(this.storageKeys.consentTimestamp, timestamp);

    this.initializeAnalytics();
    this.hideBanner();
  }

  /**
   * Handle reject button click with tracking
   */
  handleReject() {
    const timestamp = new Date().toISOString();

    localStorage.setItem(this.storageKeys.bannerDisplayed, 'true');
    localStorage.setItem(this.storageKeys.analyticsAllowed, 'false');
    localStorage.setItem(this.storageKeys.consentTimestamp, timestamp);

    this.trackConsentEvent('decline');
    this.hideBanner();
  }

  /**
   * Hide banner with smooth animation
   */
  hideBanner() {
    if (!this.cookieContainer) return;

    this.cookieContainer.classList.remove('active');

    // Remove from DOM after animation completes
    setTimeout(() => {
      if (this.cookieContainer && this.cookieContainer.parentNode) {
        this.cookieContainer.parentNode.removeChild(this.cookieContainer);
      }
    }, this.config.fadeOutDuration);
  }

  /**
   * Show banner with animation
   */
  showBanner() {
    if (!this.cookieContainer) return;

    // Use requestAnimationFrame for smooth animation
    requestAnimationFrame(() => {
      this.cookieContainer.classList.add('active');
    });
  }

  /**
   * Check if consent is still valid (optional: expire after 1 year)
   */
  isConsentValid() {
    const timestamp = localStorage.getItem(this.storageKeys.consentTimestamp);
    if (!timestamp) return false;

    const consentDate = new Date(timestamp);
    const now = new Date();
    const oneYear = 365 * 24 * 60 * 60 * 1000; // 1 year in milliseconds

    return now - consentDate < oneYear;
  }

  /**
   * Initialize the cookie consent system
   */
  init() {
    if (this.isInitialized) return;

    this.injectStyles();

    // Check for existing valid consent
    const bannerDisplayed = localStorage.getItem(this.storageKeys.bannerDisplayed);
    const analyticsAllowed = localStorage.getItem(this.storageKeys.analyticsAllowed);

    if (analyticsAllowed === 'true' && this.isConsentValid()) {
      this.initializeAnalytics();
    }

    // Show banner if not previously displayed or consent expired
    if (!bannerDisplayed || !this.isConsentValid()) {
      this.cookieContainer = this.createCookieBanner();

      // Add event listeners with proper cleanup
      const acceptButton = this.cookieContainer.querySelector('.cookie-btn');
      // const rejectButton = this.cookieContainer.querySelector('.nope-cookie-btn');

      acceptButton.addEventListener('click', () => this.handleAccept());
      // rejectButton.addEventListener('click', () => this.handleReject());

      // Show banner with delay
      setTimeout(() => {
        this.showBanner();
      }, this.config.bannerDelay);
    }

    this.isInitialized = true;
  }

  /**
   * Public method to reset consent (useful for testing)
   */
  resetConsent() {
    Object.values(this.storageKeys).forEach(key => {
      localStorage.removeItem(key);
    });
    window.location.reload();
  }
}

/**
 * Initialize Cookie Consent Manager
 * Supports both immediate and deferred loading
 */
(function initializeCookieConsent() {
  function createCookieConsent() {
    // Only create one instance
    if (window.cookieConsentInstance) return;

    window.cookieConsentInstance = new CookieConsent({
      trackingId: 'G-81E77KGMGF',
      bannerDelay: 800,
    });
  }

  // Initialize based on document ready state
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', createCookieConsent);
  } else {
    // DOM is already loaded
    createCookieConsent();
  }

  // Expose reset function for development/testing
  if (typeof window !== 'undefined') {
    window.resetCookieConsent = function () {
      if (window.cookieConsentInstance) {
        window.cookieConsentInstance.resetConsent();
      }
    };
  }
})();
