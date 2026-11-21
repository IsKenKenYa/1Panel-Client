import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/shell_fade_through_route.dart';

void main() {
  group('ShellFadeThroughPageRoute', () {
    test('uses the shared navigation duration and an opaque route', () {
      final route = ShellFadeThroughPageRoute<void>(
        builder: (_) => const SizedBox.shrink(),
      );

      expect(route.opaque, isTrue);
      expect(route.barrierDismissible, isFalse);
      expect(route.transitionDuration, AppDesignTokens.motionNormal);
      expect(route.reverseTransitionDuration, AppDesignTokens.motionNormal);
      // Opaque routes must not have a barrier.
      expect(route.barrierColor, isNull);
      expect(route.barrierLabel, isNull);
      expect(route.maintainState, isTrue);
    });

    testWidgets(
      'buildTransitions does not produce horizontal slide (Offset.x = 0)',
      (tester) async {
        final navigatorKey = GlobalKey<NavigatorState>();
        const markerKey = Key('fade-through-page');
        late ShellFadeThroughPageRoute<void> route;

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            home: const SizedBox.shrink(),
            onGenerateRoute: (settings) {
              // Capture the route the framework would build for the
              // home page so we can inspect its transitions later.
              if (settings.name == '/') {
                route = ShellFadeThroughPageRoute<void>(
                  settings: settings,
                  builder: (_) => const Scaffold(key: markerKey),
                );
                return route;
              }
              return null;
            },
          ),
        );

        // Push a separate fade-through route so we can inspect the
        // transition in mid-flight.
        navigatorKey.currentState!.push(
          ShellFadeThroughPageRoute<void>(
            builder: (_) => const Scaffold(key: markerKey),
          ),
        );
        // Run the transition to mid-frame where both fade and slide
        // are active.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // The new page must be on the route stack.
        expect(find.byKey(markerKey), findsOneWidget);

        // Find any SlideTransition and check its current offset. The
        // fade-through animation must keep the x component at zero so
        // the page does not slide in horizontally.
        final slideTransitions = find.byType(SlideTransition);
        expect(slideTransitions, findsWidgets);

        for (final element in slideTransitions.evaluate()) {
          final widget = element.widget as SlideTransition;
          final value = widget.position.value;
          expect(
            value.dx,
            equals(0.0),
            reason: 'fade-through must not slide horizontally',
          );
          // The y component is allowed to be non-zero (slide-up is part
          // of the spec), but it must stay within (-0.05, 0.05).
          expect(value.dy.abs(), lessThan(0.05));
        }

        // Let the transition complete.
        await tester.pumpAndSettle();
      },
    );

    test('honours a custom duration', () {
      final route = ShellFadeThroughPageRoute<void>(
        duration: const Duration(milliseconds: 400),
        builder: (_) => const SizedBox.shrink(),
      );

      expect(route.transitionDuration, const Duration(milliseconds: 400));
      expect(route.reverseTransitionDuration, const Duration(milliseconds: 400));
    });
  });
}
