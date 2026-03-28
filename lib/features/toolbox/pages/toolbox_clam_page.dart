import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_clam_provider.dart';
import 'package:onepanel_client/features/toolbox/widgets/toolbox_sections_widget.dart';
import 'package:provider/provider.dart';

class ToolboxClamPage extends StatefulWidget {
  const ToolboxClamPage({super.key});

  @override
  State<ToolboxClamPage> createState() => _ToolboxClamPageState();
}

class _ToolboxClamPageState extends State<ToolboxClamPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ToolboxClamProvider>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<ToolboxClamProvider>();

    return ServerAwarePageScaffold(
      title: l10n.toolboxClamTitle,
      onServerChanged: () => context.read<ToolboxClamProvider>().load(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (provider.isLoading) const LinearProgressIndicator(),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                provider.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ToolboxSectionCardWidget(
            title: l10n.toolboxClamTasksTitle,
            child: provider.tasks.isEmpty
                ? Text(l10n.commonEmpty)
                : Column(
                    children: [
                      for (final task in provider.tasks.take(6))
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(task.name ?? '-'),
                          subtitle: Text(task.path ?? '-'),
                          trailing: Text(task.status ?? '-'),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          ToolboxSectionCardWidget(
            title: l10n.toolboxClamRecordsTitle,
            child: provider.records.isEmpty
                ? Text(l10n.commonEmpty)
                : Column(
                    children: [
                      for (final record in provider.records.take(8))
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(record.name ?? '-'),
                          subtitle: Text(record.path ?? '-'),
                          trailing: Text(record.status ?? '-'),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: provider.isLoading
                  ? null
                  : () => context.read<ToolboxClamProvider>().load(),
              icon: const Icon(Icons.refresh_outlined),
              label: Text(l10n.commonRefresh),
            ),
          ),
        ],
      ),
    );
  }
}
