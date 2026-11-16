const loading = document.getElementById("loading");
const error = document.getElementById("loading-error");
const reload = document.getElementById("reload");
reload.addEventListener("click", () => window.location.reload());
const showError = () => {
  if (loading.isConnected) {
    error.hidden = false;
    reload.hidden = false;
  }
};
window.addEventListener("error", showError);
window.addEventListener("unhandledrejection", showError);
window.addEventListener("flutter-first-frame", () => {
  loading.remove();
  // Flutter 初始化后恢复浏览器缩放与安全区域设置。
  document.querySelector('meta[name="viewport"]').content =
    "width=device-width, initial-scale=1, viewport-fit=cover";
}, { once: true });

let pdfRenderer;
window.onepanelLoadPdf = () => {
  pdfRenderer ??= import("./vendor/pdfjs/legacy/build/pdf.min.mjs").then((library) => {
    library.GlobalWorkerOptions.workerSrc =
      new URL("./vendor/pdfjs/legacy/build/pdf.worker.min.mjs", document.baseURI).href;
    window.pdfjsLib = library;
  });
  return pdfRenderer;
};
