import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/server/server_form_page.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';

/// 宽内容区内打开对话框，其余宽度使用独立页面。
Future<bool?> openServerForm(BuildContext context, {String? serverId}) {
  Widget form() => serverId == null
      ? const ServerFormPage()
      : _EditServerForm(serverId: serverId);
  if (AdaptiveLayoutSpec.of(context).isDesktop) {
    return showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: AppRoutes.serverConfig),
      builder: (dialogContext) => LayoutBuilder(
        builder: (context, constraints) {
          final spec = AdaptiveLayoutSpec.of(context);
          final compact =
              constraints.maxWidth < PlatformUtils.mobileWidthBreakpoint ||
                  constraints.maxHeight < 480;
          return Dialog(
            insetPadding: compact ? EdgeInsets.zero : spec.dialogInsetPadding,
            constraints: compact
                ? BoxConstraints.tight(constraints.biggest)
                : spec.dialogConstraints.copyWith(maxHeight: 820),
            clipBehavior: Clip.antiAlias,
            child: form(),
          );
        },
      ),
    );
  }
  return Navigator.push<bool>(
    context,
    MaterialPageRoute(
      settings: const RouteSettings(name: AppRoutes.serverConfig),
      builder: (_) => form(),
    ),
  );
}

class _EditServerForm extends StatefulWidget {
  const _EditServerForm({required this.serverId});

  final String serverId;

  @override
  State<_EditServerForm> createState() => _EditServerFormState();
}

class _EditServerFormState extends State<_EditServerForm> {
  late Future<ApiConfig> _config = _load();

  Future<ApiConfig> _load() =>
      context.read<ServerProvider>().readConfig(widget.serverId);

  @override
  Widget build(BuildContext context) => FutureBuilder<ApiConfig>(
        future: _config,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ServerFormPage(existing: snapshot.requireData);
          }
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.serverFormEditTitle)),
            body: snapshot.hasError
                ? ModuleErrorStateWidget(
                    message: context.l10n.serverFormStorageError,
                    onRetry: () => setState(() => _config = _load()),
                  )
                : const Center(child: CircularProgressIndicator()),
          );
        },
      );
}

/// 用户确认后删除指定服务器并刷新当前选择。
Future<bool> confirmAndDeleteServer(
  BuildContext context,
  ApiConfig config,
) async {
  final l10n = context.l10n;
  final confirmed = await ConfirmActionSheetWidget.show(
    context,
    title: l10n.serverDeleteConfirmTitle,
    message: l10n.serverDeleteConfirmMessage(config.name),
    confirmLabel: l10n.commonDelete,
    isDestructive: true,
  );
  if (!confirmed || !context.mounted) {
    return false;
  }

  try {
    await context.read<ServerProvider>().delete(config.id);
    if (!context.mounted) {
      return true;
    }
    SnackBarUtils.showSuccess(
      context,
      l10n.serverDeleteSuccess(config.name),
    );
    return true;
  } catch (error) {
    if (!context.mounted) {
      return false;
    }
    SnackBarUtils.showError(context, l10n.serverDeleteFailed(error.toString()));
    return false;
  }
}
