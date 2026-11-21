import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/shared/widgets/operations/page_visibility_listener.dart';

void main() {
  testWidgets('模块、路由和应用可见性共同控制页面刷新', (tester) async {
    final events = <bool>[];
    final enabled = ValueNotifier(true);
    addTearDown(enabled.dispose);
    final navigator = GlobalKey<NavigatorState>();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      home: ValueListenableBuilder<bool>(
        valueListenable: enabled,
        builder: (_, visible, child) =>
            TickerMode(enabled: visible, child: child!),
        child: PageVisibilityListener(
            onChanged: events.add, child: const SizedBox()),
      ),
    ));
    expect(events, [true]);
    enabled.value = false;
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(events, [true, false]);
    enabled.value = true;
    await tester.pump();
    navigator.currentState!.push<void>(
      MaterialPageRoute(builder: (_) => const SizedBox()),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox());
    expect(events, [true, false, true, false, true, false, true, false]);
  });
}
