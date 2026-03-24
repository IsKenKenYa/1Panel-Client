import 'package:flutter/foundation.dart';
import '../../../data/models/ssl_models.dart';
import '../services/website_certificate_service.dart';

class WebsiteSiteSslProvider extends ChangeNotifier {
  WebsiteSiteSslProvider({
    required this.websiteId,
    WebsiteCertificateService? service,
  }) : _service = service;

  final int websiteId;
  WebsiteCertificateService? _service;

  bool isLoading = false;
  String? error;
  WebsiteHttpsConfig? httpsConfig;
  WebsiteSSL? boundCertificate;

  Future<void> _ensureService() async {
    _service ??= WebsiteCertificateService();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _ensureService();
      final results = await Future.wait<dynamic>([
        _service!.getHttpsConfig(websiteId),
        _service!.getBoundCertificate(websiteId),
      ]);
      httpsConfig = results[0] as WebsiteHttpsConfig;
      boundCertificate = results[1] as WebsiteSSL?;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
