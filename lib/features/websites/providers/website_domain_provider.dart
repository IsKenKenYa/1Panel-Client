import 'package:flutter/foundation.dart';

import '../../../data/models/website_models.dart';
import '../services/website_domain_service.dart';

class WebsiteDomainProvider extends ChangeNotifier {
  final int websiteId;
  final WebsiteDomainService _service;

  WebsiteDomainProvider({
    required this.websiteId,
    WebsiteDomainService? service,
  }) : _service = service ?? WebsiteDomainService();

  bool isLoading = false;
  String? error;
  List<WebsiteDomain> domains = const [];

  Future<void> loadDomains() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      domains = await _service.fetchDomains(websiteId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDomain({
    required String domain,
    required int port,
    bool ssl = false,
  }) {
    return _runMutation(() async {
      await _service.addDomain(
        websiteId: websiteId,
        domain: domain,
        port: port,
        ssl: ssl,
      );
    });
  }

  Future<void> updateDomain({
    required int id,
    String? domain,
    int? port,
    bool? ssl,
  }) {
    return _runMutation(() async {
      await _service.updateDomain(
        id: id,
        domain: domain,
        port: port,
        ssl: ssl,
      );
    });
  }

  Future<void> updateDomainSsl({
    required int id,
    required bool ssl,
  }) {
    return _runMutation(() async {
      await _service.updateDomainSsl(id: id, ssl: ssl);
    });
  }

  Future<void> deleteDomain(int id) {
    return _runMutation(() async {
      await _service.deleteDomain(id);
    });
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    error = null;
    notifyListeners();
    try {
      await action();
      await loadDomains();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
