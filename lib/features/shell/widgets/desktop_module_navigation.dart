import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class DesktopModuleShortcuts extends StatelessWidget {
  const DesktopModuleShortcuts({
    super.key,
    required this.modifier,
    required this.modules,
    required this.onSelect,
    required this.child,
  });

  final LogicalKeyboardKey modifier;
  final List<ClientModule> modules;
  final ValueChanged<ClientModule> onSelect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        for (var index = 0; index < modules.length && index < 9; index++)
          LogicalKeySet(
            modifier,
            LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + index),
          ): () => onSelect(modules[index]),
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
