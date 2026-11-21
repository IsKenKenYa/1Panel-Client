import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/monitoring/monitoring_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Monitoring Page Simplification Tests', () {
    test('Monitoring provider should have basic functionality', () {
      final provider = MonitoringProvider();

      // 验证基本状态
      expect(provider.data.isLoading, isFalse);
      expect(provider.autoRefreshEnabled, isFalse);
      expect(provider.refreshInterval, const Duration(seconds: 5));

      provider.dispose();
    });

    test('Monitoring provider should support refresh interval changes', () {
      final provider = MonitoringProvider();

      provider.setRefreshInterval(const Duration(seconds: 10));
      expect(provider.refreshInterval, const Duration(seconds: 10));

      provider.dispose();
    });

    test('Monitoring provider should support auto-refresh toggle', () {
      final provider = MonitoringProvider();

      expect(provider.autoRefreshEnabled, isFalse);

      provider.toggleAutoRefresh(true);
      expect(provider.autoRefreshEnabled, isTrue);

      provider.toggleAutoRefresh(false);
      expect(provider.autoRefreshEnabled, isFalse);

      provider.dispose();
    });

    testWidgets('页面隐藏时更改刷新选项不会触发采集', (tester) async {
      final provider = MonitoringProvider();
      addTearDown(provider.dispose);
      provider.setPageVisible(Object(), false);
      provider.setGpuAutoRefreshEnabled(true);
      provider.toggleAutoRefresh(true);
      await tester.pump(const Duration(minutes: 1));
      expect(provider.data.lastUpdated, isNull);
      expect(provider.data.error, isNull);
    });
  });
}
