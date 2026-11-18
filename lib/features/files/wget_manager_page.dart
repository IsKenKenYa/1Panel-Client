import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/files/services/file_transfer_service.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';

/// WGET download manager page.
/// Mirrors frontend's wget process list: shows active/completed downloads.
class WgetManagerPage extends StatefulWidget {
  const WgetManagerPage({super.key});

  @override
  State<WgetManagerPage> createState() => _WgetManagerPageState();
}

class _WgetManagerPageState extends State<WgetManagerPage> {
  final FileTransferService _service = FileTransferService();
  Map<String, dynamic>? _processData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProcess();
  }

  Future<void> _loadProcess() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await _service.getWgetProcess();
      if (mounted) setState(() { _processData = result; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _stopWget(String key) async {
    try {
      await _service.stopWget(key);
      if (mounted) SnackBarUtils.showSuccess(context, context.l10n.wgetStopped);
      _loadProcess();
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, context.l10n.wgetStopFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title:  Text(context.l10n.wgetTitle),
        actions: [
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh_outlined), onPressed: _loadProcess),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ModuleErrorStateWidget(message: _error, onRetry: _loadProcess)
              : _processData == null || _processData!.isEmpty
                  ?  Center(child: Text(context.l10n.wgetEmpty))
                  : ListView.builder(
                      itemCount: (_processData!['data'] as List?)?.length ?? 0,
                      itemBuilder: (context, index) {
                        final item = (_processData!['data'] as List)[index]
                            as Map<String, dynamic>;
                        return Card(
                          child: ListTile(
                            title: Text(item['name']?.toString() ?? ''),
                            subtitle: Text(item['url']?.toString() ?? ''),
                            trailing: item['status'] == 'running'
                                ? IconButton(
                                    icon: const Icon(Icons.stop),
                                    tooltip: context.l10n.commonStop,
                                    onPressed: () => _stopWget(
                                        item['key']?.toString() ?? ''),
                                  )
                                : const Icon(Icons.check_circle,
                                    color: Colors.green),
                          ),
                        );
                      },
                    ),
    );
  }
}
