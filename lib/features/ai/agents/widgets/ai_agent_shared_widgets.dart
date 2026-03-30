import 'package:flutter/material.dart';

class AISection extends StatelessWidget {
  const AISection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class AIInfoChip extends StatelessWidget {
  const AIInfoChip(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}
