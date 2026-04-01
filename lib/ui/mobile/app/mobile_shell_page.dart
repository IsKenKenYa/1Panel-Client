import 'package:flutter/material.dart';
import 'package:onepanel_client/features/shell/app_shell_page.dart';

import '../../routing/ui_target.dart';

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
    // TODO: iPadOS vs Android Pad strategies will be implemented here (shell and
    // information density), while keeping domain/state layers shared.
    return AppShellPage(
      initialIndex: initialIndex,
      initialModuleId: initialModuleId,
    );
  }
}

