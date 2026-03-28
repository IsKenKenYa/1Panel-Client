import 'package:flutter/material.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class ServerSelector extends StatelessWidget {
  const ServerSelector({
    super.key,
    required this.currentServer,
    required this.onServerChanged,
  });

  final ApiConfig? currentServer;
  final void Function(String serverId) onServerChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return FutureBuilder<List<ApiConfig>>(
      future: ApiConfigManager.getConfigs(),
      builder: (context, snapshot) {
        final servers = snapshot.data ?? [];
        return PopupMenuButton<String>(
          icon: Icon(
            Icons.dns_outlined,
            color: currentServer != null ? null : theme.colorScheme.error,
          ),
          tooltip: l10n.serverPageTitle,
          onSelected: (serverId) async {
            await ApiConfigManager.setCurrentConfig(serverId);
            onServerChanged(serverId);
          },
          itemBuilder: (context) {
            if (servers.isEmpty) {
              return [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    l10n.serverListEmptyTitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ];
            }
            return servers
                .map((s) => PopupMenuItem<String>(
                      value: s.id,
                      child: Row(
                        children: [
                          Icon(
                            s.id == currentServer?.id
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 18,
                            color: s.id == currentServer?.id
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(s.name)),
                        ],
                      ),
                    ))
                .toList();
          },
        );
      },
    );
  }
}
