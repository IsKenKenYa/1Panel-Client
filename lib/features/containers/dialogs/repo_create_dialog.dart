import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/features/containers/containers_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.repo?.name ?? '');
    _urlController = TextEditingController(text: widget.repo?.downloadUrl ?? '');
    _userController = TextEditingController(text: widget.repo?.username ?? '');
    _passwordController = TextEditingController(text: widget.repo?.password ?? '');
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

    return AlertDialog(
      title: Text(isEdit ? l10n.commonEdit : l10n.commonCreate),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.commonName,
                  border: const OutlineInputBorder(),
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
                    icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final navigator = Navigator.of(context);
              final request = ContainerRepoOperate(
                id: widget.repo?.id,
                name: _nameController.text,
                downloadUrl: _urlController.text,
                username: _userController.text.isEmpty ? null : _userController.text,
                password: _passwordController.text.isEmpty ? null : _passwordController.text,
              );

              final provider = context.read<ContainersProvider>();
              final success = isEdit
                  ? await provider.updateRepo(request)
                  : await provider.createRepo(request);

              if (!context.mounted) return;
              if (success) {
                navigator.pop(true);
              }
            }
          },
          child: Text(l10n.commonConfirm),
        ),
      ],
    );
  }
}
