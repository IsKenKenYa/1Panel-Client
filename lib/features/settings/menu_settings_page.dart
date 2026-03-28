import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/settings/menu_settings_provider.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:provider/provider.dart';

class MenuSettingsPage extends StatefulWidget {
  const MenuSettingsPage({super.key});

  @override
  State<MenuSettingsPage> createState() => _MenuSettingsPageState();
}

class _MenuSettingsPageState extends State<MenuSettingsPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MenuSettingsProvider>().load();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<MenuSettingsProvider>();
    return ServerAwarePageScaffold(
      title: l10n.menuSettingsTitle,
      actions: <Widget>[
        IconButton(
          onPressed: provider.isLoading ? null : provider.load,
          icon: const Icon(Icons.refresh),
          tooltip: l10n.commonRefresh,
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.menuSettingsDescription),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: l10n.menuSettingsAddLabel,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () {
                  context
                      .read<MenuSettingsProvider>()
                      .addMenu(_controller.text);
                  _controller.clear();
                },
                icon: const Icon(Icons.add),
              ),
            ),
            onSubmitted: (String value) {
              context.read<MenuSettingsProvider>().addMenu(value);
              _controller.clear();
            },
          ),
          const SizedBox(height: 12),
          if (provider.isLoading) const LinearProgressIndicator(),
          if (provider.error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              provider.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 8),
          if (provider.menus.isEmpty && !provider.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text(l10n.commonEmpty)),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.menus.length,
              onReorder: context.read<MenuSettingsProvider>().reorderMenu,
              itemBuilder: (BuildContext context, int index) {
                final item = provider.menus[index];
                return ListTile(
                  key: ValueKey<String>('menu:$item:$index'),
                  title: Text(item),
                  leading: const Icon(Icons.drag_handle),
                  trailing: Wrap(
                    spacing: 4,
                    children: <Widget>[
                      IconButton(
                        onPressed: () => _showEditDialog(context, index, item),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: l10n.commonEdit,
                      ),
                      IconButton(
                        onPressed: () => context
                            .read<MenuSettingsProvider>()
                            .deleteMenu(index),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: l10n.commonDelete,
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: provider.isSaving
                ? null
                : () async {
                    final menuProvider = context.read<MenuSettingsProvider>();
                    final messenger = ScaffoldMessenger.of(context);
                    final success = await menuProvider.save();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? l10n.menuSettingsSaveSuccess
                              : (menuProvider.error ?? l10n.commonSaveFailed),
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    int index,
    String initialValue,
  ) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: initialValue);
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.menuSettingsEditTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.menuSettingsAddLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              context
                  .read<MenuSettingsProvider>()
                  .updateMenu(index, controller.text);
              Navigator.of(dialogContext).pop();
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }
}
