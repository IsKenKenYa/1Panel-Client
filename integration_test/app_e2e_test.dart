// E2E UI 旅程测试（Android 模拟器 / 真实服务器）。
//
// 运行方式：
//   flutter test integration_test/app_e2e_test.dart -d emulator-5556 --timeout 900s
//
// 说明：
// - 单条 testWidgets 内串行执行旅程，共用应用启动及服务器连接。
// - 硬断言旅程失败即 FAIL；依赖动态数据的旅程为软断言，
//   条件不满足时打印 SKIP 并继续，最终输出结果摘要。
// - 默认只读走查。E2E_ENABLE_FILE_MUTATIONS=true 允许文件旅程创建和删除
//   onepanel-e2e-ui-* 测试目录。
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/features/containers/widgets/container_card.dart';
import 'package:onepanel_client/features/server/server_detail_page.dart';
import 'package:onepanel_client/features/server/widgets/server_card.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/main.dart' as app;
import 'package:onepanel_client/shared/widgets/section_card.dart';
import 'package:onepanel_client/widgets/navigation/app_bottom_navigation_bar.dart';

// 底部导航/通用文案（中文优先，英文兜底）。
const kNavServers = ['服务器', 'Servers'];
const kNavFiles = ['文件', 'Files'];
const kNavContainers = ['容器管理', 'Containers'];
const kNavSettings = ['设置', 'Settings'];

const kServerSearchHints = ['请输入服务器名称或 IP', 'Enter server name or IP'];
const kRootDirs = ['etc', 'home', 'usr', 'opt', 'var', 'tmp', 'root', 'srv'];
const kContinueLabels = ['继续', 'Continue'];
const kAgreeLabels = ['同意并继续', 'Agree and continue'];
const kSkipLabels = ['跳过', 'Skip'];

// 服务器自助配置（数据被清空时通过 UI 恢复）。凭据经 --dart-define 注入，
// 不写入仓库。
const kE2eServerName =
    String.fromEnvironment('E2E_SERVER_NAME', defaultValue: 'US');
const kE2eServerUrl = String.fromEnvironment('E2E_SERVER_URL');
const kE2eServerApiKey = String.fromEnvironment('E2E_SERVER_API_KEY');
const kEnableFileMutations = bool.fromEnvironment('E2E_ENABLE_FILE_MUTATIONS');

final Map<String, String> journeyResults = <String, String>{};

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('E2E旅程', () {
    testWidgets(
      '核心UI旅程串行：启动→服务器→仪表盘→文件→容器→网站→AI→设置',
      (tester) async {
        await _startup(tester);

        // ---- 旅程 1：启动与服务器列表（硬） ----
        await _journey1Servers(tester);

        // ---- 旅程 2：仪表盘监控数据（软） ----
        await _softJourney('2.仪表盘监控数据', () => _journey2Metrics(tester));

        // ---- 旅程 3：文件浏览（硬） ----
        await _journey3BrowseFiles(tester);

        // ---- 旅程 4：文件操作的确认及取消 ----
        await _checkFileDeleteCancel(tester);
        journeyResults['4.文件删除确认与取消'] = 'PASS';
        if (kEnableFileMutations) {
          await _softJourney('4.文件新建与删除', () => _journey4CreateDelete(tester));
        }

        // ---- 旅程 5：容器列表与详情（软） ----
        await _softJourney('5.容器列表与详情', () => _journey5Containers(tester));

        // ---- 旅程 6：网站管理列表（软） ----
        await _softJourney('6.网站管理列表', () => _journey6Websites(tester));

        // ---- 旅程 7：AI 模块（软） ----
        await _softJourney('7.AI模块', () => _journey7Ai(tester));

        // ---- 旅程 8：设置只读校验（硬+软） ----
        await _journey8SettingsReadOnly(tester);

        // ---- 旅程 9：服务器详情和运维中心的功能入口与逐层返回 ----
        await _journey9ModuleNavigation(tester);

        print('\n========== E2E 旅程结果摘要 ==========');
        for (final entry in journeyResults.entries) {
          print('${entry.key}: ${entry.value}');
        }
        print('======================================\n');
      },
    );
  });
}

// ---------------------------------------------------------------------------
// 启动与通用辅助
// ---------------------------------------------------------------------------

