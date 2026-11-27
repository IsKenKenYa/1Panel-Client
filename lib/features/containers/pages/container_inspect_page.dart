import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/api/v2/container_v2.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';

/// Container inspect detail page.
/// Mirrors frontend's container inspect view: shows raw JSON config.
class ContainerInspectPage extends StatefulWidget {
  const ContainerInspectPage({
    super.key,
    required this.containerId,
    required this.containerName,
  });

  final String containerId;
  final String containerName;

  @override
  State<ContainerInspectPage> createState() => _ContainerInspectPageState();
}

class _ContainerInspectPageState extends State<ContainerInspectPage> {
  Map<String, dynamic>? _inspectData;
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
      final api = ContainerV2Api(await ApiClientManager.instance.getCurrentClient());
      final response = await api.inspectContainer(InspectReq(id: widget.containerId, type: 'container'));
      if (mounted) {
        setState(() {
          _inspectData = response.data is Map ? Map<String, dynamic>.from(response.data as Map) : null;
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
        title: Text('${widget.containerName} - ${context.l10n.containerInspectTitle}'),
        actions: [
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh_outlined), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _inspectData == null
                  ?  Center(child: Text(context.l10n.commonEmpty))
                  : DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          const TabBar(
                            tabs: [
                              Tab(text: 'Config'),
                              Tab(text: 'Network'),
                              Tab(text: 'Raw'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildConfigTab(),
                                _buildNetworkTab(),
                                _buildRawTab(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildConfigTab() {
    final config = _inspectData?['Config'] as Map? ?? {};
    return ListView(
      padding: AppDesignTokens.cardPadding,
      children: [
        SectionPropertyList(
          properties: [
            SectionProperty(
              label: context.l10n.commonImage,
              value: config['Image']?.toString(),
            ),
            SectionProperty(
              label: context.l10n.commonCommand,
              value: config['Cmd']?.toString(),
            ),
            SectionProperty(
              label: context.l10n.containerInspectWorkingDir,
              value: config['WorkingDir']?.toString(),
            ),
            SectionProperty(
              label: context.l10n.containerInspectEntrypoint,
              value: config['Entrypoint']?.toString(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNetworkTab() {
    final networkSettings = _inspectData?['NetworkSettings'] as Map? ?? {};
    final networks = networkSettings['Networks'] as Map? ?? {};
    if (networks.isEmpty) {
      return ListView(
        padding: AppDesignTokens.cardPadding,
        children: const <Widget>[],
      );
    }
    return ListView(
      padding: AppDesignTokens.cardPadding,
      children: [
        for (final name in networks.keys) ...[
          SectionPropertyList(
            title: name.toString(),
            properties: [
              SectionProperty(
                label: context.l10n.containerInspectIpLabel,
                value: (networks[name] as Map?)?['IPAddress']?.toString(),
              ),
              SectionProperty(
                label: context.l10n.containerInspectGateway,
                value: (networks[name] as Map?)?['Gateway']?.toString(),
              ),
            ],
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
        ],
      ],
    );
  }

  Widget _buildRawTab() {
    return SingleChildScrollView(
      padding: AppDesignTokens.cardPadding,
      child: SelectableText(
        _inspectData.toString(),
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}
