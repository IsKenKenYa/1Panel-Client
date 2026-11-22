import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/api/v2/host_tool_v2.dart';
import 'package:onepanel_client/data/models/host_tool_models.dart';

/// Supervisor process management page.
/// Mirrors frontend's toolbox/supervisor page: list/create/operate/config/file.
class ToolboxSupervisorPage extends StatefulWidget {
  const ToolboxSupervisorPage({super.key});

  @override
  State<ToolboxSupervisorPage> createState() => _ToolboxSupervisorPageState();
}

class _ToolboxSupervisorPageState extends State<ToolboxSupervisorPage> {
  List<dynamic> _processes = [];
  bool _isLoading = true;
  String? _error;
  HostToolStatusResponse? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final api = HostToolV2Api(await ApiClientManager.instance.getCurrentClient());
      final statusResponse = await api.getToolStatus(HostToolRequest(type: 'supervisord'));
      final processResponse = await api.getSupervisorProcesses();
      if (mounted) {
        setState(() {
          _status = statusResponse.data;
          _processes = (processResponse.data ?? const []).map((e) => {'name': e.name, 'status': e.status.isNotEmpty ? e.status.first.status : 'unknown', 'pid': e.status.isNotEmpty ? e.status.first.pid : 'N/A'}).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _operateProcess(String name, String operate) async {
    try {
      final api = HostToolV2Api(await ApiClientManager.instance.getCurrentClient());
      await api.operateSupervisorProcess(
        HostToolProcessOperateRequest(name: name, operate: operate),
      );
      if (mounted) SnackBarUtils.showSuccess(context, '${_operateLabel(operate)} $name');
      _load();
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, context.l10n.commonOperationFailed);
    }
  }

  String _operateLabel(String operate) {
    switch (operate) {
      case 'start':
        return context.l10n.commonStart;
      case 'stop':
        return context.l10n.commonStop;
      case 'restart':
        return context.l10n.commonRestart;
      default:
        return operate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title:  Text(context.l10n.toolboxSupervisorTitle),
        actions: [
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh_outlined), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    if (_status != null)
                      Card(
                        margin: AppDesignTokens.cardPadding,
                        child: ListTile(
                          title:  Text(context.l10n.toolboxSupervisorStatusTitle),
                          subtitle: Text('${context.l10n.commonStatus}: ${_status?.config.init ?? false ? context.l10n.appStatusRunning : context.l10n.toolboxSupervisorNotInit}'),
                          trailing: Icon(
                            _status?.config.init == true ? Icons.check_circle : Icons.error_outline,
                            color: _status?.config.init == true ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    Expanded(
                      child: _processes.isEmpty
                          ?  Center(child: Text(context.l10n.toolboxSupervisorEmpty))
                          : ListView.builder(
                              itemCount: _processes.length,
                              itemBuilder: (context, index) {
                                final p = _processes[index] as Map? ?? {};
                                final status = p['status']?.toString() ?? '';
                                final isRunning = status == 'RUNNING';
                                return Card(
                                  child: ListTile(
                                    title: Text(p['name']?.toString() ?? ''),
                                    subtitle: Text('${context.l10n.commonStatus}: $status | PID: ${p['pid'] ?? 'N/A'}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(tooltip: context.l10n.commonStop, 
                                          icon: Icon(isRunning ? Icons.pause : Icons.play_arrow_outlined),
                                          onPressed: () => _operateProcess(
                                            p['name']?.toString() ?? '',
                                            isRunning ? 'stop' : 'start',
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.restart_alt),
                                          tooltip: context.l10n.commonRestart,
                                          onPressed: () => _operateProcess(
                                            p['name']?.toString() ?? '',
                                            'restart',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