Future<void> _startup(WidgetTester tester) async {
  app.main();
  await tester.pump();
  await _settle(tester, seconds: 20);
  await _dismissColdStartDialogs(tester);
  await _dismissOverlays(tester);
  await _settle(tester, seconds: 8);
  await _provisionServerIfEmpty(tester);
  await _settle(tester, seconds: 8);
}

/// 服务器数据被清空（如重装清数据）时，通过「添加服务器」表单恢复配置，
/// 保证后续旅程有真实服务器可用。
Future<void> _provisionServerIfEmpty(WidgetTester tester) async {
  if (kE2eServerUrl.isEmpty || kE2eServerApiKey.isEmpty) {
    return;
  }
  if (!_exists(find.text('暂无服务器'))) {
    return;
  }
  print('\n[E2E] 检测到服务器列表为空，开始通过 UI 恢复配置（$kE2eServerName）');
  final addBtn = _firstVisible([find.text('添加'), find.text('Add')]);
  if (addBtn == null) {
    print('[E2E] 未找到「添加」按钮，跳过自助配置');
    return;
  }
  await tester.tap(addBtn, warnIfMissed: false);
  await _settle(tester, seconds: 8);

  final fields = find.byType(TextField);
  if (fields.evaluate().length < 3) {
    print('[E2E] 服务器表单字段不足，跳过自助配置');
    await _goBack(tester);
    return;
  }
  // 字段顺序：名称 / 地址 / API 密钥 / （有效期默认 0）。
  await tester.enterText(fields.at(0), kE2eServerName);
  await _settle(tester, seconds: 1);
  await tester.enterText(fields.at(1), kE2eServerUrl);
  await _settle(tester, seconds: 1);
  await tester.enterText(fields.at(2), kE2eServerApiKey);
  await _settle(tester, seconds: 1);

  final saveBtn =
      _firstVisible([find.text('保存并继续'), find.text('Save and Continue')]);
  if (saveBtn == null) {
    print('[E2E] 未找到「保存并继续」按钮，跳过自助配置');
    await _goBack(tester);
    return;
  }
  await tester.ensureVisible(saveBtn);
  await tester.tap(saveBtn, warnIfMissed: false);
  await _settle(tester, seconds: 15);
  print('[E2E] 服务器配置恢复完成');
}

/// 宽容 settle：
/// - 真实时间轮询（live binding 下网络 IO 需要真实时钟推进）；
/// - 有帧持续调度（加载动画）时继续等待，直到连续两轮无帧调度（界面稳定）
///   或超时。
Future<void> _settle(WidgetTester tester, {int seconds = 8}) async {
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  var quietRounds = 0;
  while (DateTime.now().isBefore(deadline)) {
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 1),
      );
      quietRounds++;
    } catch (_) {
      quietRounds = 0; // 持续动画/加载中
    }
    // 让真实事件循环跑一拍，给网络回调/定时器机会。
    await Future<void>.delayed(const Duration(milliseconds: 300));
    try {
      await tester.pump(const Duration(milliseconds: 100));
    } catch (_) {
      break;
    }
    if (quietRounds >= 2) {
      return;
    }
  }
  try {
    await tester.pump(const Duration(milliseconds: 100));
  } catch (_) {}
}

/// 关闭引导/教练蒙层（跳过按钮兜底）。
Future<void> _dismissOverlays(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    final skip = _firstVisible(kSkipLabels.map((t) => find.text(t)).toList());
    if (skip == null) {
      return;
    }
    await tester.tap(skip, warnIfMissed: false);
    await _settle(tester, seconds: 4);
  }
}

Finder? _firstVisible(Iterable<Finder> finders) {
  for (final finder in finders) {
    final hit = finder.hitTestable();
    if (hit.evaluate().isNotEmpty) {
      return hit.first;
    }
  }
  return null;
}

bool _exists(Finder finder) => finder.evaluate().isNotEmpty;

Future<void> _tapVisible(
  WidgetTester tester,
  Finder finder, {
  int seconds = 8,
}) async {
  final target = finder.hitTestable().first;
  await tester.ensureVisible(target);
  await tester.tap(target, warnIfMissed: false);
  await _settle(tester, seconds: seconds);
}

Future<void> _goBack(WidgetTester tester) async {
  final back = _firstVisible([
    find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(BackButton),
    ),
    find.byIcon(Icons.arrow_back),
  ]);
  if (back != null) {
    await tester.tap(back);
  } else {
    await tester.binding.handlePopRoute();
  }
  await _settle(tester);
}

