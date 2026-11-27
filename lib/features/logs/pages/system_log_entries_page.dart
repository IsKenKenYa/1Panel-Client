import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/system_log_models.dart';
import 'package:onepanel_client/features/logs/providers/system_log_entries_provider.dart';
import 'package:onepanel_client/features/logs/utils/logs_l10n_helper.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:provider/provider.dart';

/// 宿主系统日志条目查询页，对应上游 `/logs/system`。
///
/// 使用服务端游标分页，只提供上一页与下一页；关键字筛选在来源不支持时禁用。
class SystemLogEntriesPage extends StatefulWidget {
  const SystemLogEntriesPage({super.key});

  @override
  State<SystemLogEntriesPage> createState() => _SystemLogEntriesPageState();
}

class _SystemLogEntriesPageState extends State<SystemLogEntriesPage> {
  late final TextEditingController _keywordController;

  @override
  void initState() {
    super.initState();
    _keywordController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<SystemLogEntriesProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _reload() {
    return context.read<SystemLogEntriesProvider>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<SystemLogEntriesProvider>(
      builder: (context, provider, _) {
        return ServerAwarePageScaffold(
          title: l10n.logsSystemTabLabel,
          onServerChanged: _reload,
          body: Column(
            children: <Widget>[
              _StatusBar(provider: provider),
              _FilterBar(
                provider: provider,
                keywordController: _keywordController,
              ),
              Expanded(
                child: AsyncStatePageBodyWidget(
                  isLoading: provider.loading && provider.entries.isEmpty,
                  isEmpty: provider.isEmpty,
                  errorMessage:
                      localizeLogsError(l10n, provider.errorMessage),
                  onRetry: provider.reload,
                  emptyTitle: l10n.logsSystemEntriesEmptyTitle,
                  emptyDescription:
                      l10n.logsSystemEntriesEmptyDescription,
                  emptyIcon: Icons.article_outlined,
                  child: RefreshIndicator(
                    onRefresh: provider.reload,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppDesignTokens.spacingLg,
                        0,
                        AppDesignTokens.spacingLg,
                        AppDesignTokens.spacingLg,
                      ),
                      itemCount: provider.entries.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppDesignTokens.spacingSm),
                      itemBuilder: (context, index) => _EntryCard(
                        entry: provider.entries[index],
                      ),
                    ),
                  ),
                ),
              ),
              _CursorPager(provider: provider),
            ],
          ),
        );
      },
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.provider});

  final SystemLogEntriesProvider provider;

  @override
  Widget build(BuildContext context) {
    final status = provider.status;
    if (status == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDesignTokens.spacingLg,
        AppDesignTokens.spacingMd,
        AppDesignTokens.spacingLg,
        0,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: AppDesignTokens.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: AppDesignTokens.spacingSm,
                runSpacing: AppDesignTokens.spacingXs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    status.source.name,
                    style: theme.textTheme.titleSmall,
                  ),
                  if (status.version != null && status.version!.isNotEmpty)
                    Text(
                      status.version!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              if (!status.canFilterByKeyword &&
                  status.message != null &&
                  status.message!.isNotEmpty) ...[
                const SizedBox(height: AppDesignTokens.spacingXs),
                Text(
                  status.message!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.provider,
    required this.keywordController,
  });

  final SystemLogEntriesProvider provider;
  final TextEditingController keywordController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDesignTokens.spacingLg,
        AppDesignTokens.spacingMd,
        AppDesignTokens.spacingLg,
        AppDesignTokens.spacingMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: keywordController,
            enabled: provider.canFilterByKeyword,
            decoration: InputDecoration(
              labelText: l10n.logsSystemKeywordLabel,
              helperText: provider.canFilterByKeyword
                  ? null
                  : l10n.logsSystemKeywordUnsupported,
              suffixIcon: IconButton(
                tooltip: l10n.logsSystemFilterAction,
                icon: const Icon(Icons.search),
                onPressed: provider.canFilterByKeyword
                    ? () => provider.applyFilters(
                          keyword: keywordController.text,
                        )
                    : null,
              ),
            ),
            onSubmitted: (value) {
              if (!provider.canFilterByKeyword) return;
              provider.applyFilters(keyword: value);
            },
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          Wrap(
            spacing: AppDesignTokens.spacingSm,
            runSpacing: AppDesignTokens.spacingSm,
            children: <Widget>[
              _PriorityChips(provider: provider),
              _ServiceChips(provider: provider),
            ],
          ),
        ],
      ),
    );
  }
}

