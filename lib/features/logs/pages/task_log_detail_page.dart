import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/logs/models/task_log_detail_args.dart';
import 'package:onepanel_client/features/logs/providers/task_logs_provider.dart';
import 'package:onepanel_client/features/logs/utils/logs_l10n_helper.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/log_viewer/log_viewer.dart';
import 'package:onepanel_client/shared/widgets/operations/module_empty_state_widget.dart';
import 'package:provider/provider.dart';

class TaskLogDetailPage extends StatefulWidget {
  const TaskLogDetailPage({
    super.key,
    required this.args,
  });

  final TaskLogDetailArgs args;

  @override
  State<TaskLogDetailPage> createState() => _TaskLogDetailPageState();
}

class _TaskLogDetailPageState extends State<TaskLogDetailPage> {
  final LogViewerController _controller = LogViewerController();
  String _lastContent = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<TaskLogsProvider>().initializeDetail(widget.args);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copyContent(TaskLogsProvider provider) async {
    await Clipboard.setData(ClipboardData(text: provider.detailContent));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.commonCopySuccess)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<TaskLogsProvider>(
      builder: (context, provider, _) {
        if (provider.detailContent != _lastContent) {
          _lastContent = provider.detailContent;
          _controller.setLogs(provider.detailContent);
        }
        return ServerAwarePageScaffold(
          title: l10n.operationsTaskLogDetailTitle,
          onServerChanged: () =>
              context.read<TaskLogsProvider>().initializeDetail(widget.args),
          actions: <Widget>[
            IconButton(
              onPressed: provider.detailContent.isEmpty
                  ? null
                  : () => _copyContent(provider),
              icon: const Icon(Icons.copy_outlined),
              tooltip: l10n.commonCopy,
            ),
            IconButton(
              onPressed: provider.detailLoading ? null : provider.loadDetail,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
            ),
          ],
          body: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: _MetadataCard(args: widget.args),
              ),
              Expanded(child: _buildBody(provider, l10n)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(TaskLogsProvider provider, dynamic l10n) {
    if (provider.detailLoading && _controller.logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.detailError != null && _controller.logs.isEmpty) {
      final message = localizeLogsError(l10n, provider.detailError) ??
          l10n.commonUnknownError;
      return Center(
        child: FilledButton.icon(
          onPressed: provider.loadDetail,
          icon: const Icon(Icons.refresh),
          label: Text(message),
        ),
      );
    }
    if (provider.detailContent.trim().isEmpty) {
      return ModuleEmptyStateWidget(
        title: l10n.operationsTaskLogDetailTitle,
        description: l10n.logNoLogs,
        icon: Icons.article_outlined,
      );
    }
    return LogViewer(
      controller: _controller,
      onRefresh: provider.loadDetail,
      emptyMessage: l10n.logNoLogs,
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({
    required this.args,
  });

  final TaskLogDetailArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(args.taskName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('${l10n.logsTaskDetailIdLabel}: ${args.taskId}'),
            Text('${l10n.logsTaskDetailTypeLabel}: ${args.taskType}'),
            Text('${l10n.logsTaskDetailStatusLabel}: ${args.status}'),
            if ((args.currentStep ?? '').isNotEmpty)
              Text(
                  '${l10n.logsTaskDetailCurrentStepLabel}: ${args.currentStep}'),
            if ((args.createdAt ?? '').isNotEmpty)
              Text('${l10n.logsTaskDetailCreatedAtLabel}: ${args.createdAt}'),
            if ((args.logFile ?? '').isNotEmpty)
              Text('${l10n.logsTaskDetailLogFileLabel}: ${args.logFile}'),
          ],
        ),
      ),
    );
  }
}