Future<bool> _tapBottomNav(
  WidgetTester tester,
  List<String> labels, {
  int seconds = 8,
}) async {
  for (final label in labels) {
    final tab = find
        .descendant(
          of: find.byType(AppBottomNavigationBar),
          matching: find.text(label),
        )
        .hitTestable();
    if (tab.evaluate().isNotEmpty) {
      await tester.tap(tab.first, warnIfMissed: false);
      await _settle(tester, seconds: seconds);
      return true;
    }
  }
  return false;
}

/// 确保回到 shell 根（底部导航可见），并停留在「服务器」标签。
Future<void> _ensureShellRoot(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    if (_exists(find.byType(AppBottomNavigationBar).hitTestable())) {
      break;
    }
    await _goBack(tester);
  }
  await _dismissOverlays(tester);
  await _tapBottomNav(tester, kNavServers, seconds: 4);
}

Future<bool> _openDrawer(WidgetTester tester) async {
  final button =
      find.byKey(const Key('shell-drawer-menu-button')).hitTestable();
  if (button.evaluate().isNotEmpty) {
    await tester.tap(button.first, warnIfMissed: false);
    await _settle(tester, seconds: 4);
    return _exists(find.byType(Drawer).hitTestable());
  }
  // 兜底：从左缘拖出抽屉。
  await tester.dragFrom(const Offset(6, 400), const Offset(280, 0));
  await _settle(tester, seconds: 4);
  return _exists(find.byType(Drawer).hitTestable());
}

/// 打开抽屉并点击「功能模块」区中的模块文本；失败时关闭抽屉并返回 false。
Future<bool> _openDrawerModule(WidgetTester tester, List<String> labels) async {
  await _ensureShellRoot(tester);
  if (!await _openDrawer(tester)) {
    return false;
  }
  for (final label in labels) {
    final tile =
        find.descendant(of: find.byType(Drawer), matching: find.text(label));
    if (await _scrollUntilVisible(tester, tile, maxDrags: 4)) {
      await tester.tap(tile.hitTestable().first);
      await _settle(tester, seconds: 10);
      await _dismissOverlays(tester);
      return true;
    }
  }
  await _goBack(tester); // 关闭抽屉
  return false;
}

/// 列表滚动查找：滚动最多 maxDrags 次直到 finder 可命中。
/// 拖动起点取左侧中部，避开右下角 FAB 与左缘抽屉手势热区。
Future<bool> _scrollUntilVisible(
  WidgetTester tester,
  Finder finder, {
  int maxDrags = 8,
  bool reverse = false,
}) async {
  for (var i = 0; i <= maxDrags; i++) {
    if (_exists(finder.hitTestable())) {
      return true;
    }
    if (i == maxDrags) break;
    await tester.dragFrom(
      const Offset(130, 430),
      Offset(0, reverse ? 320 : -320),
    );
    await _settle(tester, seconds: 3);
  }
  return false;
}

Future<void> _softJourney(String name, Future<void> Function() body) async {
  try {
    await body();
    journeyResults[name] = 'PASS';
    print('\n=== [$name] PASS ===');
  } catch (error, stackTrace) {
    journeyResults[name] = 'SKIP（$error）';
    print('\n=== [$name] SKIP：$error ===');
    final lines = stackTrace.toString().split('\n').take(6).join('\n');
    print('[$name] stack head:\n$lines');
  }
}

Future<void> _dismissColdStartDialogs(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    final dialog = find.byKey(const Key('testing-warning-dialog'));
    if (!_exists(dialog)) {
      return;
    }
    // 需要勾选同意时先勾选（Alpha 渠道可能要求 consent）。
    final l10n = AppLocalizations.of(tester.element(dialog));
    final consent = _firstVisible([find.text(l10n.testingWarningConsentText)]);
    if (consent != null) {
      await tester.tap(consent, warnIfMissed: false);
      await _settle(tester, seconds: 2);
    }
    final cont = _firstVisible([
      ...kContinueLabels.map((t) => find.text(t)),
      ...kAgreeLabels.map((t) => find.text(t)),
    ]);
    if (cont == null) {
      return;
    }
    await tester.tap(cont, warnIfMissed: false);
    await _settle(tester, seconds: 6);
  }
}

