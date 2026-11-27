import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';

class ServerSwitcherAction extends StatelessWidget {
  const ServerSwitcherAction({super.key, this.onChanged, this.displayedServer});

  final Future<void> Function()? onChanged;
  final ApiConfig? displayedServer;

  static Future<void> openModule(
    BuildContext context,
    ClientModule module,
    FutureOr<void> Function(ClientModule) onOpen,
  ) async {
    final server = context.read<CurrentServerController>().currentServer;
    if (module.requiresServer && server == null) {
      await showServerPicker(context);
      return;
    }
    if (module.supportsPanel(server?.panelType)) {
      await onOpen(module);
    }
  }

  static Future<void> showServerPicker(
    BuildContext context, {
    Future<void> Function()? onChanged,
    String? displayedServerId,
  }) async {
    try {
      if (!await _selectServer(context, displayedServerId)) {
        return;
      }
    } catch (error) {
      if (context.mounted) {
        SnackBarUtils.showError(
          context,
          ErrorMessageUtils.userFacingMessage(error),
        );
      }
      return;
    }
    if (context.mounted) {
      await onChanged?.call();
    }
  }

  static Future<bool> _selectServer(
    BuildContext context,
    String? displayedServerId,
  ) async {
    final controller = context.read<CurrentServerController>();
    final route = ModalRoute.of(context);
    await controller.refresh();
    if (!context.mounted || route?.isCurrent == false) {
      return false;
    }
    final selectedId = await showAppFormSheet<String>(
      context,
      title: context.l10n.serverActionSwitch,
      builder: (sheetContext) => ListenableBuilder(
        listenable: controller,
        builder: (_, child) => ServerPickerSheet(
          servers: controller.servers,
          selectedId: displayedServerId ?? controller.currentServerId,
          isLoading: controller.isLoading,
          showTitle: false,
          onSelect: (id) => Navigator.pop(sheetContext, id),
          onManage: () {
            Navigator.pop(sheetContext);
            if (context.mounted) {
              openRouteRespectingShell(context, AppRoutes.server);
            }
          },
        ),
      ),
    );
    if (selectedId == null) {
      return false;
    }
    final selectionChanged =
        selectedId != controller.currentServerId ||
        (displayedServerId != null && displayedServerId != selectedId);
    await controller.selectServer(selectedId);
    return selectionChanged && controller.currentServerId == selectedId;
  }

  @override
  Widget build(BuildContext context) {
    void open() => showServerPicker(
      context,
      onChanged: onChanged,
      displayedServerId: displayedServer?.id,
    );
    return Selector<CurrentServerController, String?>(
      selector: (_, controller) =>
          displayedServer?.name ?? controller.currentServer?.name,
      builder: (context, name, _) {
        final l10n = context.l10n;
        final width = AdaptiveLayoutSpec.of(context).width;
        final color = name == null
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.onSurfaceVariant;

        if (width >= 768) {
          return TextButton.icon(
            onPressed: open,
            icon: Icon(Icons.dns_outlined, color: color),
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                name ?? l10n.serverActionSwitch,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }

        return IconButton(
          onPressed: open,
          tooltip: name ?? l10n.serverActionSwitch,
          icon: Icon(Icons.dns_outlined, color: color),
        );
      },
    );
  }
}

/// 展示当前服务器、可选择的连接和服务器管理入口。
class ServerPickerSheet extends StatelessWidget {
  const ServerPickerSheet({
    super.key,
    required this.servers,
    required this.selectedId,
    required this.isLoading,
    required this.onSelect,
    required this.onManage,
    this.showTitle = true,
  });

  final List<ApiConfig> servers;
  final String? selectedId;
  final bool isLoading;
  final ValueChanged<String> onSelect;
  final VoidCallback onManage;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titleStyle = Theme.of(context).textTheme.titleLarge;
    final manage = Align(
      alignment: AlignmentDirectional.centerEnd,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          minimumSize: const Size.square(kMinInteractiveDimension),
          visualDensity: VisualDensity.standard,
        ),
        onPressed: onManage,
        icon: const Icon(Icons.settings_outlined),
        label: Text(l10n.serverPageTitle),
      ),
    );
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleSize = MediaQuery.textScalerOf(
            context,
          ).scale(titleStyle?.fontSize ?? 22);
          final pinManage =
              constraints.maxHeight >=
              3 * kMinInteractiveDimension + 2 * titleSize;
          final hasHeader = showTitle || !pinManage;
          final list = ListView.builder(
            primary: false,
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount:
                (hasHeader ? 1 : 0) + (servers.isEmpty ? 1 : servers.length),
            itemBuilder: (context, index) {
              if (hasHeader && index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showTitle) ...[
                      Text(l10n.serverActionSwitch, style: titleStyle),
                      const SizedBox(height: 8),
                    ],
                    if (!pinManage) manage,
                  ],
                );
              }
              if (servers.isEmpty) {
                if (isLoading) {
                  return const LinearProgressIndicator();
                }
                return ListTile(
                  minTileHeight: kMinInteractiveDimension,
                  visualDensity: VisualDensity.standard,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.serverListEmptyTitle),
                  subtitle: Text(l10n.serverListEmptyDesc),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onManage,
                );
              }
              final server = servers[index - (hasHeader ? 1 : 0)];
              final selected = server.id == selectedId;
              return ListTile(
                key: ValueKey(server.id),
                minTileHeight: kMinInteractiveDimension,
                visualDensity: VisualDensity.standard,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.dns_outlined),
                title: Text(
                  server.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  server.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: selected
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                selected: selected,
                onTap: () => onSelect(server.id),
              );
            },
          );
          if (!pinManage) {
            return list;
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: list),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: manage,
              ),
            ],
          );
        },
      ),
    );
  }
}