/// 优先级筛选，取值与服务端 `priority` 字段一致。
class _PriorityChips extends StatelessWidget {
  const _PriorityChips({required this.provider});

  final SystemLogEntriesProvider provider;

  static const _values = <String>[
    '',
    'debug',
    'info',
    'notice',
    'warning',
    'err',
    'crit',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String label(String value) => switch (value) {
          'debug' => l10n.logsSystemPriorityDebug,
          'info' => l10n.logsSystemPriorityInfo,
          'notice' => l10n.logsSystemPriorityNotice,
          'warning' => l10n.logsSystemPriorityWarning,
          'err' || 'error' => l10n.logsSystemPriorityError,
          'crit' || 'critical' => l10n.logsSystemPriorityCritical,
          _ => l10n.logsStatusAll,
        };
    return Wrap(
      spacing: AppDesignTokens.spacingXs,
      children: <Widget>[
        for (final value in _values)
          ChoiceChip(
            label: Text(label(value)),
            selected: provider.priority == value,
            showCheckmark: false,
            onSelected: (_) => provider.applyFilters(priority: value),
          ),
      ],
    );
  }
}

/// 服务筛选，选项来自 `GET /logs/system/services`。
class _ServiceChips extends StatelessWidget {
  const _ServiceChips({required this.provider});

  final SystemLogEntriesProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.services.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Wrap(
      spacing: AppDesignTokens.spacingXs,
      runSpacing: AppDesignTokens.spacingXs,
      children: <Widget>[
        ChoiceChip(
          label: Text(l10n.logsStatusAll),
          selected: provider.serviceFilter.isEmpty,
          showCheckmark: false,
          onSelected: (_) => provider.applyFilters(service: ''),
        ),
        for (final service in provider.services)
          ChoiceChip(
            label: Text(service),
            selected: provider.serviceFilter == service,
            showCheckmark: false,
            onSelected: (_) => provider.applyFilters(service: service),
          ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final SystemLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final severityColor = _severityColor(scheme, entry.priority);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppDesignTokens.dataRowPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (entry.priority != null && entry.priority!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesignTokens.spacingSm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.14),
                      borderRadius:
                          BorderRadius.circular(AppDesignTokens.radiusSm),
                    ),
                    child: Text(
                      entry.priority!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: severityColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDesignTokens.spacingSm),
                ],
                Expanded(
                  child: Text(
                    entry.time,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (entry.service != null && entry.service!.isNotEmpty) ...[
              const SizedBox(height: AppDesignTokens.spacingXs),
              Text(
                '${l10n.logsSystemServiceLabel}: ${entry.service}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppDesignTokens.spacingXs),
            SelectableText(
              entry.message,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Color _severityColor(ColorScheme scheme, String? priority) {
    return switch (priority?.toLowerCase()) {
      'err' || 'error' || 'crit' || 'critical' => scheme.error,
      'warning' || 'warn' => AppDesignTokens.warning,
      'notice' || 'info' => scheme.primary,
      _ => scheme.onSurfaceVariant,
    };
  }
}

/// 游标翻页控件：只前进与回退各一页，与服务端游标分页一致。
class _CursorPager extends StatelessWidget {
  const _CursorPager({required this.provider});

  final SystemLogEntriesProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDesignTokens.spacingLg,
        0,
        AppDesignTokens.spacingLg,
        AppDesignTokens.spacingMd,
      ),
      child: Row(
        children: <Widget>[
          OutlinedButton(
            onPressed: provider.canGoPrevious ? provider.loadPreviousPage : null,
            child: Text(l10n.logsSystemPreviousPage),
          ),
          const Spacer(),
          IconButton(
            tooltip: l10n.logsSystemRefreshAction,
            onPressed: provider.loading ? null : provider.reload,
            icon: const Icon(Icons.refresh),
          ),
          const Spacer(),
          FilledButton(
            onPressed: provider.canGoNext ? provider.loadNextPage : null,
            child: Text(l10n.logsSystemNextPage),
          ),
        ],
      ),
    );
  }
}
