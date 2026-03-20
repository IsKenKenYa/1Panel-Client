import '../../../api/v2/website_v2.dart';
import '../../../core/network/api_client_manager.dart';

class WebsiteAccountService {
  WebsiteAccountService({WebsiteV2Api? api}) : _api = api;

  WebsiteV2Api? _api;

  Future<WebsiteV2Api> _ensureApi() async {
    _api ??= await ApiClientManager.instance.getWebsiteApi();
    return _api!;
  }

  Future<List<Map<String, dynamic>>> loadDnsAccounts() async {
    final api = await _ensureApi();
    return api.searchDnsAccounts({
      'page': 1,
      'pageSize': 50,
    });
  }

  Future<List<Map<String, dynamic>>> loadAcmeAccounts() async {
    final api = await _ensureApi();
    return api.searchAcmeAccounts({
      'page': 1,
      'pageSize': 50,
    });
  }

  Future<List<Map<String, dynamic>>> loadCertificateAuthorities() async {
    final api = await _ensureApi();
    return api.searchCertificateAuthorities({
      'page': 1,
      'pageSize': 50,
    });
  }
}
