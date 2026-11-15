import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/repositories/website_config_repository.dart';
import 'package:onepanel_client/features/websites/widgets/website_async_state_view.dart';

/// Website resource monitoring page.
/// Mirrors frontend's website resource tab: CPU/memory/traffic stats.
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
  Map<String, dynamic>? _resource;
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
      if (mounted) setState(() { _resource = result; _isLoading = false; });
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
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: WebsiteAsyncStateView(
        isLoading: _isLoading,
        error: _error,
        onRetry: _load,
        child: _resource == null
            ?  Center(child: Text(context.l10n.commonEmpty))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatCard('CPU', _resource?['cpu'], '%'),
                  _buildStatCard('Memory', _resource?['memory'], 'MB'),
                  _buildStatCard('Network In', _resource?['networkIn'], 'KB/s'),
                  _buildStatCard('Network Out', _resource?['networkOut'], 'KB/s'),
                  _buildStatCard('Disk Read', _resource?['diskRead'], 'KB/s'),
                  _buildStatCard('Disk Write', _resource?['diskWrite'], 'KB/s'),
                ],
              ),
      ),
    );
  }

  Widget _buildStatCard(String label, dynamic value, String unit) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text('${value ?? 'N/A'} $unit'),
        trailing: Icon(
          _getIconForLabel(label),
          color: Colors.blue,
        ),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'CPU':
        return Icons.memory;
      case 'Memory':
        return Icons.storage;
      case 'Network In':
      case 'Network Out':
        return Icons.network_check;
      case 'Disk Read':
      case 'Disk Write':
        return Icons.sd_storage;
      default:
        return Icons.bar_chart;
    }
  }
}