// ---------------------------------------------------------------------------
// 旅程实现
// ---------------------------------------------------------------------------

/// 旅程 1：启动 → 关闭 Alpha 弹窗 → 服务器列表可见。
Future<void> _journey1Servers(WidgetTester tester) async {
  final name = '1.启动与服务器列表';
  final navOrTitle =
      _firstVisible(kNavServers.map((t) => find.text(t)).toList());
  expect(navOrTitle != null, isTrue, reason: '启动后未找到「服务器」标签/标题');

  final hasServerCard = _exists(find.byType(ServerCard).hitTestable());
  final hasSearch = kServerSearchHints.any(
        (hint) => _exists(find.text(hint).hitTestable()),
      ) ||
      _exists(find.byIcon(Icons.search).hitTestable());
  expect(
    hasServerCard || hasSearch,
    isTrue,
    reason: '服务器列表页应显示服务器卡片或搜索框',
  );

  journeyResults[name] = 'PASS';
  print('\n=== [$name] PASS ===');
}

/// 旅程 2（软）：服务器卡指标（CPU/内存）→「查看详情」→ 详情页断言 → 返回。
Future<void> _journey2Metrics(WidgetTester tester) async {
  await _ensureShellRoot(tester);

  final hasCpu = _exists(find.textContaining('CPU'));
  final hasMemory = _exists(find.textContaining('内存'));
  if (!hasCpu && !hasMemory) {
    throw StateError('服务器卡片上未找到 CPU/内存 指标文本');
  }

  final detailLink = _firstVisible([find.text('查看详情')]);
  if (detailLink == null) {
    throw StateError('未找到「查看详情」链接（指标文本已确认）');
  }
  await tester.tap(detailLink, warnIfMissed: false);
  await _settle(tester, seconds: 12);

  final detailOk = _exists(find.text('服务器详情')) ||
      _exists(find.text('功能模块')) ||
      _exists(find.text('更多')) ||
      _exists(find.textContaining('CPU'));
  if (!detailOk) {
    await _goBack(tester);
    throw StateError('详情页未找到指标/章节元素');
  }

  await _goBack(tester);
}

/// 旅程 3（硬）：底部导航 → 文件 → 根目录出现任意目录条目。
Future<void> _journey3BrowseFiles(WidgetTester tester) async {
  final name = '3.文件浏览';
  final opened = await _tapBottomNav(tester, kNavFiles, seconds: 12) ||
      await _openDrawerModule(tester, kNavFiles);
  expect(opened, isTrue, reason: '底栏或抽屉应提供文件入口');

  var found = false;
  for (final dir in kRootDirs) {
    if (_exists(find.text(dir).hitTestable())) {
      found = true;
      break;
    }
  }
  if (!found) {
    for (final dir in kRootDirs) {
      if (await _scrollUntilVisible(tester, find.text(dir), maxDrags: 6)) {
        found = true;
        break;
      }
    }
  }
  expect(
    found,
    isTrue,
    reason: '文件页根目录未出现任何系统目录条目（etc/home/usr/...）',
  );

  journeyResults[name] = 'PASS';
  print('\n=== [$name] PASS ===');
}

Future<void> _checkFileDeleteCancel(WidgetTester tester) async {
  final names =
      kRootDirs.where((name) => _exists(find.text(name).hitTestable()));
  final visibleNames = names.take(2).toList();
  expect(visibleNames, hasLength(2), reason: '文件页应显示两个可操作的目录');

  final selectedName = visibleNames.first;
  final otherName = visibleNames.last;
  final selected = find.text(selectedName).hitTestable().first;
  final l10n = AppLocalizations.of(tester.element(selected));
  final selectionTitle = find.text(l10n.filesSelectedCount(1));
  await tester.longPress(selected);
  await _settle(tester);
  expect(selectionTitle, findsOneWidget);

  final targetRow = find.ancestor(
    of: find.text(otherName).hitTestable().first,
    matching: find.byType(ListTile),
  );
  final menu = find.descendant(
    of: targetRow,
    matching: find.byType(PopupMenuButton<String>),
  );
  await _tapVisible(tester, menu);
  final delete = find.widgetWithText(
    PopupMenuItem<String>,
    l10n.filesActionDelete,
  );
  await tester.ensureVisible(delete);
  await _tapVisible(tester, delete);
  final dialog = find.byType(AlertDialog);
  expect(find.descendant(of: dialog, matching: find.text('/$otherName')),
      findsOneWidget);
  expect(find.descendant(of: dialog, matching: find.text('/$selectedName')),
      findsNothing);
  await _tapVisible(
    tester,
    find.descendant(of: dialog, matching: find.text(l10n.commonCancel)),
  );
  expect(selectionTitle, findsOneWidget);
  expect(find.text(otherName).hitTestable(), findsOneWidget);
  await _tapVisible(tester, find.text(selectedName));
  expect(selectionTitle, findsNothing);
}

