import '../../../data/models/ssl_models.dart';
import '../../../data/repositories/website_ssl_repository.dart';

class WebsiteSslService {
  WebsiteSslService({WebsiteSslRepository? repository})
      : _repository = repository ?? WebsiteSslRepository();

  final WebsiteSslRepository _repository;

  Future<WebsiteHttpsConfig> fetchHttpsConfig(int websiteId) async {
    return _repository.getHttpsConfig(websiteId);
  }

  Future<WebsiteHttpsConfig> updateHttpsConfig({
    required int websiteId,
    required WebsiteHttpsUpdateRequest request,
  }) async {
    return _repository.updateHttpsConfig(
      websiteId: websiteId,
      request: request,
    );
  }

  Future<WebsiteSSL?> fetchWebsiteSslByWebsiteId(int websiteId) async {
    return _repository.getBoundCertificate(websiteId);
  }

  Future<List<WebsiteSSL>> searchCertificates({
    int page = 1,
    int pageSize = 20,
    String order = 'descending',
    String orderBy = 'expire_date',
    String? domain,
    String? acmeAccountId,
  }) async {
    return _repository.searchCertificates(
      page: page,
      pageSize: pageSize,
      order: order,
      orderBy: orderBy,
      domain: domain,
      acmeAccountId: acmeAccountId,
    );
  }

  Future<WebsiteSSL?> fetchCertificateById(int id) async {
    return _repository.getCertificateDetail(id);
  }

  Future<void> createCertificate(WebsiteSSLCreate request) async {
    await _repository.createCertificate(request);
  }

  Future<void> applyCertificate(WebsiteSSLApply request) async {
    await _repository.applyCertificate(request);
  }

  Future<void> resolveCertificate(WebsiteSSLResolve request) async {
    await _repository.resolveCertificate(request);
  }

  Future<void> updateCertificate(WebsiteSSLUpdate request) async {
    await _repository.updateCertificate(request);
  }

  Future<void> uploadCertificate(WebsiteSSLUpload request) async {
    await _repository.uploadCertificate(request);
  }

  Future<void> deleteCertificate(int id) async {
    await _repository.deleteCertificate(id);
  }

  Future<String?> downloadCertificate(int id) async {
    return _repository.downloadCertificate(id);
  }

  Future<List<Map<String, dynamic>>> fetchSslOptions() async {
    return _repository.getSslOptions();
  }
}
