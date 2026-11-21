import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/storage/platform_secure_storage.dart';
import 'package:onepanel_client/data/models/monitor_models.dart';
import 'package:onepanel_client/features/monitoring/data/datasources/monitor_local_datasource.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('监控历史按连接保存并按采样日期清理', (_) async {
    final now = DateTime.now();
    ApiConfig server(String id) => ApiConfig(
      id: 'monitor-history-test-${now.microsecondsSinceEpoch}-$id',
      name: id,
      url: 'https://localhost',
      apiKey: '',
    );
    final a = server('a');
    final b = server('b');
    final history = MonitorLocalDataSource(server: a);
    final other = MonitorLocalDataSource(server: b);
    final vault = await PlatformSecureStorage.create();
    addTearDown(() async {
      for (final config in [a, b]) {
        final name = MonitorLocalDataSource.boxNameFor(config);
        if (Hive.isBoxOpen(name)) await Hive.box(name).close();
        if (await Hive.boxExists(name)) await Hive.deleteBoxFromDisk(name);
        await vault.delete(key: '${name}_key');
      }
    });

    final recent = now.subtract(const Duration(days: 2)).toUtc();
    final expired = recent.subtract(const Duration(days: 90));
    await history.savePoints('cpu', [
      MonitorDataPoint(time: expired, value: 1),
      MonitorDataPoint(time: recent, value: 2),
    ]);
    final start = recent.subtract(const Duration(minutes: 1)).toLocal();
    final end = recent.add(const Duration(minutes: 1)).toLocal();
    expect(await other.getPoints('cpu', start, end), isEmpty);
    await history.cleanAndCompressData();
    expect((await history.getPoints('cpu', start, end)).single.value, 2);
    expect(await history.getPoints('cpu', expired, expired), isEmpty);
  });
}
