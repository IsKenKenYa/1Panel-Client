import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/services/transfer/transfer_manager.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/debug_error_dialog.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/core/utils/keyboard_utils.dart';
import 'package:onepanel_client/core/utils/intents.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/favorites_page.dart';
import 'package:onepanel_client/features/files/file_editor_page.dart';
import 'package:onepanel_client/features/files/file_preview_page.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/features/files/files_service.dart';
import 'package:onepanel_client/features/files/mounts_page.dart';
import 'package:onepanel_client/features/files/recycle_bin_page.dart';
import 'package:onepanel_client/features/files/upload_history_page.dart';
import 'package:onepanel_client/features/files/transfer_manager_page.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/batch_copy_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/batch_move_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/compress_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/copy_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/create_directory_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/create_file_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/create_link_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/delete_confirm_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/extract_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/file_properties_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/move_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/permission_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/rename_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/search_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/sort_options_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/upload_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/wget_dialog.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/shell_drawer_scope.dart';
import 'package:onepanel_client/features/shell/widgets/server_switcher_action.dart';

export 'models/models.dart' show WgetDownloadState;

part 'files_page/files_page_scaffold_part.dart';
part 'files_page/files_page_content_part.dart';
part 'files_page/files_page_navigation_part.dart';
part 'files_page/files_page_item_part.dart';
part 'files_page/files_page_item_helpers_part.dart';
part 'files_page/files_page_item_actions_part.dart';
part 'files_page/files_page_async_actions_part.dart';
part 'files_page/files_page_actions_part.dart';

class FilesPage extends StatelessWidget {
  const FilesPage({
    super.key,
    this.provider,
    this.service,
    this.autoInitialize = true,
  });

  final FilesProvider? provider;
  final FilesService? service;
  final bool autoInitialize;

  @override
  Widget build(BuildContext context) {
    if (provider != null) {
      return ChangeNotifierProvider<FilesProvider>.value(
        value: provider!,
        child: FilesView(autoInitialize: autoInitialize),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => FilesProvider(service: service),
      child: FilesView(autoInitialize: autoInitialize),
    );
  }
}

class FilesView extends StatefulWidget {
  const FilesView({
    super.key,
    this.autoInitialize = true,
  });

  final bool autoInitialize;

  @override
  State<FilesView> createState() => _FilesViewState();
}

class _FilesViewState extends State<FilesView> {
  String? _activeServerId;

  @override
  void initState() {
    super.initState();
    if (widget.autoInitialize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<FilesProvider>().initialize();
      });
    }
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
    if (!widget.autoInitialize) {
      _activeServerId = serverId;
      return;
    }
    final previousServerId = _activeServerId;
    _activeServerId = serverId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FilesProvider>().onServerChangedWithIds(
            previousServerId: previousServerId,
            nextServerId: serverId,
          );
    });
  }

  @override
  Widget build(BuildContext context) => _buildPageScaffold(context);

  Widget _buildServerSelector(BuildContext context) {
    return const ServerSwitcherAction();
  }
}
