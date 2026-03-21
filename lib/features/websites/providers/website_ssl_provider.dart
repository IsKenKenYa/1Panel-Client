import 'package:flutter/foundation.dart';

import '../../../data/models/ssl_models.dart';
import '../services/website_ssl_service.dart';

class WebsiteSslProvider extends ChangeNotifier {
  final int websiteId;
  final WebsiteSslService _service;

  WebsiteSslProvider({
    required this.websiteId,
    WebsiteSslService? service,
  }) : _service = service ?? WebsiteSslService();

  bool isLoading = false;
  String? error;

  WebsiteHttpsConfig? httpsConfig;
  WebsiteSSL? websiteSsl;
  List<WebsiteSSL> certificates = const [];

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadHttpsConfig(),
        loadWebsiteSsl(),
        searchCertificates(),
      ]);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHttpsConfig() async {
    httpsConfig = await _service.fetchHttpsConfig(websiteId);
    notifyListeners();
  }

  Future<void> updateHttpsConfig(WebsiteHttpsUpdateRequest request) async {
    httpsConfig = await _service.updateHttpsConfig(websiteId: websiteId, request: request);
    notifyListeners();
  }

  Future<void> loadWebsiteSsl() async {
    websiteSsl = await _service.fetchWebsiteSslByWebsiteId(websiteId);
    notifyListeners();
  }

  Future<void> searchCertificates() async {
    certificates = await _service.searchCertificates(
      page: 1,
      pageSize: 20,
      order: 'descending',
      orderBy: 'expire_date',
    );
    notifyListeners();
  }

  Future<void> createCertificate(WebsiteSSLCreate request) async {
    await _service.createCertificate(request);
    await searchCertificates();
  }

  Future<void> applyCertificate(WebsiteSSLApply request) {
    return _service.applyCertificate(request);
  }

  Future<void> resolveCertificate(WebsiteSSLResolve request) {
    return _service.resolveCertificate(request);
  }

  Future<void> updateCertificate(WebsiteSSLUpdate request) async {
    await _service.updateCertificate(request);
    await searchCertificates();
    await loadWebsiteSsl();
  }

  Future<void> uploadCertificate(WebsiteSSLUpload request) async {
    await _service.uploadCertificate(request);
    await searchCertificates();
  }

  Future<void> deleteCertificate(int id) async {
    await _service.deleteCertificate(id);
    await searchCertificates();
  }

  Future<String?> downloadCertificate(int id) {
    return _service.downloadCertificate(id);
  }
}
