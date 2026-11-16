import 'package:web/web.dart' as web;

class BrowserDocumentService {
  static void updateLanguage(String language) {
    web.document.documentElement!.setAttribute('lang', language);
  }
}
