import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/api/v2/database_v2.dart';

/// Redis persistence configuration page.
/// Mirrors frontend's database/redis persistence tab.
class DatabaseRedisPersistencePage extends StatefulWidget {
  const DatabaseRedisPersistencePage({
    super.key,
    required this.databaseName,
  });

  final String databaseName;

  @override
  State<DatabaseRedisPersistencePage> createState() =>
      _DatabaseRedisPersistencePageState();
}

class _DatabaseRedisPersistencePageState
    extends State<DatabaseRedisPersistencePage> {
  Map<String, dynamic>? _config;
  bool _isLoading = true;
  bool _isSaving = false;
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
      final response = await api.loadRedisPersistenceConf(
        type: 'redis',
        name: widget.databaseName,
      );
      if (mounted) {
        setState(() {
          _config = response.data ?? const <String, dynamic>{};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _update(Map<String, dynamic> request) async {
    setState(() => _isSaving = true);
    try {
      final api = DatabaseV2Api(await ApiClientManager.instance.getCurrentClient());
      await api.updateRedisPersistenceConf(request);
      if (mounted) SnackBarUtils.showSuccess(context, context.l10n.commonUpdated);
      _load();
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, context.l10n.commonUpdateFailed);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title:  Text(context.l10n.databaseRedisPersistenceTitle),
        actions: [
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh_outlined), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _config == null
                  ?  Center(child: Text(context.l10n.commonEmpty))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Column(
                            children: [
                              SwitchListTile(
                                title:  Text(context.l10n.databaseRedisAofTitle),
                                subtitle:  Text(context.l10n.databaseRedisAofDesc),
                                value: _config?['aofEnable'] == true,
                                onChanged: _isSaving
                                    ? null
                                    : (v) => _update({
                                          'database': widget.databaseName,
                                          'aofEnable': v,
                                        }),
                              ),
                              SwitchListTile(
                                title:  Text(context.l10n.databaseRedisRdbTitle),
                                subtitle:  Text(context.l10n.databaseRedisRdbDesc),
                                value: _config?['rdbEnable'] == true,
                                onChanged: _isSaving
                                    ? null
                                    : (v) => _update({
                                          'database': widget.databaseName,
                                          'rdbEnable': v,
                                        }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}
