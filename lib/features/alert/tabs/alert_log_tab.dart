import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/alert_models.dart';
import 'package:onepanel_client/features/alert/providers/alert_provider.dart';
import 'package:onepanel_client/shared/widgets/expressive_section.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';

/// 告警日志分区。
class AlertLogTab extends StatelessWidget {
  const AlertLogTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<AlertProvider>();

    return Column(
      children: <Widget>[
        _LogFilterBar(provider: provider),
        Expanded(
          child: AsyncStatePageBodyWidget(
            isLoading: provider.logLoading && provider.logs.isEmpty,
            isEmpty: provider.logs.isEmpty && provider.logError == null,
            errorMessage: provider.logError,
            onRetry: provider.loadLogs,
            emptyTitle: l10n.alertLogEmptyTitle,
            emptyDescription: l10n.alertLogEmptyDescription,
            emptyIcon: Icons.receipt_long_outlined,
            child: RefreshIndicator(
              onRefresh: provider.loadLogs,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppDesignTokens.spacingLg,
                  AppDesignTokens.spacingSm,
                  AppDesignTokens.spacingLg,
                  AppDesignTokens.spacingXl +
                      MediaQuery.paddingOf(context).bottom,
                ),
                children: <Widget>[
                  ExpressiveSection(
                    title: l10n.alertTabLogs,
                    isBusy: provider.logLoading,
                    children: <Widget>[
                      for (final log in provider.logs) _LogRow(log: log),
                    ],
                  ),
                  const SizedBox(height: AppDesignTokens.spacingMd),
                  Text(
                    l10n.alertLogSyncUnsupported,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogFilterBar extends StatelessWidget {
  const _LogFilterBar({required this.provider});

  final AlertProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDesignTokens.spacingLg,
        AppDesignTokens.spacingMd,
        AppDesignTokens.spacingLg,
        AppDesignTokens.spacingSm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: ExpressiveFilterBar(
              options: <(String, String)>[
                ('all', l10n.alertLogFilterAllStatuses),
                ('Success', l10n.alertLogStatusSuccess),
                ('Error', l10n.alertLogStatusError),
              ],
              selected: provider.logStatus ?? 'all',
              onSelected: (value) => provider.setLogStatus(
                value == null || value == 'all' ? null : value,
              ),
            ),
          ),
          const SizedBox(width: AppDesignTokens.spacingSm),
          IconButton(
            icon: Icon(
              Icons.delete_sweep_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: l10n.alertLogCleanAction,
            onPressed: provider.isMutating ? null : () => _cleanLogs(context),
          ),
        ],
      ),
    );
  }

  Future<void> _cleanLogs(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.alertLogCleanAction,
      message: l10n.alertLogCleanConfirm,
      confirmLabel: l10n.alertLogCleanAction,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await provider.cleanLogs();
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, l10n.commonOperationSuccess);
    } catch (error) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, error.toString());
    }
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.log});

  final AlertLog log;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isError = log.status == 'Error' || log.status == 'SyncError';
    final message = _message(l10n);
    final meta = <String>[
      if (log.method.isNotEmpty) log.method,
      if (log.createdAt.isNotEmpty) log.createdAt,
      '${l10n.alertLogCountColumn} ${log.count}',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.spacingLg,
        vertical: AppDesignTokens.spacingMd + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isError
                  ? scheme.errorContainer
                  : scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
            ),
            alignment: Alignment.center,
            child: Icon(
              isError ? Icons.error_outline : Icons.receipt_long_outlined,
              size: 20,
              color: isError ? scheme.onErrorContainer : scheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: AppDesignTokens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                    const SizedBox(width: AppDesignTokens.spacingSm),
                    _StatusLabel(status: log.status),
                  ],
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: AppDesignTokens.spacingXs),
                  Text(
                    meta.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
                if (isError && log.message.isNotEmpty) ...[
                  const SizedBox(height: AppDesignTokens.spacingXs + 2),
                  Text(
                    '${l10n.alertLogFailureReasonLabel}: ${log.message}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.error),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 告警消息按规则标题与目标对象组合；服务端未给标题时回落到详情标题。
  String _message(l10n) {
    final title = log.alertRule.title.isNotEmpty
        ? log.alertRule.title
        : log.alertDetail.title;
    if (title.isNotEmpty) return title;
    return log.alertDetail.type.isEmpty
        ? l10n.alertLogMessageColumn
        : log.alertDetail.type;
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final label = switch (status) {
      'PushSuccess' || 'Success' => l10n.alertLogStatusSuccess,
      'Pushing' => l10n.alertLogStatusPushing,
      'Error' => l10n.alertLogStatusError,
      'SyncError' => l10n.alertLogStatusSyncError,
      _ => status,
    };
    final color = switch (status) {
      'PushSuccess' || 'Success' => scheme.primary,
      'Pushing' => scheme.tertiary,
      'Error' || 'SyncError' => scheme.error,
      _ => scheme.onSurfaceVariant,
    };
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
    );
  }
}
