import 'dart:typed_data';

class BrowserFileOperations {
  static Future<void> preparePdfRenderer() async =>
      throw UnsupportedError('Browser file operations required');
  static String createUrl(Uint8List bytes, {String? mimeType}) =>
      throw UnsupportedError('Browser file operations required');
  static void revokeUrl(String url) =>
      throw UnsupportedError('Browser file operations required');
  static String download(Uint8List bytes, String fileName, {String? mimeType}) =>
      throw UnsupportedError('Browser file operations required');
}
