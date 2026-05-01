import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';

import '../../../data/models/ssl_models.dart';
import '../services/website_ssl_service.dart';

class WebsiteCertificateDetailProvider extends ChangeNotifier
    with SafeChangeNotifier {
  final int certificateId;
  final WebsiteSslService _service;

  WebsiteCertificateDetailProvider({
    required this.certificateId,
    WebsiteSslService? service,
  }) : _service = service ?? WebsiteSslService();

  bool isLoading = false;
  bool isUpdating = false;
  String? error;
  WebsiteSSL? certificate;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      certificate = await _service.fetchCertificateById(certificateId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> apply(WebsiteSSLApply request) async {
    await _runUpdate(() => _service.applyCertificate(request));
  }

  Future<void> resolve(WebsiteSSLResolve request) async {
    await _runUpdate(() => _service.resolveCertificate(request));
  }

  Future<void> update(WebsiteSSLUpdate request) async {
    await _runUpdate(() => _service.updateCertificate(request), reload: true);
  }

  Future<void> delete() async {
    await _runUpdate(() => _service.deleteCertificate(certificateId));
  }

  Future<String?> download() {
    return _service.downloadCertificate(certificateId);
  }

  Future<void> _runUpdate(
    Future<void> Function() action, {
    bool reload = false,
  }) async {
    isUpdating = true;
    error = null;
    notifyListeners();
    try {
      await action();
      if (reload) {
        certificate = await _service.fetchCertificateById(certificateId);
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }
}
