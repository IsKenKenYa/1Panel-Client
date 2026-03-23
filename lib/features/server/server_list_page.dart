import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/core/services/onboarding_service.dart';
import 'package:onepanelapp_app/core/theme/app_design_tokens.dart';
import 'package:onepanelapp_app/features/onboarding/coach_mark_overlay.dart';
import 'package:onepanelapp_app/features/server/server_detail_page.dart';
import 'package:onepanelapp_app/features/server/server_form_page.dart';
import 'package:onepanelapp_app/features/server/server_models.dart';
import 'package:onepanelapp_app/features/server/server_provider.dart';
import 'package:onepanelapp_app/features/shell/controllers/current_server_controller.dart';

class ServerListPage extends StatefulWidget {
  const ServerListPage({
    super.key,
    this.enableCoach = true,
  });

  final bool enableCoach;

  @override
  State<ServerListPage> createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  final TextEditingController _searchController = TextEditingController();
  final OnboardingService _onboardingService = OnboardingService();
  late final ServerProvider _serverProvider;

  final GlobalKey _addKey = GlobalKey();
  final GlobalKey _firstCardKey = GlobalKey();
  List<CoachMarkStep> _coachSteps = const [];

  @override
  void initState() {
    super.initState();
    _serverProvider = context.read<ServerProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _serverProvider.load().then((_) {
        if (_serverProvider.servers.isNotEmpty) {
          _serverProvider.loadMetrics();
        }
      });
    });
    _serverProvider.addListener(_onProviderUpdated);
  }

  @override
  void dispose() {
    _serverProvider.removeListener(_onProviderUpdated);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onProviderUpdated() async {
    if (!widget.enableCoach || _serverProvider.servers.isEmpty) {
      return;
    }

    if (_coachSteps.isNotEmpty) {
      return;
    }

    final showAdd = await _onboardingService
        .shouldShowCoach(OnboardingService.coachServerAddKey);
    final showCard = await _onboardingService
        .shouldShowCoach(OnboardingService.coachServerCardKey);
    if (!mounted || (!showAdd && !showCard)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final l10n = context.l10n;
      final steps = <CoachMarkStep>[];
      if (showAdd) {
        steps.add(
          CoachMarkStep(
            targetKey: _addKey,
            title: l10n.coachServerAddTitle,
            description: l10n.coachServerAddDesc,
          ),
        );
      }
      if (showCard) {
        steps.add(
          CoachMarkStep(
            targetKey: _firstCardKey,
            title: l10n.coachServerCardTitle,
            description: l10n.coachServerCardDesc,
          ),
        );
      }

      setState(() {
        _coachSteps = steps;
      });
    });
  }

  Future<void> _openAddServer() async {
    final serverProvider = context.read<ServerProvider>();
    final currentServer = context.read<CurrentServerController>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ServerFormPage()),
    );

    if (result == true) {
      await serverProvider.load();
      if (mounted) {
        await currentServer.refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<ServerProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.serverPageTitle),
        actions: [
          IconButton(
            key: _addKey,
            onPressed: _openAddServer,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.serverAdd,
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final query = _searchController.text.trim().toLowerCase();
          final data = provider.servers.where((item) {
            if (query.isEmpty) {
              return true;
            }
            return item.config.name.toLowerCase().contains(query) ||
                item.config.url.toLowerCase().contains(query);
          }).toList();

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  await provider.load();
                  if (provider.servers.isNotEmpty) {
                    await provider.loadMetrics();
                  }
                },
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: AppDesignTokens.pagePadding,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: l10n.serverSearchHint,
                            prefixIcon: const Icon(Icons.search),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    if (data.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: AppDesignTokens.pagePadding,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.dns_outlined, size: 56),
                                const SizedBox(
                                    height: AppDesignTokens.spacingLg),
                                Text(
                                  l10n.serverListEmptyTitle,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(
                                    height: AppDesignTokens.spacingSm),
                                Text(l10n.serverListEmptyDesc,
                                    textAlign: TextAlign.center),
                                const SizedBox(
                                    height: AppDesignTokens.spacingLg),
                                FilledButton(
                                  onPressed: _openAddServer,
                                  child: Text(l10n.serverAdd),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList.builder(
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            final item = data[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ServerCard(
                                key: index == 0 ? _firstCardKey : null,
                                data: item,
                                onTap: () => _openDetail(item),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (_coachSteps.isNotEmpty)
                CoachMarkOverlay(
                  steps: _coachSteps,
                  onFinished: () async {
                    await _onboardingService
                        .completeCoach(OnboardingService.coachServerAddKey);
                    await _onboardingService
                        .completeCoach(OnboardingService.coachServerCardKey);
                    if (!mounted) {
                      return;
                    }
                    setState(() {
                      _coachSteps = const [];
                    });
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openDetail(ServerCardViewModel item) async {
    if (!item.isCurrent) {
      await context.read<ServerProvider>().setCurrent(item.config.id);
      if (mounted) {
        await context.read<CurrentServerController>().selectServer(item.config.id);
      }
    }
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServerDetailPage(server: item),
      ),
    );
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({
    super.key,
    required this.data,
    required this.onTap,
  });

  final ServerCardViewModel data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
        child: Padding(
          padding: AppDesignTokens.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data.config.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (data.isCurrent)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(l10n.serverCurrent),
                    ),
                ],
              ),
              const SizedBox(height: AppDesignTokens.spacingSm),
              Text('${l10n.serverIpLabel}: ${_extractHost(data.config.url)}'),
              const SizedBox(height: AppDesignTokens.spacingMd),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricPill(
                      label: l10n.serverCpuLabel,
                      value: _percent(data.metrics.cpuPercent)),
                  _MetricPill(
                      label: l10n.serverMemoryLabel,
                      value: _percent(data.metrics.memoryPercent)),
                  _MetricPill(
                      label: l10n.serverLoadLabel,
                      value: _decimal(data.metrics.load)),
                  _MetricPill(
                      label: l10n.serverDiskLabel,
                      value: _percent(data.metrics.diskPercent)),
                ],
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _hasMetrics(data.metrics)
                        ? l10n.serverMetricsAvailable
                        : l10n.serverMetricsUnavailable,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  Text(
                    l10n.serverOpenDetail,
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _extractHost(String url) {
    final uri = Uri.tryParse(url);
    return uri?.host.isNotEmpty == true ? uri!.host : url;
  }

  String _percent(double? value) {
    if (value == null) {
      return '--';
    }
    return '${value.toStringAsFixed(1)}%';
  }

  String _decimal(double? value) {
    if (value == null) {
      return '--';
    }
    return value.toStringAsFixed(2);
  }

  bool _hasMetrics(ServerMetricsSnapshot metrics) {
    return metrics.cpuPercent != null ||
        metrics.memoryPercent != null ||
        metrics.diskPercent != null ||
        metrics.load != null;
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      ),
      child: Text('$label $value'),
    );
  }
}
