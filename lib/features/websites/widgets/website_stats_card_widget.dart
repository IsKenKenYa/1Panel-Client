import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/websites/providers/websites_provider.dart';

class WebsitesStatsCard extends StatelessWidget {
  const WebsitesStatsCard({super.key, required this.stats});

  final WebsiteStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.websitesStatsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  title: l10n.websitesStatsTotal,
                  value: stats.total.toString(),
                  color: colorScheme.primary,
                  icon: Icons.language,
                ),
                _StatItem(
                  title: l10n.websitesStatsRunning,
                  value: stats.running.toString(),
                  color: colorScheme.tertiary,
                  icon: Icons.play_circle,
                ),
                _StatItem(
                  title: l10n.websitesStatsStopped,
                  value: stats.stopped.toString(),
                  color: colorScheme.secondary,
                  icon: Icons.stop_circle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
