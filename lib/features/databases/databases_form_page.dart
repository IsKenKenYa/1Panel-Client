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
  static const _creatableScopes = <DatabaseScope>[
    DatabaseScope.mysql,
    DatabaseScope.postgresql,
    DatabaseScope.remote,
  ];

  final _formKey = GlobalKey<FormState>();
  late DatabaseScope _scope;
  final _nameController = TextEditingController();
  final _engineController = TextEditingController();
  final _addressController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _mysqlPermission = '%';
  bool _postgresqlSuperUser = true;
  DatabaseListItem? _selectedDatabaseTarget;
  String? _selectedDatabaseKey;

  @override
  void initState() {
    super.initState();
    _scope = _resolveInitialScope(widget.initialScope);
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
      create: (_) => DatabaseFormProvider()..loadDatabaseTargets(_scope),
      child: Consumer<DatabaseFormProvider>(
        builder: (context, provider, _) {
          if (_scope != DatabaseScope.remote &&
              _selectedDatabaseTarget == null &&
              provider.databaseTargets.isNotEmpty) {
            _selectedDatabaseTarget = provider.databaseTargets.first;
            _selectedDatabaseKey = _databaseItemKey(_selectedDatabaseTarget!);
            _engineController.text = _selectedDatabaseTarget!.lookupName;
          }
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.commonCreate)),
            body: Padding(
              padding: AppDesignTokens.pagePadding,
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<DatabaseScope>(
                      initialValue: _scope,
                      decoration: InputDecoration(
                          labelText: context.l10n.databaseScopeLabel),
                      items: [
                        for (final scope in _creatableScopes)
                          DropdownMenuItem(
                            value: scope,
                            child: Text(scope.value),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _scope = value;
                          _selectedDatabaseTarget = null;
                          _selectedDatabaseKey = null;
                          _engineController.clear();
                          if (value == DatabaseScope.mysql) {
                            _mysqlPermission = '%';
                          }
                          if (value == DatabaseScope.postgresql) {
                            _postgresqlSuperUser = true;
                          }
                        });
                        context
                            .read<DatabaseFormProvider>()
                            .loadDatabaseTargets(value);
                      },
                    ),
                    const SizedBox(height: AppDesignTokens.spacingMd),
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          InputDecoration(labelText: context.l10n.commonName),
                      validator: (value) => _requiredValidator(
                        value,
                        context.l10n.commonName,
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.spacingMd),
                    if (_scope == DatabaseScope.remote) ...[
                      TextFormField(
                        controller: _engineController,
                        decoration: InputDecoration(
                            labelText: context.l10n.databaseEngineLabel),
                        validator: (value) => _requiredValidator(
                          value,
                          context.l10n.databaseEngineLabel,
                        ),
                      ),
                      const SizedBox(height: AppDesignTokens.spacingMd),
                    ] else ...[
                      DropdownButtonFormField<String>(
                        key: ValueKey(
                          '${_scope.value}:${_selectedDatabaseKey ?? 'none'}:${provider.databaseTargets.length}',
                        ),
                        initialValue: _selectedDatabaseKey,
                        decoration: const InputDecoration(
                          labelText: 'Target Instance',
                        ),
                        items: [
                          for (final item in provider.databaseTargets)
                            DropdownMenuItem<String>(
                              value: _databaseItemKey(item),
                              child: Text(
                                '${item.lookupName} [${item.instanceLabel ?? item.name}]',
                              ),
                            ),
                        ],
                        onChanged: provider.isLoadingOptions
                            ? null
                            : (value) {
                                DatabaseListItem? selected;
                                for (final item in provider.databaseTargets) {
                                  if (_databaseItemKey(item) == value) {
                                    selected = item;
                                    break;
                                  }
                                }
                                setState(() {
                                  _selectedDatabaseKey = value;
                                  _selectedDatabaseTarget = selected;
                                  _engineController.text =
                                      selected?.lookupName ?? '';
                                });
                              },
                        validator: (value) {
                          if (_scope == DatabaseScope.remote) return null;
                          if (value == null) {
                            return 'Target instance is required.';
                          }
                          return null;
                        },
                      ),
                      if (provider.isLoadingOptions) ...[
                        const SizedBox(height: AppDesignTokens.spacingSm),
                        const LinearProgressIndicator(minHeight: 2),
                      ],
                      const SizedBox(height: AppDesignTokens.spacingMd),
                    ],
                    if (_scope == DatabaseScope.remote) ...[
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                            labelText: context.l10n.databaseAddressLabel),
                        validator: (value) => _requiredValidator(
                          value,
                          context.l10n.databaseAddressLabel,
                        ),
                      ),
                      const SizedBox(height: AppDesignTokens.spacingMd),
                      TextFormField(
                        controller: _portController,
                        decoration: InputDecoration(
                            labelText: context.l10n.databasePortLabel),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final required = _requiredValidator(
                            value,
                            context.l10n.databasePortLabel,
                          );
                          if (required != null) {
                            return required;
                          }
                          final port = int.tryParse(value!.trim());
                          if (port == null || port <= 0) {
                            return '${context.l10n.databasePortLabel} is invalid.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDesignTokens.spacingMd),
                    ],
                    if (_scope == DatabaseScope.mysql) ...[
                      DropdownButtonFormField<String>(
                        initialValue: _mysqlPermission,
                        decoration:
                            const InputDecoration(labelText: 'Permission'),
                        items: const [
                          DropdownMenuItem(value: '%', child: Text('%')),
                          DropdownMenuItem(
                              value: 'localhost', child: Text('localhost')),
                          DropdownMenuItem(value: 'ip', child: Text('IP')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _mysqlPermission = value;
                          });
                        },
                      ),
                      const SizedBox(height: AppDesignTokens.spacingMd),
                    ],
                    if (_scope == DatabaseScope.postgresql) ...[
                      SwitchListTile.adaptive(
                        value: _postgresqlSuperUser,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('PostgreSQL Superuser'),
                        onChanged: (value) {
                          setState(() {
                            _postgresqlSuperUser = value;
                          });
                        },
                      ),
                      const SizedBox(height: AppDesignTokens.spacingSm),
                    ],
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                          labelText: context.l10n.databaseUsernameLabel),
                      validator: (value) => _requiredValidator(
                        value,
                        context.l10n.databaseUsernameLabel,
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.spacingMd),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                          labelText: context.l10n.databasePasswordLabel),
                      obscureText: true,
                      validator: (value) => _requiredValidator(
                        value,
                        context.l10n.databasePasswordLabel,
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.spacingMd),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                          labelText: context.l10n.commonDescription),
                      maxLines: 3,
                    ),
                    if (provider.errorMessages.isNotEmpty) ...[
                      const SizedBox(height: AppDesignTokens.spacingMd),
                      Container(
                        padding:
                            const EdgeInsets.all(AppDesignTokens.spacingMd),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .errorContainer
                              .withValues(alpha: 0.45),
                          borderRadius:
                              BorderRadius.circular(AppDesignTokens.radiusMd),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.errorContainer,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.commonSaveFailed,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppDesignTokens.spacingXs),
                            for (final message in provider.errorMessages)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppDesignTokens.spacingXs,
                                ),
                                child: Text(
                                  '• $message',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                          ],
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
                              child: Text(
                                  context.l10n.databaseTestConnectionAction),
                            ),
                          ),
                        if (_scope == DatabaseScope.remote)
                          const SizedBox(width: AppDesignTokens.spacingSm),
                        Expanded(
                          child: FilledButton(
                            onPressed: provider.isSubmitting
                                ? null
                                : () async {
                                    final isValid =
                                        _formKey.currentState?.validate() ??
                                            false;
                                    if (!isValid) {
                                      return;
                                    }
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
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(context.l10n.commonSave),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
      engine: _scope == DatabaseScope.remote
          ? _engineController.text.trim()
          : (_selectedDatabaseTarget?.engine ?? _scope.value),
      source: _scope == DatabaseScope.remote
          ? 'remote'
          : (_selectedDatabaseTarget?.source ?? 'local'),
      targetDatabase: _scope == DatabaseScope.remote
          ? null
          : _selectedDatabaseTarget?.lookupName,
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
      format: _scope == DatabaseScope.mysql
          ? 'utf8mb4'
          : _scope == DatabaseScope.postgresql
              ? 'UTF8'
              : null,
      permission: _scope == DatabaseScope.mysql ? _mysqlPermission : null,
      permissionIps: null,
      superUser:
          _scope == DatabaseScope.postgresql ? _postgresqlSuperUser : null,
    );
  }

  DatabaseScope _resolveInitialScope(DatabaseScope scope) {
    if (_creatableScopes.contains(scope)) {
      return scope;
    }
    return DatabaseScope.mysql;
  }

  String? _requiredValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  String _databaseItemKey(DatabaseListItem item) {
    return '${item.id}:${item.source}:${item.lookupName}:${item.instanceLabel ?? item.name}:${item.engine}';
  }
}
