import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/data/models/database_models.dart';

import 'databases_provider.dart';
import 'databases_service.dart';
import 'widgets/database_detail_actions_widget.dart';
import 'widgets/database_detail_error_widget.dart';
import 'widgets/database_detail_management_widget.dart';
import 'widgets/database_detail_sections_widget.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

class DatabaseDetailPage extends StatelessWidget {
  const DatabaseDetailPage({
    super.key,
    required this.item,
    this.service,
  });

  final DatabaseListItem item;
  final DatabasesService? service;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DatabaseDetailProvider(
        item: item,
        service: service,
      )..load(),
      child: const _DatabaseDetailPageView(),
    );
  }
}

class _DatabaseDetailPageView extends StatelessWidget {
  const _DatabaseDetailPageView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DatabaseDetailProvider>();
    final detail = provider.detail;
    final item = provider.item;

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: provider.isLoading && detail == null
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null && detail == null
              ? DatabaseDetailErrorWidget(
                  error: provider.error!,
                  onRetry: provider.load,
                )
              : RefreshIndicator(
                  onRefresh: provider.load,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 1080;
                      final content = switch (item.scope) {
                        DatabaseScope.mysql => _MysqlDetailSections(
                            item: item,
                            detail: detail,
                          ),
                        DatabaseScope.postgresql => _PostgresqlDetailSections(
                            item: item,
                            detail: detail,
                          ),
                        _ => DatabaseDetailSectionsWidget(
                            item: item,
                            detail: detail,
                          ),
                      };
                      final management =
                          DatabaseDetailManagementWidget(item: item);
                      const actions = DatabaseDetailActionsWidget();

                      if (!isWide) {
                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            content,
                            management,
                            actions,
                            if (provider.error != null) ...[
                              const SizedBox(height: 16),
                              DatabaseDetailErrorWidget(
                                error: provider.error!,
                                onRetry: provider.load,
                              ),
                            ],
                          ],
                        );
                      }

                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 11,
                              child: Column(
                                children: [
                                  content,
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 7,
                              child: Column(
                                children: [
                                  management,
                                  actions,
                                  if (provider.error != null) ...[
                                    const SizedBox(height: 16),
                                    DatabaseDetailErrorWidget(
                                      error: provider.error!,
                                      onRetry: provider.load,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _MysqlDetailSections extends StatelessWidget {
  const _MysqlDetailSections({
    required this.item,
    required this.detail,
  });

  final DatabaseListItem item;
  final DatabaseDetailData? detail;

  @override
  Widget build(BuildContext context) {
    final sections = DatabaseDetailSectionsWidget(
      item: item,
      detail: detail,
    );
    return Column(
      children: [
        _DatabaseHeaderCard(
          title: 'MySQL',
          item: item,
          accentIcon: Icons.storage_outlined,
        ),
        const SizedBox(height: 16),
        sections,
      ],
    );
  }
}

class _PostgresqlDetailSections extends StatelessWidget {
  const _PostgresqlDetailSections({
    required this.item,
    required this.detail,
  });

  final DatabaseListItem item;
  final DatabaseDetailData? detail;

  @override
  Widget build(BuildContext context) {
    final sections = DatabaseDetailSectionsWidget(
      item: item,
      detail: detail,
    );
    return Column(
      children: [
        _DatabaseHeaderCard(
          title: 'PostgreSQL',
          item: item,
          accentIcon: Icons.dataset_outlined,
        ),
        const SizedBox(height: 16),
        sections,
      ],
    );
  }
}

class _DatabaseHeaderCard extends StatelessWidget {
  const _DatabaseHeaderCard({
    required this.title,
    required this.item,
    required this.accentIcon,
  });

  final String title;
  final DatabaseListItem item;
  final IconData accentIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      title: title,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _HeaderBadge(
            icon: accentIcon,
            label: item.lookupName,
          ),
          _HeaderBadge(
            icon: Icons.inventory_2_outlined,
            label: item.name,
          ),
          _HeaderBadge(
            icon: Icons.route_outlined,
            label: item.source,
          ),
          if (item.version?.isNotEmpty == true)
            _HeaderBadge(
              icon: Icons.new_releases_outlined,
              label: item.version!,
            ),
          if (item.status?.isNotEmpty == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.status!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
