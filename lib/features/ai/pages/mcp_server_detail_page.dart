import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/ai/mcp_server_service.dart';

/// MCP Server detail page.
/// Mirrors frontend's mcp/server/config page: shows server config, connection test, status sync.
class McpServerDetailPage extends StatefulWidget {
  const McpServerDetailPage({
    super.key,
    required this.serverId,
    required this.serverName,
  });

  final int serverId;
  final String serverName;

  @override
  State<McpServerDetailPage> createState() => _McpServerDetailPageState();
}

class _McpServerDetailPageState extends State<McpServerDetailPage> {
  final McpServerService _service = McpServerService();
  Map<String, dynamic>? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await _service.getServerDetail(widget.serverId);
      if (mounted) setState(() { _detail = result; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _testConnection() async {
    try {
      final result = await _service.testConnection(widget.serverId);
      final success = result['success'] == true;
      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          success ? 'Connection OK' : 'Connection failed',
        );
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, context.l10n.mcpServerDetailTestFailed);
    }
  }

  Future<void> _syncStatus() async {
    try {
      await _service.syncStatus(widget.serverId);
      if (mounted) SnackBarUtils.showSuccess(context, context.l10n.mcpServerDetailSynced);
      _loadDetail();
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, context.l10n.mcpServerDetailSyncFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.serverName),
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi_protected_setup),
            tooltip: context.l10n.mcpServerDetailSyncStatus,
            onPressed: _syncStatus,
          ),
          IconButton(
            icon: const Icon(Icons.plagiarism_outlined),
            tooltip: context.l10n.commonTestConnection,
            onPressed: _testConnection,
          ),
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh_outlined), onPressed: _loadDetail),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _detail == null
                  ?  Center(child: Text(context.l10n.commonEmpty))
                  : ListView(
                      padding: AppDesignTokens.cardPadding,
                      children: [
                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                title:  Text(context.l10n.mcpServerDetailServerName),
                                subtitle: Text(_detail?['name']?.toString() ?? ''),
                              ),
                              ListTile(
                                title:  Text(context.l10n.aiMcpStatusLabel),
                                subtitle: Text(_detail?['status']?.toString() ?? 'unknown'),
                                trailing: Icon(
                                  _detail?['status'] == 'running'
                                      ? Icons.check_circle
                                      : Icons.error_outline,
                                  color: _detail?['status'] == 'running'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                              ListTile(
                                title:  Text(context.l10n.commonUrl),
                                subtitle: Text(_detail?['url']?.toString() ?? ''),
                              ),
                              ListTile(
                                title:  Text(context.l10n.aiMcpTransportLabel),
                                subtitle: Text(_detail?['transport']?.toString() ?? ''),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}
