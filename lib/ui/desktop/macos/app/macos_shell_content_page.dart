import 'package:flutter/material.dart';

import '../../common/app/desktop_shell_page.dart';

/// Flutter-side content area for macOS native shell.
///
/// Phase 1: fallback to Flutter desktop shell until the native glass shell
/// drives navigation via MethodChannel.
class MacosShellContentPage extends StatelessWidget {
  const MacosShellContentPage({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return DesktopShellPage(initialIndex: initialIndex);
  }
}

