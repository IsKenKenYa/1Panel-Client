import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/database_models.dart';

import 'databases_provider.dart';

class DatabaseFormPage extends StatefulWidget {
  const DatabaseFormPage({
    super.key,
    this.initialScope = DatabaseScope.mysql,
  });

  final DatabaseScope initialScope;

  @override
  State<DatabaseFormPage> createState() => _DatabaseFormPageState();
}

class _DatabaseFormPageState extends State<DatabaseFormPage> {
  late DatabaseScope _scope;
  final _nameController = TextEditingController();
  final _engineController = TextEditingController();
  final _addressController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scope = widget.initialScope;
    _engineController.text = _scope.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _engineController.dispose();
    _addressController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DatabaseFormProvider(),
      child: Consumer<DatabaseFormProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.commonCreate)),
            body: Padding(
              padding: AppDesignTokens.pagePadding,
              child: ListView(
                children: [
                  DropdownButtonFormField<DatabaseScope>(
                    initialValue: _scope,
                    decoration: InputDecoration(
                        labelText: context.l10n.databaseScopeLabel),
                    items: [
                      for (final scope in DatabaseScope.values)
                        DropdownMenuItem(
                          value: scope,
                          child: Text(scope.value),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _scope = value;
                        _engineController.text = value.value;
                      });
                    },
                  ),
                  const SizedBox(height: AppDesignTokens.spacingMd),
                  TextField(
                    controller: _nameController,
                    decoration:
                        InputDecoration(labelText: context.l10n.commonName),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingMd),
                  TextField(
                    controller: _engineController,
                    decoration: InputDecoration(
                        labelText: context.l10n.databaseEngineLabel),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingMd),
                  if (_scope == DatabaseScope.remote) ...[
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                          labelText: context.l10n.databaseAddressLabel),
                    ),
                    const SizedBox(height: AppDesignTokens.spacingMd),
                    TextField(
                      controller: _portController,
                      decoration: InputDecoration(
                          labelText: context.l10n.databasePortLabel),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppDesignTokens.spacingMd),
                  ],
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                        labelText: context.l10n.databaseUsernameLabel),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingMd),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                        labelText: context.l10n.databasePasswordLabel),
                    obscureText: true,
                  ),
                  const SizedBox(height: AppDesignTokens.spacingMd),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                        labelText: context.l10n.commonDescription),
                    maxLines: 3,
                  ),
                  if (provider.error != null) ...[
                    const SizedBox(height: AppDesignTokens.spacingMd),
                    Text(
                      provider.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDesignTokens.spacingLg),
                  Row(
                    children: [
                      if (_scope == DatabaseScope.remote)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: provider.isSubmitting
                                ? null
                                : () => provider.testRemote(_buildInput()),
                            child:
                                Text(context.l10n.databaseTestConnectionAction),
                          ),
                        ),
                      if (_scope == DatabaseScope.remote)
                        const SizedBox(width: AppDesignTokens.spacingSm),
                      Expanded(
                        child: FilledButton(
                          onPressed: provider.isSubmitting
                              ? null
                              : () async {
                                  final navigator = Navigator.of(context);
                                  final ok =
                                      await provider.submit(_buildInput());
                                  if (!mounted || !ok) return;
                                  navigator.pop(true);
                                },
                          child: provider.isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(context.l10n.commonSave),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  DatabaseFormInput _buildInput() {
    return DatabaseFormInput(
      scope: _scope,
      name: _nameController.text.trim(),
      engine: _engineController.text.trim(),
      source: _scope == DatabaseScope.remote ? 'remote' : 'local',
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      port: int.tryParse(_portController.text.trim()),
      username: _usernameController.text.trim().isEmpty
          ? null
          : _usernameController.text.trim(),
      password: _passwordController.text.trim().isEmpty
          ? null
          : _passwordController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );
  }
}
