import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_panel.dart';

class NetworkCreateDialog extends StatefulWidget {
  const NetworkCreateDialog({super.key});

  @override
  State<NetworkCreateDialog> createState() => _NetworkCreateDialogState();
}

class _NetworkCreateDialogState extends State<NetworkCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subnetController = TextEditingController();
  final _gatewayController = TextEditingController();
  final _labelsController = TextEditingController();

  final List<String> _drivers = [
    'bridge',
    'host',
    'null',
    'macvlan',
    'ipvlan',
    'overlay'
  ];
  String _selectedDriver = 'bridge';
  bool _enableIPv6 = false;

  @override
  void dispose() {
    _nameController.dispose();
    _subnetController.dispose();
    _gatewayController.dispose();
    _labelsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: l10n.orchestrationCreateNetwork,
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.commonName,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.serverFormRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedDriver,
                decoration: InputDecoration(
                  labelText: l10n.commonDriver,
                  border: const OutlineInputBorder(),
                ),
                items: _drivers.map((driver) {
                  return DropdownMenuItem(
                    value: driver,
                    child: Text(driver),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDriver = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subnetController,
                decoration: InputDecoration(
                  labelText: l10n.containerNetworkSubnetLabel,
                  hintText: l10n.containerNetworkSubnetHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gatewayController,
                decoration: InputDecoration(
                  labelText: l10n.containerNetworkGatewayLabel,
                  hintText: l10n.containerNetworkGatewayHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.containerNetworkEnableIPv6),
                value: _enableIPv6,
                onChanged: (value) {
                  setState(() {
                    _enableIPv6 = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _labelsController,
                decoration: InputDecoration(
                  labelText: l10n.containerNetworkLabelsLabel,
                  hintText: l10n.containerNetworkLabelsHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      confirmLabel: l10n.commonCreate,
      onConfirm: () async {
        if (_formKey.currentState!.validate()) {
          Navigator.of(context).pop({
            'name': _nameController.text,
            'driver': _selectedDriver,
            'subnet': _subnetController.text,
            'gateway': _gatewayController.text,
            'enableIPv6': _enableIPv6,
            'labels': _labelsController.text,
          });
        }
      },
    );
  }
}
