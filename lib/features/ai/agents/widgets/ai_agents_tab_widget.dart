import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/ai/agents/agents_provider.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/shared/widgets/operations/partial_error_toast_listener.dart';

import 'ai_agent_accounts_widget.dart';
import 'ai_agents_list_widget.dart';

class AIAgentsTabWidget extends StatefulWidget {
  const AIAgentsTabWidget({super.key});

  @override
  State<AIAgentsTabWidget> createState() => _AIAgentsTabWidgetState();
}

class _AIAgentsTabWidgetState extends State<AIAgentsTabWidget>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<AgentsProvider>().loadInitial();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Consumer<AgentsProvider>(
      builder: (context, provider, _) {
        return PartialErrorToastListener(
          errorMessage: provider.error,
          hasCachedData: true,
          onRetry: provider.clearError,
          child: Column(
          children: <Widget>[
            if (provider.isLoading)
              const LinearProgressIndicator(minHeight: 2),
            TabBar(
              controller: _tabController,
              // 次级标签：左对齐滚动，避免与页面级标签形成两条全宽标签栏。
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              tabs: <Widget>[
                Tab(text: l10n.aiAgentsSubTabAgent),
                Tab(text: l10n.aiAgentsSubTabModel),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const <Widget>[
                  AIAgentsListWidget(),
                  AIAgentAccountsWidget(),
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
