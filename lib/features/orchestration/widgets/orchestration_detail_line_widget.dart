import 'package:flutter/material.dart';

class OrchestrationDetailLineWidget extends StatelessWidget {
  const OrchestrationDetailLineWidget({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 120,
  });

  final String label;
  final String? value;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              (value == null || value!.isEmpty) ? '-' : value!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
