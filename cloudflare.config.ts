import { defineConfig } from "cf/config";

export default defineConfig({
  worker: {
    name: "onepanel-client-web",
    compatibilityDate: "2026-11-16",
    domains: ["1pc.iskenkenya.com"],
    assets: {
      notFoundHandling: "single-page-application",
    },
  },
});
