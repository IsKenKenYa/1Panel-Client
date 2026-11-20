import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/theme/app_theme.dart';
import 'package:onepanel_client/data/models/vm/vm_models.dart';
import 'package:onepanel_client/data/models/vm/vm_resource_models.dart';
import 'package:onepanel_client/features/vm/providers/vm_provider.dart';
import 'package:onepanel_client/features/vm/vm_service.dart';
import 'package:onepanel_client/features/vm/widgets/vm_environment_banner.dart';
import 'package:onepanel_client/features/vm/widgets/vm_instance_card.dart';
import 'package:onepanel_client/features/vm/widgets/vm_sparkline.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockVMService extends Mock implements VMService {}

Widget wrap(Widget child, {VmProvider? provider}) {
  final theme = AppTheme.create(
    ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FE4)),
  );
  final scoped = provider == null
      ? child
      : ChangeNotifierProvider<VmProvider>.value(
          value: provider,
          child: child,
        );
  return MaterialApp(
    theme: theme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: scoped),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vm instance card', () {
    testWidgets('renders name, status chip and resource facts', (tester) async {
      await tester.pumpWidget(wrap(
        VmInstanceCard(
          vm: const VMItem(
            id: 1,
            name: 'demo-vm',
            cpu: 4,
            memory: 4096,
            diskSize: 21474836480,
            status: 'running',
            network: 'default',
            storagePool: 'default-pool',
            description: 'ubuntu node',
          ),
          onOpenActions: () {},
        ),
      ));

      expect(find.text('demo-vm'), findsOneWidget);
      expect(find.text('running'), findsOneWidget);
      expect(find.textContaining('default'), findsWidgets);
      expect(find.text('ubuntu node'), findsOneWidget);
    });

    testWidgets('status chip maps shut off to the neutral palette',
        (tester) async {
      await tester.pumpWidget(wrap(
        const VmStatusChip(status: 'shut off'),
      ));

      expect(find.text('shut off'), findsOneWidget);
    });

    testWidgets('card tap forwards to the action callback', (tester) async {
      var opened = 0;
      await tester.pumpWidget(wrap(
        VmInstanceCard(
          vm: const VMItem(id: 1, name: 'tap-me', status: 'running'),
          onOpenActions: () => opened++,
        ),
      ));

      await tester.tap(find.text('tap-me'));
      await tester.pump();
      expect(opened, 1);
    });
  });

  group('Vm environment banner', () {
    testWidgets('stays hidden when the runtime environment is ready',
        (tester) async {
      final service = _MockVMService();
      when(() => service.checkEnvironment()).thenAnswer(
        (_) async => const VMEnvironment(
          arch: 'x86_64',
          archSupported: true,
          ready: true,
          helperExist: true,
          kvmExist: true,
          libvirtExist: true,
          libvirtActive: true,
          storageExist: true,
        ),
      );
      final provider = VmProvider(service: service);
      await provider.loadEnvironment();
      addTearDown(provider.dispose);

      await tester.pumpWidget(wrap(
        const VmEnvironmentBanner(),
        provider: provider,
      ));
      await tester.pump();

      expect(find.text('1Panel-kvm'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('lists the failing checks when the environment is not ready',
        (tester) async {
      final service = _MockVMService();
      when(() => service.checkEnvironment()).thenAnswer(
        (_) async => const VMEnvironment(
          arch: 'x86_64',
          archSupported: true,
          ready: false,
          helperExist: false,
          helperMessage: 'helper missing',
          kvmExist: false,
          kvmMessage: '/dev/kvm not found',
          libvirtExist: true,
          libvirtActive: false,
          libvirtMessage: 'libvirtd inactive',
          storageExist: true,
        ),
      );
      final provider = VmProvider(service: service);
      await provider.loadEnvironment();
      addTearDown(provider.dispose);

      await tester.pumpWidget(wrap(
        const VmEnvironmentBanner(),
        provider: provider,
      ));
      await tester.pump();

      expect(find.textContaining('helper missing'), findsOneWidget);
      expect(find.textContaining('/dev/kvm not found'), findsOneWidget);
    });

    testWidgets('hides the banner while the environment is ready',
        (tester) async {
      final service = _MockVMService();
      when(() => service.checkEnvironment())
          .thenAnswer((_) async => const VMEnvironment(ready: true));
      when(() => service.listIso())
          .thenAnswer((_) async => const <VMIsoItem>[]);
      when(() => service.listTemplates())
          .thenAnswer((_) async => const <VMTemplateItem>[]);
      when(() => service.listNetworks())
          .thenAnswer((_) async => const <VMNetworkItem>[]);
      when(() => service.listStorages())
          .thenAnswer((_) async => const <VMStorageItem>[]);
      when(() => service.searchVMs(info: any(named: 'info')))
          .thenAnswer((_) async => const VMSearchResult());
      final provider = VmProvider(service: service);
      await provider.loadAll();
      addTearDown(provider.dispose);

      await tester.pumpWidget(wrap(
        const VmEnvironmentBanner(),
        provider: provider,
      ));
      await tester.pump();

      expect(find.byType(SizedBox), findsWidgets);
      expect(find.text('运行环境未就绪'), findsNothing);
    });
  });

  group('VmSparkline', () {
    testWidgets('draws a placeholder line without samples', (tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 200,
          height: 64,
          child: VmSparkline(samples: <double>[]),
        ),
      ));

      expect(find.byType(VmSparkline), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('draws the series with multiple samples', (tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 200,
          height: 64,
          child: VmSparkline(samples: <double>[0, 12, 30, 18, 44]),
        ),
      ));

      expect(find.byType(VmSparkline), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('repaints when the sample window changes', (tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 200,
          height: 64,
          child: VmSparkline(samples: <double>[1, 2, 3]),
        ),
      ));
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 200,
          height: 64,
          child: VmSparkline(samples: <double>[3, 2, 1]),
        ),
      ));

      expect(tester.takeException(), isNull);
    });
  });
}
