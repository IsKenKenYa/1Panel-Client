import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/logs/providers/logs_provider.dart';
import 'package:onepanel_client/features/logs/utils/logs_l10n_helper.dart';
import 'package:onepanel_client/features/logs/widgets/operation_log_card_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';

class LogsOperationTabWidget extends StatelessWidget {
  const LogsOperationTabWidget({
    super.key,
    required this.provider,
    required this.operationController,
    required this.sourceController,
    required this.onCopy,
  });

  final LogsProvider provider;
  final TextEditingController operationController;
  final TextEditingController sourceController;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              TextField(
                controller: operationController,
                onChanged: provider.updateOperationKeyword,
                onSubmitted: (_) => provider.loadOperationLogs(),
                decoration: InputDecoration(
                  labelText: l10n.logsOperationActionLabel,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sourceController,
                onChanged: provider.updateOperationSource,
                onSubmitted: (_) => provider.loadOperationLogs(),
                decoration: InputDecoration(
                  labelText: l10n.logsOperationSourceLabel,
                  prefixIcon: const Icon(Icons.filter_alt_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  _StatusChip(
                    label: l10n.logsStatusAll,
                    selected: provider.operationStatus.isEmpty,
                    onTap: () async {
                      provider.updateOperationStatus('');
                      await provider.loadOperationLogs();
                    },
                  ),
                  _StatusChip(
                    label: l10n.logsStatusSuccess,
                    selected: provider.operationStatus == 'Success',
                    onTap: () async {
                      provider.updateOperationStatus('Success');
                      await provider.loadOperationLogs();
                    },
                  ),
                  _StatusChip(
                    label: l10n.logsStatusFailed,
                    selected: provider.operationStatus == 'Failed',
                    onTap: () async {
                      provider.updateOperationStatus('Failed');
                      await provider.loadOperationLogs();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncStatePageBodyWidget(
            isLoading: provider.operationLoading,
            isEmpty: provider.operationEmpty,
            errorMessage: localizeLogsError(l10n, provider.operationError),
            onRetry: provider.loadOperationLogs,
            emptyTitle: l10n.logsOperationEmptyTitle,
            emptyDescription: l10n.logsOperationEmptyDescription,
            child: RefreshIndicator(
              onRefresh: provider.loadOperationLogs,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: provider.operationItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = provider.operationItems[index];
                  return OperationLogCardWidget(
                    item: item,
                    onCopy: () => onCopy(
                      '${item.detailZh ?? item.detailEn ?? item.message ?? '-'}\n'
                      '${item.method ?? '-'} ${item.path ?? ''}\n'
                      '${item.status ?? '-'}\n'
                      '${item.createdAt ?? '-'}',
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
