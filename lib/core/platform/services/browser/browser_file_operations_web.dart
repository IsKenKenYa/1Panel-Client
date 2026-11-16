import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

@JS('onepanelLoadPdf')
external JSPromise<JSAny?> _loadPdf();

class BrowserFileOperations {
  static Future<void> preparePdfRenderer() async {
    await _loadPdf().toDart;
  }
  static String createUrl(Uint8List bytes, {String? mimeType}) {
    final blob = web.Blob([bytes.toJS].toJS,
        web.BlobPropertyBag(type: mimeType ?? 'application/octet-stream'));
    return web.URL.createObjectURL(blob);
  }

  static void revokeUrl(String url) => web.URL.revokeObjectURL(url);

  static String download(Uint8List bytes, String fileName, {String? mimeType}) {
    final url = createUrl(bytes, mimeType: mimeType);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName;
    web.document.body!.appendChild(anchor);
    anchor.click();
    anchor.remove();
    // Safari 需要在下载开始后释放 Blob URL。
    Timer(const Duration(minutes: 1), () => revokeUrl(url));
    return url;
  }
}
