import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/settings/panel_ssl/providers/panel_ssl_provider.dart';
import 'package:onepanel_client/features/settings/panel_ssl/services/panel_ssl_service.dart';
import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';

class _FakePanelSslService extends PanelSslService {
  _FakePanelSslService({
    required this.info,
    this.downloadPayload = const <int>[1, 2, 3],
  });

  Map<String, dynamic> info;
  final List<int> downloadPayload;
  Map<String, dynamic>? lastUpdateRequest;

  @override
  Future<Map<String, dynamic>> getSslInfo() async => info;

  @override
  Future<void> updateSsl({
    required String domain,
    required String sslType,
    required String cert,
    required String key,
  }) async {
    lastUpdateRequest = <String, dynamic>{
      'domain': domain,
      'sslType': sslType,
      'cert': cert,
      'key': key,
    };
    info = <String, dynamic>{
      ...info,
      'domain': domain,
      'sslType': sslType,
    };
  }

  @override
  Future<List<int>> downloadSsl() async => downloadPayload;
}

void main() {
  test('PanelSslProvider loads upload/download state and computes risk',
      () async {
    final service = _FakePanelSslService(
      info: <String, dynamic>{
        'domain': 'panel.example.com',
        'status': 'enabled',
        'sslType': 'selfSigned',
        'provider': 'local',
        'expirationDate':
            DateTime.now().add(const Duration(days: 5)).toIso8601String(),
      },
    );
    final provider = PanelSslProvider(service: service);

    await provider.loadSslInfo();

    expect(provider.domain, 'panel.example.com');
    expect(provider.healthStatus, CertificateHealthStatus.expiringSoon);
    expect(provider.riskNotices, isNotEmpty);

    final uploadSuccess = await provider.uploadSsl(
      domain: 'panel.example.com',
      sslType: 'selfSigned',
      cert: '-----BEGIN CERTIFICATE-----\nabc\n-----END CERTIFICATE-----',
      key: '-----BEGIN PRIVATE KEY-----\nxyz\n-----END PRIVATE KEY-----',
    );

    expect(uploadSuccess, isTrue);
    expect(service.lastUpdateRequest?['domain'], 'panel.example.com');
    expect(provider.history.first, contains('Uploaded'));

    final downloadSuccess = await provider.downloadSsl();

    expect(downloadSuccess, isTrue);
    expect(provider.lastDownloadedBytes, 3);
    expect(provider.history.first, contains('Downloaded'));
  });

  test('PanelSslProvider rejects invalid upload payload', () async {
    final provider = PanelSslProvider(
      service: _FakePanelSslService(info: <String, dynamic>{}),
    );

    final success = await provider.uploadSsl(
      domain: '',
      sslType: 'selfSigned',
      cert: 'invalid',
      key: '',
    );

    expect(success, isFalse);
    expect(provider.error, contains('Domain is required'));
  });
}
