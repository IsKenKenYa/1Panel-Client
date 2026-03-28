import '../../../data/repositories/website_domain_repository.dart';
import '../../../data/models/website_models.dart';

class WebsiteDomainService {
  WebsiteDomainService({WebsiteDomainRepository? repository})
      : _repository = repository ?? WebsiteDomainRepository();

  final WebsiteDomainRepository _repository;

  Future<List<WebsiteDomain>> getDomains(int websiteId) async {
    return _repository.getDomains(websiteId);
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
    await _repository.addDomains(
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

  Future<void> addDomains({
    required int websiteId,
    required List<Map<String, dynamic>> domains,
  }) async {
    await _repository.addDomains(
      websiteId: websiteId,
      domains: domains,
    );
  }

  Future<void> updateDomain({
    required int id,
    String? domain,
    int? port,
    bool? ssl,
  }) async {
    await _repository.updateDomain(
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
    await _repository.deleteDomain(id);
  }
}
