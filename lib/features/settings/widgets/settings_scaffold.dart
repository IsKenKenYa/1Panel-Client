import 'package:flutter/material.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';

class SettingsScaffold extends StatelessWidget {
  const SettingsScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text(title), actions: actions),
      body: AdaptiveWidthContainer(
        maxWidth: AdaptiveLayoutSpec.of(context).settingsBodyMaxWidth,
        child: body,
      ),
    );
  }
}
