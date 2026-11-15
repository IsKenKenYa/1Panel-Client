import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/repositories/website_config_repository.dart';
import 'package:onepanel_client/features/websites/widgets/website_async_state_view.dart';

/// Website redirect rules configuration page.
/// Mirrors frontend's website redirect tab.
class WebsiteRedirectPage extends StatefulWidget {
  const WebsiteRedirectPage({
    super.key,
    required this.websiteId,
    required this.displayName,
  });

  final int websiteId;
  final String displayName;

  @override
  State<WebsiteRedirectPage> createState() => _WebsiteRedirectPageState();
}

class _WebsiteRedirectPageState extends State<WebsiteRedirectPage> {
  final WebsiteConfigRepository _repo = WebsiteConfigRepository();
  List<Map<String, dynamic>> _rules = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _repo.getRedirectRules(widget.websiteId);
      if (mounted) {
        setState(() {
          _rules = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text('${widget.displayName} - ${context.l10n.websiteRedirectTitle}')),
      body: WebsiteAsyncStateView(
        isLoading: _isLoading,
        error: _error,
        onRetry: _loadRules,
        child: _rules.isEmpty
            ?  Center(child: Text(context.l10n.websiteRedirectEmpty))
            : ListView.builder(
                itemCount: _rules.length,
                itemBuilder: (context, index) {
                  final rule = _rules[index];
                  return Card(
                    child: ListTile(
                      title: Text(rule['source']?.toString() ?? ''),
                      subtitle: Text('-> ${rule['target'] ?? ''} (${rule['type'] ?? '301'})'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: context.l10n.commonDelete,
                        onPressed: () async {
                          try {
                            await _repo.deleteRedirectRule(
                              websiteId: widget.websiteId,
                              ruleId: rule['id'] as int,
                            );
                            _loadRules();
                          } catch (e) {
                            if (context.mounted) {
                              SnackBarUtils.showError(context, context.l10n.commonDeleteFailed);
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
