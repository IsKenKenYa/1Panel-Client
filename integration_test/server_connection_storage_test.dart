import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/network/network_exceptions.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/storage/hive_storage_service.dart';
import 'package:onepanel_client/core/storage/platform_secure_storage.dart';
import 'package:onepanel_client/data/repositories/files_repository.dart';
import 'package:onepanel_client/features/server/server_detail_page.dart';
import 'package:onepanel_client/features/server/server_list_page.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/server/server_repository.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_switcher_action.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_disk_provider.dart';
import 'package:onepanel_client/features/toolbox/widgets/toolbox_server_scope.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/pages/settings/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _credentialKey(ApiConfig config) {
  final identity = jsonEncode([config.id, config.panelType, config.url, config.credentialId]);
  return 'kenpanel_credentials_${sha256.convert(utf8.encode(identity))}';
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    final run = DateTime.now().microsecondsSinceEpoch;
    SharedPreferences.setPrefix('kenpanel.connection_test.$run.');
  });

  testWidgets('系统安全存储支持重新打开、更新和删除凭据', (_) async {
    final key = 'kenpanel_test_${DateTime.now().microsecondsSinceEpoch}';
    final storage = await PlatformSecureStorage.create();
    addTearDown(() => storage.delete(key: key));
    expect(await storage.read(key: key), isNull);
    await storage.write(key: key, value: '第一组凭据');
    final reopened = await PlatformSecureStorage.create();
    expect(await reopened.read(key: key), '第一组凭据');
    await reopened.write(key: key, value: '第二组凭据');
    expect(await storage.read(key: key), '第二组凭据');
    await reopened.delete(key: key);
    expect(await storage.read(key: key), isNull);
  });

  testWidgets('设置首页随当前连接显示对应的面板设置', (tester) async {
    const repository = ServerRepository();
    final run = DateTime.now().microsecondsSinceEpoch;
    final selection = CurrentServerController();
    addTearDown(selection.dispose);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: selection),
        ChangeNotifierProvider(create: (_) => AppSettingsController()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsPage(),
      ),
    ));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(SettingsPage)));
    final manage = find.text(l10n.settingsServerManagement);
    final panel = find.text(l10n.systemSettingsPanelSection);
    await tester.scrollUntilVisible(manage, 160);
    expect(manage, findsOneWidget);
    expect(panel, findsNothing);
    for (final type in [ApiConfig.onePanelType, 'unregistered']) {
      final server = ApiConfig(
        id: 'settings-$type-$run',
        name: 'Settings $type',
        url: 'https://localhost:8106',
        panelType: type,
        apiKey: 'settings-$run',
      );
      await repository.saveConfig(server);
      addTearDown(() => repository.removeConfig(server.id));
      await selection.selectServer(server.id);
      await tester.pumpAndSettle();
      if (type == ApiConfig.onePanelType) {
        await tester.ensureVisible(panel);
        expect(find.text(server.name), findsOneWidget);
      } else {
        expect(panel, findsNothing);
        expect(manage, findsOneWidget);
      }
    }
  });

  for (final pickedIndex in [0, 1]) {
    final selectedName = pickedIndex == 0 ? 'A' : 'B';
    testWidgets('显式查看 B 后选择 $selectedName 并跟随后续切换', (tester) async {
      const repository = ServerRepository();
      final run = DateTime.now().microsecondsSinceEpoch;
      final servers = [
        for (final name in ['A', 'B'])
          ApiConfig(
            id: 'detail-$name-$run',
            name: 'Detail $name',
            panelType: 'unregistered',
            url: 'https://localhost',
            apiKey: '',
          ),
      ];
      for (final server in servers) {
        await repository.saveConfig(server);
        addTearDown(() => repository.removeConfig(server.id));
      }
      final directory = CurrentServerController();
      addTearDown(directory.dispose);
      await directory.selectServer(servers.first.id);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: directory),
          ChangeNotifierProvider(create: (_) => ServerProvider(directory: directory)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ServerDetailPage(server: servers.last),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text(servers.last.name), findsWidgets);
      expect(find.text(servers.first.name), findsNothing);
      expect(directory.currentServerId, servers.first.id);
      await tester.tap(find.byType(ServerSwitcherAction));
      await tester.pumpAndSettle();
      final picked = servers[pickedIndex];
      final other = servers[1 - pickedIndex];
      final choice = find.descendant(
        of: find.byType(ServerPickerSheet),
        matching: find.text(picked.name),
      );
      await tester.tap(choice);
      await tester.pumpAndSettle();
      expect(directory.currentServerId, picked.id);
      expect(find.text(picked.name), findsWidgets);
      expect(find.text(other.name), findsNothing);
      await directory.selectServer(other.id);
      await tester.pumpAndSettle();
      expect(find.text(other.name), findsWidgets);
      expect(find.text(picked.name), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('保留筛选时刷新非当前服务器的名称', (tester) async {
    const repository = ServerRepository();
    final run = DateTime.now().microsecondsSinceEpoch;
    ApiConfig entry(String id, String name) => ApiConfig(
          id: id,
          name: name,
          panelType: 'unregistered',
          url: 'https://localhost',
          apiKey: '',
        );
    final first = entry('first-$run', 'Current');
    final second = entry('second-$run', 'Node A');
    for (final server in [first, second]) {
      await repository.saveConfig(server);
      addTearDown(() => repository.removeConfig(server.id));
    }
    final selection = CurrentServerController();
    final provider = ServerProvider(directory: selection);
    addTearDown(selection.dispose);
    addTearDown(provider.dispose);
    await selection.selectServer(first.id);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: selection),
        ChangeNotifierProvider.value(value: provider),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ServerListPage(enableCoach: false),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Node');
    await tester.pumpAndSettle();
    expect(find.text('Node A'), findsOneWidget);
    await repository.updateConfig(
      entry(second.id, 'Node B'),
      expected: await repository.readConfig(second.id),
    );
    await selection.refresh();
    await tester.pumpAndSettle();
    expect(selection.currentServerId, first.id);
    expect(find.text('Node'), findsOneWidget);
    expect(find.text('Node B'), findsOneWidget);
    expect(find.text('Node A'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('重复读取和快速切换面板只发布最终目录', (_) async {
    const repository = ServerRepository();
    final prefix = 'directory-${DateTime.now().microsecondsSinceEpoch}';
    final ids = ['$prefix-a', '$prefix-b'];
    for (final id in ids) {
      await repository.saveConfig(ApiConfig(
        id: id, name: id, url: 'https://example.invalid', apiKey: id,
      ));
      addTearDown(() => repository.removeConfig(id));
    }
    final selection = CurrentServerController();
    addTearDown(selection.dispose);
    final initial = selection.ensureLoaded();
    expect(selection.ensureLoaded(), same(initial));
    await initial;
    await selection.selectServer(ids.first);
    final directory = selection.servers;
    final changes = <String?>[];
    selection.addListener(() => changes.add(selection.currentServerId));
    await selection.refresh();
    expect(selection.servers, same(directory));
    expect(changes, isEmpty);

    final firstSwitch = selection.selectServer(ids.last);
    expect(selection.selectServer(ids.last), same(firstSwitch));
    await Future.wait([firstSwitch, selection.selectServer(ids.first)]);
    expect(selection.currentServerId, ids.first);
    expect((await ApiConfigManager.getServerDirectory()).selectedId, ids.first);
    expect(changes, isEmpty);

    final confirmed = selection.selectServer(ids.last);
    final invalid = selection.selectServer('$prefix-missing');
    await expectLater(invalid, throwsStateError);
    await confirmed;
    expect(selection.servers, same(directory));
    expect(changes, [ids.last]);
  });

  testWidgets('加密数据库缺少密钥时保留原文件和记录', (_) async {
    final name = 'kenpanel_hive_test_${DateTime.now().microsecondsSinceEpoch}';
    final keyName = '${name}_key';
    final vault = await PlatformSecureStorage.create();
    await Hive.initFlutter();
    addTearDown(() async {
      await Hive.deleteBoxFromDisk(name);
      await vault.delete(key: keyName);
    });

    final first = HiveStorageService(boxName: name, isEncrypted: true);
    final second = HiveStorageService(boxName: name, isEncrypted: true);
    await Future.wait([first.init(), second.init()]);
    await first.put('metric', 42);
    expect(second.get<int>('metric'), 42);
    final originalKey = (await vault.read(key: keyName))!;
    await vault.write(key: keyName, value: 'invalid');
    await expectLater(second.init(), throwsStateError);
    await Hive.box(name).close();
    await vault.delete(key: keyName);

    await expectLater(second.init(), throwsStateError);
    expect(await Hive.boxExists(name), isTrue);
    expect(await vault.read(key: keyName), isNull);
    await vault.write(key: keyName, value: originalKey);
    await second.init();
    expect(second.get<int>('metric'), 42);
  });

  testWidgets('同一地址轮换凭据时，重开目录仅读取其引用的版本', (_) async {
    const repository = ServerRepository();
    const directoryKey = 'kenpanel_servers';
    final id = 'credential-rotation-${DateTime.now().microsecondsSinceEpoch}';
    ApiConfig configFor(String secret) => ApiConfig(
          id: id,
          name: 'Credential rotation',
          url: 'https://localhost:8105',
          panelType: ApiConfig.onePanelType,
          apiKey: secret,
        );
    final preferences = await SharedPreferences.getInstance();
    final vault = await PlatformSecureStorage.create();
    addTearDown(preferences.clear);
    addTearDown(() => repository.removeConfig(id));
    await repository.saveConfig(configFor('rotation-first'));
    final previous = await ApiConfigManager.getConfig(id);
    final originalDirectory = preferences.getString(directoryKey)!;
    final previousKey = _credentialKey(previous);
    addTearDown(() => vault.delete(key: previousKey));
    final previousValue = (await vault.read(key: previousKey))!;

    await repository.updateConfig(configFor('rotation-second'), expected: previous);
    final next = await ApiConfigManager.getConfig(id);
    final nextDirectory = preferences.getString(directoryKey)!;
    final nextKey = _credentialKey(next);
    addTearDown(() => vault.delete(key: nextKey));
    expect(nextKey, isNot(previousKey));
    expect(await vault.read(key: previousKey), isNull);
    expect(await vault.read(key: nextKey), isNotNull);

    // 重建进程被终止时可能保留的两份实际凭据，分别重新加载提交前后的目录。
    await vault.write(key: previousKey, value: previousValue);
    for (final state in [(originalDirectory, previous), (nextDirectory, next)]) {
      expect(await preferences.setString(directoryKey, state.$1), isTrue);
      await preferences.reload();
      final reopened = await ApiConfigManager.getConfig(id);
      expect(reopened.revision, state.$2.revision);
      expect(reopened.apiKey, state.$2.apiKey);
    }
    await vault.delete(key: previousKey);
    expect((await ApiConfigManager.getConfig(id)).apiKey, next.apiKey);
    await repository.removeConfig(id);
    expect(await vault.read(key: nextKey), isNull);
  });

  testWidgets('选择服务器时更新工具状态，编辑连接后更新文件 API', (tester) async {
    final run = DateTime.now().microsecondsSinceEpoch;
    final preferences = await SharedPreferences.getInstance();
    addTearDown(preferences.clear);
    final first = ApiConfig(
      id: 'connection-test-$run-a',
      panelType: ApiConfig.onePanelType,
      name: 'A',
      url: 'https://localhost:8101',
      apiKey: 'a-$run',
      isDefault: true,
    );
    final second = ApiConfig(
      id: 'connection-test-$run-b',
      panelType: ApiConfig.onePanelType,
      name: 'B',
      url: 'https://localhost:8102',
      apiKey: 'b-$run',
      isDefault: true,
    );
    const repository = ServerRepository();
    final invalid = ApiConfig(
      id: 'connection-test-$run-invalid',
      name: 'Invalid',
      url: 'https://localhost:8104',
      apiKey: '',
      panelType: '',
    );
    for (final config in [first, second, invalid]) {
      addTearDown(() async {
        await repository.removeConfig(config.id);
      });
    }

    final files = FilesRepository();
    await expectLater(
      files.getApi(),
      throwsA(isA<NetworkConnectionException>()),
    );
    await repository.saveConfig(first);
    final savedFirst = await ApiConfigManager.getConfig(first.id);
    expect(savedFirst.revision, isNotEmpty);
    await expectLater(
      repository.updateConfig(first, expected: first),
      throwsStateError,
    );
    expect((await ApiConfigManager.getCurrentServerMetadata())?.id, first.id);
    final results = await repository.saveConfigs([invalid, second]);
    expect(results.map((item) => item.serverId), [invalid.id, second.id]);
    expect(results.first.error, isA<ArgumentError>());
    expect(results.last.error, isNull);
    final afterDefaultChange = await ApiConfigManager.getConfig(first.id);
    expect(afterDefaultChange.isDefault, isFalse);
    expect(afterDefaultChange.revision, isNot(savedFirst.revision));
    expect(afterDefaultChange.credentialId, savedFirst.credentialId);
    await expectLater(
      repository.updateConfig(first, expected: savedFirst),
      throwsStateError,
    );
    final savedSecond = await ApiConfigManager.getConfig(second.id);
    await repository.updateConfig(savedSecond, expected: savedSecond);
    final currentSecond = await ApiConfigManager.getConfig(second.id);
    expect(currentSecond.revision, isNot(savedSecond.revision));
    await expectLater(
      repository.updateConfig(savedSecond, expected: savedSecond),
      throwsStateError,
    );
    final missingTools = ToolboxDiskProvider(serverId: invalid.id);
    addTearDown(missingTools.dispose);
    await missingTools.load();
    expect(missingTools.hasSnapshot, isFalse);
    expect(missingTools.loadError, isNotEmpty);
    expect((await ApiConfigManager.getCurrentServerMetadata())?.id, first.id);
    final settings = preferences.getKeys().map(preferences.get).join('\n');
    expect(settings, isNot(contains(first.apiKey)));
    expect(settings, isNot(contains(second.apiKey)));

    final controller = CurrentServerController();
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.servers.map((server) => server.id), [first.id, second.id]);
    expect(controller.currentServerId, first.id);
    expect(controller.hasServer, isTrue);
    expect(controller.servers.every((server) => server.apiKey.isEmpty), isTrue);
    late ToolboxDiskProvider visibleTools;
    final selection = Completer<String?>();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(children: [
            SizedBox(
              width: 260,
              child: AdaptiveLayoutViewport(
                child: Align(
                  child: ServerSwitcherAction(onChanged: () async {
                    selection.complete(controller.currentServerId);
                  }),
                ),
              ),
            ),
            Expanded(
              child: ToolboxServerScope<ToolboxDiskProvider>(
                title: 'Disk',
                create: (id) => ToolboxDiskProvider(serverId: id),
                child: Builder(builder: (context) {
                  visibleTools = context.read<ToolboxDiskProvider>();
                  return const SizedBox.shrink();
                }),
              ),
            ),
          ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final firstTools = visibleTools;
    final firstApi = await files.getApi();
    expect(await files.getApi(), same(firstApi));

    final switcher = find.byIcon(Icons.dns_outlined);
    await tester.tap(switcher);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(ServerPickerSheet)).width,
      lessThanOrEqualTo(260),
    );
    expect(
      tester.widget<ListTile>(find.byKey(ValueKey(first.id))).selected,
      isTrue,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(controller.currentServerId, first.id);
    expect(selection.isCompleted, isFalse);
    await tester.tap(switcher);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey(first.id)));
    await tester.pumpAndSettle();
    expect(selection.isCompleted, isFalse);
    expect(visibleTools, same(firstTools));
    await tester.tap(switcher);
    await tester.pumpAndSettle();
    final nextServer = find.byKey(ValueKey(second.id));
    await tester.ensureVisible(nextServer);
    await tester.tap(nextServer);
    await tester.pumpAndSettle();
    expect(
      await selection.future.timeout(const Duration(seconds: 10)),
      second.id,
    );
    expect(firstTools.isDisposed, isTrue);
    expect(visibleTools, isNot(same(firstTools)));
    expect(visibleTools.hasSnapshot, isFalse);
    final secondTools = visibleTools;
    final restored = CurrentServerController();
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.currentServerId, second.id);
    expect((await ApiConfigManager.getCurrentConfig())!.apiKey, second.apiKey);
    final secondApi = await files.getApi();
    expect(secondApi, isNot(same(firstApi)));
    expect(await files.getApi(), same(secondApi));

    final edited = ApiConfig(
      id: second.id,
      panelType: ApiConfig.onePanelType,
      name: second.name,
      url: 'https://localhost:8103',
      apiKey: second.apiKey,
    );
    final retiredKey = _credentialKey(currentSecond);
    final vault = await PlatformSecureStorage.create();
    final originalCredentials = (await vault.read(key: retiredKey))!;
    await vault.write(key: retiredKey, value: 'invalid');
    try {
      await expectLater(
        repository.updateConfig(edited, expected: currentSecond),
        throwsFormatException,
      );
      final unchanged = await ApiConfigManager.getCurrentServerMetadata();
      expect(unchanged?.revision, currentSecond.revision);
      expect(unchanged?.url, currentSecond.url);
      expect(await vault.read(key: retiredKey), 'invalid');
    } finally {
      await vault.write(key: retiredKey, value: originalCredentials);
    }
    await repository.updateConfig(edited, expected: currentSecond);
    await controller.refresh();
    await tester.pump();
    expect(secondTools.isDisposed, isTrue);
    expect(visibleTools, isNot(same(secondTools)));
    await expectLater(
      repository.updateConfig(second, expected: currentSecond),
      throwsStateError,
    );
    final savedEdit = await ApiConfigManager.getConfig(second.id);
    expect(savedEdit.url, edited.url);
    expect(savedEdit.revision, isNot(currentSecond.revision));
    expect(await vault.read(key: retiredKey), isNull);
    final changedApi = await files.getApi();
    expect(changedApi, isNot(same(secondApi)));
    files.clearCache();
    final fresh = await files.getApi();
    expect(fresh, isNot(same(changedApi)));
    expect(await files.getApi(), same(fresh));
    await tester.pumpWidget(const SizedBox.shrink());

    await repository.removeConfig(second.id);
    await expectLater(
      repository.updateConfig(edited, expected: savedEdit),
      throwsStateError,
    );
    expect((await ApiConfigManager.getCurrentServerMetadata())?.id, first.id);
    await repository.removeConfig(first.id);
    expect(await ApiConfigManager.getCurrentServerMetadata(), isNull);
  });
}
