import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/api/v2/website_v2.dart';

/// Website load balancer detail page.
/// Mirrors frontend's website load-balance tab: upstream management.
class WebsiteLoadBalancerPage extends StatefulWidget {
  const WebsiteLoadBalancerPage({
    super.key,
    required this.websiteId,
    required this.displayName,
  });

  final int websiteId;
  final String displayName;

  @override
  State<WebsiteLoadBalancerPage> createState() =>
      _WebsiteLoadBalancerPageState();
}

class _WebsiteLoadBalancerPageState extends State<WebsiteLoadBalancerPage> {
  List<Map<String, dynamic>> _balancers = [];
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
      final api = WebsiteV2Api(await ApiClientManager.instance.getCurrentClient());
      final result = await api.getWebsiteLoadBalancers(widget.websiteId);
      if (mounted) setState(() { _balancers = result; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _deleteBalancer(int id) async {
    try {
      final api = WebsiteV2Api(await ApiClientManager.instance.getCurrentClient());
      await api.deleteWebsiteLoadBalancer({'id': id});
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
        title: Text('${widget.displayName} - ${context.l10n.websiteLoadBalancerTitle}'),
        actions: [
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _balancers.isEmpty
                  ?  Center(child: Text(context.l10n.websiteLoadBalancerEmpty))
                  : ListView.builder(
                      itemCount: _balancers.length,
                      itemBuilder: (context, index) {
                        final lb = _balancers[index];
                        return Card(
                          child: ListTile(
                            title: Text(lb['server']?.toString() ?? ''),
                            subtitle: Text(
                              'Weight: ${lb['weight'] ?? 1} | '
                              'Max Fails: ${lb['maxFails'] ?? 0} | '
                              'Fail Timeout: ${lb['failTimeout'] ?? '10s'}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: context.l10n.commonDelete,
                              onPressed: () => _deleteBalancer(lb['id'] as int),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
