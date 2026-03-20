import 'package:flutter/material.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/features/containers/providers/container_detail_provider.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/shared/widgets/log_viewer/log_viewer.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<ContainerDetailProvider>();

    if (provider.logs != _lastLogs) {
      _lastLogs = provider.logs;
      _controller.setLogs(provider.logs);
    }

    if (provider.logsLoading && _controller.logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.logsError != null && _controller.logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.containerOperateFailed(provider.logsError!),
              style: TextStyle(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: provider.loadLogs,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    return LogViewer(
      controller: _controller,
      onRefresh: provider.loadLogs,
      emptyMessage: l10n.containerNoLogs,
    );
  }
}
