import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_scaffold.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';

import '../providers/website_template_provider.dart';

class WebsiteTemplateOutputCreatePage extends StatefulWidget {
  const WebsiteTemplateOutputCreatePage({super.key, required this.templateId});

  final int templateId;

  @override
  State<WebsiteTemplateOutputCreatePage> createState() =>
      _WebsiteTemplateOutputCreatePageState();
}

class _WebsiteTemplateOutputCreatePageState
    extends State<WebsiteTemplateOutputCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _variablesController = TextEditingController();
  String _preview = '';

  @override
  void dispose() {
    _nameController.dispose();
    _variablesController.dispose();
    super.dispose();
  }

  Map<String, String> _parseVariables() {
    final result = <String, String>{};
    for (final line in _variablesController.text.split('\n')) {
      final index = line.indexOf('=');
      if (index <= 0) continue;
      result[line.substring(0, index).trim()] =
          line.substring(index + 1).trim();
    }
    return result;
  }

  Future<void> _loadPreview() async {
    final provider = context.read<WebsiteTemplateProvider>();
    try {
      final html = await provider.preview(
        templateID: widget.templateId,
        variableValues: _parseVariables(),
      );
      if (mounted) setState(() => _preview = html);
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, e.toString());
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final provider = context.read<WebsiteTemplateProvider>();
    final ok = await provider.createOutput(
      name: _nameController.text.trim(),
      templateID: widget.templateId,
      variableValues: _parseVariables(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      SnackBarUtils.showSuccess(context, l10n.websitesTemplateGenerate);
    } else {
      SnackBarUtils.showError(
        context,
        provider.operationError ?? l10n.websitesTemplateLoadFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<WebsiteTemplateProvider>();
    return AppFormScaffold(
      title: l10n.websitesTemplateGenerate,
      isSaving: provider.isSaving,
      onSave: _save,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SectionCard(
                  title: l10n.websitesTemplateOutputsTitle,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: l10n.websitesTemplateOutputName,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? l10n.websitesTemplateRequired
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _variablesController,
                          decoration: InputDecoration(
                            labelText: l10n.websitesTemplateVariables,
                            hintText: 'port=8080',
                            border: const OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 5,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _loadPreview,
                          icon: const Icon(Icons.visibility_outlined),
                          label: Text(l10n.websitesTemplatePreview),
                        ),
                        if (_preview.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SelectableText(
                            _preview,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
