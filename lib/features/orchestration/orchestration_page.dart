import 'package:flutter/material.dart';
import 'package:onepanel_client/features/containers/containers_page_create_dialogs.dart';
import 'package:onepanel_client/features/containers/containers_page_image_dialogs.dart';
import 'package:onepanel_client/features/orchestration/compose_page.dart';
import 'package:onepanel_client/features/orchestration/compose_template_page.dart';
import 'package:onepanel_client/features/orchestration/image_page.dart';
import 'package:onepanel_client/features/orchestration/network_page.dart';
import 'package:onepanel_client/features/orchestration/providers/compose_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/compose_template_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/image_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/network_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/volume_provider.dart';
import 'package:onepanel_client/features/orchestration/volume_page.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/orchestration/widgets/compose_template_dialog.dart';
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
    _tabController = TabController(length: 5, vsync: this)
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
          icon: const Icon(Icons.add_outlined),
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
          icon: const Icon(Icons.add_outlined),
          label: Text(l10n.orchestrationCreateNetwork),
        );
      case 3:
        return FloatingActionButton.extended(
          heroTag: 'orchestration_volume_fab',
          onPressed: () =>
              ContainersPageCreateDialogs.showCreateVolumeDialog(context),
          icon: const Icon(Icons.add_outlined),
          label: Text(l10n.orchestrationCreateVolume),
        );
      case 4:
        return FloatingActionButton.extended(
          heroTag: 'orchestration_template_fab',
          onPressed: () => _createTemplate(context),
          icon: const Icon(Icons.add_outlined),
          label: Text(l10n.orchestrationCreateTemplate),
        );
      default:
        return null;
    }
  }

  Future<void> _createTemplate(BuildContext context) async {
    final request = await showComposeTemplateEditDialog(context);
    if (request == null || !context.mounted) return;
    final provider = context.read<ComposeTemplateProvider>();
    final ok = await provider.createTemplate(request);
    if (!context.mounted) return;
    if (ok) {
      SnackBarUtils.showSuccess(context, context.l10n.commonCreateSuccess);
    } else {
      SnackBarUtils.showError(
          context, ErrorMessageUtils.truncateForToast(provider.error ?? context.l10n.commonUnknownError));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // When OrchestrationPage is embedded inside the containers module shell,
    // the parent ContainersPage already provides ComposeProvider,
    // DockerImageProvider, NetworkProvider, and VolumeProvider. Re-registering
    // them here would create independent instances whose state diverges from
    // the containers view (architecture review candidate ⑧).
    //
    // _provideIfMissing checks whether each provider is already available in
    // the ancestor tree and only creates a new one when missing (standalone
    // route access).
    return _provideIfMissing(
      context,
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
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
                  Tab(text: l10n.orchestrationTemplates),
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
                ComposeTemplatePage(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Wraps [child] with provider registrations only for those not already
  /// available in the ancestor tree. This prevents duplicate independent
  /// instances when OrchestrationPage is embedded inside ContainersPage
  /// (which already provides the same providers).
  Widget _provideIfMissing(BuildContext context, {required Widget child}) {
    var result = child;
    // Check each provider; wrap only when missing. Order doesn't matter
    // since they are independent provider types.
    if (_missing<VolumeProvider>(context)) {
      result = ChangeNotifierProvider(
          create: (_) => VolumeProvider(), child: result);
    }
    if (_missing<NetworkProvider>(context)) {
      result = ChangeNotifierProvider(
          create: (_) => NetworkProvider(), child: result);
    }
    if (_missing<DockerImageProvider>(context)) {
      result = ChangeNotifierProvider(
          create: (_) => DockerImageProvider(), child: result);
    }
    if (_missing<ComposeProvider>(context)) {
      result = ChangeNotifierProvider(
          create: (_) => ComposeProvider(), child: result);
    }
    if (_missing<ComposeTemplateProvider>(context)) {
      result = ChangeNotifierProvider(
          create: (_) => ComposeTemplateProvider(), child: result);
    }
    return result;
  }

  static bool _missing<T extends ChangeNotifier>(BuildContext context) {
    try {
      Provider.of<T>(context, listen: false);
      return false;
    } on ProviderNotFoundException {
      return true;
    }
  }
}
