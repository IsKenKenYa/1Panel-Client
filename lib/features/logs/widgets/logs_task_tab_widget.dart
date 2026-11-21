import 'package:flutter/material.dart';
import 'package:onepanel_client/shared/widgets/module_search_field.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/logs/models/task_log_detail_args.dart';
import 'package:onepanel_client/features/logs/providers/task_logs_provider.dart';
import 'package:onepanel_client/features/logs/utils/logs_l10n_helper.dart';
import 'package:onepanel_client/features/logs/widgets/task_log_card_widget.dart';
import 'package:onepanel_client/features/logs/widgets/log_status_filter.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';

class LogsTaskTabWidget extends StatelessWidget {
  const LogsTaskTabWidget({
    super.key,
    required this.provider,
    required this.typeController,
    required this.onCopy,
  });

  final TaskLogsProvider provider;
  final TextEditingController typeController;
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
              ModuleSearchField(
                controller: typeController,
                onChanged: provider.updateTypeFilter,
                onSubmitted: (_) => provider.load(),
                labelText: l10n.logsTaskTypeLabel,
              ),
              const SizedBox(height: 12),
              LogStatusFilter(
                value: provider.statusFilter,
                executingCount: provider.executingCount,
                onChanged: (status) async {
                  provider.updateStatusFilter(status);
                  await provider.load();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncStatePageBodyWidget(
            isLoading: provider.isLoading,
            isEmpty: provider.isEmpty,
            errorMessage: localizeLogsError(l10n, provider.errorMessage),
            onRetry: provider.load,
            emptyTitle: l10n.logsTaskEmptyTitle,
            emptyDescription: l10n.logsTaskEmptyDescription,
            child: RefreshIndicator(
              onRefresh: provider.load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: provider.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = provider.items[index];
                  return TaskLogCardWidget(
                    item: item,
                    onCopy: () => onCopy(
                      '${item.name ?? '-'}\n'
                      '${item.type ?? '-'}\n'
                      '${item.status ?? '-'}\n'
                      '${item.currentStep ?? '-'}',
                    ),
                    onOpenDetail: () => Navigator.pushNamed(
                      context,
                      AppRoutes.taskLogDetail,
                      arguments: TaskLogDetailArgs(
                        taskId: item.id ?? '',
                        taskName: item.name ?? '',
                        taskType: item.type ?? '',
                        status: item.status ?? '',
                        currentStep: item.currentStep,
                        logFile: item.logFile,
                        createdAt: item.createdAt,
                        resourceId: item.resourceId,
                      ),
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
