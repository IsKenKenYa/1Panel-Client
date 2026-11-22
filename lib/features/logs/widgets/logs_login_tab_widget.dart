import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/shared/widgets/module_search_field.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/logs/providers/logs_provider.dart';
import 'package:onepanel_client/features/logs/utils/logs_l10n_helper.dart';
import 'package:onepanel_client/features/logs/widgets/login_log_card_widget.dart';
import 'package:onepanel_client/features/logs/widgets/log_status_filter.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';

class LogsLoginTabWidget extends StatelessWidget {
  const LogsLoginTabWidget({
    super.key,
    required this.provider,
    required this.ipController,
    required this.onCopy,
  });

  final LogsProvider provider;
  final TextEditingController ipController;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: <Widget>[
        Padding(
          padding: AppDesignTokens.cardPadding,
          child: Column(
            children: <Widget>[
              ModuleSearchField(
                controller: ipController,
                onChanged: provider.updateLoginIp,
                onSubmitted: (_) => provider.loadLoginLogs(),
                labelText: l10n.logsLoginIpLabel,
              ),
              const SizedBox(height: 12),
              LogStatusFilter(
                value: provider.loginStatus,
                onChanged: (status) async {
                  provider.updateLoginStatus(status);
                  await provider.loadLoginLogs();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncStatePageBodyWidget(
            isLoading: provider.loginLoading,
            isEmpty: provider.loginEmpty,
            errorMessage: localizeLogsError(l10n, provider.loginError),
            onRetry: provider.loadLoginLogs,
            emptyTitle: l10n.logsLoginEmptyTitle,
            emptyDescription: l10n.logsLoginEmptyDescription,
            child: RefreshIndicator(
              onRefresh: provider.loadLoginLogs,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: provider.loginItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = provider.loginItems[index];
                  return LoginLogCardWidget(
                    item: item,
                    onCopy: () => onCopy(
                      '${item.ip ?? '-'}\n'
                      '${item.address ?? '-'}\n'
                      '${item.agent ?? '-'}\n'
                      '${item.status ?? '-'}\n'
                      '${item.message ?? '-'}',
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
