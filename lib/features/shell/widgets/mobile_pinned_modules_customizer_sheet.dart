import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanelapp_app/features/shell/models/client_module.dart';

Future<void> showMobilePinnedModulesCustomizerSheet(
    BuildContext context) async {
  final controller = context.read<PinnedModulesController>();
  final options = controller.options;
  final l10n = context.l10n;
  var primary = controller.primaryPin;
  var secondary = controller.secondaryPin;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.shellPinnedModulesTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.shellPinnedModulesDescription,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ClientModule>(
                    initialValue: primary,
                    decoration: InputDecoration(
                      labelText: l10n.shellPinnedModulesPrimary,
                    ),
                    items: [
                      for (final module in options)
                        DropdownMenuItem(
                          value: module,
                          child: Text(module.label(l10n)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() {
                        primary = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ClientModule>(
                    initialValue: secondary,
                    decoration: InputDecoration(
                      labelText: l10n.shellPinnedModulesSecondary,
                    ),
                    items: [
                      for (final module in options)
                        DropdownMenuItem(
                          value: module,
                          child: Text(module.label(l10n)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() {
                        secondary = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await controller.reset();
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: Text(l10n.commonReset),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: primary == secondary
                            ? null
                            : () async {
                                await controller.setPin(0, primary);
                                await controller.setPin(1, secondary);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                        child: Text(l10n.commonSave),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
