import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_form_args.dart';
import 'package:onepanel_client/features/runtimes/providers/runtime_form_provider.dart';
import 'package:onepanel_client/features/runtimes/utils/runtime_l10n_helper.dart';
import 'package:onepanel_client/features/runtimes/widgets/runtime_form_advanced_section_widget.dart';
import 'package:onepanel_client/features/runtimes/widgets/runtime_form_basic_section_widget.dart';
import 'package:onepanel_client/features/runtimes/widgets/runtime_form_runtime_section_widget.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:provider/provider.dart';

class RuntimeFormPage extends StatefulWidget {
  const RuntimeFormPage({
    super.key,
    this.args,
  });

  final RuntimeFormArgs? args;

  @override
  State<RuntimeFormPage> createState() => _RuntimeFormPageState();
}

class _RuntimeFormPageState extends State<RuntimeFormPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<RuntimeFormProvider>().initialize(widget.args);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<RuntimeFormProvider>(
      builder: (context, provider, _) {
        return ServerAwarePageScaffold(
          title: provider.isEditing
              ? l10n.runtimeFormEditTitle
              : l10n.runtimeFormCreateTitle,
          onServerChanged: () =>
              context.read<RuntimeFormProvider>().initialize(widget.args),
          body: AsyncStatePageBodyWidget(
            isLoading: provider.isLoading,
            errorMessage: localizeRuntimeError(l10n, provider.errorMessage),
            onRetry: () => provider.initialize(widget.args),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(
                  l10n.runtimeFormBasicSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                RuntimeFormBasicSectionWidget(
                  draft: provider.draft,
                  onChanged: provider.updateBasic,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.runtimeFormRuntimeSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                RuntimeFormRuntimeSectionWidget(
                  draft: provider.draft,
                  onChanged: provider.updateRuntimeConfig,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.runtimeFormAdvancedSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                RuntimeFormAdvancedSectionWidget(
                  draft: provider.draft,
                  onChanged: provider.updateAdvanced,
                ),
                if (!provider.isEditing &&
                    provider.draft.resource == 'appstore') ...<Widget>[
                  const SizedBox(height: 16),
                  Text(l10n.runtimeFormAppStoreCreateWeek8Hint),
                ],
                if (!provider.isEditing && provider.draft.isPhp) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(l10n.runtimeFormPhpCreateWeek8Hint),
                ],
                const SizedBox(height: 120),
              ],
            ),
          ),
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

  Future<void> _save() async {
    final success = await context.read<RuntimeFormProvider>().save();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      final message = localizeRuntimeError(
            context.l10n,
            context.read<RuntimeFormProvider>().errorMessage,
          ) ??
          context.l10n.commonSaveFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
