module.exports = {
  ci: {
    collect: {
      // Number of audits to run per URL
      numberOfRuns: 3,

      // URLs to audit - adjust these based on your important pages
      url: [
        "http://localhost:3000",
        // 'http://localhost:3000/about',
        // 'http://localhost:3000/contact',
        // 'http://localhost:3000/properties',
      ],

      // Start server command for CI
      startServerCommand: "yarn start",
      startServerReadyPattern: "ready on",
      startServerReadyTimeout: 30000,

      // Chrome settings for consistent testing
      settings: {
        chromeFlags: [
          "--headless",
          "--no-sandbox",
          "--disable-dev-shm-usage",
          "--disable-gpu",
        ],
        // Use mobile emulation for mobile-first testing
        preset: "desktop",
        // Or use 'mobile' for mobile testing

        // Only run performance category to focus on Core Web Vitals
        onlyCategories: ["performance"],

        // Disable PWA audits if not needed
        skipAudits: [
          "service-worker",
          "installable-manifest",
          "splash-screen",
          "themed-omnibox",
          "maskable-icon",
        ],
      },
    },

    assert: {
      // Simplified configuration - focus only on Core Web Vitals
      includePassedAssertions: false,

      // Only test Core Web Vitals metrics for performance regression
      assertions: {
        // Core Web Vitals only - the metrics that actually matter for user experience
        "largest-contentful-paint": [
          "error",
          {
            maxNumericValue: 4000,
            aggregationMethod: "median-run",
          },
        ],
        "first-contentful-paint": [
          "error",
          {
            maxNumericValue: 3000,
            aggregationMethod: "median-run",
          },
        ],
        "cumulative-layout-shift": [
          "error",
          {
            maxNumericValue: 0.25,
            aggregationMethod: "median-run",
          },
        ],
        "total-blocking-time": [
          "error",
          {
            maxNumericValue: 600,
            aggregationMethod: "median-run",
          },
        ],
      },
    },

    upload: {
      // Configure Lighthouse CI server for storing results and baselines
      target: "temporary-public-storage",
      // For production, you might want to use LHCI server:
      // target: 'lhci',
      // serverBaseUrl: 'https://your-lhci-server.com',
      // token: process.env.LHCI_TOKEN,
    },

    // GitHub status check configuration
    wizard: {
      // Set up GitHub integration
      githubAppToken: process.env.LHCI_GITHUB_APP_TOKEN,
      githubToken: process.env.GITHUB_TOKEN,
    },
  },

  // Custom configuration for CI environments
  ...(process.env.CI && {
    ci: {
      collect: {
        // In CI, build the app first
        startServerCommand: "yarn localbuild && yarn start",

        // Adjust URLs for CI environment
        url: [
          "http://localhost:3000",
          // "http://localhost:3000/about",
          // "http://localhost:3000/contact",
          // "http://localhost:3000/properties",
        ],

        // CI-specific Chrome flags
        settings: {
          chromeFlags: [
            "--headless",
            "--no-sandbox",
            "--disable-dev-shm-usage",
            "--disable-gpu",
            "--disable-web-security",
            "--allow-running-insecure-content",
          ],
        },
      },

      // CI-specific assertions with baseline comparison - Core Web Vitals only
      assert: {
        // Only test Core Web Vitals for regression detection
        assertions: {
          // Core Web Vitals regression detection with baseline comparison
          "largest-contentful-paint": [
            "error",
            {
              maxNumericValue: "auto",
              baselinePercentDelta: 0.2, // Allow 20% increase from baseline
            },
          ],
          "first-contentful-paint": [
            "error",
            {
              maxNumericValue: "auto",
              baselinePercentDelta: 0.2, // Allow 20% increase from baseline
            },
          ],
          "cumulative-layout-shift": [
            "error",
            {
              maxNumericValue: "auto",
              baselinePercentDelta: 0.2, // Allow 20% increase in CLS
            },
          ],
          "total-blocking-time": [
            "error",
            {
              maxNumericValue: "auto",
              baselinePercentDelta: 0.2, // Allow 20% increase from baseline
            },
          ],
        },
      },
    },
  }),
};
