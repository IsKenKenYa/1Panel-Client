import 'package:onepanel_client/api/v2/ssl_v2.dart';
import 'package:onepanel_client/api/v2/website_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/ssl_models.dart';

class WebsiteSslRepository {
  WebsiteSslRepository({
    SSLV2Api? sslApi,
    WebsiteV2Api? websiteApi,
  })  : _sslApi = sslApi,
        _websiteApi = websiteApi;

  SSLV2Api? _sslApi;
  WebsiteV2Api? _websiteApi;

  Future<SSLV2Api> _ensureSslApi() async {
    _sslApi ??= await ApiClientManager.instance.getSslApi();
    return _sslApi!;
  }

  Future<WebsiteV2Api> _ensureWebsiteApi() async {
    _websiteApi ??= await ApiClientManager.instance.getWebsiteApi();
    return _websiteApi!;
  }

  Future<List<WebsiteSSL>> searchCertificates({
    int page = 1,
    int pageSize = 20,
    String order = 'descending',
    String orderBy = 'expire_date',
    String? domain,
    String? acmeAccountId,
  }) async {
    final api = await _ensureSslApi();
    final response = await api.searchWebsiteSSL(
      WebsiteSSLSearch(
        page: page,
        pageSize: pageSize,
        order: order,
        orderBy: orderBy,
        domain: domain,
        acmeAccountId: acmeAccountId,
      ),
    );
    return response.data?.items ?? const <WebsiteSSL>[];
  }

  Future<WebsiteSSL?> getCertificateDetail(int id) async {
    final api = await _ensureSslApi();
    final response = await api.getWebsiteSSLById(id);
    return response.data;
  }

  Future<WebsiteSSL?> getBoundCertificate(int websiteId) async {
    final api = await _ensureSslApi();
    try {
      final response = await api.getWebsiteSSLByWebsiteId(websiteId);
      return response.data;
    } catch (_) {
      return null;
    }
  }

  Future<WebsiteHttpsConfig> getHttpsConfig(int websiteId) async {
    final api = await _ensureWebsiteApi();
    return api.getWebsiteHttps(websiteId);
  }

  Future<WebsiteHttpsConfig> updateHttpsConfig({
    required int websiteId,
    required WebsiteHttpsUpdateRequest request,
  }) async {
    final api = await _ensureWebsiteApi();
    return api.updateWebsiteHttps(websiteId: websiteId, request: request);
  }

  Future<void> createCertificate(WebsiteSSLCreate request) async {
    final api = await _ensureSslApi();
    await api.createWebsiteSSL(request);
  }

  Future<void> applyCertificate(WebsiteSSLApply request) async {
    final api = await _ensureSslApi();
    await api.applySSL(request);
  }

  Future<void> resolveCertificate(WebsiteSSLResolve request) async {
    final api = await _ensureSslApi();
    await api.resolveWebsiteSSL(request);
  }

  Future<void> updateCertificate(WebsiteSSLUpdate request) async {
    final api = await _ensureSslApi();
    await api.updateWebsiteSSL(request);
  }

  Future<void> uploadCertificate(WebsiteSSLUpload request) async {
    final api = await _ensureSslApi();
    await api.uploadSSL(request);
  }

  Future<void> deleteCertificate(int id) async {
    final api = await _ensureSslApi();
    await api.deleteWebsiteSSL([id]);
  }

  Future<String?> downloadCertificate(int id) async {
    final api = await _ensureSslApi();
    final response = await api.downloadSSLFile(id);
    return response.data;
  }

  Future<List<Map<String, dynamic>>> getSslOptions() async {
    final api = await _ensureSslApi();
    final response = await api.getSSLOptions();
    return response.data ?? const <Map<String, dynamic>>[];
  }
}
