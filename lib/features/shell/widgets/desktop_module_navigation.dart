import 'package:flutter/material.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';

class DesktopModuleNavigation extends InheritedWidget {
  const DesktopModuleNavigation({
    super.key,
    required this.onOpenModuleRoot,
    required super.child,
  });

  final ValueChanged<ClientModule> onOpenModuleRoot;

  static DesktopModuleNavigation? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DesktopModuleNavigation>();

  @override
  bool updateShouldNotify(DesktopModuleNavigation oldWidget) =>
      onOpenModuleRoot != oldWidget.onOpenModuleRoot;
}
