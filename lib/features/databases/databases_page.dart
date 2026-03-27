import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
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
      create: (_) => DatabasesProvider(scope: scope)..load(),
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
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l10n.commonSearch,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onSubmitted: (value) => provider.load(query: value),
                ),
              ),
              const SizedBox(width: AppDesignTokens.spacingSm),
              IconButton(
                onPressed: provider.refresh,
                tooltip: l10n.commonRefresh,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                onPressed: scope == DatabaseScope.redis
                    ? null
                    : () => Navigator.pushNamed(
                          context,
                          AppRoutes.databaseForm,
                          arguments: {'scope': scope.value},
                        ),
                tooltip: l10n.commonCreate,
                icon: const Icon(Icons.add),
              ),
            ],
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
                : ListView.separated(
                    padding: AppDesignTokens.pagePadding,
                    itemCount: provider.state.items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDesignTokens.spacingSm),
                    itemBuilder: (context, index) {
                      final item = provider.state.items[index];
                      return AppCard(
                        title: item.name,
                        subtitle: Text(_subtitle(item)),
                        child: Text(_detail(item)),
                        onTap: () => Navigator.pushNamed(
                          context,
                          item.scope == DatabaseScope.redis
                              ? AppRoutes.databaseRedisConfig
                              : AppRoutes.databaseDetail,
                          arguments: item,
                        ),
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
    if (item.address?.isNotEmpty == true) {
      parts.add(
          item.port != null ? '${item.address}:${item.port}' : item.address!);
    }
    if (item.username?.isNotEmpty == true) {
      parts.add(item.username!);
    }
    if (item.description?.isNotEmpty == true) {
      parts.add(item.description!);
    }
    return parts.isEmpty ? '-' : parts.join(' · ');
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
