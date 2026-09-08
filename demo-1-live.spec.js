const { test, expect } = require("@playwright/test");

const urls = {
  page: "https://www.fractal5solutions.com/demo-1",
  demo: "https://demo-reduwyf2ra-uc.a.run.app/demo",
  health: "https://demo-reduwyf2ra-uc.a.run.app/health",
  status: "https://demo-reduwyf2ra-uc.a.run.app/status",
  manifest: "https://raw.githubusercontent.com/Fractal5-Solutions/dominion-os-demo-build/main/demo/assets/demo-manifest.json",
  poster: "https://raw.githubusercontent.com/Fractal5-Solutions/dominion-os-demo-build/main/demo/assets/dominion-os-demo-poster.svg",
  sampleData: "https://raw.githubusercontent.com/Fractal5-Solutions/dominion-os-demo-build/main/demo/assets/sample-data.json",
  demoPackage: "https://raw.githubusercontent.com/Fractal5-Solutions/dominion-os-demo-build/main/demo/assets/demo-download-package.json",
  receipts: "https://raw.githubusercontent.com/Fractal5-Solutions/dominion-os-demo-build/main/demo/assets/release-receipts.json"
};

test("demo-1 live page renders required public experience", async ({ page }) => {
  await page.goto(urls.page, { waitUntil: "networkidle" });

  await expect(page.getByText("Dominion OS, live on the cloud.")).toBeVisible();
  await expect(page.getByText("Open Live Demo").first()).toBeVisible();
  await expect(page.getByText("Watch Video").first()).toBeVisible();
  await expect(page.getByText("Play With Data").first()).toBeVisible();
  await expect(page.getByText("Health JSON").first()).toBeVisible();
  await expect(page.getByText("Status JSON").first()).toBeVisible();
  await expect(page.getByText("View Sample Data").first()).toBeVisible();
  await expect(page.getByText("Open Demo Package").first()).toBeVisible();
  await expect(page.getByText("Open Receipts").first()).toBeVisible();
  await expect(page.getByText("Contact Fractal5").first()).toBeVisible();

  await expect(page.locator("#f5-demo-poster")).toBeVisible();

  const body = await page.textContent("body");
  const forbidden = ["BEGIN PRIVATE KEY", "client_secret", "ghp_", "gho_", "sk_live_"];
  for (const marker of forbidden) {
    expect(body).not.toContain(marker);
  }
});

test("public routes and assets return 200", async ({ request }) => {
  for (const [name, url] of Object.entries(urls)) {
    const res = await request.get(url);
    expect(res.status(), `${name} ${url}`).toBe(200);
  }
});

test("manifest is honest about direct MP4", async ({ request }) => {
  const res = await request.get(urls.manifest);
  expect(res.status()).toBe(200);

  const manifest = await res.json();
  expect(manifest.assets.videoPoster).toContain("dominion-os-demo-poster.svg");
  expect(manifest.assets.sampleData).toContain("sample-data.json");
  expect(manifest.assets.demoDownload).toContain("demo-download-package.json");
  expect(manifest.assets.releaseReceiptsJson).toContain("release-receipts.json");
  expect(manifest.assets.videoMp4).toBeNull();
});
