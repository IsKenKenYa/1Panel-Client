import 'package:flutter/material.dart';

class NetworkCreateDialog extends StatefulWidget {
  const NetworkCreateDialog({super.key});

  @override
  State<NetworkCreateDialog> createState() => _NetworkCreateDialogState();
}

class _NetworkCreateDialogState extends State<NetworkCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _driverController = TextEditingController();
  final _subnetController = TextEditingController();
  final _gatewayController = TextEditingController();

  final List<String> _drivers = ['bridge', 'host', 'null', 'macvlan', 'ipvlan', 'overlay'];
  String _selectedDriver = 'bridge';

  @override
  void dispose() {
    _nameController.dispose();
    _driverController.dispose();
    _subnetController.dispose();
    _gatewayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Network'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDriver,
                decoration: const InputDecoration(
                  labelText: 'Driver',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Subnet (e.g., 172.20.0.0/16)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gatewayController,
                decoration: const InputDecoration(
                  labelText: 'Gateway (e.g., 172.20.0.1)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text,
                'driver': _selectedDriver,
                'subnet': _subnetController.text,
                'gateway': _gatewayController.text,
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
