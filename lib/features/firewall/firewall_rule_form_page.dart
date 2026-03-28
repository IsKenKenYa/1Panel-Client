import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/firewall_models.dart';

import 'providers/firewall_rule_list_provider.dart';

class FirewallRuleFormArguments {
  const FirewallRuleFormArguments({
    required this.kind,
    this.rule,
  });

  final FirewallRuleKind kind;
  final FirewallRule? rule;
}

class FirewallRuleFormPage extends StatelessWidget {
  const FirewallRuleFormPage({
    super.key,
    required this.arguments,
  });

  final FirewallRuleFormArguments arguments;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FirewallRuleFormProvider(),
      child: _FirewallRuleFormView(arguments: arguments),
    );
  }
}

class _FirewallRuleFormView extends StatefulWidget {
  const _FirewallRuleFormView({required this.arguments});

  final FirewallRuleFormArguments arguments;

  @override
  State<_FirewallRuleFormView> createState() => _FirewallRuleFormViewState();
}

class _FirewallRuleFormViewState extends State<_FirewallRuleFormView> {
  late final TextEditingController _addressController;
  late final TextEditingController _portController;
  late final TextEditingController _descriptionController;
  String _protocol = 'tcp';
  String _strategy = 'accept';
  String _source = 'anyWhere';
  String? _validationError;

  bool get _isPort => widget.arguments.kind == FirewallRuleKind.port;

  @override
  void initState() {
    super.initState();
    final rule = widget.arguments.rule;
    _addressController = TextEditingController(text: rule?.address ?? '');
    _portController = TextEditingController(text: rule?.port ?? '');
    _descriptionController =
        TextEditingController(text: rule?.description ?? '');
    _protocol = rule?.protocol ?? 'tcp';
    _strategy = rule?.strategy ?? 'accept';
    _source = (rule?.address?.isNotEmpty == true) ? 'address' : 'anyWhere';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _portController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FirewallRuleFormProvider>();
    final l10n = context.l10n;
    final isEdit = widget.arguments.rule != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit
              ? l10n.commonEdit
              : (_isPort
                  ? l10n.firewallCreatePortRuleAction
                  : l10n.firewallCreateIpRuleAction),
        ),
      ),
      body: Padding(
        padding: AppDesignTokens.pagePadding,
        child: ListView(
          children: [
            if (_isPort) ...[
              DropdownButtonFormField<String>(
                initialValue: _protocol,
                decoration: InputDecoration(
                  labelText: l10n.firewallProtocolLabel,
                ),
                items: const [
                  DropdownMenuItem(value: 'tcp', child: Text('tcp')),
                  DropdownMenuItem(value: 'udp', child: Text('udp')),
                  DropdownMenuItem(value: 'tcp/udp', child: Text('tcp/udp')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _protocol = value);
                  }
                },
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              TextField(
                controller: _portController,
                decoration: InputDecoration(
                  labelText: l10n.firewallPortLabel,
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              DropdownButtonFormField<String>(
                initialValue: _source,
                decoration: InputDecoration(
                  labelText: l10n.firewallSourceLabel,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'anyWhere',
                    child: Text(l10n.firewallSourceAnywhere),
                  ),
                  DropdownMenuItem(
                    value: 'address',
                    child: Text(l10n.firewallSourceAddress),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _source = value);
                  }
                },
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
            ],
            TextField(
              controller: _addressController,
              enabled: !_isPort || _source == 'address',
              decoration: InputDecoration(
                labelText: l10n.firewallAddressLabel,
              ),
              minLines: _isPort ? 1 : 3,
              maxLines: _isPort ? 1 : 5,
            ),
            const SizedBox(height: AppDesignTokens.spacingMd),
            DropdownButtonFormField<String>(
              initialValue: _strategy,
              decoration: InputDecoration(
                labelText: l10n.firewallStrategyLabel,
              ),
              items: [
                DropdownMenuItem(
                  value: 'accept',
                  child: Text(l10n.firewallStrategyAccept),
                ),
                DropdownMenuItem(
                  value: 'drop',
                  child: Text(l10n.firewallStrategyDrop),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _strategy = value);
                }
              },
            ),
            const SizedBox(height: AppDesignTokens.spacingMd),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: l10n.commonDescription),
            ),
            if (provider.error != null) ...[
              const SizedBox(height: AppDesignTokens.spacingMd),
              Text(
                provider.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_validationError != null) ...[
              const SizedBox(height: AppDesignTokens.spacingMd),
              Text(
                _validationError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppDesignTokens.spacingLg),
            FilledButton(
              onPressed: provider.isSubmitting
                  ? null
                  : () async {
                      final validationError = _validate(l10n);
                      if (validationError != null) {
                        setState(() => _validationError = validationError);
                        return;
                      }
                      setState(() => _validationError = null);
                      final navigator = Navigator.of(context);
                      final ok = _isPort
                          ? await provider.submitPort(
                              payload: _buildPortPayload('add'),
                              oldRule:
                                  isEdit ? _buildPortPayload('remove') : null,
                            )
                          : await provider.submitIp(
                              payload: _buildIpPayload('add'),
                              oldRule:
                                  isEdit ? _buildIpPayload('remove') : null,
                            );
                      if (!mounted || !ok) return;
                      navigator.pop(true);
                    },
              child: provider.isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }

  FirewallPortRulePayload _buildPortPayload(String operation) {
    return FirewallPortRulePayload(
      operation: operation,
      address: _source == 'address' ? _addressController.text.trim() : '',
      port: _portController.text.trim(),
      source: _source,
      protocol: _protocol,
      strategy: _strategy,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );
  }

  FirewallIpRulePayload _buildIpPayload(String operation) {
    return FirewallIpRulePayload(
      operation: operation,
      address: _addressController.text.trim(),
      strategy: _strategy,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );
  }

  String? _validate(AppLocalizations l10n) {
    if (_isPort && _portController.text.trim().isEmpty) {
      return l10n.firewallPortRequired;
    }
    if ((!_isPort || _source == 'address') &&
        _addressController.text.trim().isEmpty) {
      return l10n.firewallAddressRequired;
    }
    return null;
  }
}
