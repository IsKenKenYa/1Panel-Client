import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/api/v2/database_v2.dart';

/// MySQL slow query log page.
/// Mirrors frontend's database/mysql slow-log tab.
class DatabaseSlowLogPage extends StatefulWidget {
  const DatabaseSlowLogPage({
    super.key,
    required this.databaseName,
  });

  final String databaseName;

  @override
  State<DatabaseSlowLogPage> createState() => _DatabaseSlowLogPageState();
}

class _DatabaseSlowLogPageState extends State<DatabaseSlowLogPage> {
  List<dynamic> _logs = [];
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
      final api = DatabaseV2Api(await ApiClientManager.instance.getCurrentClient());
      // MySQL variables endpoint also returns slow-log related settings
      final response = await api.loadMysqlVariables(
        type: 'mysql',
        name: widget.databaseName,
      );
      if (mounted) {
        final data = response.data ?? {};
        final slowLogEntries = data['slowLogs'] as List? ?? [];
        setState(() {
          _logs = slowLogEntries;
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
        title:  Text(context.l10n.databaseSlowLogTitle),
        actions: [
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh_outlined), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _logs.isEmpty
                  ?  Center(child: Text(context.l10n.databaseSlowLogEmpty))
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index] as Map? ?? {};
                        return Card(
                          child: ListTile(
                            title: Text(log['sql']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${context.l10n.databaseSlowLogTimeWith(log['time'] ?? 'N/A')} | ${context.l10n.databaseSlowLogDuration}: ${log['duration'] ?? 'N/A'}s'),
                            dense: true,
                          ),
                        );
                      },
                    ),
    );
  }
}
