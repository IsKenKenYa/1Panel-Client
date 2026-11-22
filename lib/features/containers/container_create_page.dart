import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/features/containers/containers_provider.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_scaffold.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';

class ContainerCreatePage extends StatefulWidget {
  const ContainerCreatePage({super.key});

  @override
  State<ContainerCreatePage> createState() => _ContainerCreatePageState();
}

class _ContainerCreatePageState extends State<ContainerCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imageController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
    });

    final l10n = context.l10n;
    final provider = context.read<ContainersProvider>();
    final ok = await provider.createContainer(
      ContainerOperate(
        name: _nameController.text.trim(),
        image: _imageController.text.trim(),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
    });

    if (ok) {
      Navigator.of(context).pop(true);
      SnackBarUtils.showSuccess(context, l10n.containerOperateSuccess);
      return;
    }

    SnackBarUtils.showError(
        context,
        l10n.containerOperateFailed(
            provider.data.error ?? l10n.commonUnknownError));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormScaffold(
      title: l10n.containerCreate,
      isSaving: _submitting,
      saveLabel: l10n.containerCreate,
      onSave: _submit,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppDesignTokens.cardPadding,
          children: [
            SectionCard(
              padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
              title: l10n.containerCreateBasicSectionTitle,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.containerInfoName,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.serverFormRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _imageController,
                    decoration: InputDecoration(
                      labelText: l10n.containerInfoImage,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.serverFormRequired;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
