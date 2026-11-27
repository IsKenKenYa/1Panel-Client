import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';

Future<void> showMobilePinnedModulesCustomizerSheet(
  BuildContext context,
) async {
  final controller = context.read<PinnedModulesController>();
  final options = controller.options;
  final l10n = context.l10n;
  var primary = controller.primaryPin;
  var secondary = controller.secondaryPin;

  await showAppFormSheet<void>(
    context,
    title: l10n.shellPinnedModulesTitle,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.shellPinnedModulesDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ClientModule>(
                  initialValue: primary,
                  isExpanded: true,
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
                    if (value == null) {
                      return;
                    }
                    setModalState(() {
                      primary = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ClientModule>(
                  initialValue: secondary,
                  isExpanded: true,
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
                    if (value == null) {
                      return;
                    }
                    setModalState(() {
                      secondary = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: 8,
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
          );
        },
      );
    },
  );
}
