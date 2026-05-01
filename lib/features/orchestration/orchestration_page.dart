import 'package:flutter/material.dart';
import 'package:onepanel_client/features/containers/containers_page_create_dialogs.dart';
import 'package:onepanel_client/features/containers/containers_page_image_dialogs.dart';
import 'package:onepanel_client/features/orchestration/compose_page.dart';
import 'package:onepanel_client/features/orchestration/image_page.dart';
import 'package:onepanel_client/features/orchestration/network_page.dart';
import 'package:onepanel_client/features/orchestration/providers/compose_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/image_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/network_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/volume_provider.dart';
import 'package:onepanel_client/features/orchestration/volume_page.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:provider/provider.dart';

class OrchestrationPage extends StatefulWidget {
  const OrchestrationPage({super.key});

  @override
  State<OrchestrationPage> createState() => _OrchestrationPageState();
}

class _OrchestrationPageState extends State<OrchestrationPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this)
      ..addListener(() {
        if (_tabController.indexIsChanging) return;
        setState(() {});
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Widget> _buildActions(BuildContext context) {
    final l10n = context.l10n;
    if (_tabController.index == 1) {
      return [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: l10n.orchestrationImageSearch,
          onPressed: () =>
              ContainersPageImageDialogs.showSearchImageDialog(context),
        ),
        PopupMenuButton<String>(
          tooltip: l10n.commonMore,
          onSelected: (value) {
            if (value == 'build') {
              ContainersPageImageDialogs.showBuildImageDialog(context);
            }
            if (value == 'load') {
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
    }
    return const [];
  }

  Widget? _buildFab(BuildContext context) {
    final l10n = context.l10n;
    switch (_tabController.index) {
      case 0:
        return FloatingActionButton.extended(
          heroTag: 'orchestration_compose_fab',
          onPressed: () =>
              ContainersPageCreateDialogs.showCreateComposeDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateProject),
        );
      case 1:
        return FloatingActionButton.extended(
          heroTag: 'orchestration_image_fab',
          onPressed: () => ContainersPageImageDialogs.showPullDialog(context),
          icon: const Icon(Icons.download),
          label: Text(l10n.orchestrationPullImage),
        );
      case 2:
        return FloatingActionButton.extended(
          heroTag: 'orchestration_network_fab',
          onPressed: () =>
              ContainersPageCreateDialogs.showCreateNetworkDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateNetwork),
        );
      case 3:
        return FloatingActionButton.extended(
          heroTag: 'orchestration_volume_fab',
          onPressed: () =>
              ContainersPageCreateDialogs.showCreateVolumeDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.orchestrationCreateVolume),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ComposeProvider()),
        ChangeNotifierProvider(create: (_) => DockerImageProvider()),
        ChangeNotifierProvider(create: (_) => NetworkProvider()),
        ChangeNotifierProvider(create: (_) => VolumeProvider()),
      ],
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.orchestrationTitle),
              actions: _buildActions(context),
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [
                  Tab(text: l10n.orchestrationCompose),
                  Tab(text: l10n.orchestrationImages),
                  Tab(text: l10n.orchestrationNetworks),
                  Tab(text: l10n.orchestrationVolumes),
                ],
              ),
            ),
            floatingActionButton: _buildFab(context),
            body: TabBarView(
              controller: _tabController,
              children: const [
                ComposePage(),
                ImagePage(),
                NetworkPage(),
                VolumePage(),
              ],
            ),
          );
        },
      ),
    );
  }
}
