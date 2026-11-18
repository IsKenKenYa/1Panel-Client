import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/files/services/file_transfer_service.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';

/// File share management page.
/// Mirrors frontend's file share list: create/delete/search shared links.
class FileSharePage extends StatefulWidget {
  const FileSharePage({super.key});

  @override
  State<FileSharePage> createState() => _FileSharePageState();
}

class _FileSharePageState extends State<FileSharePage> {
  final FileTransferService _service = FileTransferService();
  List<Map<String, dynamic>> _shares = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShares();
  }

  Future<void> _loadShares() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await _service.searchShares();
      if (mounted) setState(() { _shares = result; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _deleteShare(String shareId) async {
    try {
      await _service.deleteShare(shareId);
      if (mounted) SnackBarUtils.showSuccess(context, context.l10n.commonDeleted);
      _loadShares();
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, context.l10n.commonDeleteFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title:  Text(context.l10n.fileShareTitle),
        actions: [
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh_outlined), onPressed: _loadShares),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ModuleErrorStateWidget(message: _error, onRetry: _loadShares)
              : _shares.isEmpty
                  ?  Center(child: Text(context.l10n.fileShareEmpty))
                  : ListView.builder(
                      itemCount: _shares.length,
                      itemBuilder: (context, index) {
                        final share = _shares[index];
                        return Card(
                          child: ListTile(
                            title: Text(share['name']?.toString() ?? ''),
                            subtitle: Text(share['path']?.toString() ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: context.l10n.commonDelete,
                              onPressed: () => _deleteShare(share['id']?.toString() ?? ''),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
