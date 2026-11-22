import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_scaffold.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';

import '../providers/website_template_provider.dart';

class WebsiteTemplateFormPage extends StatefulWidget {
  const WebsiteTemplateFormPage({super.key, this.templateId});

  final int? templateId;

  @override
  State<WebsiteTemplateFormPage> createState() =>
      _WebsiteTemplateFormPageState();
}

class _WebsiteTemplateFormPageState extends State<WebsiteTemplateFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  final _remarkController = TextEditingController();
  final _variablesController = TextEditingController();
  String _type = 'single';
  bool _loadingDetail = false;

  @override
  void initState() {
    super.initState();
    final id = widget.templateId;
    if (id != null) {
      _loadingDetail = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final provider = context.read<WebsiteTemplateProvider>();
        provider.clearEditing();
        final detail = await provider.loadTemplate(id);
        if (!mounted || detail == null) return;
        _nameController.text = detail.name;
        _contentController.text = detail.content;
        _remarkController.text = detail.remark;
        _variablesController.text = detail.variables;
        setState(() {
          _type = detail.type;
          _loadingDetail = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    _remarkController.dispose();
    _variablesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final provider = context.read<WebsiteTemplateProvider>();
    final ok = await provider.saveTemplate(
      name: _nameController.text.trim(),
      type: _type,
      content: _contentController.text,
      remark: _remarkController.text,
      variables: _variablesController.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      SnackBarUtils.showSuccess(context, l10n.commonSave);
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
      title: widget.templateId == null
          ? l10n.websitesTemplateCreate
          : l10n.websitesTemplateEdit,
      isSaving: provider.isSaving || _loadingDetail,
      onSave: _save,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppDesignTokens.cardPadding,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SectionCard(
                  title: l10n.websitesTemplateTitle,
                  child: Padding(
                    padding: AppDesignTokens.cardPadding,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: l10n.websitesTemplateName,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? l10n.websitesTemplateRequired
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _type,
                          decoration: InputDecoration(
                            labelText: l10n.websitesTemplateType,
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'single',
                              child: Text(l10n.websitesTemplateTypeSingle),
                            ),
                            DropdownMenuItem(
                              value: 'multi',
                              child: Text(l10n.websitesTemplateTypeMulti),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _type = value ?? 'single'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contentController,
                          decoration: InputDecoration(
                            labelText: l10n.websitesTemplateContent,
                            border: const OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 8,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _variablesController,
                          decoration: InputDecoration(
                            labelText: l10n.websitesTemplateVariables,
                            border: const OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _remarkController,
                          decoration: InputDecoration(
                            labelText: l10n.websitesTemplateRemark,
                            border: const OutlineInputBorder(),
                          ),
                        ),
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
