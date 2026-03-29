import '../../../data/models/ssl_models.dart';
import '../../../data/repositories/website_ssl_repository.dart';

class WebsiteCertificateService {
  WebsiteCertificateService({WebsiteSslRepository? repository})
      : _repository = repository ?? WebsiteSslRepository();

  final WebsiteSslRepository _repository;

  Future<List<WebsiteSSL>> searchCertificates({
    int page = 1,
    int pageSize = 20,
    String order = 'descending',
    String orderBy = 'expire_date',
    String? domain,
  }) async {
    return _repository.searchCertificates(
      page: page,
      pageSize: pageSize,
      order: order,
      orderBy: orderBy,
      domain: domain,
    );
  }

  Future<List<WebsiteSSL>> listCertificates({
    String order = 'descending',
    String orderBy = 'expire_date',
    String? domain,
    String? acmeAccountId,
  }) async {
    return _repository.listCertificates(
      order: order,
      orderBy: orderBy,
      domain: domain,
      acmeAccountId: acmeAccountId,
    );
  }

  Future<WebsiteSSL?> getCertificateDetail(int id) {
    return _repository.getCertificateDetail(id);
  }

  Future<WebsiteSSL?> getBoundCertificate(int websiteId) {
    return _repository.getBoundCertificate(websiteId);
  }

  Future<WebsiteHttpsConfig> getHttpsConfig(int websiteId) {
    return _repository.getHttpsConfig(websiteId);
  }

  Future<WebsiteHttpsConfig> updateHttpsConfig({
    required int websiteId,
    required WebsiteHttpsUpdateRequest request,
  }) {
    return _repository.updateHttpsConfig(
      websiteId: websiteId,
      request: request,
    );
  }

  Future<void> createCertificate(WebsiteSSLCreate request) {
    return _repository.createCertificate(request);
  }

  Future<void> applyCertificate(WebsiteSSLApply request) {
    return _repository.applyCertificate(request);
  }

  Future<void> resolveCertificate(WebsiteSSLResolve request) {
    return _repository.resolveCertificate(request);
  }

  Future<void> updateCertificate(WebsiteSSLUpdate request) {
    return _repository.updateCertificate(request);
  }

  Future<void> uploadCertificate(WebsiteSSLUpload request) {
    return _repository.uploadCertificate(request);
  }

  Future<void> deleteCertificate(int id) {
    return _repository.deleteCertificate(id);
  }

  Future<String?> downloadCertificate(int id) {
    return _repository.downloadCertificate(id);
  }
}
