import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/commands/models/command_form_args.dart';
import 'package:onepanel_client/features/commands/providers/command_form_provider.dart';
import 'package:onepanel_client/features/commands/widgets/command_preview_box_widget.dart';
import 'package:onepanel_client/features/group/widgets/group_selector_sheet_widget.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:provider/provider.dart';

class CommandFormPage extends StatefulWidget {
  const CommandFormPage({
    super.key,
    this.args,
  });

  final CommandFormArgs? args;

  @override
  State<CommandFormPage> createState() => _CommandFormPageState();
}

class _CommandFormPageState extends State<CommandFormPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _commandController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.args?.initialValue?.name ?? '');
    _commandController =
        TextEditingController(text: widget.args?.initialValue?.command ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommandFormProvider>(
      builder: (context, provider, _) {
        final l10n = context.l10n;
        return ServerAwarePageScaffold(
          title: provider.isEditing
              ? l10n.commandsEditTitle
              : l10n.commandsCreateTitle,
          onServerChanged: () => context.read<CommandFormProvider>().initialize(widget.args),
          body: AsyncStatePageBodyWidget(
            isLoading: provider.isLoading,
            errorMessage: provider.errorMessage,
            onRetry: () => provider.initialize(widget.args),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                TextField(
                  controller: _nameController,
                  onChanged: provider.updateName,
                  decoration: InputDecoration(
                    labelText: l10n.commonName,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.commandsGroupFieldLabel),
                  subtitle: Text(_groupLabel(provider)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickGroup(provider),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _commandController,
                  minLines: 6,
                  maxLines: 10,
                  onChanged: provider.updateCommand,
                  decoration: InputDecoration(
                    labelText: l10n.commandsCommandFieldLabel,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.commandsPreviewLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                CommandPreviewBoxWidget(content: provider.command),
                const SizedBox(height: 120),
              ],
            ),
          ),
          floatingActionButton: null,
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FilledButton(
              onPressed: provider.canSave ? _save : null,
              child: provider.isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.commonSave),
            ),
          ),
        );
      },
    );
  }

  String _groupLabel(CommandFormProvider provider) {
    String? name;
    for (final group in provider.groups) {
      if (group.id == provider.selectedGroupId) {
        name = group.name;
        break;
      }
    }
    return name == null || name.trim().isEmpty
        ? context.l10n.operationsGroupDefaultLabel
        : name;
  }

  Future<void> _pickGroup(CommandFormProvider provider) async {
    final groupId = await GroupSelectorSheetWidget.show(
      context,
      groupType: 'command',
      initialSelectedGroupId: provider.selectedGroupId,
    );
    if (groupId != null) {
      provider.updateGroupId(groupId);
    }
  }

  Future<void> _save() async {
    final success = await context.read<CommandFormProvider>().save();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.read<CommandFormProvider>().errorMessage ?? context.l10n.commonSaveFailed)),
    );
  }
}
