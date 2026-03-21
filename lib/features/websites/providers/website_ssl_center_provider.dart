import 'package:flutter/foundation.dart';
import '../../../data/models/ssl_models.dart';
import '../services/website_certificate_service.dart';

class WebsiteSslCenterProvider extends ChangeNotifier {
  WebsiteSslCenterProvider({WebsiteCertificateService? service}) : _service = service;

  WebsiteCertificateService? _service;

  bool isLoading = false;
  String? error;
  List<WebsiteSSL> certificates = const <WebsiteSSL>[];

  Future<void> _ensureService() async {
    _service ??= WebsiteCertificateService();
  }

  Future<void> load({String? domain}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _ensureService();
      certificates = await _service!.searchCertificates(domain: domain);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCertificate(int id) async {
    try {
      await _ensureService();
      await _service!.deleteCertificate(id);
      await load();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> createCertificate(WebsiteSSLCreate request) async {
    await _ensureService();
    await _service!.createCertificate(request);
    await load();
  }

  Future<void> uploadCertificate(WebsiteSSLUpload request) async {
    await _ensureService();
    await _service!.uploadCertificate(request);
    await load();
  }
}
