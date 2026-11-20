import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/theme/app_theme.dart';
import 'package:onepanel_client/data/models/vm/vm_models.dart';
import 'package:onepanel_client/data/models/vm/vm_resource_models.dart';
import 'package:onepanel_client/features/vm/providers/vm_provider.dart';
import 'package:onepanel_client/features/vm/vm_service.dart';
import 'package:onepanel_client/features/vm/widgets/vm_instance_actions.dart';
import 'package:onepanel_client/features/vm/widgets/vm_instance_dialogs.dart';
import 'package:onepanel_client/features/vm/widgets/vm_iso_form.dart';
import 'package:onepanel_client/features/vm/widgets/vm_monitor_dialog.dart';
import 'package:onepanel_client/features/vm/widgets/vm_orphan_dialog.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockVMService extends Mock implements VMService {}

Widget wrap(Widget child, {required VmProvider provider}) {
  return MaterialApp(
    theme: AppTheme.create(
      ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FE4)),
    ),
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ChangeNotifierProvider<VmProvider>.value(
        value: provider,
        child: SingleChildScrollView(child: child),
      ),
    ),
  );
}

VmProvider emptyProvider() {
  final service = _MockVMService();
  when(() => service.listNetworkBridges())
      .thenAnswer((_) async => const <VMNetworkBridgeItem>[]);
  when(() => service.listNetworkInterfaces())
      .thenAnswer((_) async => const <VMNetworkInterfaceItem>[]);
  when(() => service.listStorages())
      .thenAnswer((_) async => const <VMStorageItem>[]);
  when(() => service.listNetworks())
      .thenAnswer((_) async => const <VMNetworkItem>[]);
  when(() => service.listIso()).thenAnswer((_) async => const <VMIsoItem>[]);
  when(() => service.scanOrphans())
      .thenAnswer((_) async => const <VMOrphanItem>[]);
  return VmProvider(service: service);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VmInstanceForm', () {
    testWidgets('renders the create fields with capacity defaults',
        (tester) async {
      final provider = emptyProvider();
      addTearDown(provider.dispose);
      await provider.loadStorages();
      await provider.loadNetworks();
      await provider.loadIsos();

      await tester.pumpWidget(wrap(
        const VmInstanceForm(),
        provider: provider,
      ));
      await tester.pump();

      expect(find.text('创建虚拟机'), findsOneWidget);
      expect(find.text('名称'), findsOneWidget);
      expect(find.text('CPU 核数'), findsOneWidget);
      expect(find.text('内存'), findsOneWidget);
      expect(find.text('磁盘大小'), findsOneWidget);
      expect(find.text('存储池'), findsOneWidget);
      expect(find.text('网络'), findsOneWidget);
    });

    testWidgets('edit mode locks the name field', (tester) async {
      final provider = emptyProvider();
      addTearDown(provider.dispose);

      await tester.pumpWidget(wrap(
        const VmInstanceForm(
          editing: VMItem(
            id: 1,
            name: 'locked-name',
            cpu: 2,
            memory: 2048,
            diskSize: 10240,
            status: 'shut off',
          ),
        ),
        provider: provider,
      ));
      await tester.pump();

      expect(find.text('编辑虚拟机'), findsOneWidget);
      final nameField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'locked-name'),
      );
      expect(nameField.enabled, isFalse);
    });
  });

  group('Vm orphan dialog', () {
    testWidgets('opens with the cleanup warning and scan action',
        (tester) async {
      final provider = emptyProvider();
      addTearDown(provider.dispose);

      await tester.pumpWidget(wrap(
        const VmOrphanDialog(),
        provider: provider,
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('孤儿文件清理'), findsOneWidget);
      expect(find.textContaining('不属于任何虚拟机记录'), findsOneWidget);
      expect(find.text('扫描'), findsOneWidget);
    });
  });

  group('Vm iso form', () {
    testWidgets('offers the three ISO sources', (tester) async {
      final provider = emptyProvider();
      addTearDown(provider.dispose);

      await tester.pumpWidget(wrap(
        const VmIsoForm(),
        provider: provider,
      ));
      await tester.pump();

      expect(find.text('服务器文件'), findsOneWidget);
      expect(find.text('本地上传'), findsOneWidget);
      expect(find.text('服务器下载'), findsOneWidget);
    });
  });

  group('Vm monitor dialog', () {
    testWidgets('shows the four charts and waiting hint', (tester) async {
      final provider = emptyProvider();
      addTearDown(provider.dispose);

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.create(
          ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FE4)),
        ),
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChangeNotifierProvider<VmProvider>.value(
          value: provider,
          child: const VmMonitorView(
            vm: VMItem(id: 1, name: 'vm', status: 'shut off'),
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('CPU 使用率'), findsOneWidget);
      expect(find.text('内存使用率'), findsOneWidget);
      expect(find.text('磁盘读写速率'), findsOneWidget);
      expect(find.text('网络收发速率'), findsOneWidget);
    });
  });

  group('Vm instance dialogs', () {
    testWidgets('snapshot panel lists the create entry', (tester) async {
      final provider = emptyProvider();
      addTearDown(provider.dispose);

      await tester.pumpWidget(wrap(
        VmSnapshotView(
          vm: const VMItem(id: 1, name: 'vm', status: 'shut off'),
          provider: provider,
        ),
        provider: provider,
      ));
      await tester.pump();

      expect(find.text('快照'), findsOneWidget);
      expect(find.text('创建快照'), findsOneWidget);
    });
  });
}
