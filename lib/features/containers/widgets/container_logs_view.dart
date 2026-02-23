import 'package:flutter/material.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/features/containers/container_service.dart';

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
  String _logs = '';
  bool _isLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
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
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
      // Scroll to bottom after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
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

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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

    if (_logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 48, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(l10n.containerNoLogs),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadLogs,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRefresh),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: _loadLogs,
                icon: const Icon(Icons.refresh),
                tooltip: l10n.commonRefresh,
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectionArea(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Text(
                  _logs,
                  style: TextStyle(
                    fontFamily: 'Monospace',
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
