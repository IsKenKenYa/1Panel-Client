import 'package:flutter/material.dart';

class WebsiteSectionCard extends StatelessWidget {
  const WebsiteSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: icon == null ? null : Icon(icon),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
