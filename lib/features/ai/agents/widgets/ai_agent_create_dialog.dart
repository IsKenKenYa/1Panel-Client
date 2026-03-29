import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/ai/agent_models.dart';
import 'package:onepanel_client/features/ai/agents/agents_provider.dart';
import 'package:provider/provider.dart';

class AIAgentCreateDialog extends StatefulWidget {
  const AIAgentCreateDialog({super.key});

  @override
  State<AIAgentCreateDialog> createState() => _AIAgentCreateDialogState();
}

class _AIAgentCreateDialogState extends State<AIAgentCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'OpenClaw');
  final _versionController = TextEditingController(text: 'latest');
  final _portController = TextEditingController(text: '18789');
  final _tokenController = TextEditingController();

  String _agentType = 'openclaw';
  int? _accountId;
  String _model = '';
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _versionController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<AgentsProvider>();
    final selectedAccount = provider.accounts
        .where((item) => item.id == _accountId)
        .cast<AgentAccountItem?>()
        .firstOrNull;
    final models = selectedAccount?.models ?? const <AgentAccountModel>[];

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.aiAgentsCreate, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.commonName,
                border: const OutlineInputBorder(),
              ),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? l10n.aiAgentsNameRequired
                  : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _agentType,
              decoration: InputDecoration(
                labelText: l10n.aiAgentsAgentType,
                border: const OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem(
                  value: 'openclaw',
                  child: Text(l10n.aiAgentsOpenclaw),
                ),
                DropdownMenuItem(
                  value: 'copaw',
                  child: Text(l10n.aiAgentsCopaw),
                ),
              ],
              onChanged: _submitting
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _agentType = value;
                        _nameController.text =
                            value == 'copaw' ? 'CoPaw' : 'OpenClaw';
                        _portController.text = value == 'copaw' ? '8088' : '18789';
                        if (value == 'copaw') {
                          _accountId = null;
                          _model = '';
                        }
                      });
                    },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _versionController,
              decoration: InputDecoration(
                labelText: l10n.aiAgentsAppVersion,
                border: const OutlineInputBorder(),
              ),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? l10n.aiAgentsVersionRequired
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _portController,
              decoration: InputDecoration(
                labelText: l10n.aiAgentsWebUiPort,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final port = int.tryParse((value ?? '').trim());
                if (port == null || port <= 0 || port > 65535) {
                  return l10n.aiAgentsPortRequired;
                }
                return null;
              },
            ),
            if (_agentType == 'openclaw') ...<Widget>[
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _accountId,
                decoration: InputDecoration(
                  labelText: l10n.aiAgentsAccount,
                  border: const OutlineInputBorder(),
                ),
                items: provider.accounts
                    .map(
                      (item) => DropdownMenuItem<int>(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (value) {
                        setState(() {
                          _accountId = value;
                          final account = provider.accounts
                              .where((item) => item.id == value)
                              .cast<AgentAccountItem?>()
                              .firstOrNull;
                          _model = account?.models.firstOrNull?.id ?? '';
                        });
                      },
                validator: (value) => value == null
                    ? l10n.aiAgentsAccountRequired
                    : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _model.isEmpty ? null : _model,
                decoration: InputDecoration(
                  labelText: l10n.aiAgentsModel,
                  border: const OutlineInputBorder(),
                ),
                items: models
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (value) {
                        setState(() {
                          _model = value ?? '';
                        });
                      },
                validator: (value) => (value ?? '').trim().isEmpty
                    ? l10n.aiAgentsModelRequired
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: l10n.aiAgentsTokenOptional,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 12),
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
                  child: Text(l10n.commonCreate),
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

    final success = await provider.createAgentSimple(
      name: _nameController.text.trim(),
      appVersion: _versionController.text.trim(),
      webUIPort: int.parse(_portController.text.trim()),
      agentType: _agentType,
      accountId: _agentType == 'openclaw' ? _accountId : null,
      model: _agentType == 'openclaw' ? _model : null,
      token: _tokenController.text.trim().isEmpty
          ? null
          : _tokenController.text.trim(),
    );

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

extension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) {
      return null;
    }
    return first;
  }
}
