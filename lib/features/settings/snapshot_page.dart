import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/features/backups/services/backup_account_service.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/shared/widgets/operations/module_empty_state_widget.dart';
const String _snapshotPagePackage = 'features.settings.snapshot_page';

class SnapshotPage extends StatefulWidget {
  const SnapshotPage({super.key});

  @override
  State<SnapshotPage> createState() => _SnapshotPageState();
}

class _SnapshotPageState extends State<SnapshotPage> {
  List<Map<String, dynamic>>? _backupAccounts;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<SettingsProvider>();
    try {
      await provider.loadSnapshots();
    } catch (e) {
      if (mounted) {
        final l10n = context.l10n;
        setState(() {
          _loadError = l10n.snapshotLoadFailedWithError(e.toString());
        });
      }
    }

    try {
      final accounts = await provider.loadBackupAccountOptions();
      appLogger.dWithPackage(
        _snapshotPagePackage,
        'loadBackupAccountOptions count=${accounts?.length ?? 0}',
      );
      if (mounted) {
        setState(() {
          _backupAccounts = accounts;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showErrorWithDebugDetails(
          context,
          context.l10n.snapshotBackupAccountLoadFailed,
          error: e,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final provider = context.watch<SettingsProvider>();
    final snapshots = provider.data.snapshots;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.snapshotTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadData,
            tooltip: l10n.systemSettingsRefresh,
          ),
        ],
      ),
      body: _buildBody(context, theme, snapshots, l10n),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'snapshot_create_fab',
        onPressed: () => _showCreateSnapshotDialog(context, l10n),
        icon: const Icon(Icons.add_outlined),
        label: Text(l10n.snapshotCreate),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme,
      List<dynamic>? snapshots, AppLocalizations l10n) {
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadData,
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (snapshots == null || snapshots.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return ListView.builder(
      padding: AppDesignTokens.pagePadding,
      itemCount: snapshots.length,
      itemBuilder: (context, index) {
        final snapshot = snapshots[index] as Map<String, dynamic>;
        return _buildSnapshotCard(context, theme, snapshot, l10n);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return ModuleEmptyStateWidget(
      icon: Icons.photo_library_outlined,
      title: l10n.snapshotEmpty,
      actions: [
        TextButton.icon(
          onPressed: () => _showCreateSnapshotDialog(context, l10n),
          icon: const Icon(Icons.add_outlined),
          label: Text(l10n.snapshotCreate),
        ),
        TextButton.icon(
          onPressed: () => _showImportSnapshotDialog(context, l10n),
          icon: const Icon(Icons.file_upload_outlined),
          label: Text(l10n.snapshotImport),
        ),
      ],
    );
  }

  Widget _buildSnapshotCard(BuildContext context, ThemeData theme,
      Map<String, dynamic> snapshot, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDesignTokens.spacingSm),
      child: ListTile(
        leading: const Icon(Icons.photo_library_outlined),
        title: Text(snapshot['name'] ?? 'Snapshot ${snapshot['id']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.snapshotCreatedAt}: ${snapshot['createdAt'] ?? '-'}'),
            Text(
                '${l10n.snapshotDescription}: ${snapshot['description'] ?? '-'}'),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) =>
              _handleSnapshotAction(context, value, snapshot, l10n),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'recover', child: Text(l10n.snapshotRecover)),
            PopupMenuItem(
                value: 'rollback', child: Text(l10n.snapshotRollback)),
            PopupMenuItem(
                value: 'editDesc', child: Text(l10n.snapshotEditDesc)),
            const PopupMenuDivider(),
            PopupMenuItem(
                value: 'delete',
                child: Text(l10n.snapshotDelete,
                    style: const TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  void _showCreateSnapshotDialog(BuildContext context, AppLocalizations l10n) {
    final descController = TextEditingController();
    final provider = context.read<SettingsProvider>();
    int? selectedAccountId;

    if (_backupAccounts != null && _backupAccounts!.isNotEmpty) {
      selectedAccountId = _backupAccounts!.first['id'] as int;
    }

    appLogger.dWithPackage(
      _snapshotPagePackage,
      'showCreateSnapshotDialog: accountCount=${_backupAccounts?.length ?? 0}',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (statefulContext, setDialogState) {
          return AlertDialog(
            title: Text(l10n.snapshotCreate),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_backupAccounts == null || _backupAccounts!.isEmpty)
                  Padding(
                    padding: AppDesignTokens.cardPadding,
                    child: Text(l10n.snapshotNoBackupAccountHint),
                  )
                else ...[
                  Text(l10n.snapshotEnterDesc),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: l10n.snapshotDescLabel,
                      hintText: l10n.snapshotDescHint,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: selectedAccountId,
                    decoration: InputDecoration(
                      labelText: l10n.snapshotBackupAccountLabel,
                      prefixIcon: const Icon(Icons.cloud_outlined),
                    ),
                    items: _backupAccounts!.map((account) {
                      return DropdownMenuItem<int>(
                        value: account['id'] as int,
                        child: Text('${account['name']} (${account['type']})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      appLogger.dWithPackage(
                        _snapshotPagePackage,
                        'backup account changed: $value',
                      );
                      setDialogState(() {
                        selectedAccountId = value;
                      });
                    },
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: _backupAccounts == null ||
                        _backupAccounts!.isEmpty ||
                        selectedAccountId == null
                    ? null
                    : () async {
                        Navigator.pop(dialogContext);
                        appLogger.iWithPackage(
                          _snapshotPagePackage,
                          'createSnapshot with account: $selectedAccountId',
                        );
                        try {
                          final success = await provider.createSnapshot(
                            description: descController.text.isEmpty
                                ? null
                                : descController.text,
                            sourceAccountIDs: selectedAccountId.toString(),
                            downloadAccountID: selectedAccountId!,
                          );
                          appLogger.iWithPackage(
                            _snapshotPagePackage,
                            'createSnapshot result: $success',
                          );
                          if (context.mounted) {
                            SnackBarUtils.showSuccess(context, success
                                      ? l10n.snapshotCreateSuccess
                                      : l10n.snapshotCreateFailed);
                          }
                        } catch (e, stackTrace) {
                          if (context.mounted) {
                            SnackBarUtils.showErrorWithDebugDetails(context, l10n.snapshotCreateErrorTitle, error: e, stackTrace: stackTrace);
                          }
                        }
                      },
                child: Text(l10n.commonConfirm),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showImportSnapshotDialog(BuildContext context, AppLocalizations l10n) {
    final provider = context.read<SettingsProvider>();
    final accounts = _backupAccounts ?? const <Map<String, dynamic>>[];
    final backupService = BackupAccountService();
    final names = <String>{};
    int? accountId;
    String description = '';
    Future<List<String>>? files;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.snapshotImportTitle),
          content: ConstrainedBox(
            constraints: AdaptiveLayoutSpec.of(dialogContext).dialogConstraints,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (accounts.isEmpty)
                    Text(l10n.snapshotNoBackupAccountHint)
                  else ...[
                    DropdownButtonFormField<int>(
                      initialValue: accountId,
                      decoration: InputDecoration(labelText: l10n.snapshotBackupAccountLabel),
                      items: [
                        for (final account in accounts)
                          DropdownMenuItem<int>(
                            value: account['id'] as int,
                            child: Text('${account['name']} (${account['type']})'),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          accountId = value;
                          names.clear();
                          files = backupService.listFiles(value);
                        });
                      },
                    ),
                    FutureBuilder<List<String>>(
                      future: files,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const LinearProgressIndicator();
                        }
                        if (snapshot.hasError) return Text(l10n.commonLoadFailedTitle);
                        if (files != null && snapshot.data?.isEmpty == true) {
                          return Text(l10n.commonEmpty);
                        }
                        return Column(
                          children: [
                            for (final name in snapshot.data ?? const <String>[])
                              CheckboxListTile(
                                title: Text(name),
                                value: names.contains(name),
                                onChanged: (checked) => setDialogState(() {
                                  if (checked == true) {
                                    names.add(name);
                                  } else {
                                    names.remove(name);
                                  }
                                }),
                              ),
                          ],
                        );
                      },
                    ),
                    TextField(
                      maxLength: 256,
                      decoration: InputDecoration(labelText: l10n.snapshotDescLabel),
                      onChanged: (value) => description = value,
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: accountId == null || names.isEmpty
                  ? null
                  : () async {
                      final selected = accountId!;
                      final selectedNames = names.toList(growable: false);
                      Navigator.pop(dialogContext);
                      final success = await provider.importSnapshot(
                        backupAccountID: selected,
                        names: selectedNames,
                        description: description.trim().isEmpty ? null : description.trim(),
                      );
                      if (!context.mounted) return;
                      if (success) {
                        SnackBarUtils.showSuccess(context, l10n.snapshotImportSuccess);
                      } else {
                        SnackBarUtils.showError(context, l10n.snapshotImportFailed);
                      }
                    },
              child: Text(l10n.commonConfirm),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSnapshotAction(BuildContext context, String action,
      Map<String, dynamic> snapshot, AppLocalizations l10n) {
    final provider = context.read<SettingsProvider>();
    final id = snapshot['id'] as int;
    switch (action) {
      case 'recover':
        _showRecoverConfirmDialog(context, provider, id, l10n);
        break;
      case 'rollback':
        _showRollbackConfirmDialog(context, provider, id, l10n);
        break;
      case 'editDesc':
        _showEditDescDialog(
            context, provider, id, snapshot['description'] as String?, l10n);
        break;
      case 'delete':
        _showDeleteConfirmDialog(context, provider, [id], l10n);
        break;
    }
  }

  void _showRecoverConfirmDialog(BuildContext context,
      SettingsProvider provider, int id, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.snapshotRecoverTitle),
        content: Text(l10n.snapshotRecoverConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final success = await provider.recoverSnapshot(id);
                if (context.mounted) {
                  SnackBarUtils.showSuccess(context, success
                            ? l10n.snapshotRecoverSuccess
                            : l10n.snapshotRecoverFailed);
                }
              } catch (e, stackTrace) {
                if (context.mounted) {
                  SnackBarUtils.showErrorWithDebugDetails(context, l10n.snapshotRecoverErrorTitle, error: e, stackTrace: stackTrace);
                }
              }
            },
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
  }

  void _showRollbackConfirmDialog(BuildContext context,
      SettingsProvider provider, int id, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.snapshotRollbackTitle),
        content: Text(l10n.snapshotRollbackConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final success = await provider.rollbackSnapshot(id);
                if (context.mounted) {
                  SnackBarUtils.showSuccess(context, success
                            ? l10n.snapshotRollbackSuccess
                            : l10n.snapshotRollbackFailed);
                }
              } catch (e, stackTrace) {
                if (context.mounted) {
                  SnackBarUtils.showErrorWithDebugDetails(context, l10n.snapshotRollbackErrorTitle, error: e, stackTrace: stackTrace);
                }
              }
            },
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
  }

  void _showEditDescDialog(BuildContext context, SettingsProvider provider,
      int id, String? currentDesc, AppLocalizations l10n) {
    final controller = TextEditingController(text: currentDesc ?? '');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.snapshotEditDescTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.snapshotDescLabel,
            hintText: l10n.snapshotDescHint,
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final success = await provider.updateSnapshotDescription(
                    id, controller.text);
                if (context.mounted) {
                  SnackBarUtils.showSuccess(context, success
                            ? l10n.snapshotEditDescSuccess
                            : l10n.snapshotEditDescFailed);
                }
              } catch (e, stackTrace) {
                if (context.mounted) {
                  SnackBarUtils.showErrorWithDebugDetails(context, l10n.snapshotEditDescErrorTitle, error: e, stackTrace: stackTrace);
                }
              }
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, SettingsProvider provider,
      List<int> ids, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.snapshotDeleteTitle),
        content: Text(l10n.snapshotDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final success = await provider.deleteSnapshot(ids);
                if (context.mounted) {
                  SnackBarUtils.showSuccess(context, success
                            ? l10n.snapshotDeleteSuccess
                            : l10n.snapshotDeleteFailed);
                }
              } catch (e, stackTrace) {
                if (context.mounted) {
                  SnackBarUtils.showErrorWithDebugDetails(context, l10n.snapshotDeleteErrorTitle, error: e, stackTrace: stackTrace);
                }
              }
            },
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
  }
}
