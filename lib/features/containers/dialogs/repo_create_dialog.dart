import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/features/containers/containers_provider.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_panel.dart';
import 'container_form_fields.dart';

class RepoCreateDialog extends StatefulWidget {
  final ContainerRepo? repo;

  const RepoCreateDialog({super.key, this.repo});

  @override
  State<RepoCreateDialog> createState() => _RepoCreateDialogState();
}

class _RepoCreateDialogState extends State<RepoCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _userController;
  late TextEditingController _passwordController;
  bool _isObscure = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.repo?.name ?? '');
    _urlController =
        TextEditingController(text: widget.repo?.downloadUrl ?? '');
    _userController = TextEditingController(text: widget.repo?.username ?? '');
    _passwordController =
        TextEditingController(text: widget.repo?.password ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEdit = widget.repo != null;

    return AppFormPanel(
      title: isEdit ? l10n.commonEdit : l10n.commonCreate,
      isSaving: _saving,
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ContainerNameField(controller: _nameController),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: l10n.commonUrl,
                  border: const OutlineInputBorder(),
                  helperText: l10n.containerRepoUrlExample,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.serverFormRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _userController,
                decoration: InputDecoration(
                  labelText: l10n.commonUsername,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: l10n.commonPassword,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: context.l10n.commonShow,
                    icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      onConfirm: () async {
        if (!_formKey.currentState!.validate()) {
          return;
        }
        setState(() => _saving = true);
        final navigator = Navigator.of(context);
        final request = ContainerRepoOperate(
          id: widget.repo?.id,
          name: _nameController.text,
          downloadUrl: _urlController.text,
          username:
              _userController.text.isEmpty ? null : _userController.text,
          password: _passwordController.text.isEmpty
              ? null
              : _passwordController.text,
        );

        final provider = context.read<ContainersProvider>();
        final success = isEdit
            ? await provider.updateRepo(request)
            : await provider.createRepo(request);

        if (!context.mounted) return;
        if (success) {
          navigator.pop(true);
        } else {
          setState(() => _saving = false);
        }
      },
    );
  }
}
