import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/api/v2/file_v2.dart';

/// Recycle bin status management page.
/// Mirrors frontend's file recycle status tab.
class RecycleBinStatusPage extends StatefulWidget {
  const RecycleBinStatusPage({super.key});

  @override
  State<RecycleBinStatusPage> createState() => _RecycleBinStatusPageState();
}

class _RecycleBinStatusPageState extends State<RecycleBinStatusPage> {
  Map<String, dynamic>? _status;
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
      final api = FileV2Api(await ApiClientManager.instance.getCurrentClient());
      final response = await api.getRecycleBinStatus();
      if (mounted) {
        setState(() {
          _status = response.data is Map
              ? Map<String, dynamic>.from(response.data as Map)
              : const <String, dynamic>{};
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
        title:  Text(context.l10n.recycleBinStatusTitle),
        actions: [
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh_outlined), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _status == null
                  ?  Center(child: Text(context.l10n.commonEmpty))
                  : ListView(
                      padding: AppDesignTokens.cardPadding,
                      children: [
                        Card(
                          child: ListTile(
                            title:  Text(context.l10n.recycleBinTitle),
                            subtitle: Text(
                              'Status: ${_status?['status'] ?? 'unknown'} | '
                              'Size: ${_status?['size'] ?? 'N/A'}',
                            ),
                            trailing: Icon(
                              _status?['status'] == 'Enable'
                                  ? Icons.delete_outline
                                  : Icons.delete_forever,
                              color: _status?['status'] == 'Enable'
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
