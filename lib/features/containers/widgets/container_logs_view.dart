import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/partial_error_toast_listener.dart';
import 'package:onepanel_client/features/containers/providers/container_detail_provider.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/shared/widgets/log_viewer/log_viewer.dart';

class ContainerLogsView extends StatefulWidget {
  const ContainerLogsView({super.key});

  @override
  State<ContainerLogsView> createState() => _ContainerLogsViewState();
}

class _ContainerLogsViewState extends State<ContainerLogsView> {
  final _controller = LogViewerController();
  String _lastLogs = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<ContainerDetailProvider>();

    // Only push logs to the controller when content actually changes;
    // provider may notify without new data (e.g., loading state toggles).
    if (provider.logs != _lastLogs) {
      _lastLogs = provider.logs;
      _controller.setLogs(provider.logs);
    }

    if (provider.logsLoading && _controller.logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.logsError != null && _controller.logs.isEmpty) {
      return ModuleErrorStateWidget(
        message: l10n.containerOperateFailed(provider.logsError!),
        onRetry: provider.loadLogs,
      );
    }

    return PartialErrorToastListener(
      errorMessage: provider.logsError != null
          ? l10n.containerOperateFailed(provider.logsError!)
          : null,
      hasCachedData: _controller.logs.isNotEmpty,
      onRetry: provider.loadLogs,
      child: Column(
        children: [
          _FollowBar(provider: provider),
          Expanded(
            child: LogViewer(
              controller: _controller,
              onRefresh: provider.loadLogs,
              emptyMessage: l10n.containerNoLogs,
            ),
          ),
        ],
      ),
    );
  }
}

/// 跟随状态条：显示当前是否持续接收日志，并提供停止跟随与恢复跟随。
class _FollowBar extends StatelessWidget {
  const _FollowBar({required this.provider});

  final ContainerDetailProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: scheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(
            provider.followLogs ? Icons.podcasts : Icons.pause_circle_outline,
            size: 18,
            color:
                provider.followLogs ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.followLogs
                  ? l10n.containerLogsFollowing
                  : l10n.containerLogsFollowPaused,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton.icon(
            onPressed: provider.followLogs
                ? provider.stopFollowing
                : () => provider.loadLogs(follow: true),
            icon: Icon(provider.followLogs ? Icons.stop : Icons.play_arrow),
            label: Text(
              provider.followLogs
                  ? l10n.containerLogsStopFollow
                  : l10n.containerLogsResumeFollow,
            ),
          ),
        ],
      ),
    );
  }
}
