import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/api/v2/database_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';

/// Database remote connection config page (edit existing remote DB entry).
/// Mirrors frontend `database/*/remote/operate`: load config, test connection,
/// then submit update via /databases/db/update.
class DatabaseRemoteConfigPage extends StatefulWidget {
  const DatabaseRemoteConfigPage({
    super.key,
    required this.databaseName,
    required this.databaseType,
  });

  final String databaseName;
  final String databaseType;

  @override
  State<DatabaseRemoteConfigPage> createState() =>
      _DatabaseRemoteConfigPageState();
}

class _DatabaseRemoteConfigPageState extends State<DatabaseRemoteConfigPage> {
  Map<String, dynamic> _config = {};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTesting = false;
  bool _connOk = false;
  String? _error;
  final _addressController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _versionController = TextEditingController();
  final _timeoutController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _versionController.dispose();
    _timeoutController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _field(String key) => _config[key]?.toString() ?? '';

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _connOk = false;
    });
    try {
      final api =
          DatabaseV2Api(await ApiClientManager.instance.getCurrentClient());
      final response = await api.getRemoteDatabase(widget.databaseName);
      final data = response.data ?? <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _config = data;
        _addressController.text = _field('address');
        _portController.text = _field('port');
        _usernameController.text = _field('username');
        _passwordController.text = _field('password');
        _versionController.text = _field('version');
        _timeoutController.text = _field('timeout');
        _descriptionController.text = _field('description');
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _buildRequest() {
    final request = Map<String, dynamic>.from(_config);
    request['name'] = widget.databaseName;
    request['type'] = widget.databaseType;
    request['from'] = 'remote';
    request['address'] = _addressController.text.trim();
    request['port'] = int.tryParse(_portController.text.trim()) ?? 0;
    request['username'] = _usernameController.text.trim();
    request['password'] = _passwordController.text;
    request['version'] = _versionController.text.trim();
    request['timeout'] = int.tryParse(_timeoutController.text.trim()) ?? 30;
    request['description'] = _descriptionController.text.trim();
    return request;
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);
    try {
      final api =
          DatabaseV2Api(await ApiClientManager.instance.getCurrentClient());
      final response = await api.checkRemoteDatabase(_buildRequest());
      final ok = response.data ?? false;
      if (!mounted) return;
      setState(() => _connOk = ok);
      if (ok) {
        SnackBarUtils.showSuccess(context, context.l10n.commonTestPassed);
      } else {
        SnackBarUtils.showError(context, context.l10n.commonTestFailed);
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, context.l10n.commonTestFailed);
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _save() async {
    if (!_connOk) {
      SnackBarUtils.showError(context, context.l10n.databaseRemoteTestBeforeSave);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final api =
          DatabaseV2Api(await ApiClientManager.instance.getCurrentClient());
      await api.updateRemoteDatabase(_buildRequest());
      if (mounted) SnackBarUtils.showSuccess(context, context.l10n.commonSaveSuccess);
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, context.l10n.commonSaveFailed);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('${widget.databaseName} - ${context.l10n.databaseRemoteTitle}'),
        actions: [
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      TextButton(onPressed: _load, child:  Text(context.l10n.commonRetry)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextField(
                              controller: _addressController,
                              onChanged: (_) =>
                                  setState(() => _connOk = false),
                              decoration:  InputDecoration(
                                labelText: context.l10n.commonAddress,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _portController,
                              onChanged: (_) =>
                                  setState(() => _connOk = false),
                              decoration:  InputDecoration(
                                labelText: context.l10n.commonPort,
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _usernameController,
                              onChanged: (_) =>
                                  setState(() => _connOk = false),
                              decoration:  InputDecoration(
                                labelText: context.l10n.commonUsername,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _passwordController,
                              onChanged: (_) =>
                                  setState(() => _connOk = false),
                              decoration:  InputDecoration(
                                labelText: context.l10n.commonPassword,
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _versionController,
                              onChanged: (_) =>
                                  setState(() => _connOk = false),
                              decoration:  InputDecoration(
                                labelText: context.l10n.commonVersion,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _timeoutController,
                              onChanged: (_) =>
                                  setState(() => _connOk = false),
                              decoration:  InputDecoration(
                                labelText: context.l10n.databaseRemoteTimeoutLabel,
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _descriptionController,
                              decoration:  InputDecoration(
                                labelText: context.l10n.commonDescription,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isTesting || _isSaving
                                        ? null
                                        : _testConnection,
                                    icon: _isTesting
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : const Icon(Icons.network_check),
                                    label:  Text(context.l10n.commonTestConnection),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed:
                                        _isSaving || !_connOk ? null : _save,
                                    icon: _isSaving
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : const Icon(Icons.save),
                                    label:  Text(context.l10n.commonSave),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
