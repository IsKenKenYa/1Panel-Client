import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/vm/vm_resource_models.dart';
import 'package:onepanel_client/features/vm/providers/vm_provider.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';
import 'package:onepanel_client/shared/widgets/expressive_section.dart';

/// 网络分区：NAT / Bridge / Macvtap 三类与已用 IP 查看。
class VmNetworkTab extends StatelessWidget {
  const VmNetworkTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<VmProvider>();

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDesignTokens.spacingLg,
            AppDesignTokens.spacingMd,
            AppDesignTokens.spacingLg,
            AppDesignTokens.spacingSm,
          ),
          child: Row(
            children: <Widget>[
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                tooltip: l10n.commonRefresh,
                onPressed: provider.isMutating ? null : provider.loadNetworks,
              ),
              FilledButton.tonalIcon(
                onPressed: () => showVmNetworkForm(context),
                icon: const Icon(Icons.add_outlined),
                label: Text(l10n.vmNetworkCreateAction),
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncStatePageBodyWidget(
            isLoading:
                provider.networkState.isLoading && provider.networks.isEmpty,
            isEmpty:
                provider.networks.isEmpty &&
                provider.networkState.error == null,
            errorMessage: provider.networkState.error,
            onRetry: provider.loadNetworks,
            emptyTitle: l10n.vmNetworkEmptyTitle,
            emptyDescription: l10n.vmNetworkEmptyDescription,
            emptyIcon: Icons.lan_outlined,
            emptyActionLabel: l10n.vmNetworkCreateAction,
            onEmptyAction: () => showVmNetworkForm(context),
            child: RefreshIndicator(
              onRefresh: provider.loadNetworks,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppDesignTokens.spacingLg,
                  AppDesignTokens.spacingSm,
                  AppDesignTokens.spacingLg,
                  AppDesignTokens.spacingXl +
                      MediaQuery.paddingOf(context).bottom,
                ),
                children: <Widget>[
                  ExpressiveSection(
                    title: l10n.vmTabNetworks,
                    isBusy:
                        provider.networks.isEmpty == false &&
                        provider.isMutating,
                    children: <Widget>[
                      for (final network in provider.networks)
                        _NetworkCard(network: network, provider: provider),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NetworkCard extends StatelessWidget {
  const _NetworkCard({required this.network, required this.provider});

  final VMNetworkItem network;
  final VmProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final typeLabel = _typeLabel(l10n, network.type);
    final running = network.status == 'running' || network.status == 'Running';

    final meta = <String>[
      typeLabel,
      if (network.type == 'nat' && network.cidr.isNotEmpty) network.cidr,
      if (network.type == 'bridge' && network.bridgeName.isNotEmpty)
        network.bridgeName,
      if (network.type == 'macvtap' && network.sourceInterface.isNotEmpty)
        network.sourceInterface,
      '${l10n.vmNetworkVmCountLabel} ${network.vmCount}',
      if (network.autoStart) l10n.vmNetworkAutoStartLabel,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.spacingLg,
        vertical: AppDesignTokens.spacingMd + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: network.error.isEmpty
                      ? scheme.secondaryContainer
                      : scheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.lan_outlined,
                  size: 20,
                  color: network.error.isEmpty
                      ? scheme.onSecondaryContainer
                      : scheme.onErrorContainer,
                ),
              ),
              const SizedBox(width: AppDesignTokens.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      network.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.spacingXs),
                    Text(
                      meta.join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (network.type == 'nat' &&
                        (network.gateway.isNotEmpty ||
                            network.dhcpStart.isNotEmpty)) ...[
                      const SizedBox(height: AppDesignTokens.spacingXs),
                      Text(
                        '${l10n.vmNetworkGatewayLabel} ${network.gateway}'
                        ' · ${l10n.vmNetworkDhcpStartLabel} ${network.dhcpStart}'
                        ' · ${l10n.vmNetworkDhcpEndLabel} ${network.dhcpEnd}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (!network.registered) ...[
                      const SizedBox(height: AppDesignTokens.spacingXs),
                      Text(
                        l10n.vmNetworkNotRegistered,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ],
                    if (network.description.isNotEmpty) ...[
                      const SizedBox(height: AppDesignTokens.spacingXs),
                      Text(
                        network.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: running,
                onChanged: provider.isMutating
                    ? null
                    : (value) => _toggleStatus(context, network, value),
              ),
            ],
          ),
          const SizedBox(height: AppDesignTokens.spacingXs),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              if (network.usedIPs.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _showUsedIps(context, network),
                  icon: const Icon(Icons.list_alt_outlined, size: 18),
                  label: Text(l10n.vmNetworkUsedIpAction),
                ),
              TextButton.icon(
                onPressed: provider.isMutating
                    ? null
                    : () => _deleteNetwork(context, network),
                icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
                label: Text(
                  l10n.commonDelete,
                  style: TextStyle(color: scheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(
    BuildContext context,
    VMNetworkItem network,
    bool enable,
  ) async {
    final l10n = context.l10n;
    try {
      await provider.updateNetwork(
        VMNetworkUpdate(id: network.id, status: enable ? 'running' : 'stopped'),
      );
      if (!context.mounted) {
        return;
      }
      SnackBarUtils.showSuccess(context, l10n.commonOperationSuccess);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      SnackBarUtils.showError(context, error.toString());
    }
  }

  Future<void> _deleteNetwork(
    BuildContext context,
    VMNetworkItem network,
  ) async {
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.commonDelete,
      message: network.name,
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      await provider.deleteNetwork(network.id);
      if (!context.mounted) {
        return;
      }
      SnackBarUtils.showSuccess(context, l10n.commonDeleted);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      SnackBarUtils.showError(context, error.toString());
    }
  }

  Future<void> _showUsedIps(BuildContext context, VMNetworkItem network) {
    final l10n = context.l10n;
    return showAppDetailsSheet(
      context,
      title: l10n.vmNetworkUsedIpTitle,
      children: [
        network.usedIPs.isEmpty
            ? Text(l10n.vmNetworkUsedIpEmpty)
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: <DataColumn>[
                    DataColumn(label: Text(l10n.vmNetworkIpColumn)),
                    DataColumn(label: Text(l10n.vmNetworkVmColumn)),
                    DataColumn(label: Text(l10n.vmNetworkMacColumn)),
                    DataColumn(label: Text(l10n.vmNetworkSourceColumn)),
                  ],
                  rows: <DataRow>[
                    for (final usage in network.usedIPs)
                      DataRow(
                        cells: <DataCell>[
                          DataCell(Text(usage.ip)),
                          DataCell(Text(usage.vmName)),
                          DataCell(Text(usage.mac)),
                          DataCell(Text(usage.source)),
                        ],
                      ),
                  ],
                ),
              ),
      ],
    );
  }

  static String _typeLabel(l10n, String type) {
    switch (type) {
      case 'nat':
        return l10n.vmNetworkTypeNat;
      case 'bridge':
        return l10n.vmNetworkTypeBridge;
      case 'macvtap':
        return l10n.vmNetworkTypeMacvtap;
      default:
        return type;
    }
  }
}

/// 打开网络创建弹层。
Future<void> showVmNetworkForm(BuildContext context) {
  return showAdaptiveFormPanel<void>(
    context,
    builder: (_) => const _VmNetworkForm(),
  );
}

class _VmNetworkForm extends StatefulWidget {
  const _VmNetworkForm();

  @override
  State<_VmNetworkForm> createState() => _VmNetworkFormState();
}

class _VmNetworkFormState extends State<_VmNetworkForm> {
  final _nameController = TextEditingController();
  final _cidrController = TextEditingController();
  final _gatewayController = TextEditingController();
  final _dhcpStartController = TextEditingController();
  final _dhcpEndController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'nat';
  String? _bridgeName;
  String? _sourceInterface;
  bool _autoStart = true;
  bool _saving = false;

  List<VMNetworkBridgeItem> _bridges = const <VMNetworkBridgeItem>[];
  List<VMNetworkInterfaceItem> _interfaces = const <VMNetworkInterfaceItem>[];

  @override
  void initState() {
    super.initState();
    _nameController.text = 'net-${DateTime.now().millisecondsSinceEpoch}';
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOptions());
  }

  Future<void> _loadOptions() async {
    final provider = context.read<VmProvider>();
    try {
      final bridges = await provider.listBridges();
      final interfaces = await provider.listInterfaces();
      if (!mounted) {
        return;
      }
      setState(() {
        _bridges = bridges;
        _interfaces = interfaces;
        final recommended = bridges.where((item) => item.recommended);
        _bridgeName = recommended.isEmpty
            ? (bridges.isEmpty ? null : bridges.first.name)
            : recommended.first.name;
        _sourceInterface = interfaces.isEmpty ? null : interfaces.first.name;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      SnackBarUtils.showError(context, error.toString());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cidrController.dispose();
    _gatewayController.dispose();
    _dhcpStartController.dispose();
    _dhcpEndController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Bridge 只提供标记为推荐的网桥。
    final recommendedBridges = _bridges
        .where((item) => item.recommended)
        .toList(growable: false);
    return AppFormPanel(
      title: l10n.vmNetworkCreateAction,
      isSaving: _saving,
      confirmLabel: l10n.commonCreate,
      onConfirm: _submit,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.vmNetworkNameLabel),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: InputDecoration(labelText: l10n.vmNetworkTypeLabel),
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem(
                value: 'nat',
                child: Text(l10n.vmNetworkTypeNat),
              ),
              DropdownMenuItem(
                value: 'bridge',
                child: Text(l10n.vmNetworkTypeBridge),
              ),
              DropdownMenuItem(
                value: 'macvtap',
                child: Text(l10n.vmNetworkTypeMacvtap),
              ),
            ],
            onChanged: (value) => setState(() => _type = value ?? 'nat'),
          ),
          const SizedBox(height: 12),
          if (_type == 'nat') ...[
            TextField(
              controller: _cidrController,
              decoration: InputDecoration(
                labelText: l10n.vmNetworkCidrLabel,
                hintText: '192.168.100.0/24',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _gatewayController,
              decoration: InputDecoration(
                labelText: l10n.vmNetworkGatewayLabel,
                hintText: '192.168.100.1',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dhcpStartController,
              decoration: InputDecoration(
                labelText: l10n.vmNetworkDhcpStartLabel,
                hintText: '192.168.100.10',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dhcpEndController,
              decoration: InputDecoration(
                labelText: l10n.vmNetworkDhcpEndLabel,
                hintText: '192.168.100.200',
              ),
            ),
          ],
          if (_type == 'bridge') ...[
            DropdownButtonFormField<String>(
              initialValue: _bridgeName,
              decoration: InputDecoration(
                labelText: l10n.vmNetworkBridgeLabel,
                helperText: l10n.vmNetworkBridgeHint,
              ),
              items: <DropdownMenuItem<String>>[
                for (final bridge in recommendedBridges)
                  DropdownMenuItem(
                    value: bridge.name,
                    child: Text(
                      bridge.description.isEmpty
                          ? bridge.name
                          : '${bridge.name} · ${bridge.description}',
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _bridgeName = value),
            ),
          ],
          if (_type == 'macvtap') ...[
            DropdownButtonFormField<String>(
              initialValue: _sourceInterface,
              decoration: InputDecoration(
                labelText: l10n.vmNetworkSourceInterfaceLabel,
              ),
              items: <DropdownMenuItem<String>>[
                for (final nic in _interfaces)
                  DropdownMenuItem(
                    value: nic.name,
                    child: Text(
                      nic.addresses.isEmpty
                          ? nic.name
                          : '${nic.name} · ${nic.addresses.join(', ')}',
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _sourceInterface = value),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _autoStart,
            title: Text(l10n.vmNetworkAutoStartLabel),
            onChanged: (value) => setState(() => _autoStart = value),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: InputDecoration(labelText: l10n.commonDescription),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final provider = context.read<VmProvider>();
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      SnackBarUtils.showError(context, l10n.commonErrorBadRequest);
      return;
    }
    setState(() => _saving = true);
    try {
      await provider.createNetwork(
        VMNetworkCreate(
          name: name,
          type: _type,
          bridgeName: _type == 'bridge' ? _bridgeName : null,
          sourceInterface: _type == 'macvtap' ? _sourceInterface : null,
          cidr: _type == 'nat' ? _cidrController.text.trim() : null,
          gateway: _type == 'nat' ? _gatewayController.text.trim() : null,
          dhcpStart: _type == 'nat' ? _dhcpStartController.text.trim() : null,
          dhcpEnd: _type == 'nat' ? _dhcpEndController.text.trim() : null,
          autoStart: _autoStart,
          description: _descriptionController.text.trim(),
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      SnackBarUtils.showSuccess(context, l10n.commonOperationSuccess);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        SnackBarUtils.showError(context, error.toString());
      }
    }
  }
}
