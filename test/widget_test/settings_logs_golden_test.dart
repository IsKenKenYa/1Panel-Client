import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/logs_models.dart';
import 'package:onepanel_client/data/models/task_log_models.dart';
import 'package:onepanel_client/features/logs/pages/logs_center_page.dart';
import 'package:onepanel_client/features/logs/providers/logs_provider.dart';
import 'package:onepanel_client/features/logs/providers/system_logs_provider.dart';
import 'package:onepanel_client/features/logs/providers/task_logs_provider.dart';
import 'package:onepanel_client/features/logs/services/logs_service.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/pages/settings/api_test_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ui_overflow_test_utils.dart';

class _MockLogsService extends Mock implements LogsService {}

class _FakeCurrentServerController extends CurrentServerController {
  final ApiConfig _config = ApiConfig(
    id: 'server-1',
    name: 'Demo',
    url: 'https://demo.example.com',
    apiKey: 'key',
  );

  @override
  bool get hasServer => true;

  @override
  ApiConfig? get currentServer => _config;
}

void main() {
  group('Golden baseline - settings & logs', () {
    setUpAll(() {
      registerFallbackValue(const OperationLogSearchRequest());
      registerFallbackValue(const LoginLogSearchRequest());
      registerFallbackValue(const TaskLogSearch());
    });

    for (final variant in kGoldenBaselineVariants) {
      testWidgets('ApiTestPage golden ${variant.name}', (tester) async {
        final longName =
            'Primary Server ${List.filled(8, 'International-Node').join('-')}';
        final longUrl =
            'https://${List.filled(8, 'very-long-host-segment').join('.')}.example.com/${List.filled(8, 'api-path-segment').join('/')}';
        final apiKey = List.filled(40, 'a').join();

        SharedPreferences.setMockInitialValues({
          'api_configs': jsonEncode([
            {
              'id': 'server-1',
              'name': longName,
              'url': longUrl,
              'apiKey': apiKey,
              'tokenValidity': 0,
              'allowInsecureTls': false,
              'isDefault': true,
              'lastUsed': DateTime(2026, 3, 30).toIso8601String(),
            }
          ]),
          'current_api_config_id': 'server-1',
        });

        await pumpOverflowHarness(
          tester,
          variant: variant,
          wrapWithScaffold: false,
          child: const ApiTestPage(),
        );

        await expectNoFlutterExceptions(
          tester,
          reason: 'ApiTestPage golden raised Flutter exceptions',
        );

        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
              'goldens/settings/api_test_page_${variant.name}.png'),
        );
      });

      testWidgets('LogsCenterPage golden ${variant.name}', (tester) async {
        final service = _MockLogsService();
        when(() => service.searchOperationLogs(any())).thenAnswer(
          (_) async => const PageResult<OperationLogEntry>(
            items: <OperationLogEntry>[],
            total: 0,
          ),
        );
        when(() => service.searchLoginLogs(any())).thenAnswer(
          (_) async => const PageResult<LoginLogEntry>(
            items: <LoginLogEntry>[],
            total: 0,
          ),
        );
        when(() => service.searchTaskLogs(any())).thenAnswer(
          (_) async => const PageResult<TaskLog>(items: <TaskLog>[], total: 0),
        );
        when(() => service.loadExecutingTaskCount()).thenAnswer((_) async => 0);
        when(() => service.loadSystemLogFiles())
            .thenAnswer((_) async => const <String>[]);

        await pumpOverflowHarness(
          tester,
          variant: variant,
          wrapWithScaffold: false,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<CurrentServerController>.value(
                value: _FakeCurrentServerController(),
              ),
              ChangeNotifierProvider<LogsProvider>(
                create: (_) => LogsProvider(service: service),
              ),
              ChangeNotifierProvider<TaskLogsProvider>(
                create: (_) => TaskLogsProvider(service: service),
              ),
              ChangeNotifierProvider<SystemLogsProvider>(
                create: (_) => SystemLogsProvider(service: service),
              ),
            ],
            child: const LogsCenterPage(),
          ),
        );

        await expectNoFlutterExceptions(
          tester,
          reason: 'LogsCenterPage golden raised Flutter exceptions',
        );

        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
              'goldens/logs/logs_center_page_${variant.name}.png'),
        );
      });
    }
  });
}
