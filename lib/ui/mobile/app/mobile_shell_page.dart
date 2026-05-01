import 'package:flutter/material.dart';
import 'package:onepanel_client/features/shell/app_shell_page.dart';

import '../../routing/ui_target.dart';
import '../../tablet/app/tablet_shell_page.dart';

class MobileShellPage extends StatelessWidget {
  const MobileShellPage({
    super.key,
    this.initialIndex = 0,
    this.initialModuleId,
    this.tabletKind = TabletKind.none,
  });

  final int initialIndex;
  final String? initialModuleId;
  final TabletKind tabletKind;

  @override
  Widget build(BuildContext context) {
    if (tabletKind != TabletKind.none) {
      return TabletShellPage(
        initialIndex: initialIndex,
        initialModuleId: initialModuleId,
        tabletKind: tabletKind,
      );
    }

    return AppShellPage(
      initialIndex: initialIndex,
      initialModuleId: initialModuleId,
    );
  }
}

