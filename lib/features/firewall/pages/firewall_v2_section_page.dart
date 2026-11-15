import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';

import '../providers/firewall_v2_provider.dart';
import '../widgets/firewall_v2_data_view.dart';

enum FirewallV2Section { rules, forward, docker, settings }

class FirewallV2SectionPage extends StatefulWidget {
  const FirewallV2SectionPage({super.key, required this.section});

  final FirewallV2Section section;

  @override
  State<FirewallV2SectionPage> createState() => _FirewallV2SectionPageState();
}

class _FirewallV2SectionPageState extends State<FirewallV2SectionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  void _load() {
    final provider = context.read<FirewallV2Provider>();
    switch (widget.section) {
      case FirewallV2Section.rules:
        provider.loadRuleInventory();
      case FirewallV2Section.forward:
        provider.loadForward();
      case FirewallV2Section.docker:
        provider.loadDocker();
      case FirewallV2Section.settings:
        provider.loadSettings();
    }
  }

  String _title(BuildContext context) {
    final l10n = context.l10n;
    return switch (widget.section) {
      FirewallV2Section.rules => l10n.firewallV2SystemRules,
      FirewallV2Section.forward => l10n.firewallV2Forward,
      FirewallV2Section.docker => l10n.firewallV2Docker,
      FirewallV2Section.settings => l10n.firewallV2Settings,
    };
  }

  Map<String, dynamic> _data(FirewallV2Provider provider) {
    return switch (widget.section) {
      FirewallV2Section.rules => provider.ruleInventory,
      FirewallV2Section.forward => <String, dynamic>{
          ...provider.forwardBase,
          ...provider.forwardRules,
        },
      FirewallV2Section.docker => <String, dynamic>{
          ...provider.dockerPorts,
          'endpoints': provider.dockerEndpoints,
        },
      FirewallV2Section.settings => provider.settings,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ServerAwarePageScaffold(
      title: _title(context),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: l10n.firewallV2Refresh,
          onPressed: _load,
        ),
      ],
      body: Consumer<FirewallV2Provider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return FirewallV2ErrorView(
              message: provider.error!,
              onRetry: _load,
            );
          }
          return FirewallV2DataView(data: _data(provider), onRetry: _load);
        },
      ),
    );
  }
}
