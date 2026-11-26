import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/website_models.dart';
import 'package:onepanel_client/data/repositories/website_config_repository.dart';
import 'package:onepanel_client/features/websites/widgets/website_async_state_view.dart';

class WebsiteResourcePage extends StatefulWidget {
  const WebsiteResourcePage({
    super.key,
    required this.websiteId,
    required this.displayName,
  });

  final int websiteId;
  final String displayName;

  @override
  State<WebsiteResourcePage> createState() => _WebsiteResourcePageState();
}

class _WebsiteResourcePageState extends State<WebsiteResourcePage> {
  final WebsiteConfigRepository _repo = WebsiteConfigRepository();
  List<WebsiteResource> _resources = const [];
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
      final result = await _repo.getResource(widget.websiteId);
      if (mounted) setState(() { _resources = result; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('${widget.displayName} - ${context.l10n.websiteResourceTitle}'),
        actions: [
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh_outlined), onPressed: _load),
        ],
      ),
      body: WebsiteAsyncStateView(
        isLoading: _isLoading,
        error: _error,
        onRetry: _load,
        child: _resources.isEmpty
            ?  Center(child: Text(context.l10n.commonEmpty))
            : ListView(
                padding: AppDesignTokens.cardPadding,
                children: [
                  for (final resource in _resources)
                    ListTile(
                      title: Text(resource.name),
                      subtitle: Text(switch (resource.type) {
                        'app' => context.l10n.serverModuleApps,
                        'runtime' => context.l10n.serverModuleRuntime,
                        'database' => context.l10n.serverModuleDatabases,
                        _ => resource.type,
                      }),
                    ),
                ],
              ),
      ),
    );
  }

}
