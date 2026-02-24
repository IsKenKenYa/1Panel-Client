import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/data/models/app_config_models.dart';
import 'package:onepanelapp_app/features/apps/providers/installed_apps_provider.dart';

class EditAppConfigDialog extends StatefulWidget {
  final int appInstallId;
  final AppConfig appConfig;
  final int? httpPort;
  final int? httpsPort;

  const EditAppConfigDialog({
    super.key,
    required this.appInstallId,
    required this.appConfig,
    this.httpPort,
    this.httpsPort,
  });

  @override
  State<EditAppConfigDialog> createState() => _EditAppConfigDialogState();
}

class _EditAppConfigDialogState extends State<EditAppConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _params = {};
  late TextEditingController _httpPortController;
  late TextEditingController _httpsPortController;
  late TextEditingController _containerNameController;
  late TextEditingController _cpuQuotaController;
  late TextEditingController _memoryLimitController;
  String _memoryUnit = 'MB';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (var param in widget.appConfig.params) {
      if (param.edit) {
        _params[param.key] = param.value;
      }
    }
    _httpPortController = TextEditingController(text: widget.httpPort?.toString() ?? '');
    _httpsPortController = TextEditingController(text: widget.httpsPort?.toString() ?? '');
    _containerNameController = TextEditingController(text: widget.appConfig.containerName);
    _cpuQuotaController = TextEditingController(text: widget.appConfig.cpuQuota.toString());
    _memoryLimitController = TextEditingController(text: widget.appConfig.memoryLimit.toString());
    _memoryUnit = widget.appConfig.memoryUnit;
  }

  @override
  void dispose() {
    _httpPortController.dispose();
    _httpsPortController.dispose();
    _containerNameController.dispose();
    _cpuQuotaController.dispose();
    _memoryLimitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    final provider = context.read<InstalledAppsProvider>();
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 1. Update Params
      if (_params.isNotEmpty) {
        await provider.updateAppParams(widget.appInstallId, _params);
      }

      // 2. Update Ports
      if (widget.appConfig.allowPort) {
        final newHttp = int.tryParse(_httpPortController.text);
        final newHttps = int.tryParse(_httpsPortController.text);
        
        if (newHttp != widget.httpPort || newHttps != widget.httpsPort) {
           await provider.changeAppPort(
             widget.appInstallId, 
             newHttp ?? 0, 
             newHttps ?? 0,
           );
        }
      }

      // 3. Update Container Config
      final containerName = _containerNameController.text;
      final cpuQuota = double.tryParse(_cpuQuotaController.text) ?? 0;
      final memoryLimit = double.tryParse(_memoryLimitController.text) ?? 0;

      if (containerName != widget.appConfig.containerName ||
          cpuQuota != widget.appConfig.cpuQuota ||
          memoryLimit != widget.appConfig.memoryLimit ||
          _memoryUnit != widget.appConfig.memoryUnit) {
        
        await provider.updateAppInstallConfig({
          'installId': widget.appInstallId,
          'containerName': containerName,
          'cpuQuota': cpuQuota,
          'memoryLimit': memoryLimit,
          'memoryUnit': _memoryUnit,
          'dockerCompose': widget.appConfig.dockerCompose, // Required?
        });
      }

      if (mounted) {
        navigator.pop(true);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.commonSaveSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('${l10n.commonSaveFailed}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Filter editable params
    final editableParams = widget.appConfig.params.where((p) => p.edit).toList();

    return AlertDialog(
      title: Text(l10n.appTabConfig),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.appConfig.allowPort) ...[
                  Text(l10n.commonPort, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _httpPortController,
                          decoration: const InputDecoration(
                            labelText: 'HTTP',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _httpsPortController,
                          decoration: const InputDecoration(
                            labelText: 'HTTPS',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                ],

                Text(l10n.containerTitle, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _containerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Container Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cpuQuotaController,
                        decoration: const InputDecoration(
                          labelText: 'CPU Quota',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _memoryLimitController,
                              decoration: const InputDecoration(
                                labelText: 'Memory',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            child: DropdownButtonFormField<String>(
                              value: _memoryUnit,
                              items: const [
                                DropdownMenuItem(value: 'MB', child: Text('MB')),
                                DropdownMenuItem(value: 'GB', child: Text('GB')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _memoryUnit = val;
                                  });
                                }
                              },
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                if (editableParams.isNotEmpty) ...[
                  Text(l10n.commonParams, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ...editableParams.map((param) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildParamField(param),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(l10n.commonSave),
        ),
      ],
    );
  }

  Widget _buildParamField(InstallParams param) {
    // Determine label (use current locale if possible, or fallback)
    // Here simplified
    final label = param.labelZh; 
    
    if (param.type == 'select' && param.values != null) {
       final values = param.values; 
       List<DropdownMenuItem<dynamic>> items = [];
       
       if (values is List) {
         for (var v in values) {
           // Handle string or map
           if (v is String) {
             items.add(DropdownMenuItem(value: v, child: Text(v)));
           } else if (v is Map) {
             items.add(DropdownMenuItem(
               value: v['value'], 
               child: Text(v['label']?.toString() ?? v['value'].toString()),
             ));
           }
         }
       }
       
       // Ensure current value exists in items, otherwise add it or set to null
       var currentValue = _params[param.key];
       if (currentValue != null && !items.any((i) => i.value == currentValue)) {
         // If current value is not in the list, maybe it's a type mismatch or custom value?
         // Or just don't set value
         currentValue = null; 
       }

       return DropdownButtonFormField<dynamic>(
         value: currentValue,
         decoration: InputDecoration(
           labelText: label,
           border: const OutlineInputBorder(),
           isDense: true,
           helperText: param.rule,
         ),
         items: items,
         onChanged: (val) {
           setState(() {
             _params[param.key] = val;
           });
         },
       );
    }
    
    // Default to text field
    return TextFormField(
      initialValue: _params[param.key]?.toString(),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        helperText: param.rule,
      ),
      onSaved: (val) {
        if (val != null) {
           _params[param.key] = val;
        }
      },
      validator: (val) {
        if (param.required == true && (val == null || val.isEmpty)) {
          return 'Required';
        }
        return null;
      },
    );
  }
}
