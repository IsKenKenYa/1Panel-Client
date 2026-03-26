import 'package:flutter/material.dart';

class ProcessSortBarWidget extends StatelessWidget {
  const ProcessSortBarWidget({
    super.key,
    required this.currentField,
    required this.onSelected,
    required this.cpuLabel,
    required this.memoryLabel,
    required this.nameLabel,
    required this.pidLabel,
  });

  final String currentField;
  final ValueChanged<String> onSelected;
  final String cpuLabel;
  final String memoryLabel;
  final String nameLabel;
  final String pidLabel;

  @override
  Widget build(BuildContext context) {
    final items = <({String field, String label})>[
      (field: 'cpu', label: cpuLabel),
      (field: 'memory', label: memoryLabel),
      (field: 'name', label: nameLabel),
      (field: 'pid', label: pidLabel),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return ChoiceChip(
          label: Text(item.label),
          selected: currentField == item.field,
          onSelected: (_) => onSelected(item.field),
        );
      }).toList(growable: false),
    );
  }
}
