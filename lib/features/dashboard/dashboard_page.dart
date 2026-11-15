import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import '../../core/i18n/l10n_x.dart';
import 'widgets/widgets.dart';
import 'dashboard_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DashboardProvider>();
      provider.loadData();
      // 默认启用自动刷新
      provider.toggleAutoRefresh(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        actions: [
          // 自动刷新设置
          PopupMenuButton<Duration>(
            icon: const Icon(Icons.timer),
            tooltip: l10n.dashboardRefreshInterval,
            onSelected: (duration) {
              context.read<DashboardProvider>().setRefreshInterval(duration);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: Duration(seconds: 3),
                child: Text(l10n.dashboardInterval3s),
              ),
              PopupMenuItem(
                value: Duration(seconds: 5),
                child: Text(l10n.dashboardInterval5s),
              ),
              PopupMenuItem(
                value: Duration(seconds: 10),
                child: Text(l10n.dashboardInterval10s),
              ),
              PopupMenuItem(
                value: Duration(seconds: 30),
                child: Text(l10n.dashboardInterval30s),
              ),
              PopupMenuItem(
                value: Duration(minutes: 1),
                child: Text(l10n.dashboardInterval1m),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.commonRefresh,
            onPressed: () => context.read<DashboardProvider>().refresh(),
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          switch (provider.status) {
            case DashboardStatus.initial:
            case DashboardStatus.loading:
              return const DashboardLoadingView();

            case DashboardStatus.error:
              return DashboardErrorView(
                error: provider.errorMessage,
                onRetry: () => provider.loadData(),
              );

            case DashboardStatus.loaded:
              return _buildContent(context, provider);
          }
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, DashboardProvider provider) {
    final spec = AdaptiveLayoutSpec.of(context);
    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: spec.pagePadding,
        child: AdaptiveWidthContainer(
          maxWidth: spec.dashboardMaxWidth,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (spec.isDesktop || spec.isTablet) {
                return _buildTabletLayout(provider,
                    compact: constraints.maxWidth < 900);
              }
              return _buildMobileLayout(provider);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(DashboardProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HealthOverviewGrid(data: provider.data),
        const SizedBox(height: 16),
        ServerInfoCard(data: provider.data),
        const SizedBox(height: 16),
        TopProcessesCard(
          cpuProcesses: provider.data.topCpuProcesses,
          memoryProcesses: provider.data.topMemoryProcesses,
          isLoading: provider.isLoadingTopProcesses,
          onRefresh: () => provider.loadTopProcesses(),
        ),
        const SizedBox(height: 16),
        const QuickActionsCard(),
        const SizedBox(height: 16),
        ActivityCard(activities: provider.activities),
      ],
    );
  }

  Widget _buildTabletLayout(DashboardProvider provider,
      {required bool compact}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: compact ? 5 : 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HealthOverviewGrid(data: provider.data),
              const SizedBox(height: 16),
              ServerInfoCard(data: provider.data),
              const SizedBox(height: 16),
              TopProcessesCard(
                cpuProcesses: provider.data.topCpuProcesses,
                memoryProcesses: provider.data.topMemoryProcesses,
                isLoading: provider.isLoadingTopProcesses,
                onRefresh: () => provider.loadTopProcesses(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: compact ? 3 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const QuickActionsCard(),
              const SizedBox(height: 16),
              ActivityCard(activities: provider.activities),
            ],
          ),
        ),
      ],
    );
  }
}
