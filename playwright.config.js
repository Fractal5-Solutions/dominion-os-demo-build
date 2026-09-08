/** @type {import('@playwright/test').PlaywrightTestConfig} */
module.exports = {
  timeout: 60000,
  expect: {
    timeout: 15000
  },
  use: {
    browserName: "chromium",
    headless: false,
    viewport: { width: 1440, height: 1100 },
    screenshot: "only-on-failure",
    video: "retain-on-failure",
    trace: "retain-on-failure"
  },
  projects: [
    {
      name: "chromium",
      use: { browserName: "chromium" }
    }
  ]
};
