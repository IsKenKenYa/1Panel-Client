import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class PhpContainerSectionHeaderWidget extends StatelessWidget {
  const PhpContainerSectionHeaderWidget({
    super.key,
    required this.title,
    required this.onAdd,
  });

  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text(context.l10n.commonAdd),
        ),
      ],
    );
  }
}

class PhpContainerInlineRowWidget extends StatelessWidget {
  const PhpContainerInlineRowWidget({
    super.key,
    required this.first,
    required this.second,
    required this.onRemove,
    this.third,
  });

  final Widget first;
  final Widget second;
  final Widget? third;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: first),
          const SizedBox(width: 8),
          Expanded(child: second),
          if (third != null) ...<Widget>[
            const SizedBox(width: 8),
            Expanded(child: third!),
          ],
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
            tooltip: context.l10n.commonDelete,
          ),
        ],
      ),
    );
  }
}
