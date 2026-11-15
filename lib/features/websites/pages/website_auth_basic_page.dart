import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/api/v2/website_v2.dart';
import 'package:onepanel_client/features/websites/widgets/website_async_state_view.dart';

/// Website HTTP basic authentication page.
/// Mirrors frontend's website auth-basic tab.
class WebsiteAuthBasicPage extends StatefulWidget {
  const WebsiteAuthBasicPage({
    super.key,
    required this.websiteId,
    required this.displayName,
  });

  final int websiteId;
  final String displayName;

  @override
  State<WebsiteAuthBasicPage> createState() => _WebsiteAuthBasicPageState();
}

class _WebsiteAuthBasicPageState extends State<WebsiteAuthBasicPage> {
  Future<WebsiteV2Api> _getApi() async => WebsiteV2Api(await ApiClientManager.instance.getCurrentClient());
  List<Map<String, dynamic>> _users = [];
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
      final api = await _getApi();
      final result = await api.getWebsiteAuthConfig({'websiteId': widget.websiteId});
      if (mounted) {
        final list = result['data'] as List? ?? [];
        setState(() {
          _users = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _deleteUser(int userId) async {
    try {
      final api = await _getApi();
      await api.updateWebsiteAuthConfig({'websiteId': widget.websiteId, 'id': userId, 'operate': 'delete'});
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
      appBar: AppBar(title: Text('${widget.displayName} - ${context.l10n.websiteAuthBasicTitle}')),
      body: WebsiteAsyncStateView(
        isLoading: _isLoading,
        error: _error,
        onRetry: _load,
        child: _users.isEmpty
            ?  Center(child: Text(context.l10n.websiteAuthBasicEmpty))
            : ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return Card(
                    child: ListTile(
                      title: Text(user['username']?.toString() ?? ''),
                      subtitle: Text(user['remark']?.toString() ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: context.l10n.commonDelete,
                        onPressed: () => _deleteUser(user['id'] as int),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