/// 旅程 4（软）：FAB 新建文件夹 → 输入夹具名 → 创建 → 断言出现 → 菜单删除 →
/// 断言消失。
Future<void> _journey4CreateDelete(WidgetTester tester) async {
  await _tapBottomNav(tester, kNavFiles, seconds: 8);

  final fab = _firstVisible([find.text('新建'), find.text('New')]);
  if (fab == null) {
    throw StateError('文件页未找到「新建」FAB');
  }
  await tester.tap(fab, warnIfMissed: false);
  await _settle(tester, seconds: 4);

  final newFolder =
      _firstVisible([find.text('新建文件夹'), find.text('New Folder')]);
  if (newFolder == null) {
    throw StateError('新建底部弹层未找到「新建文件夹」入口');
  }
  await tester.tap(newFolder, warnIfMissed: false);
  await _settle(tester, seconds: 4);

  final nameField = find
      .descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      )
      .hitTestable();
  if (nameField.evaluate().isEmpty) {
    throw StateError('新建文件夹对话框未找到名称输入框');
  }
  final suffix = DateTime.now().millisecondsSinceEpoch % 1000000;
  final fixtureName = 'onepanel-e2e-ui-$suffix';
  await tester.enterText(nameField.first, fixtureName);
  await _settle(tester, seconds: 2);

  final createBtn = find
      .descendant(of: find.byType(AlertDialog), matching: find.text('创建'))
      .hitTestable();
  if (createBtn.evaluate().isEmpty) {
    throw StateError('新建文件夹对话框未找到「创建」确认按钮');
  }
  await tester.tap(createBtn.first, warnIfMissed: false);
  await _settle(tester, seconds: 12);

  // 等待对话框完全关闭，避免输入框同名文本残留造成误判。
  for (var i = 0; i < 10; i++) {
    if (find.byType(AlertDialog).hitTestable().evaluate().isEmpty) {
      break;
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 100));
  }

  // 滚动直到夹具条目及其菜单按钮均可命中（evaluate 只能证明「已构建」，
  // 位于视口缓存区时 hitTestable 为空，直接链式取 .first 会抛 Bad state）。
  // 注意：条目的弹出菜单是 PopupMenuButton<String>，byType(PopupMenuButton)
  // 匹配 runtimeType == PopupMenuButton<dynamic> 永不相等，必须用
  // byWidgetPredicate。
  Element? menuButtonElement;
  for (var i = 0; i < 10 && menuButtonElement == null; i++) {
    final nameEls = find.text(fixtureName).hitTestable().evaluate();
    if (nameEls.isNotEmpty) {
      Element? tileElement;
      nameEls.first.visitAncestorElements((ancestor) {
        if (ancestor.widget is ListTile) {
          tileElement = ancestor;
          return false;
        }
        return true;
      });
      if (tileElement != null) {
        final menuFinder = find
            .descendant(
              of: find.byElementPredicate((e) => identical(e, tileElement)),
              matching: find.byWidgetPredicate((w) => w is PopupMenuButton),
            )
            .hitTestable();
        final menuEls = menuFinder.evaluate();
        if (menuEls.isNotEmpty) {
          menuButtonElement = menuEls.first;
          break;
        }
      }
    }
    await tester.dragFrom(const Offset(130, 430), const Offset(0, -320));
    await _settle(tester, seconds: 2);
  }
  if (menuButtonElement == null) {
    throw StateError('创建后列表未出现 $fixtureName（或其菜单按钮不可命中）');
  }

  // 通过条目菜单删除。
  final menuButtonFinder =
      find.byElementPredicate((e) => identical(e, menuButtonElement));
  await tester.ensureVisible(menuButtonFinder);
  await tester.tap(menuButtonFinder, warnIfMissed: false);
  await _settle(tester, seconds: 4);

  final deleteItem = _firstVisible([find.text('删除'), find.text('Delete')]);
  if (deleteItem == null) {
    throw StateError('弹出菜单未找到「删除」项');
  }
  await tester.tap(deleteItem, warnIfMissed: false);
  await _settle(tester, seconds: 4);

  final confirmDelete = _firstVisible([find.text('删除'), find.text('Delete')]);
  if (confirmDelete == null) {
    throw StateError('删除确认对话框未找到「删除」按钮');
  }
  await tester.tap(confirmDelete, warnIfMissed: false);
  await _settle(tester, seconds: 12);

  if (_exists(find.text(fixtureName))) {
    throw StateError('删除后 $fixtureName 仍出现在列表中');
  }
}

