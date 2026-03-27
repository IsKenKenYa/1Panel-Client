import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/ssl_models.dart';
import 'package:onepanel_client/features/websites/providers/website_site_ssl_provider.dart';
import 'package:onepanel_client/features/websites/services/website_certificate_service.dart';
import 'package:onepanel_client/shared/security_gateway/security_gateway_snapshot_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeWebsiteCertificateService extends WebsiteCertificateService {
  _FakeWebsiteCertificateService({
    required this.currentConfig,
    required this.boundCert,
    required this.availableCertificates,
  });

  WebsiteHttpsConfig currentConfig;
  WebsiteSSL? boundCert;
  final List<WebsiteSSL> availableCertificates;
  final List<WebsiteHttpsUpdateRequest> updateRequests =
      <WebsiteHttpsUpdateRequest>[];

  @override
  Future<WebsiteHttpsConfig> getHttpsConfig(int websiteId) async =>
      currentConfig;

  @override
  Future<WebsiteSSL?> getBoundCertificate(int websiteId) async => boundCert;

  @override
  Future<List<WebsiteSSL>> searchCertificates({
    int page = 1,
    int pageSize = 20,
    String order = 'descending',
    String orderBy = 'expire_date',
    String? domain,
  }) async {
    return availableCertificates;
  }

  @override
  Future<WebsiteHttpsConfig> updateHttpsConfig({
    required int websiteId,
    required WebsiteHttpsUpdateRequest request,
  }) async {
    updateRequests.add(request);
    final nextCert = availableCertificates
        .where((cert) => cert.id == request.websiteSSLId)
        .toList();
    boundCert = nextCert.isEmpty ? null : nextCert.first;
    currentConfig = WebsiteHttpsConfig(
      enable: request.enable,
      httpConfig: request.httpConfig,
      ssl: boundCert,
      hsts: request.hsts,
      hstsIncludeSubDomains: request.hstsIncludeSubDomains,
      http3: request.http3,
      algorithm: request.algorithm,
      sslProtocol: request.sslProtocol ?? const <String>[],
    );
    return currentConfig;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    SecurityGatewaySnapshotStore.instance.resetForTest();
  });

  test('WebsiteSiteSslProvider updates strategy and stores rollback snapshot',
      () async {
    final currentCert = WebsiteSSL(
      id: 1,
      primaryDomain: 'example.com',
      provider: 'letsencrypt',
      expireDate:
          DateTime.now().add(const Duration(days: 60)).toIso8601String(),
    );
    final nextCert = WebsiteSSL(
      id: 2,
      primaryDomain: 'alt.example.com',
      provider: 'custom',
      expireDate:
          DateTime.now().add(const Duration(days: 120)).toIso8601String(),
    );
    final service = _FakeWebsiteCertificateService(
      currentConfig: WebsiteHttpsConfig(
        enable: true,
        httpConfig: 'HTTPAlso',
        ssl: currentCert,
      ),
      boundCert: currentCert,
      availableCertificates: <WebsiteSSL>[currentCert, nextCert],
    );
    final provider = WebsiteSiteSslProvider(
      websiteId: 7,
      expectedDomain: 'example.com',
      service: service,
      snapshotStore: SecurityGatewaySnapshotStore.instance,
    );

    await provider.load();
    provider.stageHttpsStrategy(
      enable: true,
      httpConfig: 'HTTPSOnly',
      certificate: nextCert,
    );

    expect(provider.hasPendingChanges, isTrue);
    expect(provider.strategyDraft?.diffItems.map((item) => item.label),
        contains('Certificate'));

    final applySuccess = await provider.applyHttpsStrategy();

    expect(applySuccess, isTrue);
    expect(service.updateRequests, hasLength(1));
    expect(SecurityGatewaySnapshotStore.instance.read('website_https:7'),
        isNotNull);

    final rollbackSuccess = await provider.rollbackLastSuccessful();

    expect(rollbackSuccess, isTrue);
    expect(service.updateRequests, hasLength(2));
    expect(service.updateRequests.last.websiteSSLId, 1);
  });

  test('WebsiteSiteSslProvider surfaces mismatch risk on selected certificate',
      () async {
    final service = _FakeWebsiteCertificateService(
      currentConfig:
          const WebsiteHttpsConfig(enable: false, httpConfig: 'HTTPAlso'),
      boundCert: null,
      availableCertificates: <WebsiteSSL>[
        WebsiteSSL(
          id: 3,
          primaryDomain: 'wrong-domain.example',
          provider: 'custom',
          expireDate:
              DateTime.now().add(const Duration(days: 10)).toIso8601String(),
        ),
      ],
    );
    final provider = WebsiteSiteSslProvider(
      websiteId: 8,
      expectedDomain: 'example.com',
      service: service,
      snapshotStore: SecurityGatewaySnapshotStore.instance,
    );

    await provider.load();
    provider.stageHttpsStrategy(
      enable: true,
      httpConfig: 'HTTPSOnly',
      certificate: service.availableCertificates.first,
    );

    expect(
        provider.pendingRisks
            .any((notice) => notice.title == 'Domain mismatch'),
        isTrue);
  });
}
