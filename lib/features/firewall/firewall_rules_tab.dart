import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

import '../../data/models/firewall_models.dart';

import 'firewall_rule_form_page.dart';
import 'providers/firewall_rule_list_provider.dart';
import 'widgets/firewall_tab_error.dart';

class FirewallRulesTab extends StatefulWidget {
  const FirewallRulesTab({super.key});

  @override
  State<FirewallRulesTab> createState() => _FirewallRulesTabState();
}

class _FirewallRulesTabState extends State<FirewallRulesTab> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) {
        return;
      }
      _initialized = true;
      context.read<FirewallRulesProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FirewallRulesProvider>();

    if (provider.isLoading && provider.items.isEmpty) {
      return const _LoadingBody();
    }

    if (provider.error != null && provider.items.isEmpty) {
      return FirewallTabError(
        error: provider.error!,
        onRetry: () => provider.load(),
        l10n: context.l10n,
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
                  arguments: const FirewallRuleFormArguments(
                    kind: FirewallRuleKind.port,
                  ),
                ),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.commonCreate),
              ),
            );
          }
          final rule = provider.items[index - 1];
          return AppCard(
            title: _ruleTitle(rule),
            subtitle: _ruleSubtitle(rule),
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
                  child: Text(context.l10n.commonEdit),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(context.l10n.firewallToggleStrategyAction),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(context.l10n.commonDelete),
                ),
              ],
            ),
            child: _ruleDetail(rule),
          );
        },
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    FirewallRulesProvider provider,
    FirewallRule rule,
    String action,
  ) async {
    switch (action) {
      case 'edit':
        await Navigator.pushNamed(
          context,
          AppRoutes.firewallRuleForm,
          arguments: FirewallRuleFormArguments(
            kind: (rule.port ?? '').isNotEmpty
                ? FirewallRuleKind.port
                : FirewallRuleKind.ip,
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

  String _ruleTitle(FirewallRule rule) {
    if (rule.description?.isNotEmpty == true) {
      return rule.description!;
    }
    if (rule.address?.isNotEmpty == true) {
      return rule.address!;
    }
    if (rule.destination?.isNotEmpty == true) {
      return rule.destination!;
    }
    return '${context.l10n.firewallRuleDefaultTitle} ${rule.id ?? '—'}';
  }

  Widget? _ruleSubtitle(FirewallRule rule) {
    final parts = <String>[];
    if (rule.protocol?.isNotEmpty == true) {
      parts.add(rule.protocol!);
    }
    if (rule.strategy?.isNotEmpty == true) {
      parts.add(rule.strategy!);
    }
    if (rule.port?.isNotEmpty == true) {
      parts.add('${context.l10n.firewallPortLabel} ${rule.port}');
    }
    if (parts.isEmpty) {
      return null;
    }
    return Text(parts.join(' · '));
  }

  Widget? _ruleDetail(FirewallRule rule) {
    final parts = <String>[];
    if (rule.family?.isNotEmpty == true) {
      parts.add('${context.l10n.firewallFamilyLabel}: ${rule.family}');
    }
    if (rule.srcPort?.isNotEmpty == true) {
      parts.add(
        '${context.l10n.firewallSourcePortLabel}: ${rule.srcPort}',
      );
    }
    if (rule.destPort?.isNotEmpty == true) {
      parts.add(
        '${context.l10n.firewallDestinationPortLabel}: ${rule.destPort}',
      );
    }
    if (parts.isEmpty) {
      return null;
    }
    return Text(parts.join(' · '));
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
