import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/ssl_models.dart';
import 'package:onepanel_client/features/websites/providers/website_ssl_center_provider.dart';
import 'package:onepanel_client/features/websites/services/website_certificate_service.dart';

class _FakeWebsiteSslCenterService extends WebsiteCertificateService {
  _FakeWebsiteSslCenterService({
    required this.certificates,
  });

  List<WebsiteSSL> certificates;
  int deleteCallCount = 0;

  @override
  Future<List<WebsiteSSL>> searchCertificates({
    int page = 1,
    int pageSize = 20,
    String order = 'descending',
    String orderBy = 'expire_date',
    String? domain,
  }) async {
    return certificates;
  }

  @override
  Future<void> deleteCertificate(int id) async {
    deleteCallCount += 1;
    certificates = certificates.where((item) => item.id != id).toList();
  }
}

void main() {
  test('WebsiteSslCenterProvider loads and filters certificates', () async {
    final service = _FakeWebsiteSslCenterService(
      certificates: <WebsiteSSL>[
        WebsiteSSL(
          id: 1,
          primaryDomain: 'example.com',
          provider: 'letsencrypt',
          expireDate:
              DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        ),
        WebsiteSSL(
          id: 2,
          primaryDomain: 'api.example.com',
          provider: 'custom',
          expireDate:
              DateTime.now().add(const Duration(days: 40)).toIso8601String(),
        ),
      ],
    );
    final provider = WebsiteSslCenterProvider(service: service);

    await provider.load();

    expect(provider.error, isNull);
    expect(provider.certificates, hasLength(2));
    expect(provider.providerOptions,
        containsAll(<String>['letsencrypt', 'custom']));
    expect(provider.within7DaysCount, 1);

    provider.setProviderFilter('letsencrypt');
    expect(provider.certificates, hasLength(1));
    expect(provider.certificates.first.id, 1);

    provider.setSearchQuery('api');
    expect(provider.certificates, isEmpty);
  });

  test('WebsiteSslCenterProvider delete reloads list', () async {
    final service = _FakeWebsiteSslCenterService(
      certificates: <WebsiteSSL>[
        WebsiteSSL(
          id: 1,
          primaryDomain: 'example.com',
          provider: 'letsencrypt',
          expireDate:
              DateTime.now().add(const Duration(days: 20)).toIso8601String(),
        ),
      ],
    );
    final provider = WebsiteSslCenterProvider(service: service);

    await provider.load();
    await provider.deleteCertificate(1);

    expect(service.deleteCallCount, 1);
    expect(provider.certificates, isEmpty);
  });
}
