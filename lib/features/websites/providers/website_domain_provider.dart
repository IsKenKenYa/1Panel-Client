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
  }) async {
    await _service.addDomain(
      websiteId: websiteId,
      domain: domain,
      port: port,
      ssl: ssl,
    );
    await loadDomains();
  }

  Future<void> updateDomainSsl({
    required int id,
    required bool ssl,
  }) async {
    await _service.updateDomainSsl(id: id, ssl: ssl);
    await loadDomains();
  }

  Future<void> deleteDomain(int id) async {
    await _service.deleteDomain(id);
    await loadDomains();
  }
}
