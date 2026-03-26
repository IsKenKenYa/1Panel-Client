import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/firewall_models.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

import 'firewall_rule_form_page.dart';
import 'providers/firewall_rule_list_provider.dart';
import 'widgets/firewall_tab_error.dart';

class FirewallIpTab extends StatefulWidget {
  const FirewallIpTab({super.key});

  @override
  State<FirewallIpTab> createState() => _FirewallIpTabState();
}

class _FirewallIpTabState extends State<FirewallIpTab> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) {
        return;
      }
      _initialized = true;
      context.read<FirewallIpProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FirewallIpProvider>();
    final l10n = context.l10n;

    if (provider.isLoading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.items.isEmpty) {
      return FirewallTabError(
        error: provider.error!,
        onRetry: () => provider.load(),
        l10n: l10n,
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView.separated(
        padding: AppDesignTokens.pagePadding,
        itemCount: provider.items.length + 1,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppDesignTokens.spacingSm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.firewallRuleForm,
                  arguments: FirewallRuleFormArguments(
                    kind: FirewallRuleKind.ip,
                  ),
                ),
                icon: const Icon(Icons.add),
                label: Text(l10n.commonCreate),
              ),
            );
          }
          final rule = provider.items[index - 1];
          return AppCard(
            title: rule.address ?? '${l10n.firewallTabIps} ${rule.id ?? '—'}',
            subtitle: rule.strategy != null ? Text(rule.strategy!) : null,
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleAction(
                context,
                provider,
                rule,
                value,
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(l10n.commonEdit),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(l10n.firewallToggleStrategyAction),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(l10n.commonDelete),
                ),
              ],
            ),
            child: Text(rule.description ?? '-'),
          );
        },
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    FirewallIpProvider provider,
    FirewallRule rule,
    String action,
  ) async {
    switch (action) {
      case 'edit':
        await Navigator.pushNamed(
          context,
          AppRoutes.firewallRuleForm,
          arguments: FirewallRuleFormArguments(
            kind: FirewallRuleKind.ip,
            rule: rule,
          ),
        );
        if (context.mounted) {
          await provider.refresh();
        }
        break;
      case 'toggle':
        await provider.toggleStrategy(
          rule,
          (rule.strategy ?? '').toLowerCase() == 'accept' ? 'drop' : 'accept',
        );
        break;
      case 'delete':
        await provider.deleteRules([rule]);
        break;
    }
  }
}
