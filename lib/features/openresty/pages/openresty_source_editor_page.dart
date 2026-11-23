import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/features/openresty/providers/openresty_provider.dart';

import '../../../core/utils/snackbar_utils.dart';
class OpenRestySourceEditorPage extends StatefulWidget {
  final String? initialContent;

  const OpenRestySourceEditorPage({super.key, this.initialContent});

  @override
  State<OpenRestySourceEditorPage> createState() =>
      _OpenRestySourceEditorPageState();
}

class _OpenRestySourceEditorPageState extends State<OpenRestySourceEditorPage> {
  late final TextEditingController _controller;
  bool _didInitFromProvider = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromProvider || widget.initialContent != null) {
      return;
    }
    _controller.text = context.read<OpenRestyProvider>().configContent;
    _didInitFromProvider = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    try {
      await context
          .read<OpenRestyProvider>()
          .updateConfigSource(_controller.text);
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, l10n.commonSaveSuccess);
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(
        context,
        ErrorMessageUtils.userFacingMessage(e),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isSaving = context.watch<OpenRestyProvider>().isSaving;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.openrestyTabConfig),
        actions: [
          IconButton(
            onPressed: isSaving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            tooltip: l10n.commonSave,
          ),
        ],
      ),
      body: Padding(
        padding: AppDesignTokens.cardPadding,
        child: Column(
          children: [
            if (isSaving) const LinearProgressIndicator(),
            if (isSaving) const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: l10n.openrestyTabConfig,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
