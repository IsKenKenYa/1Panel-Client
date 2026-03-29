part of 'package:onepanel_client/features/containers/containers_page.dart';

extension _ContainersPageSections on _ContainersPageViewState {
  List<ModuleSubnavItem> _buildSubnavItems(dynamic l10n) {
    return [
      ModuleSubnavItem(
        id: 'containers',
        label: l10n.containerTabContainers,
        icon: Icons.layers_outlined,
      ),
      ModuleSubnavItem(
        id: 'images',
        label: l10n.containerTabImages,
        icon: Icons.image_outlined,
      ),
      ModuleSubnavItem(
        id: 'networks',
        label: l10n.containerTabNetworks,
        icon: Icons.hub_outlined,
      ),
      ModuleSubnavItem(
        id: 'volumes',
        label: l10n.containerTabVolumes,
        icon: Icons.storage_outlined,
      ),
      ModuleSubnavItem(
        id: 'compose',
        label: l10n.containerTabOrchestration,
        icon: Icons.dashboard_customize_outlined,
      ),
      ModuleSubnavItem(
        id: 'repositories',
        label: l10n.containerTabRepositories,
        icon: Icons.store_outlined,
      ),
      ModuleSubnavItem(
        id: 'templates',
        label: l10n.containerTabTemplates,
        icon: Icons.description_outlined,
      ),
      ModuleSubnavItem(
        id: 'config',
        label: l10n.containerTabConfig,
        icon: Icons.tune_outlined,
      ),
    ];
  }

  Widget _buildSectionContent(BuildContext context) {
    switch (_selectedSection) {
      case 'containers':
        return Consumer<ContainersProvider>(
          builder: (context, provider, child) {
            final data = provider.data;
            if (provider.containersState.error != null &&
                data.containers.isEmpty) {
              return ContainersErrorView(
                error: provider.containersState.error!,
                onRetry: provider.loadContainers,
              );
            }
            if (provider.containersState.isLoading && data.containers.isEmpty) {
              return const ContainersLoadingView();
            }
            return ContainersTab(
              containers: data.containers,
              stats: data.containerStats,
              isLoading: provider.containersState.isLoading,
              showStatsHeader: false,
              onRefresh: provider.refresh,
              onStart: (name) => _handleContainerAction(
                context,
                provider,
                name,
                action: _ContainerLifecycleAction.start,
              ),
              onStop: (name) => _handleContainerAction(
                context,
                provider,
                name,
                action: _ContainerLifecycleAction.stop,
              ),
              onRestart: (name) => _handleContainerAction(
                context,
                provider,
                name,
                action: _ContainerLifecycleAction.restart,
              ),
              onDelete: (id) => ContainersPageContainerMaintenanceDialogs
                  .showDeleteContainerDialog(context, id),
              onRename: (name) =>
                  ContainersPageContainerEditDialogs.showRenameContainerDialog(
                context,
                name,
              ),
              onUpgrade: (container) => ContainersPageContainerImageDialogs
                  .showUpgradeContainerDialog(
                context,
                container,
              ),
              onCommit: (container) =>
                  ContainersPageContainerImageDialogs.showCommitContainerDialog(
                context,
                container,
              ),
              onEdit: (container) =>
                  ContainersPageContainerEditDialogs.showEditContainerDialog(
                context,
                container,
              ),
              onCleanLog: (name) =>
                  ContainersPageContainerEditDialogs.showCleanLogDialog(
                context,
                name,
              ),
              onTerminal: (container) => _openContainerTerminal(
                context,
                container,
              ),
            );
          },
        );
      case 'compose':
        return const ComposePage();
      case 'images':
        return const ImagePage();
      case 'networks':
        return const NetworkPage();
      case 'volumes':
        return const VolumePage();
      case 'repositories':
        return const ReposTab();
      case 'templates':
        return const TemplatesTab();
      case 'config':
        return const ConfigTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _handleContainerAction(
    BuildContext context,
    ContainersProvider provider,
    String containerName, {
    required _ContainerLifecycleAction action,
  }) async {
    final l10n = context.l10n;
    final actionLabel = _actionLabel(l10n, action);
    final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(actionLabel),
              content: Text('${l10n.containerInfoName}: $containerName'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.commonCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(l10n.commonConfirm),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldContinue) {
      return;
    }

    bool success;
    switch (action) {
      case _ContainerLifecycleAction.start:
        success = await provider.startContainer(containerName);
        break;
      case _ContainerLifecycleAction.stop:
        success = await provider.stopContainer(containerName);
        break;
      case _ContainerLifecycleAction.restart:
        success = await provider.restartContainer(containerName);
        break;
    }

    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final message = success
        ? l10n.containerOperateSuccess
        : l10n.containerOperateFailed(
            provider.data.error ?? l10n.commonUnknownError,
          );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              success ? Theme.of(context).colorScheme.tertiary : null,
        ),
      );
  }

  String _actionLabel(dynamic l10n, _ContainerLifecycleAction action) {
    switch (action) {
      case _ContainerLifecycleAction.start:
        return l10n.containerActionStart;
      case _ContainerLifecycleAction.stop:
        return l10n.containerActionStop;
      case _ContainerLifecycleAction.restart:
        return l10n.containerActionRestart;
    }
  }

  void _openContainerTerminal(BuildContext context, dynamic container) {
    final containerId =
        (container.id?.toString().isNotEmpty ?? false) ? container.id : null;
    Navigator.pushNamed(
      context,
      '/terminal',
      arguments: <String, dynamic>{
        'type': 'container',
        'containerId': containerId ?? container.name,
        'containerName': container.name,
        'command': '/bin/sh',
        'user': 'root',
      },
    );
  }
}

enum _ContainerLifecycleAction {
  start,
  stop,
  restart,
}
