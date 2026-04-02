import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/onboarding_service.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/onboarding/coach_mark_overlay.dart';
import 'package:onepanel_client/features/server/server_detail_page.dart';
import 'package:onepanel_client/features/server/server_form_page.dart';
import 'package:onepanel_client/features/server/server_models.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/shell_drawer_scope.dart';

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
    if (!widget.enableCoach) {
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
      if (showCard && _serverProvider.servers.isNotEmpty) {
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
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              )
            : buildShellDrawerLeading(
                context,
                key: const Key('shell-drawer-menu-button'),
              ),
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
                                onDelete: () => _deleteServer(item),
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
      await context
          .read<CurrentServerController>()
          .selectServer(item.config.id);
      if (mounted) {
        await context.read<ServerProvider>().load();
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

  Future<void> _deleteServer(ServerCardViewModel item) async {
    final l10n = context.l10n;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.serverDeleteConfirmTitle),
            content: Text(l10n.serverDeleteConfirmMessage(item.config.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.commonDelete),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    final serverProvider = context.read<ServerProvider>();
    final currentServerController = context.read<CurrentServerController>();
    final messenger = ScaffoldMessenger.of(context);
    final successMessage = l10n.serverDeleteSuccess(item.config.name);

    try {
      await serverProvider.delete(item.config.id);
      await currentServerController.refresh();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.serverDeleteFailed(error.toString())),
        ),
      );
    }
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({
    super.key,
    required this.data,
    required this.onTap,
    required this.onDelete,
  });

  final ServerCardViewModel data;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
                  IconButton(
                    tooltip: l10n.commonDelete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
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
                    icon: Icons.memory_outlined,
                    label: l10n.serverCpuLabel,
                    value: _percent(data.metrics.cpuPercent),
                  ),
                  _MetricPill(
                    icon: Icons.storage_outlined,
                    label: l10n.serverMemoryLabel,
                    value: _percent(data.metrics.memoryPercent),
                  ),
                  _MetricPill(
                    icon: Icons.speed_outlined,
                    label: l10n.serverLoadLabel,
                    value: _decimal(data.metrics.load),
                  ),
                  _MetricPill(
                    icon: Icons.sd_card_outlined,
                    label: l10n.serverDiskLabel,
                    value: _percent(data.metrics.diskPercent),
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
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text('$label $value'),
        ],
      ),
    );
  }
}
