import '../../../api/v2/website_v2.dart';
import '../../../core/network/api_client_manager.dart';
import '../../../data/models/website_models.dart';

class WebsiteDomainService {
  WebsiteDomainService({WebsiteV2Api? api}) : _api = api;

  WebsiteV2Api? _api;

  Future<WebsiteV2Api> _ensureApi() async {
    _api ??= await ApiClientManager.instance.getWebsiteApi();
    return _api!;
  }

  Future<List<WebsiteDomain>> getDomains(int websiteId) async {
    final api = await _ensureApi();
    return api.getWebsiteDomains(websiteId);
  }

  Future<List<WebsiteDomain>> fetchDomains(int websiteId) {
    return getDomains(websiteId);
  }

  Future<void> addDomain({
    required int websiteId,
    required String domain,
    required int port,
    bool ssl = false,
  }) async {
    final api = await _ensureApi();
    await api.addWebsiteDomains(
      websiteId: websiteId,
      domains: [
        {
          'domain': domain,
          'port': port,
          'ssl': ssl,
        },
      ],
    );
  }

  Future<void> updateDomain({
    required int id,
    String? domain,
    int? port,
    bool? ssl,
  }) async {
    final api = await _ensureApi();
    await api.updateWebsiteDomainSsl(
      id: id,
      domain: domain,
      port: port,
      ssl: ssl,
    );
  }

  Future<void> updateDomainSsl({
    required int id,
    required bool ssl,
  }) {
    return updateDomain(id: id, ssl: ssl);
  }

  Future<void> deleteDomain(int id) async {
    final api = await _ensureApi();
    await api.deleteWebsiteDomain(id: id);
  }
}
