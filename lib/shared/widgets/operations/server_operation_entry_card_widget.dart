import 'package:flutter/material.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

class ServerOperationEntryCardWidget extends StatelessWidget {
  const ServerOperationEntryCardWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.badgeLabel,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String badgeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      title: title,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Chip(label: Text(badgeLabel)),
      child: Row(
        children: <Widget>[
          Text(
            MaterialLocalizations.of(context).viewLicensesButtonLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.transparent,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
