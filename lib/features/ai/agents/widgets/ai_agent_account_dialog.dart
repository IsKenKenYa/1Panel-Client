import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/ai/agent_models.dart';
import 'package:onepanel_client/features/ai/agents/agents_provider.dart';
import 'package:provider/provider.dart';

import 'ai_agent_account_form_widget.dart';

class AIAgentAccountDialog extends StatefulWidget {
  const AIAgentAccountDialog({
    super.key,
    this.account,
  });

  final AgentAccountItem? account;

  @override
  State<AIAgentAccountDialog> createState() => _AIAgentAccountDialogState();
}

class _AIAgentAccountDialogState extends State<AIAgentAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _apiTypeController = TextEditingController(text: 'openai-completions');
  final _remarkController = TextEditingController();

  String _provider = '';
  bool _rememberApiKey = false;
  bool _syncAgents = false;
  bool _submitting = false;

  bool get _isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    if (account != null) {
      _provider = account.provider;
      _nameController.text = account.name;
      _apiKeyController.text = account.apiKey;
      _baseUrlController.text = account.baseUrl;
      _apiTypeController.text = account.apiType;
      _remarkController.text = account.remark;
      _rememberApiKey = account.rememberApiKey;
      _syncAgents = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_provider.isNotEmpty) {
      return;
    }
    final providers = context.read<AgentsProvider>().providers;
    if (providers.isNotEmpty) {
      _provider = providers.first.provider;
      _baseUrlController.text = providers.first.baseUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _apiTypeController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<AgentsProvider>();

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _isEdit ? l10n.commonEdit : l10n.commonCreate,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            AIAgentAccountFormWidget(
              provider: provider,
              uiProvider: provider,
              submitting: _submitting,
              isEdit: _isEdit,
              currentProvider: _provider,
              nameController: _nameController,
              apiKeyController: _apiKeyController,
              baseUrlController: _baseUrlController,
              apiTypeController: _apiTypeController,
              remarkController: _remarkController,
              rememberApiKey: _rememberApiKey,
              syncAgents: _syncAgents,
              onProviderChanged: (value) {
                if (value == null) {
                  return;
                }
                final providerItem = provider.providers
                    .where((item) => item.provider == value)
                    .cast<ProviderInfo?>()
                    .firstOrNull;
                setState(() {
                  _provider = value;
                  _baseUrlController.text = providerItem?.baseUrl ?? '';
                });
              },
              onRememberApiKeyChanged: (value) {
                setState(() {
                  _rememberApiKey = value ?? false;
                });
              },
              onSyncAgentsChanged: (value) {
                setState(() {
                  _syncAgents = value ?? false;
                });
              },
              providerValidator: (value) => (value ?? '').isEmpty
                  ? l10n.aiAgentsProviderRequired
                  : null,
              nameValidator: (value) => (value ?? '').trim().isEmpty
                  ? l10n.aiAgentsNameRequired
                  : null,
              apiKeyValidator: (value) => (value ?? '').trim().isEmpty
                  ? l10n.aiAgentsApiKeyRequired
                  : null,
              apiTypeValidator: (value) => (value ?? '').trim().isEmpty
                  ? l10n.aiAgentsApiTypeRequired
                  : null,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(l10n.commonCancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(_isEdit ? l10n.commonSave : l10n.commonCreate),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final provider = context.read<AgentsProvider>();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    bool success = false;
    if (_isEdit) {
      success = await provider.updateAccount(
        AgentAccountUpdateReq(
          id: widget.account!.id,
          name: _nameController.text.trim(),
          apiKey: _apiKeyController.text.trim(),
          rememberApiKey: _rememberApiKey,
          baseURL: _baseUrlController.text.trim(),
          apiType: _apiTypeController.text.trim(),
          remark: _remarkController.text.trim(),
          syncAgents: _syncAgents,
        ),
      );
    } else {
      success = await provider.createAccount(
        AgentAccountCreateReq(
          provider: _provider,
          name: _nameController.text.trim(),
          apiKey: _apiKeyController.text.trim(),
          rememberApiKey: _rememberApiKey,
          baseURL: _baseUrlController.text.trim(),
          apiType: _apiTypeController.text.trim(),
          remark: _remarkController.text.trim(),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _submitting = false;
      });
    }

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }
}
