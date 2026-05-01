import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

import 'databases_provider.dart';

class DatabasesPage extends StatefulWidget {
  const DatabasesPage({super.key});

  @override
  State<DatabasesPage> createState() => _DatabasesPageState();
}

class _DatabasesPageState extends State<DatabasesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _scopes = <DatabaseScope>[
    DatabaseScope.mysql,
    DatabaseScope.postgresql,
    DatabaseScope.redis,
    DatabaseScope.remote,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _scopes.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final serverId = context.watch<CurrentServerController>().currentServerId;
    return ServerAwarePageScaffold(
      title: l10n.serverModuleDatabases,
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: [
          Tab(text: l10n.databaseMysqlTab),
          Tab(text: l10n.databasePostgresqlTab),
          Tab(text: l10n.databaseRedisTab),
          Tab(text: l10n.databaseRemoteTab),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (final scope in _scopes)
            KeyedSubtree(
              key: ValueKey('${scope.value}:${serverId ?? 'none'}'),
              child: _DatabaseScopeTab(scope: scope),
            ),
        ],
      ),
    );
  }
}

class _DatabaseScopeTab extends StatelessWidget {
  const _DatabaseScopeTab({required this.scope});

  final DatabaseScope scope;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = DatabasesProvider(scope: scope);
        if (scope == DatabaseScope.mysql || scope == DatabaseScope.postgresql) {
          provider.loadTargets().then((_) => provider.load());
        } else {
          provider.load();
        }
        return provider;
      },
      child: _DatabaseScopeTabView(scope: scope),
    );
  }
}

class _DatabaseScopeTabView extends StatelessWidget {
  const _DatabaseScopeTabView({required this.scope});

  final DatabaseScope scope;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DatabasesProvider>();
    final l10n = context.l10n;

    if (provider.state.isLoading && provider.state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.state.error != null && provider.state.items.isEmpty) {
      return _DatabaseErrorState(
        error: provider.state.error!,
        onRetry: provider.refresh,
      );
    }

