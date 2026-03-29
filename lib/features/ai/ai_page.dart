import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/ai/agents/widgets/ai_agents_tab_widget.dart';
import 'package:onepanel_client/features/ai/mcp_server_provider.dart';
import 'package:onepanel_client/features/ai/widgets/ai_domain_tab_widget.dart';
import 'package:onepanel_client/features/ai/widgets/ai_gpu_tab_widget.dart';
import 'package:onepanel_client/features/ai/widgets/ai_mcp_tab_widget.dart';
import 'package:onepanel_client/features/ai/widgets/ai_ollama_tab_widget.dart';
import 'package:provider/provider.dart';

import 'ai_provider.dart';

class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Consumer2<AIProvider, McpServerProvider>(
      builder: (context, provider, _, __) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.serverModuleAi),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.aiTabModels),
                Tab(text: l10n.aiTabGpu),
                Tab(text: l10n.aiTabDomain),
                Tab(text: l10n.aiTabAgents),
                Tab(text: l10n.aiTabMcp),
              ],
            ),
          ),
          body: Column(
            children: [
              if (provider.errorMessage != null)
                MaterialBanner(
                  content: Text(provider.errorMessage!),
                  actions: [
                    TextButton(
                      onPressed: provider.clearError,
                      child: Text(l10n.commonClose),
                    ),
                  ],
                ),
              if (provider.isLoading)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    AIOllamaTabWidget(),
                    AIGpuTabWidget(),
                    AIDomainTabWidget(),
                    AIAgentsTabWidget(),
                    AIMcpTabWidget(),
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
