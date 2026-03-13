import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/data/models/docker_models.dart';
import 'package:onepanelapp_app/data/models/container_models.dart';
import 'package:onepanelapp_app/features/orchestration/providers/compose_provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';

class ComposeCard extends StatelessWidget {
  final ComposeProject compose;

  const ComposeCard({super.key, required this.compose});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final provider = context.read<ComposeProvider>();

    Future<void> showUpdateDialog() async {
      final nameController = TextEditingController(text: compose.name);
      final pathController = TextEditingController(text: compose.path ?? '');
      final contentController = TextEditingController();
      final envController = TextEditingController();

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.orchestrationComposeUpdate),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.commonName,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pathController,
                  decoration: InputDecoration(
                    labelText: l10n.commonPath,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: l10n.orchestrationComposeContentLabel,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 8,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: envController,
                  decoration: InputDecoration(
                    labelText: l10n.env,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonConfirm),
            ),
          ],
        ),
      );

      if (result == true) {
        await provider.updateCompose(ContainerComposeUpdateRequest(
          name: nameController.text,
          path: pathController.text,
          content: contentController.text,
          env: envController.text.isEmpty ? null : envController.text,
        ));
      }
    }

    Future<void> showTestDialog() async {
      final nameController = TextEditingController(text: compose.name);
      final pathController = TextEditingController(text: compose.path ?? '');
      final contentController = TextEditingController();
      final envController = TextEditingController();

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.orchestrationComposeTest),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.commonName,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pathController,
                  decoration: InputDecoration(
                    labelText: l10n.commonPath,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: l10n.orchestrationComposeContentLabel,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 8,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: envController,
                  decoration: InputDecoration(
                    labelText: l10n.env,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonConfirm),
            ),
          ],
        ),
      );

      if (result == true) {
        await provider.testCompose(ContainerComposeCreate(
          from: 'edit',
          name: nameController.text,
          path: pathController.text,
          file: contentController.text,
          env: envController.text.isEmpty ? null : envController.text,
        ));
      }
    }

    Future<void> cleanLog() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.orchestrationComposeCleanLog),
          content: Text(l10n.orchestrationComposeCleanLogConfirm(compose.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonConfirm),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await provider.cleanComposeLog(ContainerComposeLogCleanRequest(
          name: compose.name,
          path: compose.path ?? '',
        ));
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        compose.name,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        compose.status ?? l10n.orchestrationStatusUnknown,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: compose.status?.toLowerCase().contains('running') == true
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (compose.createTime != null)
                  Text(
                    compose.createTime!,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (compose.services != null && compose.services!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${l10n.orchestrationServicesLabel}: ${compose.services!.join(", ")}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => provider.upCompose(compose),
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  label: Text(l10n.commonStart),
                ),
                TextButton.icon(
                  onPressed: () => provider.downCompose(compose),
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  label: Text(l10n.commonStop),
                ),
                TextButton.icon(
                  onPressed: () => provider.restartCompose(compose),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.commonRestart),
                ),
                PopupMenuButton<String>(
                  tooltip: l10n.commonMore,
                  onSelected: (value) {
                    if (value == 'update') showUpdateDialog();
                    if (value == 'test') showTestDialog();
                    if (value == 'cleanLog') cleanLog();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'update',
                      child: Text(l10n.orchestrationComposeUpdate),
                    ),
                    PopupMenuItem(
                      value: 'test',
                      child: Text(l10n.orchestrationComposeTest),
                    ),
                    PopupMenuItem(
                      value: 'cleanLog',
                      child: Text(l10n.orchestrationComposeCleanLog),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
