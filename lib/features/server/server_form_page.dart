import 'package:flutter/material.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/server/server_repository.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'server_connection_service.dart';

class ServerFormPage extends StatefulWidget {
  const ServerFormPage({super.key});

  @override
  State<ServerFormPage> createState() => _ServerFormPageState();
}

class _ServerFormPageState extends State<ServerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _tokenValidityController = TextEditingController(text: '0');
  final _repository = const ServerRepository();
  final _connectionService = ServerConnectionService();

  bool _saving = false;
  bool _testing = false;
  bool _allowInsecureTls = false;
  ServerConnectionResult? _testResult;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _apiKeyController.dispose();
    _tokenValidityController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (_urlController.text.trim().isEmpty ||
        _apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.serverFormRequired)),
      );
      return;
    }

    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      final result = await _connectionService.testConnection(
        serverUrl: _urlController.text.trim(),
        apiKey: _apiKeyController.text.trim(),
        allowInsecureTls: _allowInsecureTls,
      );

      if (!mounted) return;

      setState(() {
        _testResult = result;
      });

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.l10n.serverTestSuccess} (${result.responseTime?.inMilliseconds}ms)',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${context.l10n.serverTestFailed}: ${result.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _testing = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = context.l10n;
    final currentServerController = context.read<CurrentServerController>();
    setState(() {
      _saving = true;
    });

    try {
      final config = ApiConfig(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        url: _urlController.text.trim(),
        apiKey: _apiKeyController.text.trim(),
        tokenValidity: int.tryParse(_tokenValidityController.text.trim()) ?? 0,
        allowInsecureTls: _allowInsecureTls,
        isDefault: true,
      );

      await _repository.saveConfig(config);
      await currentServerController.refresh();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.serverFormSaveSuccess)),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context, true);
        return;
      }
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.serverFormSaveFailed(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.serverFormTitle)),
      body: SingleChildScrollView(
        padding: AppDesignTokens.pagePadding,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.serverFormName,
                  hintText: l10n.serverFormNameHint,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.serverFormRequired
                    : null,
              ),
              const SizedBox(height: AppDesignTokens.spacingLg),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: l10n.serverFormUrl,
                  hintText: l10n.serverFormUrlHint,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.serverFormRequired
                    : null,
              ),
              const SizedBox(height: AppDesignTokens.spacingLg),
              TextFormField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: l10n.serverFormApiKey,
                  hintText: l10n.serverFormApiKeyHint,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.serverFormRequired
                    : null,
              ),
              const SizedBox(height: AppDesignTokens.spacingLg),
              TextFormField(
                controller: _tokenValidityController,
                decoration: InputDecoration(
                  labelText: l10n.serverTokenValidity,
                  hintText: l10n.serverTokenValidityHint,
                  suffixText: l10n.serverFormMinutes,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppDesignTokens.spacingSm),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _allowInsecureTls,
                onChanged: (value) {
                  setState(() {
                    _allowInsecureTls = value;
                  });
                },
                title: Text(l10n.serverFormAllowInsecureTls),
                subtitle: Text(l10n.serverFormAllowInsecureTlsHint),
              ),
              const SizedBox(height: AppDesignTokens.spacingLg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _testing ? null : _testConnection,
                  child: _testing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(l10n.serverTestTesting),
                          ],
                        )
                      : Text(l10n.serverFormTest),
                ),
              ),
              if (_testResult != null) ...[
                const SizedBox(height: AppDesignTokens.spacingMd),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _testResult!.success
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _testResult!.success
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _testResult!.success
                                ? Icons.check_circle
                                : Icons.error,
                            color: _testResult!.success
                                ? Colors.green
                                : Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _testResult!.success
                                ? l10n.serverTestSuccess
                                : l10n.serverTestFailed,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _testResult!.success
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      if (_testResult!.osInfo != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'OS: ${_testResult!.osInfo!['os'] ?? 'Unknown'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                      if (_testResult!.errorMessage != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _testResult!.errorMessage!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppDesignTokens.spacingMd),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.serverFormSaveConnect),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
