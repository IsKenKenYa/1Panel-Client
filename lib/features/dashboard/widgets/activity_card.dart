import 'package:flutter/material.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/i18n/l10n_x.dart';
import '../../../shared/widgets/app_card.dart';
import '../dashboard_provider.dart';

class ActivityCard extends StatelessWidget {
  final List<DashboardActivity> activities;

  const ActivityCard({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      title: l10n.dashboardActivityTitle,
      child: activities.isEmpty
          ? Center(
              child: Padding(
                padding: AppDesignTokens.cardPadding,
                child: Text(l10n.dashboardActivityEmpty),
              ),
            )
          : Column(
              children: activities
                  .map((activity) => _ActivityItem(
                        title: activity.title,
                        description: activity.description,
                        time: _formatTimeAgo(context, activity.time),
                        type: activity.type,
                      ))
                  .toList(),
            ),
    );
  }

  String _formatTimeAgo(BuildContext context, DateTime time) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
      return l10n.dashboardActivityDaysAgo(diff.inDays);
    } else if (diff.inHours > 0) {
      return l10n.dashboardActivityHoursAgo(diff.inHours);
    } else if (diff.inMinutes > 0) {
      return l10n.dashboardActivityMinutesAgo(diff.inMinutes);
    } else {
      return l10n.dashboardActivityJustNow;
    }
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String description;
  final String time;
  final ActivityType type;

  const _ActivityItem({
    required this.title,
    required this.description,
    required this.time,
    this.type = ActivityType.info,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypeIcon(context),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    IconData iconData;
    Color color;

    switch (type) {
      case ActivityType.success:
        iconData = Icons.check_circle;
        color = colorScheme.primary;
        break;
      case ActivityType.warning:
        iconData = Icons.warning;
        color = colorScheme.tertiary;
        break;
      case ActivityType.error:
        iconData = Icons.error;
        color = colorScheme.error;
        break;
      case ActivityType.info:
        iconData = Icons.info;
        color = colorScheme.secondary;
        break;
    }

    return Icon(iconData, color: color, size: 20);
  }
}
