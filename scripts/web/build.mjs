import { cp, mkdir, rm } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../../", import.meta.url));
await rm(new URL("../../web/vendor/pdfjs/", import.meta.url), { recursive: true, force: true });
await rm(new URL("../../build/web/", import.meta.url), { recursive: true, force: true });
await mkdir(new URL("../../web/vendor/pdfjs/", import.meta.url), { recursive: true });
for (const directory of ["cmaps", "standard_fonts", "wasm"]) {
  await cp(
    new URL(`../../node_modules/pdfjs-dist/${directory}/`, import.meta.url),
    new URL(`../../web/vendor/pdfjs/${directory}/`, import.meta.url),
    { recursive: true },
  );
}
await mkdir(new URL("../../web/vendor/pdfjs/legacy/build/", import.meta.url), { recursive: true });
for (const name of ["pdf.min.mjs", "pdf.worker.min.mjs"]) {
  await cp(
    new URL(`../../node_modules/pdfjs-dist/legacy/build/${name}`, import.meta.url),
    new URL(`../../web/vendor/pdfjs/legacy/build/${name}`, import.meta.url),
  );
}
await cp(
  new URL("../../node_modules/pdfjs-dist/LICENSE", import.meta.url),
  new URL("../../web/vendor/pdfjs/LICENSE", import.meta.url),
);
const result = spawnSync(process.env.FLUTTER_BIN ?? "flutter", [
  "build", "web", "--release", "--no-web-resources-cdn", "--pwa-strategy", "none",
], { cwd: root, stdio: "inherit" });
if (result.error) throw result.error;
process.exitCode = result.status ?? 1;
