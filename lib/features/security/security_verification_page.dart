import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/features/security/security_provider.dart';
import 'package:onepanel_client/features/shell/widgets/server_switcher_action.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';

import '../../core/utils/snackbar_utils.dart';
class SecurityVerificationPage extends StatefulWidget {
  const SecurityVerificationPage({super.key});

  @override
  State<SecurityVerificationPage> createState() =>
      _SecurityVerificationPageState();
}

class _SecurityVerificationPageState extends State<SecurityVerificationPage> {
  final SecurityProvider _provider = SecurityProvider();
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider.load();
  }

  @override
  void dispose() {
    _provider.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.securityPageTitle),
        actions: [
          ServerSwitcherAction(
            onChanged: () async {
              await _provider.load();
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _provider,
        builder: (context, _) {
          if (_provider.loading && _provider.mfaInfo == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final info = _provider.mfaInfo;
          // 首屏没有 MFA 数据且加载失败：整页错误态，不再渲染空表单。
          if (info == null && _provider.error != null) {
            return ModuleErrorStateWidget(
              message: _provider.error,
              onRetry: _provider.load,
            );
          }
          return ListView(
            padding: AppDesignTokens.pagePadding,
            children: [
              Card(
                child: Padding(
                  padding: AppDesignTokens.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.securityStatusTitle,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppDesignTokens.spacingSm),
                      Chip(
                        label: Text(
                          info?.enabled == true
                              ? l10n.securityStatusEnabled
                              : l10n.securityStatusDisabled,
                        ),
                      ),
                      if ((info?.secret ?? '').isNotEmpty) ...[
                        const SizedBox(height: AppDesignTokens.spacingMd),
                        Text(
                            '${l10n.securitySecretLabel}: ${info?.secret}'),
                      ],
                      if ((info?.qrImage ?? '').isNotEmpty) ...[
                        const SizedBox(height: AppDesignTokens.spacingMd),
                        _MfaQrImage(base64Data: info!.qrImage),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingLg),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.securityCodeLabel,
                  hintText: l10n.securityCodeHint,
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingLg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _provider.loading ? null : _provider.load,
                      icon: const Icon(Icons.refresh_outlined),
                      label: Text(l10n.securityLoadInfo),
                    ),
                  ),
                  const SizedBox(width: AppDesignTokens.spacingMd),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _provider.loading
                          ? null
                          : () async {
                              try {
                                await _provider.bind(
                                    code: _codeController.text.trim());
                                if (!context.mounted) {
                                  return;
                                }
                                SnackBarUtils.showSuccess(context, l10n.securityBindSuccess);
                              } catch (e) {
                                if (!context.mounted) {
                                  return;
                                }
                                SnackBarUtils.showError(
                                  context,
                                  l10n.securityBindFailed(
                                    ErrorMessageUtils.normalize(e),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.verified_user_outlined),
                      label: Text(l10n.securityBind),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MfaQrImage extends StatelessWidget {
  const _MfaQrImage({required this.base64Data});

  final String base64Data;

  @override
  Widget build(BuildContext context) {
    try {
      final bytes = base64Decode(base64Data);
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
        child: Image.memory(
          bytes,
          height: 180,
          width: 180,
          fit: BoxFit.cover,
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
