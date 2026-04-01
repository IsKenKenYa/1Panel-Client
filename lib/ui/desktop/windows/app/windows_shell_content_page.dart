import 'package:flutter/material.dart';

import '../../common/app/desktop_shell_page.dart';

/// Flutter-side content area for Windows Fluent / WinUI native shell.
///
/// Phase 1: fallback to Flutter desktop shell until native window material and
/// command bar are wired to Flutter via platform channels.
class WindowsShellContentPage extends StatelessWidget {
  const WindowsShellContentPage({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return DesktopShellPage(initialIndex: initialIndex);
  }
}

