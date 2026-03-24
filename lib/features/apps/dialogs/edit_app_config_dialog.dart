import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/app_config_models.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/features/apps/providers/installed_apps_provider.dart';

class EditAppConfigDialog extends StatefulWidget {
  final int appInstallId;
  final AppConfig appConfig;
  final String appKey;
  final String appName;
  final int? httpPort;
  final int? httpsPort;

  const EditAppConfigDialog({
    super.key,
    required this.appInstallId,
    required this.appConfig,
    required this.appKey,
    required this.appName,
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
        await provider.updateAppParams(
          AppInstalledParamsUpdateRequest(
            installId: widget.appInstallId,
            params: _params,
            advanced: true,
            allowPort: widget.appConfig.allowPort,
            containerName: _containerNameController.text,
            cpuQuota: double.tryParse(_cpuQuotaController.text),
            memoryLimit: double.tryParse(_memoryLimitController.text),
            memoryUnit: _memoryUnit,
            dockerCompose: widget.appConfig.dockerCompose,
            hostMode: widget.appConfig.hostMode,
            type: widget.appConfig.type,
            webUI: widget.appConfig.webUI,
            specifyIP: widget.appConfig.specifyIP,
            restartPolicy: widget.appConfig.restartPolicy,
          ),
        );
      }

      // 2. Update Ports
      if (widget.appConfig.allowPort) {
        final newHttp = int.tryParse(_httpPortController.text);
        final newHttps = int.tryParse(_httpsPortController.text);
        final canUpdatePort = widget.appKey.isNotEmpty && widget.appName.isNotEmpty;

        if (canUpdatePort && newHttp != widget.httpPort && newHttp != null) {
          await provider.changeAppPort(
            AppPortUpdateRequest(
              key: widget.appKey,
              name: widget.appName,
              port: newHttp,
            ),
          );
        }
        if (canUpdatePort && newHttps != widget.httpsPort && newHttps != null) {
          await provider.changeAppPort(
            AppPortUpdateRequest(
              key: widget.appKey,
              name: widget.appName,
              port: newHttps,
            ),
          );
        }
      }

      // 3. Update Container Config
      if (widget.appConfig.webUI.isNotEmpty) {
        await provider.updateAppInstallConfig(
          AppConfigUpdateRequest(
            installId: widget.appInstallId,
            webUI: widget.appConfig.webUI,
          ),
        );
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
    final colorScheme = Theme.of(context).colorScheme;

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
                          decoration: InputDecoration(
                            labelText: l10n.commonHttp,
                            border: const OutlineInputBorder(),
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
                          decoration: InputDecoration(
                            labelText: l10n.commonHttps,
                            border: const OutlineInputBorder(),
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
                  decoration: InputDecoration(
                    labelText: l10n.appInstallContainerName,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cpuQuotaController,
                        decoration: InputDecoration(
                          labelText: l10n.appInstallCpuLimit,
                          border: const OutlineInputBorder(),
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
                              decoration: InputDecoration(
                                labelText: l10n.appInstallMemoryLimit,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            child: DropdownButtonFormField<String>(
                              initialValue: _memoryUnit,
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
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onPrimary,
                ),
              )
            : Text(l10n.commonSave),
        ),
      ],
    );
  }

  Widget _buildParamField(InstallParams param) {
    final l10n = context.l10n;
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
         initialValue: currentValue,
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
          return l10n.serverFormRequired;
        }
        return null;
      },
    );
  }
}
