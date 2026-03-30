import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/process_detail_models.dart';
import 'package:onepanel_client/features/processes/pages/process_detail_page.dart';
import 'package:onepanel_client/features/processes/providers/process_detail_provider.dart';
import 'package:onepanel_client/features/processes/services/process_service.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockProcessService extends Mock implements ProcessService {}

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

class _NoServerCurrentServerController extends CurrentServerController {}

void main() {
  const detail = ProcessDetail(
    pid: 1,
    name: 'sshd',
    parentPid: 0,
    username: 'root',
    status: 'running',
    startTime: 'now',
    numThreads: 1,
    numConnections: 1,
    diskRead: '0B',
    diskWrite: '0B',
    cmdLine: 'sshd',
    rss: '1M',
    pss: '1M',
    uss: '1M',
    swap: '0B',
    shared: '0B',
    vms: '1M',
    hwm: '1M',
    data: '0B',
    stack: '0B',
    locked: '0B',
    text: '0B',
    dirty: '0B',
    envs: <String>['A=B'],
    openFiles: <ProcessOpenFile>[],
    connections: <ProcessConnection>[],
  );

  testWidgets('ProcessDetailPage renders detail sections', (tester) async {
    final service = _MockProcessService();
    when(() => service.loadDetail(any())).thenAnswer((_) async => detail);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<ProcessDetailProvider>(
            create: (_) => ProcessDetailProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const ProcessDetailPage(pid: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Command line'), findsOneWidget);
  });

  testWidgets('ProcessDetailPage does not load when no server is active',
      (tester) async {
    final service = _MockProcessService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _NoServerCurrentServerController(),
          ),
          ChangeNotifierProvider<ProcessDetailProvider>(
            create: (_) => ProcessDetailProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const ProcessDetailPage(pid: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    verifyNever(() => service.loadDetail(any()));
  });

  testWidgets('ProcessDetailPage keeps long detail rows stable',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final longCmd =
        '${List.filled(10, '/usr/local/bin/very-long-command').join(' ')} --with-flag --env=staging';
    final longDetail = ProcessDetail(
      pid: 2,
      name: 'runtime',
      parentPid: 1,
      username: 'root',
      status: 'running',
      startTime: 'now',
      numThreads: 2,
      numConnections: 2,
      diskRead: '12MB',
      diskWrite: '22MB',
      cmdLine: longCmd,
      rss: '1M',
      pss: '1M',
      uss: '1M',
      swap: '0B',
      shared: '0B',
      vms: '1M',
      hwm: '1M',
      data: '0B',
      stack: '0B',
      locked: '0B',
      text: '0B',
      dirty: '0B',
      envs: const <String>['A=B'],
      openFiles: <ProcessOpenFile>[
        ProcessOpenFile(
          path:
              '/var/log/${List.filled(24, 'very-long-file-path-segment').join('/')}/runtime.log',
          fd: 3,
        ),
      ],
      connections: const <ProcessConnection>[],
    );

    final service = _MockProcessService();
    when(() => service.loadDetail(any())).thenAnswer((_) async => longDetail);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<ProcessDetailProvider>(
            create: (_) => ProcessDetailProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(textScaler: const TextScaler.linear(2)),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const ProcessDetailPage(pid: 2),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final commandFinder = find.byWidgetPredicate(
      (widget) =>
          widget is SelectableText &&
          (widget.data?.contains('--env=staging') ?? false),
    );
    expect(commandFinder, findsOneWidget);

    final commandWidget = tester.widget<SelectableText>(commandFinder);
    expect(commandWidget.maxLines, 4);
  });
}
