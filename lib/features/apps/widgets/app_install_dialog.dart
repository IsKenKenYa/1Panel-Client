import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import '../../../data/models/app_models.dart';
import '../app_service.dart';

class AppInstallDialog extends StatefulWidget {
  final AppItem app;

  const AppInstallDialog({super.key, required this.app});

  @override
  State<AppInstallDialog> createState() => _AppInstallDialogState();
}

class _AppInstallDialogState extends State<AppInstallDialog> {
  final _formKey = GlobalKey<FormState>();
  late final AppService _appService;

  late TextEditingController _nameController;
  late TextEditingController _containerNameController;
  late TextEditingController _cpuQuotaController;
  late TextEditingController _memoryLimitController;

  String? _selectedVersion;
  int? _currentDetailId;
  bool _showAdvanced = false;
  bool _isLoading = false;
  bool _isCheckingVersion = false;
  bool _isLoadingParams = false;

  // Dynamic form fields from API params
  final Map<String, TextEditingController> _paramControllers = {};
  List<AppFormField>? _formFields; // From API response

  // Services (Ports): key = service/port, value = exposed port?
  // Actually AppInstallCreateRequest.services is Map<String, String>
  // Let's assume Key = Service Name/Internal Port, Value = External Port
  final List<_MapEntryController> _services = [];

  // Additional Params (Env): key = env name, value = env value
  final List<_MapEntryController> _additionalParams = [];