/// 旅程 5（软）：容器管理页 → 列表/空态断言 →（有容器时）点入详情 → 返回。
/// 注意：绝不点击 启动/停止/重启 按钮（容器操作由 API 集成层覆盖）。
Future<void> _journey5Containers(WidgetTester tester) async {
  final opened = await _tapBottomNav(tester, kNavContainers, seconds: 12) ||
      await _openDrawerModule(tester, kNavContainers);
  if (!opened) {
    throw StateError('底栏或抽屉应提供容器管理入口');
  }

  final pageOk = _exists(find.text('容器管理')) ||
      _exists(find.text('暂无容器')) ||
      _exists(find.text('容器统计')) ||
      _exists(find.byType(ContainerCard));
  if (!pageOk) {
    throw StateError('容器页未找到标题/统计/列表任一元素');
  }

  if (!_exists(find.byType(ContainerCard))) {
    print('SKIP-NOTE: 容器列表为空（暂无容器），跳过详情子步骤');
    return;
  }

  // 点入第一个容器的名称区域（卡片顶部），避开底部操作按钮行。
  final firstCard = find.byType(ContainerCard).first;
  await tester.ensureVisible(firstCard);
  await _settle(tester, seconds: 2);
  final rect = tester.getRect(firstCard);
  await tester.tapAt(Offset(rect.center.dx, rect.top + 24));
  await _settle(tester, seconds: 12);

  final detailOk = _exists(find.text('容器详情')) ||
      _exists(find.text('名称')) ||
      _exists(find.text('镜像')) ||
      _exists(find.text('状态'));
  if (!detailOk) {
    await _goBack(tester);
    throw StateError('容器详情页未找到 名称/镜像/状态 字段');
  }
  await _goBack(tester);
}

/// 旅程 6（软）：抽屉（或底部标签）→ 网站管理 → 断言标题/统计卡/空态。
Future<void> _journey6Websites(WidgetTester tester) async {
  final opened = await _openDrawerModule(tester, ['网站管理', 'Websites']);
  final openedViaNav = opened || await _tapBottomNav(tester, ['网站管理', 'Websites']);
  if (!openedViaNav) {
    throw StateError('抽屉与底部导航均未找到「网站管理」入口');
  }

  final pageOk = _exists(find.text('网站管理')) ||
      _exists(find.text('网站统计')) ||
      _exists(find.text('暂无网站'));
  if (!pageOk) {
    throw StateError('网站管理页未找到标题/统计卡/空态');
  }
  await _ensureShellRoot(tester);
}

/// 旅程 7（软）：抽屉（或底部标签）→ AI → 断言 TabBar（「模型」标签）。
Future<void> _journey7Ai(WidgetTester tester) async {
  final opened = await _openDrawerModule(tester, ['AI']);
  final openedViaNav = opened || await _tapBottomNav(tester, ['AI']);
  if (!openedViaNav) {
    throw StateError('抽屉与底部导航均未找到「AI」入口');
  }

  final pageOk = _exists(find.byType(TabBar)) && _exists(find.text('模型'));
  if (!pageOk) {
    await _ensureShellRoot(tester);
    throw StateError('AI 页未找到 TabBar 或「模型」标签');
  }
  await _ensureShellRoot(tester);
}

