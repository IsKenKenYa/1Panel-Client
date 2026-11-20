import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/theme/app_theme.dart';
import 'package:onepanel_client/data/models/alert_models.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/vm/vm_models.dart';
import 'package:onepanel_client/data/models/vm/vm_resource_models.dart';
import 'package:onepanel_client/features/alert/alert_page.dart';
import 'package:onepanel_client/features/alert/alert_service.dart';
import 'package:onepanel_client/features/alert/providers/alert_provider.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/vm/providers/vm_provider.dart';
import 'package:onepanel_client/features/vm/vm_page.dart';
import 'package:onepanel_client/features/vm/vm_service.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class _MockVMService extends Mock implements VMService {}

class _MockAlertService extends Mock implements AlertService {}

/// 页面骨架在无服务器时整页替换为空态，测试需要带服务器状态的控制器。
class _ServerCurrentServerController extends CurrentServerController {
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

  @override
  String? get currentServerId => _config.id;
}

MaterialApp harness(Widget child, {VmProvider? vm, AlertProvider? alert}) {
  return MaterialApp(
    theme: AppTheme.create(
      ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FE4)),
    ),
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<CurrentServerController>.value(
          value: _ServerCurrentServerController(),
        ),
        if (vm != null) ChangeNotifierProvider<VmProvider>.value(value: vm),
        if (alert != null)
          ChangeNotifierProvider<AlertProvider>.value(value: alert),
      ],
      child: child,
    ),
  );
}

VmProvider stubVmProvider() {
  final service = _MockVMService();
  when(() => service.checkEnvironment())
      .thenAnswer((_) async => const VMEnvironment(ready: true));
  when(() => service.searchVMs(info: any(named: 'info')))
      .thenAnswer((_) async => const VMSearchResult());
  when(() => service.listIso()).thenAnswer((_) async => const <VMIsoItem>[]);
  when(() => service.listTemplates())
      .thenAnswer((_) async => const <VMTemplateItem>[]);
  when(() => service.listNetworks())
      .thenAnswer((_) async => const <VMNetworkItem>[]);
  when(() => service.listStorages())
      .thenAnswer((_) async => const <VMStorageItem>[]);
  return VmProvider(service: service);
}

AlertProvider stubAlertProvider() {
  final service = _MockAlertService();
  when(() => service.searchAlerts(
        page: any(named: 'page'),
        type: any(named: 'type'),
        status: any(named: 'status'),
      )).thenAnswer((_) async => const PageResult<AlertInfo>(
        items: <AlertInfo>[],
        total: 0,
      ));
  when(() => service.searchLogs(
        page: any(named: 'page'),
        status: any(named: 'status'),
      )).thenAnswer((_) async => const PageResult<AlertLog>(
        items: <AlertLog>[],
        total: 0,
      ));
  when(() => service.listConfigs())
      .thenAnswer((_) async => const <AlertConfigInfo>[]);
  return AlertProvider(service: service);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VmPage', () {
    testWidgets('renders the six section tabs', (tester) async {
      final vmProvider = stubVmProvider();
      addTearDown(vmProvider.dispose);

      await tester.pumpWidget(harness(const VmPage(), vm: vmProvider));
      await tester.pump();
      await tester.pump();

      for (final label in <String>['概览', 'ISO', '模板', '网络', '存储池']) {
        expect(find.text(label), findsWidgets, reason: 'missing tab $label');
      }
      expect(find.text('虚拟机'), findsWidgets);
    });

    testWidgets('overview tab shows the four status counters', (tester) async {
      final vmProvider = stubVmProvider();
      addTearDown(vmProvider.dispose);

      await tester.pumpWidget(harness(const VmPage(), vm: vmProvider));
      await tester.pump();
      await tester.pump();

      expect(find.text('运行中'), findsOneWidget);
      expect(find.text('已停止'), findsOneWidget);
      expect(find.text('创建中'), findsOneWidget);
      expect(find.text('异常'), findsOneWidget);
    });
  });

  group('AlertPage', () {
    testWidgets('renders the three alert tabs', (tester) async {
      final alertProvider = stubAlertProvider();
      addTearDown(alertProvider.dispose);

      await tester
          .pumpWidget(harness(const AlertPage(), alert: alertProvider));
      await tester.pump();
      await tester.pump();

      expect(find.text('告警任务'), findsOneWidget);
      expect(find.text('告警日志'), findsOneWidget);
      expect(find.text('通知渠道'), findsOneWidget);
    });

    testWidgets('rule tab shows the empty state when no rules exist',
        (tester) async {
      final alertProvider = stubAlertProvider();
      addTearDown(alertProvider.dispose);

      await tester
          .pumpWidget(harness(const AlertPage(), alert: alertProvider));
      await tester.pump();
      await tester.pump();

      expect(find.text('还没有告警任务'), findsOneWidget);
    });
  });
}
