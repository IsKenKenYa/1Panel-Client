import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

/// 模块内页面切换时仅对内容区执行淡入和垂直位移。
class ShellFadeThroughPageRoute<T> extends PageRoute<T> {
  ShellFadeThroughPageRoute({
    required this.builder,
    this.duration = AppDesignTokens.motionNormal,
    super.settings,
  });

  /// Builder for the page content.
  final WidgetBuilder builder;

  final Duration duration;

  @override
  final bool opaque = true;

  @override
  final bool barrierDismissible = false;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Builder(builder: builder);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved =
        animation.drive(CurveTween(curve: AppDesignTokens.motionEmphasized));
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: curved.drive(
          Tween(begin: const Offset(0, 0.04), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }
}
