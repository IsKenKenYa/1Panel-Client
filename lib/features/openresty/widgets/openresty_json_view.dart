import 'package:flutter/material.dart';

class OpenRestyJsonView extends StatelessWidget {
  final String text;
  final String? emptyText;

  const OpenRestyJsonView({
    super.key,
    required this.text,
    this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final content = text.trim().isEmpty ? (emptyText ?? '-') : text;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: SelectableText(content),
      ),
    );
  }
}
