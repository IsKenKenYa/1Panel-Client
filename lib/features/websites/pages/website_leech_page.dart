import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/repositories/website_config_repository.dart';
import 'package:onepanel_client/features/websites/widgets/website_async_state_view.dart';

/// Website anti-leech (hotlink protection) configuration page.
class WebsiteLeechPage extends StatefulWidget {
  const WebsiteLeechPage({
    super.key,
    required this.websiteId,
    required this.displayName,
  });

  final int websiteId;
  final String displayName;

  @override
  State<WebsiteLeechPage> createState() => _WebsiteLeechPageState();
}

class _WebsiteLeechPageState extends State<WebsiteLeechPage> {
  final WebsiteConfigRepository _repo = WebsiteConfigRepository();
  Map<String, dynamic>? _config;
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
      final result = await _repo.getLeechConfig(widget.websiteId);
      if (mounted) setState(() { _config = result; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _update(bool enable) async {
    try {
      await _repo.updateLeechConfig({
        'websiteId': widget.websiteId,
        'enable': enable,
        ...?_config,
      });
      if (mounted) SnackBarUtils.showSuccess(context, context.l10n.commonUpdated);
      _load();
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, context.l10n.commonUpdateFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text('${widget.displayName} - ${context.l10n.websiteLeechTitle}')),
      body: WebsiteAsyncStateView(
        isLoading: _isLoading,
        error: _error,
        onRetry: _load,
        child: _config == null
            ?  Center(child: Text(context.l10n.commonEmpty))
            : ListView(
                padding: AppDesignTokens.cardPadding,
                children: [
                  Card(
                    child: SwitchListTile(
                      title:  Text(context.l10n.websiteLeechProtection),
                      subtitle: Text(_config?['enable'] == true ? 'Enabled' : 'Disabled'),
                      value: _config?['enable'] == true,
                      onChanged: _update,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