    return Column(
      children: [
        Padding(
          padding: AppDesignTokens.pagePadding,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWideToolbar = constraints.maxWidth >= 720;
              final showSourceFilter = scope == DatabaseScope.mysql ||
                  scope == DatabaseScope.postgresql;
              final filterControls = <Widget>[
                if (showSourceFilter)
                  Padding(
                    padding: EdgeInsets.only(
                      right: isWideToolbar ? AppDesignTokens.spacingSm : 0,
                      bottom: isWideToolbar ? 0 : AppDesignTokens.spacingSm,
                    ),
                    child: SegmentedButton<DatabaseSourceFilter>(
                      segments: [
                        const ButtonSegment(
                          value: DatabaseSourceFilter.all,
                          label: Text('All'),
                        ),
                        const ButtonSegment(
                          value: DatabaseSourceFilter.local,
                          label: Text('Local'),
                        ),
                        ButtonSegment(
                          value: DatabaseSourceFilter.remote,
                          label: Text(l10n.databaseRemoteTab),
                        ),
                      ],
                      selected: {provider.state.sourceFilter},
                      onSelectionChanged: (selection) {
                        if (selection.isEmpty) return;
                        provider.setSourceFilter(selection.first);
                      },
                    ),
                  ),
                if (showSourceFilter)
                  SizedBox(
                    width: isWideToolbar ? 300 : double.infinity,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(
                        '${scope.value}:${provider.state.sourceFilter.name}:${provider.state.selectedTarget?.lookupName ?? 'none'}:${provider.state.visibleTargets.length}',
                      ),
                      initialValue: provider.state.selectedTarget?.lookupName,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Target Instance',
                      ),
                      items: [
                        for (final target in provider.state.visibleTargets)
                          DropdownMenuItem<String>(
                            value: target.lookupName,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${target.lookupName} [${target.name}]',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  target.source,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      selectedItemBuilder: (context) {
                        return [
                          for (final target in provider.state.visibleTargets)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${target.lookupName} [${target.name}]',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ];
                      },
                      onChanged: provider.state.isLoadingTargets
                          ? null
                          : (value) {
                              DatabaseListItem? next;
                              for (final item
                                  in provider.state.visibleTargets) {
                                if (item.lookupName == value) {
                                  next = item;
                                  break;
                                }
                              }
                              provider.selectTarget(next);
                            },
                    ),
                  ),
              ];
              final searchField = ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: isWideToolbar ? 240 : 0,
                  maxWidth: isWideToolbar ? 360 : double.infinity,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l10n.commonSearch,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onSubmitted: (value) => provider.load(query: value),
                ),
              );
              final actions = Wrap(
                spacing: AppDesignTokens.spacingSm,
                runSpacing: AppDesignTokens.spacingSm,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: provider.refresh,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.commonRefresh),
                  ),
                  FilledButton.icon(
                    onPressed: scope == DatabaseScope.redis
                        ? null
                        : () => openRouteRespectingShell(
                              context,
                              AppRoutes.databaseForm,
                              arguments: {'scope': scope.value},
                            ),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.commonCreate),
                  ),
                ],
              );

              if (!isWideToolbar) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: AppDesignTokens.spacingSm,
                      runSpacing: AppDesignTokens.spacingSm,
                      children: [
                        ...filterControls,
                        searchField,
                      ],
                    ),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    Row(
                      children: [
                        const Spacer(),
                        actions,
                      ],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: AppDesignTokens.spacingSm,
                      runSpacing: AppDesignTokens.spacingSm,
                      children: [
                        ...filterControls,
                        searchField,
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDesignTokens.spacingSm),
                  actions,
                ],
              );
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: provider.refresh,
            child: provider.state.items.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: AppDesignTokens.spacingXl),
                      Center(child: Text(l10n.commonEmpty)),
                    ],
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = switch (constraints.maxWidth) {
                        >= 1360 => 3,
                        >= 820 => 2,
                        _ => 1,
                      };
                      return GridView.builder(
                        padding: AppDesignTokens.pagePadding,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: AppDesignTokens.spacingSm,
                          mainAxisSpacing: AppDesignTokens.spacingSm,
                          mainAxisExtent: 238,
                        ),
                        itemCount: provider.state.items.length,
                        itemBuilder: (context, index) {
                          final item = provider.state.items[index];
                          return _DatabaseGridCard(
                            item: item,
                            subtitle: _subtitle(item),
                            detail: _detail(item),
                            onRefresh: provider.refresh,
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  String _subtitle(DatabaseListItem item) {
    final parts = <String>[item.engine];
    if (item.lookupName != item.name) {
      parts.add(item.lookupName);
    }
    if (item.version?.isNotEmpty == true) {
      parts.add(item.version!);
    }
    if (item.status?.isNotEmpty == true) {
      parts.add(item.status!);
    }
    return parts.join(' · ');
  }

  String _detail(DatabaseListItem item) {
    final parts = <String>[];
    if (item.instanceLabel?.isNotEmpty == true &&
        item.instanceLabel != item.lookupName &&
        item.instanceLabel != item.name) {
      parts.add(item.instanceLabel!);
    }
    if (item.address?.isNotEmpty == true) {
      parts.add(
          item.port != null ? '${item.address}:${item.port}' : item.address!);
    }
    if (item.username?.isNotEmpty == true) {
      parts.add(item.username!);
    }
    
    if (item.database?.isNotEmpty == true && 
        item.database != item.name && 
        item.database != item.lookupName) {
      parts.add('DB: ${item.database}');
    }
    
    // Postgresql or MySQL specific
    final charset = item.raw['charset'] as String?;
    if (charset != null && charset.isNotEmpty) {
      parts.add('Charset: $charset');
    }
    
    final format = item.raw['format'] as String?;
    if (format != null && format.isNotEmpty) {
      parts.add('Format: $format');
    }

    if (item.description?.isNotEmpty == true) {
      parts.add(item.description!);
    }
    return parts.isEmpty ? '-' : parts.join(' · ');
  }
}

class _DatabaseGridCard extends StatelessWidget {
  const _DatabaseGridCard({
    required this.item,
    required this.subtitle,
    required this.detail,
    required this.onRefresh,
  });

  final DatabaseListItem item;
  final String subtitle;
  final String detail;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final destination = item.scope == DatabaseScope.redis
        ? AppRoutes.databaseRedisConfig
        : AppRoutes.databaseDetail;

    return AppCard(
      title: item.name,
      leading: _DatabaseEngineBadge(item: item),
      subtitle: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _InfoChip(
            icon: Icons.developer_board_outlined,
            label: subtitle,
          ),
          if (item.lookupName != item.name)
            _InfoChip(
              icon: Icons.hub_outlined,
              label: item.lookupName,
            ),
          _StatusChip(item: item),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDesignTokens.spacingSm),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
            ),
            child: Text(
              detail,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  destination,
                  arguments: item,
                ),
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.commonMore),
              ),
              OutlinedButton.icon(
                onPressed: detail == '-'
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: detail));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.commonCopied)),
                        );
                      },
                icon: const Icon(Icons.content_copy_outlined),
                label: Text(l10n.commonCopy),
              ),
              IconButton(
                tooltip: l10n.commonRefresh,
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ],
      ),
      onTap: () => Navigator.pushNamed(
        context,
        destination,
        arguments: item,
      ),
    );
  }
}

class _DatabaseEngineBadge extends StatelessWidget {
  const _DatabaseEngineBadge({required this.item});

  final DatabaseListItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        switch (item.scope) {
          DatabaseScope.mysql => Icons.storage_outlined,
          DatabaseScope.postgresql => Icons.dataset_outlined,
          DatabaseScope.redis => Icons.memory_outlined,
          DatabaseScope.remote => Icons.cloud_outlined,
        },
        color: scheme.onSecondaryContainer,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.item});

  final DatabaseListItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusText = item.status?.trim().isNotEmpty == true
        ? item.status!
        : (item.source == 'remote' ? 'remote' : 'local');
    final isPositive = statusText.toLowerCase().contains('run') ||
        statusText.toLowerCase().contains('local');
    final bg =
        isPositive ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = isPositive ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        statusText,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}

class _DatabaseErrorState extends StatelessWidget {
  const _DatabaseErrorState({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: AppDesignTokens.spacingMd),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: AppDesignTokens.spacingMd),
            FilledButton(
              onPressed: () => onRetry(),
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
