import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/api/v2/database_v2.dart';

/// MySQL variables & slow-log configuration page.
/// Mirrors frontend's database/mysql variables and slow-log tabs.
class DatabaseMysqlVariablesPage extends StatefulWidget {
  const DatabaseMysqlVariablesPage({super.key, required this.databaseName});

  final String databaseName;

  @override
  State<DatabaseMysqlVariablesPage> createState() =>
      _DatabaseMysqlVariablesPageState();
}

class _DatabaseMysqlVariablesPageState
    extends State<DatabaseMysqlVariablesPage> {
  Map<String, dynamic>? _variables;
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
      final response = await api.loadMysqlVariables(
        type: 'mysql',
        name: widget.databaseName,
      );
      if (mounted) setState(() { _variables = response.data ?? {}; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title:  Text(context.l10n.databaseMysqlVariablesTitle),
        actions: [
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh_outlined), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _variables == null || _variables!.isEmpty
                  ?  Center(child: Text(context.l10n.databaseMysqlVariablesEmpty))
                  : ListView.builder(
                      itemCount: _variables!.keys.length,
                      itemBuilder: (context, index) {
                        final key = _variables!.keys.elementAt(index);
                        return ListTile(
                          title: Text(key),
                          subtitle: Text(_variables![key]?.toString() ?? ''),
                          dense: true,
                        );
                      },
                    ),
    );
  }
}
