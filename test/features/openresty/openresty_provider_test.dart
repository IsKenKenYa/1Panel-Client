import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/openresty_models.dart';
import 'package:onepanel_client/features/openresty/providers/openresty_provider.dart';
import 'package:onepanel_client/features/openresty/services/openresty_service.dart';
import 'package:onepanel_client/shared/security_gateway/security_gateway_snapshot_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeOpenRestyService extends OpenRestyService {
  OpenRestySnapshot snapshot = const OpenRestySnapshot(
    status: <String, dynamic>{'active': 0},
    modules: <String, dynamic>{
      'mirror': '',
      'modules': <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'http-cache',
          'enable': false,
          'packages': '',
          'params': '',
          'script': '',
        },
      ],
    },
    https: <String, dynamic>{'https': false, 'sslRejectHandshake': false},
    configContent: 'worker_processes 1;',
  );

  final List<Map<String, dynamic>> httpsUpdates = <Map<String, dynamic>>[];

  @override
  Future<OpenRestySnapshot> loadSnapshot() async => snapshot;

  @override
  Future<void> updateHttps(Map<String, dynamic> request) async {
    httpsUpdates.add(request);
    snapshot = OpenRestySnapshot(
      status: snapshot.status,
      modules: snapshot.modules,
      https: <String, dynamic>{
        'https': request['operate'] == 'enable',
        'sslRejectHandshake': request['sslRejectHandshake'] == true,
      },
      configContent: snapshot.configContent,
    );
  }

  @override
  Future<List<OpenrestyParam>> loadScope({
    required NginxKey scope,
    int? websiteId,
  }) async {
    return const <OpenrestyParam>[
      OpenrestyParam(name: 'index', params: <String>['root', 'index']),
    ];
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    SecurityGatewaySnapshotStore.instance.resetForTest();
  });

  test(
      'OpenRestyProvider loads snapshot and supports https draft apply/rollback',
      () async {
    final service = _FakeOpenRestyService();
    final provider = OpenRestyProvider(
      service: service,
      snapshotStore: SecurityGatewaySnapshotStore.instance,
    );

    await provider.loadAll();

    expect(provider.hasData, isTrue);
    expect(provider.httpsEnabled, isFalse);
    expect(provider.riskNotices, isNotEmpty);

    provider.stageHttpsUpdate(
      httpsEnabled: true,
      sslRejectHandshake: false,
    );
    expect(provider.httpsDraft?.hasChanges, isTrue);

    final applied = await provider.applyHttpsDraft();

    expect(applied, isTrue);
    expect(provider.httpsEnabled, isTrue);
    expect(service.httpsUpdates, hasLength(1));
    expect(provider.httpsRollbackSnapshot, isNotNull);

    final rollback = await provider.rollbackHttps();

    expect(rollback, isTrue);
    expect(service.httpsUpdates, hasLength(2));
  });

  test('OpenRestyProvider loadScope stores params', () async {
    final provider = OpenRestyProvider(
      service: _FakeOpenRestyService(),
      snapshotStore: SecurityGatewaySnapshotStore.instance,
    );

    await provider.loadScope(scope: NginxKey.indexKey);

    expect(provider.scopeParams, hasLength(1));
    expect(provider.scopeParams.first.name, 'index');
  });
}