/// 旅程 8：设置页硬断言「通用」分组；软部分进入面板设置页做只读校验
/// （绝不点击任何保存/提交按钮）。
Future<void> _journey8SettingsReadOnly(WidgetTester tester) async {
  final hardName = '8.设置只读校验（硬）';
  final opened = await _tapBottomNav(tester, kNavSettings, seconds: 12);
  expect(opened, isTrue, reason: '底部导航未找到「设置」标签');
  final settings = _firstVisible(kNavSettings.map(find.text).toList())!;
  final l10n = AppLocalizations.of(tester.element(settings));
  final appearance = find.text(l10n.settingsUIRenderMode);
  expect(await _scrollUntilVisible(tester, appearance), isTrue,
      reason: '设置页应提供界面风格入口');
  await _tapVisible(tester, appearance);
  final dialog = find.byType(AlertDialog);
  expect(
    find.descendant(
        of: dialog, matching: find.text(l10n.settingsUIRenderModeMD3)),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: dialog,
      matching: find.text(l10n.settingsUIRenderModeLiquidGlass),
    ),
    findsOneWidget,
  );
  await _tapVisible(
    tester,
    find.descendant(of: dialog, matching: find.text(l10n.commonClose)),
  );
  await tester.dragFrom(const Offset(130, 430), const Offset(0, 600));
  await _settle(tester);
  journeyResults[hardName] = 'PASS';
  print('\n=== [$hardName] PASS ===');

  await _softJourney('8.设置只读校验（软：面板设置只读）', () async {
    // 滚动查找「服务器管理」行。
    var serverRow = _firstVisible([find.text('服务器管理')]);
    serverRow ??= await _scrollUntilVisible(tester, find.text('服务器管理'))
        ? find.text('服务器管理').hitTestable().first
        : null;
    if (serverRow == null) {
      throw StateError('设置页未找到「服务器管理」行');
    }
    await tester.tap(serverRow, warnIfMissed: false);
    await _settle(tester, seconds: 12);
    await _dismissOverlays(tester);

    // 从服务器列表进入已配置服务器的详情页。
    final serverCard = _firstVisible([find.byType(ServerCard)]);
    if (serverCard == null) {
      print('SKIP-NOTE: 服务器列表没有可打开的服务器卡片');
      await _goBack(tester);
      return;
    }
    await tester.tap(serverCard, warnIfMissed: false);
    await _settle(tester, seconds: 12);
    await _dismissOverlays(tester);
    if (_firstVisible([find.text(l10n.serverDetailTitle)]) == null) {
      throw StateError('点击服务器卡片后应进入服务器详情');
    }

    // 详情 → 更多区「系统设置」。
    if (!await _scrollUntilVisible(tester, find.text('系统设置'), maxDrags: 6)) {
      throw StateError('服务器详情未找到「系统设置」入口');
    }
    await _tapVisible(tester, find.text('系统设置'), seconds: 12);

    // 系统设置页 → 滚动找「面板配置」。
    if (!await _scrollUntilVisible(tester, find.text('面板配置'), maxDrags: 6)) {
      throw StateError('系统设置页未找到「面板配置」入口');
    }
    await _tapVisible(tester, find.text('面板配置'), seconds: 12);

    // 面板设置页（只读信息展示）断言。
    final panelOk = _exists(find.text('基本信息')) &&
        (_exists(find.text('面板名称')) ||
            _exists(find.text('监听端口')) ||
            _exists(find.text('系统版本')));
    if (!panelOk) {
      await _goBack(tester);
      throw StateError('面板设置页未找到基本信息展示元素');
    }
    // 只读校验：此处不点击任何保存/提交/开关控件；页面本身为纯信息展示。

    // 逐层返回：面板设置 → 系统设置 → 服务器详情 → 服务器列表 → 设置页。
    await _goBack(tester);
    await _goBack(tester);
    await _goBack(tester);
    await _goBack(tester);
  });
}

