import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/logs/providers/logs_provider.dart';
import 'package:onepanel_client/features/logs/utils/logs_l10n_helper.dart';
import 'package:onepanel_client/features/logs/widgets/login_log_card_widget.dart';
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              TextField(
                controller: ipController,
                onChanged: provider.updateLoginIp,
                onSubmitted: (_) => provider.loadLoginLogs(),
                decoration: InputDecoration(
                  labelText: l10n.logsLoginIpLabel,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  _StatusChip(
                    label: l10n.logsStatusAll,
                    selected: provider.loginStatus.isEmpty,
                    onTap: () async {
                      provider.updateLoginStatus('');
                      await provider.loadLoginLogs();
                    },
                  ),
                  _StatusChip(
                    label: l10n.logsStatusSuccess,
                    selected: provider.loginStatus == 'Success',
                    onTap: () async {
                      provider.updateLoginStatus('Success');
                      await provider.loadLoginLogs();
                    },
                  ),
                  _StatusChip(
                    label: l10n.logsStatusFailed,
                    selected: provider.loginStatus == 'Failed',
                    onTap: () async {
                      provider.updateLoginStatus('Failed');
                      await provider.loadLoginLogs();
                    },
                  ),
                ],
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
