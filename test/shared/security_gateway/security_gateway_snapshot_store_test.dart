import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';
import 'package:onepanel_client/shared/security_gateway/security_gateway_snapshot_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _storageKey = 'security_gateway_snapshots_v1';

void main() {
  final store = SecurityGatewaySnapshotStore.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store.resetForTest();
  });

  test('loads persisted snapshots during initialization', () async {
    final now = DateTime.now().toIso8601String();
    SharedPreferences.setMockInitialValues(<String, Object>{
      _storageKey:
          '[{"scope":"website_https:7","title":"Website HTTPS Strategy","summary":"Rollback previous strategy","data":{"websiteId":7,"enable":true},"createdAt":"$now"}]',
    });

    store.resetForTest();
    await store.ensureInitialized();

    final snapshot = store.read('website_https:7');
    expect(snapshot, isNotNull);
    expect(snapshot?.title, 'Website HTTPS Strategy');
    expect(snapshot?.data, isA<Map<String, dynamic>>());
  });

  test('save persists snapshots and clear removes persisted snapshots', () async {
    await store.ensureInitialized();

    store.save<Map<String, dynamic>>(
      ConfigRollbackSnapshot<Map<String, dynamic>>(
        scope: 'openresty_https',
        title: 'OpenResty HTTPS',
        summary: 'Rollback HTTPS config',
        data: <String, dynamic>{
          'operate': 'enable',
          'sslRejectHandshake': false,
        },
        createdAt: DateTime.now(),
      ),
    );
    await store.flushPendingWrites();

    store.resetForTest();
    await store.ensureInitialized();

    final reloaded = store.read('openresty_https');
    expect(reloaded, isNotNull);

    store.clear();
    await store.flushPendingWrites();

    store.resetForTest();
    await store.ensureInitialized();
    expect(store.read('openresty_https'), isNull);
  });
}
