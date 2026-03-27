import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class CronjobFormUrlTargetSectionWidget extends StatelessWidget {
  const CronjobFormUrlTargetSectionWidget({
    super.key,
    required this.urlItems,
    required this.onChanged,
  });

  final List<String> urlItems;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: <Widget>[
        for (var index = 0; index < urlItems.length; index++) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  key: ValueKey<String>('curl-url-$index-${urlItems[index]}'),
                  initialValue: urlItems[index],
                  onChanged: (value) {
                    final items = List<String>.from(urlItems);
                    items[index] = value;
                    onChanged(items);
                  },
                  decoration: InputDecoration(
                    labelText: l10n.cronjobFormUrlItemLabel(index + 1),
                  ),
                ),
              ),
              if (urlItems.length > 1)
                IconButton(
                  onPressed: () {
                    final items = List<String>.from(urlItems)..removeAt(index);
                    onChanged(items);
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => onChanged(<String>[...urlItems, '']),
            icon: const Icon(Icons.add),
            label: Text(l10n.cronjobFormAddUrlAction),
          ),
        ),
      ],
    );
  }
}
