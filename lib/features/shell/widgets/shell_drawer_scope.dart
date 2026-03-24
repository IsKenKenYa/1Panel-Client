import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class ShellDrawerScope extends InheritedWidget {
  const ShellDrawerScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  final VoidCallback openDrawer;

  static ShellDrawerScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellDrawerScope>();
  }

  @override
  bool updateShouldNotify(covariant ShellDrawerScope oldWidget) {
    return oldWidget.openDrawer != openDrawer;
  }
}

Widget? buildShellDrawerLeading(BuildContext context, {Key? key}) {
  final scope = ShellDrawerScope.maybeOf(context);
  if (scope == null) {
    return null;
  }

  return IconButton(
    key: key,
    onPressed: scope.openDrawer,
    tooltip: context.l10n.commonMore,
    icon: const Icon(Icons.menu_rounded),
  );
}
