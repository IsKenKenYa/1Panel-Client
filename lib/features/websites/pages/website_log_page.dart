import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
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
  List<Map<String, dynamic>> _logs = [];
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
      final result = await _repo.searchWebsiteLogs({
        'websiteId': widget.websiteId,
        'page': 1,
        'pageSize': 50,
      });
      if (mounted) setState(() { _logs = result; _isLoading = false; });
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
        child: _logs.isEmpty
            ?  Center(child: Text(context.l10n.websiteLogEmpty))
            : ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  return ListTile(
                    title: Text(log['message']?.toString() ?? ''),
                    subtitle: Text(log['time']?.toString() ?? ''),
                    dense: true,
                  );
                },
              ),
      ),
    );
  }
}
