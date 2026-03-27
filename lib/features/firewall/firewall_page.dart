import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';

import 'providers/firewall_status_provider.dart';
import 'providers/firewall_rule_list_provider.dart';
import 'firewall_status_tab.dart';
import 'firewall_ip_tab.dart';
import 'firewall_port_tab.dart';
import 'firewall_rules_tab.dart';

class FirewallPage extends StatelessWidget {
  const FirewallPage({
    super.key,
    this.initialTab = 0,
  });

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final serverId = context.watch<CurrentServerController>().currentServerId;
    final tabs = [
      Tab(text: l10n.firewallTabStatus),
      Tab(text: l10n.firewallTabRules),
      Tab(text: l10n.firewallTabIps),
      Tab(text: l10n.firewallTabPorts),
    ];
    return DefaultTabController(
      length: tabs.length,
      initialIndex:
          initialTab >= 0 && initialTab < tabs.length ? initialTab : 0,
      child: ServerAwarePageScaffold(
        title: l10n.serverModuleFirewall,
        bottom: TabBar(tabs: tabs),
        body: KeyedSubtree(
          key: ValueKey('firewall:${serverId ?? 'none'}'),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => FirewallStatusProvider()),
              ChangeNotifierProvider(create: (_) => FirewallRulesProvider()),
              ChangeNotifierProvider(create: (_) => FirewallIpProvider()),
              ChangeNotifierProvider(create: (_) => FirewallPortsProvider()),
            ],
            child: const TabBarView(
              children: [
                FirewallStatusTab(),
                FirewallRulesTab(),
                FirewallIpTab(),
                FirewallPortTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
