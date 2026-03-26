import 'package:flutter/material.dart';

class CommandsPageHeaderWidget extends StatelessWidget {
  const CommandsPageHeaderWidget({
    super.key,
    required this.controller,
    required this.searchHint,
    required this.selectedGroupLabel,
    required this.allGroupsLabel,
    required this.isGroupSelected,
    required this.isImporting,
    required this.importingLabel,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onSearchTap,
    required this.onPickGroup,
  });

  final TextEditingController controller;
  final String searchHint;
  final String selectedGroupLabel;
  final String allGroupsLabel;
  final bool isGroupSelected;
  final bool isImporting;
  final String importingLabel;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchSubmitted;
  final VoidCallback onSearchTap;
  final VoidCallback onPickGroup;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextField(
          controller: controller,
          onChanged: onSearchChanged,
          onSubmitted: (_) => onSearchSubmitted(),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: searchHint,
            suffixIcon: IconButton(
              onPressed: onSearchTap,
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilterChip(
                label: Text(
                  isGroupSelected ? selectedGroupLabel : allGroupsLabel,
                ),
                selected: isGroupSelected,
                onSelected: (_) => onPickGroup(),
              ),
              if (isImporting) Chip(label: Text(importingLabel)),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
