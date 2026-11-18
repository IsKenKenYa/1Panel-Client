import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/server/server_form_page.dart';
import 'package:onepanel_client/features/server/server_models.dart';
import 'package:onepanel_client/features/server/view_models/server_list_view_model.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';

/// 服务器列表 UI 交互编排：表单打开、删除确认与结果反馈。
/// 业务数据操作在 [ServerListViewModel]，确认弹窗与 SnackBar 留在 UI 层。

/// 打开服务器新增/编辑表单：桌面端对话框、移动端推入页面；
/// 表单成功关闭后统一刷新列表与当前服务器控制器。
Future<void> openServerForm(
  BuildContext context,
  ServerListViewModel viewModel,
) async {
  final currentServer = context.read<CurrentServerController>();
  final bool? result;
  if (PlatformUtils.isDesktop(context)) {
    result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 720,
            maxHeight: 820,
          ),
          child: const ServerFormPage(),
        ),
      ),
    );
  } else {
    result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ServerFormPage()),
    );
  }

  if (result == true) {
    await viewModel.refreshAfterServerChange();
    if (context.mounted) {
      await currentServer.refresh();
    }
  }
}

/// 确认并删除服务器：ConfirmActionSheet 二次确认 → VM 删除 → 刷新控制器 → 反馈。
Future<void> confirmAndDeleteServer(
  BuildContext context,
  ServerListViewModel viewModel,
  ServerCardViewModel item,
) async {
  final l10n = context.l10n;
  final confirmed = await ConfirmActionSheetWidget.show(
    context,
    title: l10n.serverDeleteConfirmTitle,
    message: l10n.serverDeleteConfirmMessage(item.config.name),
    confirmLabel: l10n.commonDelete,
    isDestructive: true,
  );
  if (!confirmed || !context.mounted) {
    return;
  }

  final currentServerController = context.read<CurrentServerController>();
  try {
    await viewModel.deleteServer(item);
    await currentServerController.refresh();
    if (!context.mounted) {
      return;
    }
    SnackBarUtils.showSuccess(
      context,
      l10n.serverDeleteSuccess(item.config.name),
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    SnackBarUtils.showError(context, l10n.serverDeleteFailed(error.toString()));
  }
}
