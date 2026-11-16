import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

import 'providers/firewall_status_provider.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/partial_error_toast_listener.dart';

class FirewallStatusTab extends StatefulWidget {
  const FirewallStatusTab({super.key});

  @override
  State<FirewallStatusTab> createState() => _FirewallStatusTabState();
}

class _FirewallStatusTabState extends State<FirewallStatusTab> {
  bool _initialized = false;

  String _pingStatusLabel(BuildContext context, String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value == 'disable' || value == 'disabled') {
      return context.l10n.firewallPingDisabled;
    }
    if (value == 'enable' || value == 'enabled') {
      return context.l10n.firewallPingEnabled;
    }
    return (raw ?? '').trim().isEmpty ? '-' : raw!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) {
        return;
      }
      _initialized = true;
      context.read<FirewallStatusProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<FirewallStatusProvider>();
    final status = provider.status;

    if (provider.loading && status == null) {
      return const _LoadingBody();
    }

    if (provider.error != null && status == null) {
      return ModuleErrorStateWidget(
        message: provider.error,
        onRetry: () => provider.load(),
      );
    }

    return PartialErrorToastListener(
      errorMessage: provider.error,
      hasCachedData: status != null,
      onRetry: () => provider.load(),
      child: RefreshIndicator(
        onRefresh: () => provider.load(),
        child: ListView(
          padding: AppDesignTokens.scrollPagePadding(context),
          children: [
            AppCard(
              title: l10n.serverModuleFirewall,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusRow(
                    label: l10n.firewallNameLabel,
                    value: status?.name ?? '-',
                  ),
                  _StatusRow(
                    label: l10n.firewallVersionLabel,
                    value: status?.version ?? '-',
                  ),
                  _StatusRow(
                    label: l10n.firewallPingLabel,
                    value: _pingStatusLabel(context, status?.pingStatus),
                  ),
                  _StatusRow(
                    label: l10n.firewallActiveLabel,
                    value: status?.isActive == true
                        ? l10n.commonYes
                        : l10n.commonNo,
                  ),
                  _StatusRow(
                    label: l10n.firewallInitLabel,
                    value:
                        status?.isInit == true ? l10n.commonYes : l10n.commonNo,
                  ),
                  _StatusRow(
                    label: l10n.firewallBoundLabel,
                    value:
                        status?.isBind == true ? l10n.commonYes : l10n.commonNo,
                  ),
                  const SizedBox(height: AppDesignTokens.spacingMd),
                  _OperationButtons(provider: provider, l10n: l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesignTokens.spacingXs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _OperationButtons extends StatelessWidget {
  const _OperationButtons({
    required this.provider,
    required this.l10n,
  });

  final FirewallStatusProvider provider;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final status = provider.status;
    final isActive = status?.isActive ?? false;
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: !isActive && !provider.busy
                ? () => _confirmAndOperate(context, operation: 'start')
                : null,
            child: Text(l10n.commonStart),
          ),
        ),
        const SizedBox(width: AppDesignTokens.spacingSm),
        Expanded(
          child: OutlinedButton(
            onPressed: isActive && !provider.busy
                ? () => _confirmAndOperate(context, operation: 'stop')
                : null,
            child: Text(l10n.commonStop),
          ),
        ),
        const SizedBox(width: AppDesignTokens.spacingSm),
        Expanded(
          child: OutlinedButton(
            onPressed: provider.busy
                ? null
                : () => _confirmAndOperate(context, operation: 'restart'),
            child: Text(l10n.commonRestart),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndOperate(
    BuildContext context, {
    required String operation,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.firewallOperationConfirmTitle),
        content: Text(_messageFor(context, operation)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await provider.operate(operation: operation);
    }
  }

  String _messageFor(BuildContext context, String operation) {
    switch (operation) {
      case 'start':
        return context.l10n.firewallStartConfirmMessage;
      case 'stop':
        return context.l10n.firewallStopConfirmMessage;
      case 'restart':
      default:
        return context.l10n.firewallRestartConfirmMessage;
    }
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
