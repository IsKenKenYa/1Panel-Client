import '../../../api/v2/ssl_v2.dart';
import '../../../api/v2/website_v2.dart';
import '../../../core/network/api_client_manager.dart';
import '../../../data/models/ssl_models.dart';

class WebsiteSslService {
  WebsiteV2Api? _websiteApi;
  SSLV2Api? _sslApi;

  Future<void> _ensureApis() async {
    _websiteApi ??= await ApiClientManager.instance.getWebsiteApi();
    _sslApi ??= await ApiClientManager.instance.getSslApi();
  }

  Future<WebsiteHttpsConfig> fetchHttpsConfig(int websiteId) async {
    await _ensureApis();
    return _websiteApi!.getWebsiteHttps(websiteId);
  }

  Future<WebsiteHttpsConfig> updateHttpsConfig({
    required int websiteId,
    required WebsiteHttpsUpdateRequest request,
  }) async {
    await _ensureApis();
    return _websiteApi!.updateWebsiteHttps(websiteId: websiteId, request: request);
  }

  Future<WebsiteSSL?> fetchWebsiteSslByWebsiteId(int websiteId) async {
    await _ensureApis();
    try {
      final resp = await _sslApi!.getWebsiteSSLByWebsiteId(websiteId);
      return resp.data;
    } catch (_) {
      return null;
    }
  }

  Future<List<WebsiteSSL>> searchCertificates({
    int page = 1,
    int pageSize = 20,
    String order = 'descending',
    String orderBy = 'expire_date',
    String? domain,
    String? acmeAccountId,
  }) async {
    await _ensureApis();
    final resp = await _sslApi!.searchWebsiteSSL(
      WebsiteSSLSearch(
        page: page,
        pageSize: pageSize,
        order: order,
        orderBy: orderBy,
        domain: domain,
        acmeAccountId: acmeAccountId,
      ),
    );
    return resp.data?.items ?? const [];
  }

  Future<WebsiteSSL?> fetchCertificateById(int id) async {
    await _ensureApis();
    try {
      final resp = await _sslApi!.getWebsiteSSLById(id);
      return resp.data;
    } catch (_) {
      return null;
    }
  }

  Future<void> createCertificate(WebsiteSSLCreate request) async {
    await _ensureApis();
    await _sslApi!.createWebsiteSSL(request);
  }

  Future<void> applyCertificate(WebsiteSSLApply request) async {
    await _ensureApis();
    await _sslApi!.applySSL(request);
  }

  Future<void> resolveCertificate(WebsiteSSLResolve request) async {
    await _ensureApis();
    await _sslApi!.resolveWebsiteSSL(request);
  }

  Future<void> updateCertificate(WebsiteSSLUpdate request) async {
    await _ensureApis();
    await _sslApi!.updateWebsiteSSL(request);
  }

  Future<void> uploadCertificate(WebsiteSSLUpload request) async {
    await _ensureApis();
    await _sslApi!.uploadSSL(request);
  }

  Future<void> deleteCertificate(int id) async {
    await _ensureApis();
    await _sslApi!.deleteWebsiteSSL([id]);
  }

  Future<String?> downloadCertificate(int id) async {
    await _ensureApis();
    final resp = await _sslApi!.downloadSSLFile(id);
    return resp.data;
  }

  Future<List<Map<String, dynamic>>> fetchSslOptions() async {
    await _ensureApis();
    final resp = await _sslApi!.getSSLOptions();
    return resp.data ?? const [];
  }
}
