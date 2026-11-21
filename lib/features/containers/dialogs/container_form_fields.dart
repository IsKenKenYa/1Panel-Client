import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class ContainerNameField extends StatelessWidget {
  const ContainerNameField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: l10n.commonName,
        border: const OutlineInputBorder(),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? l10n.serverFormRequired : null,
    );
  }
}

class ContainerDriverField extends StatelessWidget {
  const ContainerDriverField({
    super.key,
    required this.drivers,
    required this.selected,
    required this.onChanged,
  });

  final List<String> drivers;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selected,
      decoration: InputDecoration(
        labelText: context.l10n.commonDriver,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final driver in drivers)
          DropdownMenuItem(value: driver, child: Text(driver)),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
