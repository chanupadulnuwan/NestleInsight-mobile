const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './tests',
  testMatch: '**/*.js',
  timeout: 90000,
  workers: 1,
  reporter: 'html',
  use: {
    headless: false,
    browserName: 'chromium',
  },
  projects: [
    {
      name: 'chromium',
      use: { browserName: 'chromium' },
    },
  ],
});