  @override
  void initState() {
    super.initState();
    _appService = context.read<AppService>();
    _nameController = TextEditingController(text: widget.app.name);
    _containerNameController = TextEditingController(text: widget.app.name);
    _cpuQuotaController = TextEditingController();
    _memoryLimitController = TextEditingController();
    // Don't set _currentDetailId here - it will be set by _resolveDetailId

    if (widget.app.versions != null && widget.app.versions!.isNotEmpty) {
      _selectedVersion = widget.app.versions!.first;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveDetailId(showError: false);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _containerNameController.dispose();
    _cpuQuotaController.dispose();
    _memoryLimitController.dispose();
    for (var controller in _paramControllers.values) {
      controller.dispose();
    }
    for (var entry in _services) {
      entry.dispose();
    }
    for (var entry in _additionalParams) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _handleVersionChanged(String? newValue) async {
    if (newValue == null || newValue == _selectedVersion) return;
    setState(() {
      _selectedVersion = newValue;
    });
    await _resolveDetailId();
  }

  Future<void> _resolveDetailId({bool showError = true}) async {
    final appId = widget.app.id;
    final version = _selectedVersion;
    if (appId == null || version == null) return;

    setState(() {
      _isCheckingVersion = true;
      _isLoadingParams = true;
    });

    try {
      // Call getAppDetail to get appDetailId and params (like web frontend does)
      final detail = await _appService.getAppDetail(
        appId.toString(),
        version,
        widget.app.type ?? 'app',
      );
      
      if (mounted) {
        setState(() {
          _currentDetailId = detail.id; // This is the appDetailId we need
          
          // Load form fields from params
          if (detail.params != null && detail.params!.formFields.isNotEmpty) {
            _formFields = detail.params!.formFields;
            
            // Initialize controllers with default values
            for (final field in _formFields!) {
              final controller = TextEditingController();
              
              // Set default value if available
              if (field.defaultValue != null) {
                controller.text = field.defaultValue.toString();
              }
              
              _paramControllers[field.envKey] = controller;
            }
          }
        });
      }
    } catch (e) {
      if (mounted && showError) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.appOperateFailed(_formatError(e)))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVersion = false;
          _isLoadingParams = false;
        });
      }
    }
  }



  /// 格式化错误信息，使其更友好
  String _formatError(Object error) {
    final errorStr = error.toString();
    
    // 处理 docker-compose.yml 获取失败的错误
    if (errorStr.contains('docker-compose.yml') && 
        errorStr.contains('unsupported protocol scheme')) {
      return '应用配置文件获取失败，可能是应用商店配置不完整';
    }
    
    // 处理其他常见错误
    if (errorStr.contains('DioException')) {
      // 提取 message 部分
      final messageMatch = RegExp(r'message:\s*(.+?)(?:,|$)').firstMatch(errorStr);
      if (messageMatch != null) {
        return messageMatch.group(1)?.trim() ?? errorStr;
      }
    }
    
    return errorStr;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentDetailId == null) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.appOperateFailed(l10n.commonUnknownError))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final servicesMap = <String, String>{};
      for (var entry in _services) {
        if (entry.key.text.isNotEmpty) {
          servicesMap[entry.key.text] = entry.value.text;
        }
      }

      final paramsMap = <String, dynamic>{};
      
      // Add dynamic form field values
      for (var entry in _paramControllers.entries) {
        paramsMap[entry.key] = entry.value.text;
      }
      
      // Add additional manual params
      for (var entry in _additionalParams) {
        if (entry.key.text.isNotEmpty) {
          paramsMap[entry.key.text] = entry.value.text;
        }
      }

      final request = AppInstallCreateRequest(
        appDetailId: _currentDetailId!,
        name: _nameController.text,
        type: widget.app.type,
        advanced: _showAdvanced,
        containerName: _showAdvanced && _containerNameController.text.isNotEmpty
            ? _containerNameController.text
            : null,
        cpuQuota: _showAdvanced && _cpuQuotaController.text.isNotEmpty
            ? double.tryParse(_cpuQuotaController.text)
            : null,
        memoryLimit: _showAdvanced && _memoryLimitController.text.isNotEmpty
            ? double.tryParse(_memoryLimitController.text)
            : null,
        memoryUnit: 'MB', // Default unit
        services: _showAdvanced && servicesMap.isNotEmpty ? servicesMap : null,
        params: paramsMap.isNotEmpty ? paramsMap : null,
        // Default values
        dockerCompose: null,
        hostMode: false,
        allowPort: true,
      );

      // Use AppService directly instead of Provider
      await _appService.installApp(request);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).appOperateSuccess),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).appOperateFailed(_formatError(e))),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog.adaptive(
      title: Text('${l10n.appStoreInstall} ${widget.app.name}'),
      scrollable: true,
      content: SizedBox(
        width: 600, // Reasonable width for desktop/tablet
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.appInfoName,
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
              if (widget.app.versions != null &&
                  widget.app.versions!.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: _selectedVersion,
                  decoration: InputDecoration(
                    labelText: l10n.appInfoVersion,
                    border: const OutlineInputBorder(),
                  ),
                  items: widget.app.versions!.map((v) {
                    return DropdownMenuItem(value: v, child: Text(v));
                  }).toList(),
                  onChanged: (_isLoading || _isCheckingVersion)
                      ? null
                      : _handleVersionChanged,
                ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(l10n.panelSettingsAdvanced),
                value: _showAdvanced,
                onChanged: (value) {
                  setState(() => _showAdvanced = value);
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (_showAdvanced) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _containerNameController,
                  decoration: InputDecoration(
                    labelText: l10n.appInstallContainerName,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cpuQuotaController,
                        decoration: InputDecoration(
                          labelText: l10n.appInstallCpuLimit,
                          border: const OutlineInputBorder(),
                          suffixText: 'Core',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _memoryLimitController,
                        decoration: InputDecoration(
                          labelText: l10n.appInstallMemoryLimit,
                          border: const OutlineInputBorder(),
                          suffixText: 'MB',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildMapEditor(
                  title: l10n.appInstallPorts,
                  keyLabel: l10n.appInstallPortService, // Or Host Port?
                  valueLabel: l10n.appInstallPortHost, // Or Container Port?
                  items: _services,
                ),
                const SizedBox(height: 24),
                _buildMapEditor(
                  title: l10n.appInstallEnv,
                  keyLabel: l10n.appInstallEnvKey,
                  valueLabel: l10n.appInstallEnvValue,
                  items: _additionalParams,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: (_isLoading || _isCheckingVersion) ? null : _handleSubmit,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : Text(l10n.commonConfirm),
        ),
      ],
    );
  }

  Widget _buildMapEditor({
    required String title,
    required String keyLabel,
    required String valueLabel,
    required List<_MapEntryController> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  items.add(_MapEntryController());
                });
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text(AppLocalizations.of(context).serverAdd),
            ),
          ],
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              AppLocalizations.of(context).commonEmpty,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.key,
                    decoration: InputDecoration(
                      labelText: keyLabel,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller.value,
                    decoration: InputDecoration(
                      labelText: valueLabel,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: () {
                    setState(() {
                      items[index].dispose();
                      items.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _MapEntryController {
  final TextEditingController key = TextEditingController();
  final TextEditingController value = TextEditingController();

  void dispose() {
    key.dispose();
    value.dispose();
  }
}
