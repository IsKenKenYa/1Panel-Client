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
              onStart: provider.startContainer,
              onStop: provider.stopContainer,
              onRestart: provider.restartContainer,
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
}
