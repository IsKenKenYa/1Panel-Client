import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/data/models/website_models.dart';
import 'package:onepanel_client/features/websites/providers/website_domain_provider.dart';
import 'package:onepanel_client/features/websites/services/website_domain_service.dart';

class _FakeWebsiteDomainService extends WebsiteDomainService {
  _FakeWebsiteDomainService({
    this.items = const <WebsiteDomain>[],
    this.throwOnUpdate = false,
  });

  final List<WebsiteDomain> items;
  final bool throwOnUpdate;
  int updateCallCount = 0;
  List<Map<String, dynamic>> lastBatch = const <Map<String, dynamic>>[];

  @override
  Future<List<WebsiteDomain>> fetchDomains(int websiteId) async => items;

  @override
  Future<void> updateDomain({
    required int id,
    String? domain,
    int? port,
    bool? ssl,
  }) async {
    updateCallCount += 1;
    if (throwOnUpdate) {
      throw Exception('domain update failed');
    }
  }

  @override
  Future<void> addDomains({
    required int websiteId,
    required List<Map<String, dynamic>> domains,
  }) async {
    lastBatch = domains;
  }
}

void main() {
  test('WebsiteDomainProvider loads domains', () async {
    final provider = WebsiteDomainProvider(
      websiteId: 1,
      service: _FakeWebsiteDomainService(
        items: const [WebsiteDomain(id: 1, domain: 'example.com', port: 80)],
      ),
    );

    await provider.loadDomains();

    expect(provider.domains, hasLength(1));
    expect(provider.error, isNull);
  });

  test('WebsiteDomainProvider surfaces update errors', () async {
    final service = _FakeWebsiteDomainService(throwOnUpdate: true);
    final provider = WebsiteDomainProvider(
      websiteId: 1,
      service: service,
    );

    await provider.updateDomain(id: 1, domain: 'example.com', port: 80);

    expect(service.updateCallCount, 1);
    expect(provider.error, contains('domain update failed'));
  });

  test('WebsiteDomainProvider supports batch domain import', () async {
    final service = _FakeWebsiteDomainService();
    final provider = WebsiteDomainProvider(
      websiteId: 1,
      service: service,
    );

    await provider.addDomainsBatch(const <Map<String, dynamic>>[
      {'domain': 'a.example.com', 'port': 80, 'ssl': false},
      {'domain': 'b.example.com', 'port': 8080, 'ssl': true},
    ]);

    expect(service.lastBatch, hasLength(2));
    expect(service.lastBatch.first['domain'], 'a.example.com');
    expect(service.lastBatch.last['port'], 8080);
  });
}
