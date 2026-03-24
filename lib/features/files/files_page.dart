import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/core/services/logger/logger_service.dart';
import 'package:onepanelapp_app/core/services/transfer/transfer_manager.dart';
import 'package:onepanelapp_app/core/theme/app_design_tokens.dart';
import 'package:onepanelapp_app/core/utils/debug_error_dialog.dart';
import 'package:onepanelapp_app/data/models/file_models.dart';
import 'package:onepanelapp_app/features/files/favorites_page.dart';
import 'package:onepanelapp_app/features/files/file_editor_page.dart';
import 'package:onepanelapp_app/features/files/file_preview_page.dart';
import 'package:onepanelapp_app/features/files/files_provider.dart';
import 'package:onepanelapp_app/features/files/mounts_page.dart';
import 'package:onepanelapp_app/features/files/recycle_bin_page.dart';
import 'package:onepanelapp_app/features/files/upload_history_page.dart';
import 'package:onepanelapp_app/features/files/transfer_manager_page.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/batch_copy_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/batch_move_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/compress_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/copy_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/create_directory_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/create_file_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/create_link_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/delete_confirm_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/extract_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/file_properties_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/move_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/permission_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/rename_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/search_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/sort_options_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/upload_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/wget_dialog.dart';
import 'package:onepanelapp_app/features/shell/controllers/current_server_controller.dart';
import 'package:onepanelapp_app/features/shell/widgets/server_switcher_action.dart';

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
  const FilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FilesProvider(),
      child: const FilesView(),
    );
  }
}

class FilesView extends StatefulWidget {
  const FilesView({super.key});

  @override
  State<FilesView> createState() => _FilesViewState();
}

class _FilesViewState extends State<FilesView> {
  String? _activeServerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FilesProvider>().initialize();
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
      context.read<FilesProvider>().onServerChanged();
    });
  }

  @override
  Widget build(BuildContext context) => _buildPageScaffold(context);

  Widget _buildServerSelector(BuildContext context) {
    return const ServerSwitcherAction();
  }
}
