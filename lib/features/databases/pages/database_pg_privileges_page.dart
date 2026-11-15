import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/api/v2/database_v2.dart';
import 'package:onepanel_client/data/models/database_models.dart';

/// PostgreSQL privileges management page.
/// Mirrors frontend's database/postgresql privileges tab.
class DatabasePgPrivilegesPage extends StatefulWidget {
  const DatabasePgPrivilegesPage({
    super.key,
    required this.databaseName,
  });

  final String databaseName;

  @override
  State<DatabasePgPrivilegesPage> createState() =>
      _DatabasePgPrivilegesPageState();
}

class _DatabasePgPrivilegesPageState extends State<DatabasePgPrivilegesPage> {
  List<dynamic> _privileges = [];
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
      final response = await api.searchPostgresqlDatabases(
        DatabaseSearch(database: widget.databaseName),
      );
      if (mounted) {
        setState(() {
          _privileges = (response.data?.items ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
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
        title:  Text(context.l10n.databasePgPrivilegesTitle),
        actions: [
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _privileges.isEmpty
                  ?  Center(child: Text(context.l10n.databasePgPrivilegesEmpty))
                  : ListView.builder(
                      itemCount: _privileges.length,
                      itemBuilder: (context, index) {
                        final p = _privileges[index] as Map? ?? {};
                        return Card(
                          child: ListTile(
                            title: Text(p['name']?.toString() ?? ''),
                            subtitle: Text(context.l10n.databasePgPrivilegeWith(p['privileges'] ?? 'N/A')),
                          ),
                        );
                      },
                    ),
    );
  }
}
