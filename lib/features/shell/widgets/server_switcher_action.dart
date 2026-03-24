import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';

class ServerSwitcherAction extends StatelessWidget {
  const ServerSwitcherAction({
    super.key,
    this.onChanged,
  });

  final Future<void> Function()? onChanged;

  static Future<void> showServerPicker(
    BuildContext context, {
    Future<void> Function()? onChanged,
  }) async {
    final controller = context.read<CurrentServerController>();
    if (!controller.isLoading) {
      await controller.refresh();
    }
    if (!context.mounted) return;

    final width = MediaQuery.sizeOf(context).width;
    if (width >= 600) {
      await _showServerSheet(context, onChanged: onChanged);
      return;
    }
    await _showServerSheet(context, onChanged: onChanged);
  }

  static Future<void> _showServerSheet(
    BuildContext context, {
    Future<void> Function()? onChanged,
  }) async {
    final controller = context.read<CurrentServerController>();
    final l10n = context.l10n;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.serverActionSwitch,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (controller.servers.isEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.serverListEmptyTitle),
                    subtitle: Text(l10n.serverListEmptyDesc),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Navigator.pushNamed(context, AppRoutes.server);
                    },
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: controller.servers.length,
                      itemBuilder: (itemContext, index) {
                        final server = controller.servers[index];
                        final selected =
                            server.id == controller.currentServerId;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.dns_outlined),
                          title: Text(server.name),
                          subtitle: Text(server.url,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: selected
                              ? Icon(
                                  Icons.check,
                                  color:
                                      Theme.of(itemContext).colorScheme.primary,
                                )
                              : null,
                          selected: selected,
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            await controller.selectServer(server.id);
                            if (onChanged != null) {
                              await onChanged();
                            }
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.pushNamed(context, AppRoutes.server);
                    },
                    icon: const Icon(Icons.settings_outlined),
                    label: Text(l10n.serverPageTitle),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentServerController>(
      builder: (context, controller, _) {
        final l10n = context.l10n;
        final server = controller.currentServer;
        final width = MediaQuery.sizeOf(context).width;
        final color = server == null
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.onSurfaceVariant;

        if (width >= 768) {
          return TextButton.icon(
            onPressed: () => showServerPicker(context, onChanged: onChanged),
            icon: Icon(Icons.dns_outlined, color: color),
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                server?.name ?? l10n.serverActionSwitch,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }

        return IconButton(
          onPressed: () => showServerPicker(context, onChanged: onChanged),
          tooltip: server?.name ?? l10n.serverActionSwitch,
          icon: Icon(Icons.dns_outlined, color: color),
        );
      },
    );
  }
}
