import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/ai/agent_models.dart';
import 'package:onepanel_client/features/ai/agents/agents_provider.dart';
import 'package:provider/provider.dart';

import 'ai_agent_create_form_widget.dart';

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

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.aiAgentsCreate, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            AIAgentCreateFormWidget(
              provider: provider,
              submitting: _submitting,
              agentType: _agentType,
              accountId: _accountId,
              model: _model,
              nameController: _nameController,
              versionController: _versionController,
              portController: _portController,
              tokenController: _tokenController,
              onAgentTypeChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _agentType = value;
                  _nameController.text = value == 'copaw' ? 'CoPaw' : 'OpenClaw';
                  _portController.text = value == 'copaw' ? '8088' : '18789';
                  if (value == 'copaw') {
                    _accountId = null;
                    _model = '';
                  }
                });
              },
              onAccountChanged: (value) {
                setState(() {
                  _accountId = value;
                  final account = provider.accounts
                      .where((item) => item.id == value)
                      .cast<AgentAccountItem?>()
                      .firstOrNull;
                  _model = account?.models.firstOrNull?.id ?? '';
                });
              },
              onModelChanged: (value) {
                setState(() {
                  _model = value ?? '';
                });
              },
              nameValidator: (value) => (value ?? '').trim().isEmpty
                  ? l10n.aiAgentsNameRequired
                  : null,
              versionValidator: (value) => (value ?? '').trim().isEmpty
                  ? l10n.aiAgentsVersionRequired
                  : null,
              portValidator: (value) {
                final port = int.tryParse((value ?? '').trim());
                if (port == null || port <= 0 || port > 65535) {
                  return l10n.aiAgentsPortRequired;
                }
                return null;
              },
              accountValidator: (value) =>
                  value == null ? l10n.aiAgentsAccountRequired : null,
              modelValidator: (value) => (value ?? '').trim().isEmpty
                  ? l10n.aiAgentsModelRequired
                  : null,
            ),
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
