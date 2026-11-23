import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/website_log_models.dart';
import 'package:onepanel_client/data/repositories/website_config_repository.dart';
import 'package:onepanel_client/features/websites/widgets/website_async_state_view.dart';

/// Website log viewer page (access/error logs).
class WebsiteLogPage extends StatefulWidget {
  const WebsiteLogPage({
    super.key,
    required this.websiteId,
    required this.displayName,
  });

  final int websiteId;
  final String displayName;

  @override
  State<WebsiteLogPage> createState() => _WebsiteLogPageState();
}

class _WebsiteLogPageState extends State<WebsiteLogPage> {
  final WebsiteConfigRepository _repo = WebsiteConfigRepository();
  WebsiteLogContent _logContent = const WebsiteLogContent();
  String _logType = 'access.log';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final content = await _repo.loadWebsiteLog(
        websiteId: widget.websiteId,
        logType: _logType,
      );
      if (mounted) {
        setState(() {
          _logContent = content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('${widget.displayName} - ${context.l10n.commonLogs}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: context.l10n.websiteLogClear,
            onPressed: () async {
              await _repo.operateWebsiteLog({
                'websiteId': widget.websiteId,
                'operate': 'clear',
              });
              _load();
            },
          ),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'access.log', label: Text('access.log')),
              ButtonSegment(value: 'error.log', label: Text('error.log')),
            ],
            selected: {_logType},
            onSelectionChanged: (selection) {
              final type = selection.first;
              if (type == _logType) return;
              setState(() => _logType = type);
              _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: context.l10n.commonRefresh,
            onPressed: _load,
          ),
        ],
      ),
      body: WebsiteAsyncStateView(
        isLoading: _isLoading,
        error: _error,
        onRetry: _load,
        child: !_logContent.enable || _logContent.lines.isEmpty
            ? Center(child: Text(context.l10n.websiteLogEmpty))
            : ListView.builder(
                itemCount: _logContent.lines.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      _logContent.lines[index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                    dense: true,
                  );
                },
              ),
      ),
    );
  }
}
