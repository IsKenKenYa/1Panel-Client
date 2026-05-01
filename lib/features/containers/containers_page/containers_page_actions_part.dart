part of 'package:onepanel_client/features/containers/containers_page.dart';

extension _ContainersPageActions on _ContainersPageViewState {
  List<Widget> _buildAppBarActions(BuildContext context, dynamic l10n) {
    switch (_selectedSection) {
      case 'containers':
        return [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () =>
                ContainersPageContainerMaintenanceDialogs.showPruneDialog(
              context,
            ),
            tooltip: l10n.containerActionPrune,
          ),
        ];
      case 'images':
        return [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () =>
                ContainersPageImageDialogs.showSearchImageDialog(context),
            tooltip: l10n.orchestrationImageSearch,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: l10n.commonMore,
            onSelected: (value) {
              if (value == 'build') {
                ContainersPageImageDialogs.showBuildImageDialog(context);
              } else if (value == 'load') {
                ContainersPageImageDialogs.showLoadImageDialog(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'build',
                child: Text(l10n.orchestrationImageBuild),
              ),
              PopupMenuItem(
                value: 'load',
                child: Text(l10n.orchestrationImageLoad),
              ),
            ],
          ),
        ];
      default:
        return const [];
    }
  }

  Widget? _buildFloatingActionButton(BuildContext context, dynamic l10n) {
    switch (_selectedSection) {
      case 'containers':
        return FloatingActionButton.extended(
          heroTag: 'containers_section_fab',
          onPressed: () async {
            if (PlatformUtils.isDesktop(context)) {
              await openRouteRespectingShell(context, '/container-create');
              return;
            }
            final created =
                await Navigator.pushNamed(context, '/container-create');
            if (created == true && context.mounted) {
              await context.read<ContainersProvider>().loadContainers();
            }
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.containerCreate),
        );
      case 'compose':
        return FloatingActionButton.extended(
          heroTag: 'containers_compose_fab',
          onPressed: () =>
              ContainersPageCreateDialogs.showCreateComposeDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateProject),
        );
      case 'images':
        return FloatingActionButton.extended(
          heroTag: 'containers_images_fab',
          onPressed: () => ContainersPageImageDialogs.showPullDialog(context),
          icon: const Icon(Icons.download),
          label: Text(l10n.orchestrationPullImage),
        );
      case 'networks':
        return FloatingActionButton.extended(
          heroTag: 'containers_networks_fab',
          onPressed: () =>
              ContainersPageCreateDialogs.showCreateNetworkDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateNetwork),
        );
      case 'volumes':
        return FloatingActionButton.extended(
          heroTag: 'containers_volumes_fab',
          onPressed: () =>
              ContainersPageCreateDialogs.showCreateVolumeDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateVolume),
        );
      case 'repositories':
        return FloatingActionButton.extended(
          heroTag: 'containers_repositories_fab',
          onPressed: () =>
              ContainersPageCreateDialogs.showCreateRepoDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateRepo),
        );
      case 'templates':
        return FloatingActionButton.extended(
          heroTag: 'containers_templates_fab',
          onPressed: () =>
              ContainersPageCreateDialogs.showCreateTemplateDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateTemplate),
        );
      default:
        return null;
    }
  }
}