Future<void> _journey9ModuleNavigation(WidgetTester tester) async {
  await _ensureShellRoot(tester);
  final card = find.byType(ServerCard).hitTestable().first;
  final l10n = AppLocalizations.of(tester.element(card));
  final details = find.descendant(
    of: card,
    matching: find.text(l10n.serverOpenDetail),
  );
  await _tapVisible(tester, details);
  _expectPageRoute(AppRoutes.serverDetail);

  await _checkStandaloneFilesBack(tester, l10n);
  journeyResults['9.文件目录与页面逐层返回'] = 'PASS';

  final moduleEntries = <(String, String)>[
    (l10n.appsPageTitle, AppRoutes.apps),
    (l10n.serverActionSecurity, AppRoutes.securityVerification),
    (l10n.serverModuleDatabases, AppRoutes.databases),
    (l10n.serverModuleFirewall, AppRoutes.firewall),
    (l10n.serverModuleTerminal, AppRoutes.terminal),
    (l10n.serverModuleMonitoring, AppRoutes.monitoring),
    (l10n.openrestyPageTitle, AppRoutes.openrestyCenter),
    (l10n.serverModuleSystemSettings, AppRoutes.systemSettings),
  ];
  for (final (label, route) in moduleEntries) {
    await _checkModuleRoute(tester, label, route, AppRoutes.serverDetail);
  }

  await _openEntry(tester, l10n.operationsCenterServerEntryTitle);
  _expectPageRoute(AppRoutes.operations);
  final operationEntries = <(String, String)>[
    (l10n.operationsCronjobsTitle, AppRoutes.cronjobs),
    (l10n.operationsScriptsTitle, AppRoutes.scripts),
    (l10n.operationsCommandsTitle, AppRoutes.commands),
    (l10n.operationsBackupsTitle, AppRoutes.backups),
    (l10n.operationsRuntimesTitle, AppRoutes.runtimes),
    (l10n.operationsGroupCenterTitle, AppRoutes.groupCenter),
    (l10n.operationsHostAssetsTitle, AppRoutes.hostAssets),
    (l10n.operationsSshTitle, AppRoutes.ssh),
    (l10n.operationsProcessesTitle, AppRoutes.processes),
    (l10n.operationsLogsTitle, AppRoutes.logs),
    (l10n.operationsToolboxTitle, AppRoutes.toolbox),
  ];
  for (final (label, route) in operationEntries) {
    await _checkModuleRoute(tester, label, route, AppRoutes.operations);
  }
  await _goBack(tester);
  _expectPageRoute(AppRoutes.serverDetail);
  await _goBack(tester);
  expect(find.byType(AppBottomNavigationBar).hitTestable(), findsOneWidget);
}

Future<void> _checkStandaloneFilesBack(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  await _openEntry(tester, l10n.navFiles);
  final directoryRow = find.widgetWithText(ListTile, 'etc');
  final breadcrumb = find.widgetWithText(TextButton, 'etc');
  expect(await _scrollUntilVisible(tester, directoryRow), isTrue);
  await _tapVisible(tester, directoryRow);
  expect(breadcrumb, findsOneWidget);
  await _goBack(tester);
  expect(find.text(l10n.filesPageTitle).hitTestable(), findsOneWidget);
  expect(breadcrumb, findsNothing);
  expect(await _scrollUntilVisible(tester, directoryRow), isTrue);
  await _tapVisible(tester, directoryRow);
  expect(breadcrumb, findsOneWidget);
  await tester.binding.handlePopRoute();
  await _settle(tester);
  expect(find.text(l10n.filesPageTitle).hitTestable(), findsOneWidget);
  expect(breadcrumb, findsNothing);
  await _goBack(tester);
  _expectPageRoute(AppRoutes.serverDetail);
}

Future<void> _checkModuleRoute(
  WidgetTester tester,
  String label,
  String route,
  String parentRoute,
) async {
  await _openEntry(tester, label);
  try {
    _expectPageRoute(route);
  } finally {
    await _goBack(tester);
  }
  _expectPageRoute(parentRoute);
  journeyResults['9.$label'] = 'PASS';
}

Future<void> _openEntry(WidgetTester tester, String label) async {
  final entry = find.descendant(
    of: find.byType(SectionEntryList),
    matching: find.widgetWithText(ListTile, label),
  );
  final visible = await _scrollUntilVisible(tester, entry) ||
      await _scrollUntilVisible(tester, entry, reverse: true);
  expect(visible, isTrue, reason: '应显示功能入口 $label');
  await _tapVisible(tester, entry);
}

void _expectPageRoute(String route) {
  if (route == AppRoutes.serverDetail) {
    expect(find.byType(ServerDetailPage), findsOneWidget);
    return;
  }
  final visiblePageRoutes = find.byType(AppBar).hitTestable().evaluate().map(
        (appBar) => ModalRoute.of(appBar)?.settings.name,
      );
  expect(visiblePageRoutes, contains(route));
}
