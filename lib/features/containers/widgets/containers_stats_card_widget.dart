import 'package:flutter/material.dart';
import 'package:onepanelapp_app/shared/widgets/app_card.dart';

class ContainersStatsCard extends StatelessWidget {
  final String title;
  final List<ContainersStatItem> items;

  const ContainersStatsCard({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: title,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items,
      ),
    );
  }
}

class ContainersStatItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const ContainersStatItem({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
