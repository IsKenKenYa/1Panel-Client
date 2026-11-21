import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

class AppNavigationIcon extends StatelessWidget {
  const AppNavigationIcon({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedSwitcher(
      duration: AppDesignTokens.motionFast,
      switchInCurve: AppDesignTokens.motionEmphasized,
      switchOutCurve: AppDesignTokens.motionStandard,
      transitionBuilder: _transition,
      child: child,
    );
  }

  static Widget _transition(Widget child, Animation<double> animation) {
    return ScaleTransition(
      scale: animation,
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}
