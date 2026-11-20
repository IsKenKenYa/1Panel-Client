import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/theme/app_theme.dart';
import 'package:onepanel_client/data/models/alert_models.dart';
import 'package:onepanel_client/features/alert/alert_service.dart';
import 'package:onepanel_client/features/alert/providers/alert_provider.dart';
import 'package:onepanel_client/features/alert/widgets/alert_channel_form.dart';
import 'package:onepanel_client/features/alert/widgets/alert_rule_form.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockAlertService extends Mock implements AlertService {}

Widget wrap(Widget child, {required AlertProvider provider}) {
  return MaterialApp(
    theme: AppTheme.create(
      ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FE4)),
    ),
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ChangeNotifierProvider<AlertProvider>.value(
        value: provider,
        child: SingleChildScrollView(child: child),
      ),
    ),
  );
}

AlertProvider emptyProvider() {
  final service = _MockAlertService();
  when(() => service.listDisks())
      .thenAnswer((_) async => const <AlertDisk>[]);
  when(() => service.listClams())
      .thenAnswer((_) async => const <AlertClam>[]);
  when(() => service.listCronJobs(type: any(named: 'type')))
      .thenAnswer((_) async => const <AlertCronJob>[]);
  when(() => service.listConfigs())
      .thenAnswer((_) async => const <AlertConfigInfo>[]);
  return AlertProvider(service: service);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Alert rule form', () {
    testWidgets('renders the type selector and threshold fields',
        (tester) async {
      final provider = emptyProvider();
      addTearDown(provider.dispose);

      await tester.pumpWidget(wrap(
        const AlertRuleForm(),
        provider: provider,
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('创建告警任务'), findsOneWidget);
      expect(find.text('标题'), findsOneWidget);
      expect(find.text('任务类型'), findsOneWidget);
      expect(find.text('超限阈值'), findsOneWidget);
      expect(find.text('均值统计时长'), findsOneWidget);
      expect(find.text('每日发送次数'), findsOneWidget);
    });

    testWidgets('edit mode prefills the saved rule title', (tester) async {
      final provider = emptyProvider();
      addTearDown(provider.dispose);

      await tester.pumpWidget(wrap(
        const AlertRuleForm(
          editing: AlertInfo(
            id: 1,
            title: 'CPU 过高',
            type: 'cpu',
            count: 80,
            interval: 5,
            sendCount: 2,
            status: 'Enable',
            sendMethod: <String>['Mail'],
          ),
        ),
        provider: provider,
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('编辑'), findsOneWidget);
      expect(find.text('CPU 过高'), findsOneWidget);
    });
  });

  group('Alert channel form', () {
    testWidgets('shows the email fields by default', (tester) async {
      final provider = emptyProvider();
      addTearDown(provider.dispose);

      await tester.pumpWidget(wrap(
        const AlertChannelForm(),
        provider: provider,
      ));
      await tester.pump();

      expect(find.text('新建通知渠道'), findsOneWidget);
      expect(find.text('显示名称'), findsOneWidget);
      expect(find.text('发件人'), findsOneWidget);
      expect(find.text('SMTP 主机'), findsOneWidget);
      expect(find.text('端口'), findsOneWidget);
      expect(find.text('收件人'), findsOneWidget);
    });

    testWidgets('edit mode offers the password keep/replace/clear states',
        (tester) async {
      final provider = emptyProvider();
      addTearDown(provider.dispose);

      await tester.pumpWidget(wrap(
        const AlertChannelForm(
          editing: AlertConfigInfo(
            id: 1,
            type: 'email',
            title: 'Mail',
            config: '{}',
            status: 'Enable',
          ),
        ),
        provider: provider,
      ));
      await tester.pump();

      expect(find.text('保持不变'), findsOneWidget);
      expect(find.text('替换'), findsOneWidget);
      expect(find.text('清除'), findsOneWidget);
    });
  });
}
