import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/features/server/server_models.dart';
import 'package:onepanel_client/features/server/widgets/server_detail_header_card.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

void main() {
  group('Server UI Optimization Tests', () {
    testWidgets('ServerDetailHeaderCard displays metric icons',
        (tester) async {
      final testServer = ServerCardViewModel(
        config: ApiConfig(
          id: 'test-1',
          name: '测试服务器',
          url: 'https://test.example.com',
          apiKey: 'test-token',
        ),
        isCurrent: true,
        metrics: const ServerMetricsSnapshot(
          cpuPercent: 10.5,
          memoryPercent: 28.4,
          load: 0.06,
          diskPercent: 51.6,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: ServerDetailHeaderCard(
              server: testServer,
              onRefresh: () async {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证指标图标存在
      expect(find.byIcon(Icons.memory_outlined), findsOneWidget);
      expect(find.byIcon(Icons.storage_outlined), findsOneWidget);
      expect(find.byIcon(Icons.speed_outlined), findsOneWidget);
      expect(find.byIcon(Icons.sd_card_outlined), findsOneWidget);

      // 验证指标值显示
      expect(find.textContaining('10.5%'), findsOneWidget);
      expect(find.textContaining('28.4%'), findsOneWidget);
      expect(find.textContaining('0.06'), findsOneWidget);
      expect(find.textContaining('51.6%'), findsOneWidget);
    });
  });
}
