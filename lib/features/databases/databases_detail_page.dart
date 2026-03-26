import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

import 'databases_provider.dart';

class DatabaseDetailPage extends StatelessWidget {
  const DatabaseDetailPage({
    super.key,
    required this.item,
  });

  final DatabaseListItem item;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DatabaseDetailProvider(item: item)..load(),
      child: const _DatabaseDetailPageView(),
    );
  }
}

class _DatabaseDetailPageView extends StatelessWidget {
  const _DatabaseDetailPageView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DatabaseDetailProvider>();
    final detail = provider.detail;
    final item = provider.item;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: provider.isLoading && detail == null
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null && detail == null
              ? _DatabaseDetailError(
                  error: provider.error!,
                  onRetry: provider.load,
                )
              : RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView(
                    padding: AppDesignTokens.pagePadding,
                    children: [
                      AppCard(
                        title: l10n.databaseOverviewTitle,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailRow(
                                label: l10n.commonName, value: item.name),
                            _DetailRow(
                              label: l10n.databaseEngineLabel,
                              value: item.engine,
                            ),
                            _DetailRow(
                              label: l10n.databaseSourceLabel,
                              value: item.source,
                            ),
                            _DetailRow(
                              label: l10n.databaseAddressLabel,
                              value: item.address ?? '-',
                            ),
                            _DetailRow(
                              label: l10n.databaseUsernameLabel,
                              value: item.username ?? '-',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDesignTokens.spacingMd),
                      AppCard(
                        title: l10n.databaseConfigTitle,
                        child: Text(detail?.rawConfigFile ?? '-'),
                      ),
                      if (detail?.baseInfo != null) ...[
                        const SizedBox(height: AppDesignTokens.spacingMd),
                        AppCard(
                          title: l10n.databaseBaseInfoTitle,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DetailRow(
                                label: l10n.databaseContainerLabel,
                                value: detail!.baseInfo!.containerName ?? '-',
                              ),
                              _DetailRow(
                                label: l10n.databasePortLabel,
                                value: detail.baseInfo!.port?.toString() ?? '-',
                              ),
                              _DetailRow(
                                label: l10n.databaseRemoteAccessLabel,
                                value: detail.baseInfo!.remoteConn == true
                                    ? l10n.commonYes
                                    : l10n.commonNo,
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (detail?.status != null) ...[
                        const SizedBox(height: AppDesignTokens.spacingMd),
                        AppCard(
                          title: l10n.databaseStatusTitle,
                          child: Text(detail!.status.toString()),
                        ),
                      ],
                      if (detail?.variables != null) ...[
                        const SizedBox(height: AppDesignTokens.spacingMd),
                        AppCard(
                          title: l10n.databaseVariablesTitle,
                          child: Text(detail!.variables.toString()),
                        ),
                      ],
                      const SizedBox(height: AppDesignTokens.spacingMd),
                      Wrap(
                        spacing: AppDesignTokens.spacingSm,
                        runSpacing: AppDesignTokens.spacingSm,
                        children: [
                          OutlinedButton(
                            onPressed: () => _showSingleInputDialog(
                              context,
                              title: l10n.commonDescription,
                              initialValue: item.description ?? '',
                              onSubmit: provider.updateDescription,
                            ),
                            child: Text(l10n.commonEdit),
                          ),
                          OutlinedButton(
                            onPressed: () => _showPasswordDialog(
                              context,
                              onSubmit: provider.changePassword,
                            ),
                            child: Text(l10n.databaseChangePasswordAction),
                          ),
                          OutlinedButton(
                            onPressed: () => _showBindUserDialog(
                              context,
                              onSubmit: provider.bindUser,
                            ),
                            child: Text(l10n.databaseBindUserAction),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _showSingleInputDialog(
    BuildContext context, {
    required String title,
    required String initialValue,
    required Future<bool> Function(String) onSubmit,
  }) async {
    final controller = TextEditingController(text: initialValue);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await onSubmit(controller.text.trim());
              if (!context.mounted) return;
              if (ok) Navigator.of(context).pop();
            },
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
  }

  Future<void> _showPasswordDialog(
    BuildContext context, {
    required Future<bool> Function(String) onSubmit,
  }) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.databaseChangePasswordAction),
        content: TextField(
          controller: controller,
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await onSubmit(controller.text.trim());
              if (!context.mounted) return;
              if (ok) Navigator.of(context).pop();
            },
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
  }

  Future<void> _showBindUserDialog(
    BuildContext context, {
    required Future<bool> Function({
      required String username,
      required String password,
    }) onSubmit,
  }) async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.databaseBindUserAction),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                  labelText: context.l10n.databaseUsernameLabel),
            ),
            const SizedBox(height: AppDesignTokens.spacingSm),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                  labelText: context.l10n.databasePasswordLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await onSubmit(
                username: usernameController.text.trim(),
                password: passwordController.text.trim(),
              );
              if (!context.mounted) return;
              if (ok) Navigator.of(context).pop();
            },
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesignTokens.spacingXs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: AppDesignTokens.spacingSm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatabaseDetailError extends StatelessWidget {
  const _DatabaseDetailError({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: AppDesignTokens.spacingMd),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: AppDesignTokens.spacingMd),
            FilledButton(
              onPressed: () => onRetry(),
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
