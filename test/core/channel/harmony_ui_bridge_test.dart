import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/core/channel/harmony_ui_bridge.dart';
import 'package:onepanel_client/features/containers/containers_page.dart';
import 'package:onepanel_client/features/files/files_page.dart';
import 'package:onepanel_client/features/security/app_lock_gate.dart';
import 'package:onepanel_client/features/security/app_lock_controller.dart';

void main() {
  testWidgets('切换未受保护的原生标签持续允许显示', (tester) async {
    final controller = AppLockController();
    addTearDown(controller.dispose);
    final bridge = HarmonyUIBridge(
      navigatorKey: GlobalKey<NavigatorState>(),
      refreshSettings: () async {},
      requiresUnlock: (module) => AppLockGate.requiresUnlock(controller, module),
    );
    addTearDown(bridge.dispose);
    bridge.setGateVisible(true);

    for (final module in ['files', 'containers', 'settings', 'servers']) {
      expect(bridge.setActiveModule(module), isTrue);
      expect(bridge.activeModule, module);
    }
    await tester.pump();
  });

  testWidgets('原生页面仅覆盖主根页，Flutter 功能页面返回后恢复', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    final bridge = HarmonyUIBridge(
      navigatorKey: navigator,
      refreshSettings: () async {},
      requiresUnlock: (module) => AppLockGate.requiresUnlock(null, module),
    );
    addTearDown(bridge.dispose);

    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      navigatorObservers: [bridge],
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const Scaffold(body: SizedBox()),
      ),
    ));
    expect(bridge.isAtNativeRoot, isFalse);

    navigator.currentState!.pushReplacementNamed(AppRoutes.onboarding);
    await tester.pumpAndSettle();
    expect(bridge.isAtNativeRoot, isFalse);

    navigator.currentState!.pushReplacementNamed(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(bridge.isAtNativeRoot, isTrue);

    navigator.currentState!.pushNamed(AppRoutes.serverConfig);
    await tester.pumpAndSettle();
    expect(bridge.isAtNativeRoot, isFalse);

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(bridge.isAtNativeRoot, isTrue);

    navigator.currentState!.pushNamed(AppRoutes.files);
    await tester.pumpAndSettle();
    expect(bridge.isAtNativeRoot, isFalse);

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(bridge.isAtNativeRoot, isTrue);

    unawaited(showDialog<void>(
      context: navigator.currentContext!,
      builder: (_) => const AlertDialog(content: Text('提示')),
    ));
    await tester.pumpAndSettle();
    expect(bridge.isAtNativeRoot, isFalse);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(bridge.isAtNativeRoot, isTrue);

    navigator.currentState!.pushReplacementNamed(AppRoutes.serverConfig);
    await tester.pumpAndSettle();
    expect(bridge.isAtNativeRoot, isTrue);
  });

  testWidgets('Files 和 Containers 入口使用带应用锁的独立业务页面并可返回',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    final recorder = _PushedRouteObserver();
    final bridge = HarmonyUIBridge(
      navigatorKey: navigator,
      refreshSettings: () async {},
      requiresUnlock: (module) => AppLockGate.requiresUnlock(null, module),
    );
    addTearDown(bridge.dispose);

    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      navigatorObservers: [bridge, recorder],
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const Scaffold(body: SizedBox()),
      ),
    ));
    navigator.currentState!.pushReplacementNamed(AppRoutes.home);
    await tester.pumpAndSettle();

    for (final route in [AppRoutes.files, AppRoutes.containers]) {
      const arguments = <String, dynamic>{'source': 'native'};
      bridge.openFlutterRoute(route, arguments: arguments);
      expect(bridge.isAtNativeRoot, isFalse);

      final pushed = recorder.lastPushed! as MaterialPageRoute<void>;
      expect(pushed.settings.name, route);
      expect(pushed.settings.arguments, same(arguments));
      final gate = pushed.builder(navigator.currentContext!) as AppLockGate;
      expect(gate.target, route == AppRoutes.files ? 'files' : 'containers');
      expect(gate.child,
          route == AppRoutes.files ? isA<FilesPage>() : isA<ContainersPage>());

      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(bridge.isAtNativeRoot, isTrue);
    }
  });
}

class _PushedRouteObserver extends NavigatorObserver {
  Route<dynamic>? lastPushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastPushed = route;
  }
}
