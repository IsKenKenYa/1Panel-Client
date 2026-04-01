import 'package:flutter/material.dart';
import 'package:onepanel_client/features/shell/app_shell_page.dart';

/// Desktop shell entry for platforms that use Flutter-managed UI (Linux/Web),
/// and as a temporary fallback for macOS/Windows until native shells fully
/// drive navigation.
class DesktopShellPage extends StatelessWidget {
  const DesktopShellPage({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    // NOTE: AppShellPage already contains responsive layouts for wide screens
    // (rail/sidebar). We reuse it initially to avoid duplicating module gating,
    // pinned modules and navigation logic. Platform-specific desktop shells will
    // progressively replace this.
    return AppShellPage(initialIndex: initialIndex);
  }
}

