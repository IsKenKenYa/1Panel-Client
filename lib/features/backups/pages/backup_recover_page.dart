import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/backups/models/backup_recover_args.dart';
import 'package:onepanel_client/features/backups/providers/backup_recover_provider.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:provider/provider.dart';

class BackupRecoverPage extends StatefulWidget {
  const BackupRecoverPage({
    super.key,
    this.args,
  });

  final BackupRecoverArgs? args;

  @override
  State<BackupRecoverPage> createState() => _BackupRecoverPageState();
}

class _BackupRecoverPageState extends State<BackupRecoverPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<BackupRecoverProvider>().initialize(widget.args);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<BackupRecoverProvider>(
      builder: (context, provider, _) {
        return ServerAwarePageScaffold(
          title: l10n.operationsBackupRecoverTitle,
          onServerChanged: () =>
              context.read<BackupRecoverProvider>().initialize(widget.args),
          body: AsyncStatePageBodyWidget(
            isLoading: provider.isLoading,
            errorMessage: provider.errorMessage,
            onRetry: () => provider.initialize(widget.args),
            child: Stepper(
              currentStep: provider.selectedRecord == null
                  ? 0
                  : provider.canSubmit
                      ? 2
                      : 1,
              controlsBuilder: (_, __) => const SizedBox.shrink(),
              steps: <Step>[
                Step(
                  title: const Text('Resource'),
                  content: Column(
                    children: <Widget>[
                      DropdownButtonFormField<String>(
                        initialValue: provider.resourceType,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem(value: 'app', child: Text('App')),
                          DropdownMenuItem(
                              value: 'website', child: Text('Website')),
                          DropdownMenuItem(
                              value: 'database', child: Text('Database')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            provider.updateResourceType(value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      if (provider.resourceType == 'app')
                        DropdownButtonFormField<String>(
                          initialValue: provider.resourceName.isEmpty
                              ? null
                              : provider.resourceName,
                          decoration: const InputDecoration(labelText: 'App'),
                          items: provider.apps
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item.appKey,
                                  child: Text(item.name ?? ''),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            final item = provider.apps.firstWhere(
                              (candidate) => candidate.appKey == value,
                            );
                            provider.selectApp(item);
                          },
                        ),
                      if (provider.resourceType == 'website')
                        DropdownButtonFormField<String>(
                          initialValue: provider.resourceName.isEmpty
                              ? null
                              : provider.resourceName,
                          decoration:
                              const InputDecoration(labelText: 'Website'),
                          items: provider.websites
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item['alias']?.toString(),
                                  child: Text(
                                    item['primaryDomain']?.toString() ??
                                        item['alias']?.toString() ??
                                        '',
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            final item = provider.websites.firstWhere(
                              (candidate) =>
                                  candidate['alias']?.toString() == value,
                            );
                            provider.selectWebsite(item);
                          },
                        ),
                      if (provider.resourceType == 'database') ...<Widget>[
                        DropdownButtonFormField<String>(
                          initialValue: provider.databaseType,
                          decoration:
                              const InputDecoration(labelText: 'Database type'),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem(
                                value: 'mysql', child: Text('MySQL')),
                            DropdownMenuItem(
                              value: 'postgresql',
                              child: Text('PostgreSQL'),
                            ),
                            DropdownMenuItem(
                                value: 'redis', child: Text('Redis')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              provider.updateDatabaseType(value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: provider.resourceDetailName.isEmpty
                              ? null
                              : provider.resourceDetailName,
                          decoration:
                              const InputDecoration(labelText: 'Database item'),
                          items: provider.databaseItems
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item.name,
                                  child:
                                      Text('${item.name} (${item.database})'),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            final item = provider.databaseItems.firstWhere(
                              (candidate) => candidate.name == value,
                            );
                            provider.selectDatabaseItem(item);
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonal(
                          onPressed: provider.hasResourceSelection
                              ? provider.loadRecords
                              : null,
                          child: const Text('Load records'),
                        ),
                      ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Record'),
                  content: Column(
                    children: <Widget>[
                      if (provider.records.isEmpty)
                        const Text('No candidate records')
                      else
                        DropdownButtonFormField<int>(
                          initialValue: provider.selectedRecord?.id,
                          decoration:
                              const InputDecoration(labelText: 'Backup record'),
                          items: provider.records
                              .map(
                                (item) => DropdownMenuItem<int>(
                                  value: item.id,
                                  child: Text(item.fileName ?? ''),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            provider.selectRecord(
                              provider.records.firstWhere(
                                (item) => item.id == value,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Confirm'),
                  content: Column(
                    children: <Widget>[
                      TextFormField(
                        initialValue: provider.secret,
                        onChanged: provider.updateSecret,
                        decoration: const InputDecoration(labelText: 'Secret'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: provider.timeout.toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (value) =>
                            provider.updateTimeout(int.tryParse(value) ?? 3600),
                        decoration: const InputDecoration(labelText: 'Timeout'),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(provider.selectedRecord?.fileName ?? '-'),
                        subtitle: Text(provider.selectedRecord?.fileDir ?? ''),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: provider.canSubmit ? _submit : null,
                        child: provider.isSubmitting
                            ? const SizedBox.square(
                                dimension: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Start recover'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.operationsBackupRecoverTitle,
      message: 'Start recovery from the selected backup record?',
      confirmLabel: context.l10n.commonConfirm,
      isDestructive: true,
      confirmIcon: Icons.restore_outlined,
    );
    if (!confirmed || !mounted) return;
    final success = await context.read<BackupRecoverProvider>().submitRecover();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.read<BackupRecoverProvider>().errorMessage ??
              context.l10n.commonUnknownError,
        ),
      ),
    );
  }
}
