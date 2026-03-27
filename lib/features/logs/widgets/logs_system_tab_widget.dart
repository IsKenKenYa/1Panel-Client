import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/logs/models/system_log_viewer_args.dart';
import 'package:onepanel_client/features/logs/providers/system_logs_provider.dart';
import 'package:onepanel_client/features/logs/utils/logs_l10n_helper.dart';
import 'package:onepanel_client/features/logs/widgets/system_log_file_card_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';

class LogsSystemTabWidget extends StatelessWidget {
  const LogsSystemTabWidget({
    super.key,
    required this.provider,
  });

  final SystemLogsProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            children: <Widget>[
              ChoiceChip(
                label: Text(l10n.logsSystemSourceAgent),
                selected: provider.source == SystemLogSource.agent,
                onSelected: (_) => provider.updateSource(SystemLogSource.agent),
              ),
              ChoiceChip(
                label: Text(l10n.logsSystemSourceCore),
                selected: provider.source == SystemLogSource.core,
                onSelected: (_) => provider.updateSource(SystemLogSource.core),
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncStatePageBodyWidget(
            isLoading: provider.filesLoading,
            isEmpty: provider.filesEmpty,
            errorMessage: localizeLogsError(l10n, provider.filesError),
            onRetry: provider.loadFiles,
            emptyTitle: l10n.logsSystemEmptyTitle,
            emptyDescription: l10n.logsSystemEmptyDescription,
            child: RefreshIndicator(
              onRefresh: provider.loadFiles,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: provider.files.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final file = provider.files[index];
                  return SystemLogFileCardWidget(
                    fileName: file,
                    onOpen: () => Navigator.pushNamed(
                      context,
                      AppRoutes.systemLogViewer,
                      arguments: SystemLogViewerArgs(
                        initialFileName: file,
                        useCoreLogs: provider.source == SystemLogSource.core,
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
