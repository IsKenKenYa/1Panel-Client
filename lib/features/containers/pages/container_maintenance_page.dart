import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/api/v2/container_v2.dart';
import 'package:onepanel_client/data/models/container_models.dart';

/// Container commit & prune operations page.
/// Mirrors frontend's container commit dialog and prune action.
class ContainerMaintenancePage extends StatefulWidget {
  const ContainerMaintenancePage({super.key});

  @override
  State<ContainerMaintenancePage> createState() =>
      _ContainerMaintenancePageState();
}

class _ContainerMaintenancePageState extends State<ContainerMaintenancePage> {
  final _commitController = TextEditingController();
  final _imageController = TextEditingController();
  final _containerIdController = TextEditingController();
  bool _isCommitting = false;
  bool _isPruning = false;

  @override
  void dispose() {
    _commitController.dispose();
    _imageController.dispose();
    _containerIdController.dispose();
    super.dispose();
  }

  Future<void> _commitContainer(String containerId) async {
    if (containerId.isEmpty || _imageController.text.isEmpty) return;
    setState(() => _isCommitting = true);
    try {
      final api =
          ContainerV2Api(await ApiClientManager.instance.getCurrentClient());
      await api.commitContainer(ContainerCommit(
        containerID: containerId,
        containerName: containerId,
        newImageName: _imageController.text,
        comment: _commitController.text,
      ));
      if (mounted) SnackBarUtils.showSuccess(context, context.l10n.containerMaintenanceCommitted);
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, context.l10n.containerMaintenanceCommitFailed);
    } finally {
      if (mounted) setState(() => _isCommitting = false);
    }
  }

  Future<void> _pruneContainers() async {
    setState(() => _isPruning = true);
    try {
      final api =
          ContainerV2Api(await ApiClientManager.instance.getCurrentClient());
      final report = await api.pruneContainers(const ContainerPrune(pruneType: 'container'));
      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          'Pruned: ${report.data?.spaceReclaimed ?? 0} bytes reclaimed',
        );
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, context.l10n.containerMaintenancePruneFailed);
    } finally {
      if (mounted) setState(() => _isPruning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title:  Text(context.l10n.containerMaintenanceTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.containerMaintenanceCommitTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _containerIdController,
                    decoration:  InputDecoration(
                      labelText: context.l10n.containerMaintenanceContainerId,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _imageController,
                    decoration:  InputDecoration(
                      labelText: context.l10n.containerMaintenanceNewImageName,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commitController,
                    decoration:  InputDecoration(
                      labelText: context.l10n.containerMaintenanceCommitMessage,
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isCommitting ? null : () => _commitContainer(_containerIdController.text),
                    icon: _isCommitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                    label:  Text(context.l10n.containerMaintenanceCommit),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.containerMaintenancePruneTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                      'Remove all stopped containers to reclaim disk space.'),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: _isPruning ? null : _pruneContainers,
                    icon: _isPruning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.cleaning_services),
                    label:  Text(context.l10n.containerMaintenancePrune),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
