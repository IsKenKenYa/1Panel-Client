import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/ai/agent_account_models.dart';
import 'package:onepanel_client/features/ai/ai_repository.dart';

/// AI model accounts management page.
/// Mirrors frontend's ai/model page: list/create/update/delete AI accounts
/// and their model pools.
class AiAccountsPage extends StatefulWidget {
  const AiAccountsPage({super.key});

  @override
  State<AiAccountsPage> createState() => _AiAccountsPageState();
}

class _AiAccountsPageState extends State<AiAccountsPage> {
  final AIRepository _repo = AIRepository();
  List<Map<String, dynamic>> _accounts = [];
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
      final api = await _repo.getApi();
      final response = await api.pageAgentAccounts(const AgentAccountSearch());
      final data = response.data;
      if (mounted) {
        setState(() {
          _accounts = (data?.items ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _deleteAccount(int id) async {
    try {
      final api = await _repo.getApi();
      await api.deleteAgentAccount(AgentAccountDeleteReq(id: id));
      if (mounted) SnackBarUtils.showSuccess(context, context.l10n.commonDeleted);
      _load();
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, context.l10n.commonDeleteFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title:  Text(context.l10n.aiAccountsTitle),
        actions: [
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh_outlined), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child:  Text(context.l10n.commonRetry)),
                    ],
                  ),
                )
              : _accounts.isEmpty
                  ?  Center(child: Text(context.l10n.aiAccountsEmpty))
                  : ListView.builder(
                      itemCount: _accounts.length,
                      itemBuilder: (context, index) {
                        final account = _accounts[index];
                        return Card(
                          child: ListTile(
                            title: Text(account['name']?.toString() ?? ''),
                            subtitle: Text(
                              'Type: ${account['type'] ?? 'N/A'} | '
                              'Models: ${account['modelCount'] ?? 0}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: context.l10n.commonDelete,
                              onPressed: () =>
                                  _deleteAccount(account['id'] as int),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
