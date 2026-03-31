import 'package:flutter/material.dart';
import 'package:onepanelapp_app/features/shell/platform/platform_adaptive_shell_page.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  @override
  Widget build(BuildContext context) {
    return PlatformAdaptiveShellPage(initialIndex: widget.initialIndex);
  }
}
