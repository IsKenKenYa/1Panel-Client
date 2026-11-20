import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/ai/agents/widgets/ai_agents_tab_widget.dart';
import 'package:onepanel_client/features/ai/mcp_server_provider.dart';
import 'package:onepanel_client/features/ai/widgets/ai_domain_tab_widget.dart';
import 'package:onepanel_client/features/ai/widgets/ai_gpu_tab_widget.dart';
import 'package:onepanel_client/features/ai/widgets/ai_mcp_tab_widget.dart';
import 'package:onepanel_client/features/ai/widgets/ai_ollama_tab_widget.dart';
import 'package:onepanel_client/features/ai/widgets/model_downloader_tab_widget.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/partial_error_toast_listener.dart';

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
    _tabController = TabController(length: 6, vsync: this);
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
        return ServerAwarePageScaffold(
          title: l10n.serverModuleAi,
          onServerChanged: () => provider.searchOllamaModels(),
          bottom: TabBar(
            controller: _tabController,
            // 六个分页在手机宽度下无法等分，标签会被截断成 "Mode"、"Doma"，
            // 第六个「模型下载」完全不可见。
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.aiTabModels),
              Tab(text: l10n.aiTabGpu),
              Tab(text: l10n.aiTabModelDownloader),
              Tab(text: l10n.aiTabDomain),
              Tab(text: l10n.aiTabAgents),
              Tab(text: l10n.aiTabMcp),
            ],
          ),
          body: PartialErrorToastListener(
            errorMessage: provider.errorMessage,
            hasCachedData: true,
            onRetry: provider.clearError,
            child: Column(
            children: [
              if (provider.isLoading)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    AIOllamaTabWidget(),
                    AIGpuTabWidget(),
                    ModelDownloaderTabWidget(),
                    AIDomainTabWidget(),
                    AIAgentsTabWidget(),
                    AIMcpTabWidget(),
                  ],
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}
