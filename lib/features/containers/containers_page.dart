import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/features/containers/containers_page_container_edit_dialogs.dart';
import 'package:onepanel_client/features/containers/containers_page_container_image_dialogs.dart';
import 'package:onepanel_client/features/containers/containers_page_container_maintenance_dialogs.dart';
import 'package:onepanel_client/features/containers/containers_page_create_dialogs.dart';
import 'package:onepanel_client/features/containers/containers_page_image_dialogs.dart';
import 'package:onepanel_client/features/containers/containers_provider.dart';
import 'package:onepanel_client/features/containers/tabs/config_tab.dart';
import 'package:onepanel_client/features/containers/tabs/containers_tab.dart';
import 'package:onepanel_client/features/containers/tabs/repos_tab.dart';
import 'package:onepanel_client/features/containers/tabs/templates_tab.dart';
import 'package:onepanel_client/features/containers/widgets/container_inline_summary_card.dart';
import 'package:onepanel_client/features/containers/widgets/containers_error_widget.dart';
import 'package:onepanel_client/features/containers/widgets/containers_loading_widget.dart';
import 'package:onepanel_client/features/orchestration/compose_page.dart';
import 'package:onepanel_client/features/orchestration/image_page.dart';
import 'package:onepanel_client/features/orchestration/network_page.dart';
import 'package:onepanel_client/features/orchestration/providers/compose_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/image_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/network_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/volume_provider.dart';
import 'package:onepanel_client/features/orchestration/volume_page.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/module_subnav_controller.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/features/shell/widgets/module_subnav.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';

part 'containers_page/containers_page_sections_part.dart';
part 'containers_page/containers_page_actions_part.dart';

class ContainersPage extends StatelessWidget {
  const ContainersPage({
    super.key,
    this.containersProvider,
    this.composeProvider,
    this.imageProvider,
    this.networkProvider,
    this.volumeProvider,
  });

  final ContainersProvider? containersProvider;
  final ComposeProvider? composeProvider;
  final DockerImageProvider? imageProvider;
  final NetworkProvider? networkProvider;
  final VolumeProvider? volumeProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        if (containersProvider != null)
          ChangeNotifierProvider<ContainersProvider>.value(
              value: containersProvider!)
        else
          ChangeNotifierProvider(create: (_) => ContainersProvider()),
        if (composeProvider != null)
          ChangeNotifierProvider<ComposeProvider>.value(value: composeProvider!)
        else
          ChangeNotifierProvider(create: (_) => ComposeProvider()),
        if (imageProvider != null)
          ChangeNotifierProvider<DockerImageProvider>.value(
              value: imageProvider!)
        else
          ChangeNotifierProvider(create: (_) => DockerImageProvider()),
        if (networkProvider != null)
          ChangeNotifierProvider<NetworkProvider>.value(value: networkProvider!)
        else
          ChangeNotifierProvider(create: (_) => NetworkProvider()),
        if (volumeProvider != null)
          ChangeNotifierProvider<VolumeProvider>.value(value: volumeProvider!)
        else
          ChangeNotifierProvider(create: (_) => VolumeProvider()),
      ],
      child: const _ContainersPageView(),
    );
  }
}

class _ContainersPageView extends StatefulWidget {
  const _ContainersPageView();

  @override
  State<_ContainersPageView> createState() => _ContainersPageViewState();
}

class _ContainersPageViewState extends State<_ContainersPageView> {
  static const _defaultSectionOrder = [
    'containers',
    'images',
    'networks',
    'volumes',
    'compose',
    'repositories',
    'templates',
    'config',
  ];

  late final ModuleSubnavController _subnavController;
  String _selectedSection = 'containers';
  String? _activeServerId;

  @override
  void initState() {
    super.initState();
    _subnavController = ModuleSubnavController(
      storageKey: 'container_module_subnav',
      defaultOrder: _defaultSectionOrder,
    )..load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ContainersProvider>().loadAll();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final serverId =
        Provider.of<CurrentServerController>(context).currentServerId;
    if (_activeServerId == null) {
      _activeServerId = serverId;
      return;
    }
    if (serverId == null || serverId == _activeServerId) {
      return;
    }
    _activeServerId = serverId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleServerChanged();
    });
  }

  Future<void> _handleServerChanged() async {
    final containersProvider = context.read<ContainersProvider>();
    final composeProvider = context.read<ComposeProvider>();
    final imageProvider = context.read<DockerImageProvider>();
    final networkProvider = context.read<NetworkProvider>();
    final volumeProvider = context.read<VolumeProvider>();

    await Future.wait([
      containersProvider.onServerChanged(),
      composeProvider.onServerChanged(reload: _selectedSection == 'compose'),
      imageProvider.onServerChanged(reload: _selectedSection == 'images'),
      networkProvider.onServerChanged(reload: _selectedSection == 'networks'),
      volumeProvider.onServerChanged(reload: _selectedSection == 'volumes'),
    ]);
  }

  @override
  void dispose() {
    _subnavController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: _subnavController,
      builder: (context, _) {
        final subnavItems = _buildSubnavItems(l10n);
        if (!subnavItems.any((item) => item.id == _selectedSection)) {
          _selectedSection = 'containers';
        }

        return ServerAwarePageScaffold(
          title: l10n.containerManagement,
          actions: _buildAppBarActions(context, l10n),
          floatingActionButton: _buildFloatingActionButton(context, l10n),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ContainerInlineSummaryCard(),
                    const SizedBox(height: 8),
                    ModuleSubnav(
                      controller: _subnavController,
                      items: subnavItems,
                      selectedId: _selectedSection,
                      onSelected: (value) {
                        setState(() {
                          _selectedSection = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildSectionContent(context)),
            ],
          ),
        );
      },
    );
  }
}
