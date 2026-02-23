import 'package:flutter/material.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/features/containers/container_service.dart';
import 'package:onepanelapp_app/shared/widgets/log_viewer/log_viewer.dart';

class ContainerLogsView extends StatefulWidget {
  final String containerName;

  const ContainerLogsView({
    super.key,
    required this.containerName,
  });

  @override
  State<ContainerLogsView> createState() => _ContainerLogsViewState();
}

class _ContainerLogsViewState extends State<ContainerLogsView> {
  final _service = ContainerService();
  final _controller = LogViewerController();
  
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final logs = await _service.getContainerLogs(widget.containerName, tail: '1000');
      if (!mounted) return;
      
      _controller.setLogs(logs);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading && _controller.logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _controller.logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.containerOperateFailed(_error!),
              style: TextStyle(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadLogs,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    return LogViewer(
      controller: _controller,
      onRefresh: _loadLogs,
      emptyMessage: l10n.containerNoLogs,
    );
  }
}
