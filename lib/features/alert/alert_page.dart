import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/alert/providers/alert_provider.dart';
import 'package:onepanel_client/features/alert/tabs/alert_channel_tab.dart';
import 'package:onepanel_client/features/alert/tabs/alert_log_tab.dart';
import 'package:onepanel_client/features/alert/tabs/alert_rule_tab.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';

/// 告警中心：任务、日志、渠道三块。
class AlertPage extends StatefulWidget {
  const AlertPage({super.key});

  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOnce());
  }

  void _loadOnce() {
    if (_initialized || !mounted) return;
    _initialized = true;
    context.read<AlertProvider>().loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<AlertProvider>(
      builder: (context, provider, _) {
        return ServerAwarePageScaffold(
          title: l10n.alertPageTitle,
          onServerChanged: provider.onServerChanged,
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              tooltip: l10n.commonRefresh,
              onPressed: provider.isMutating ? null : provider.loadAll,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: <Widget>[
              Tab(text: l10n.alertTabRules),
              Tab(text: l10n.alertTabLogs),
              Tab(text: l10n.alertTabChannels),
            ],
          ),
          body: Column(
            children: <Widget>[
              if (provider.isMutating)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const <Widget>[
                    AlertRuleTab(),
                    AlertLogTab(),
                    AlertChannelTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
