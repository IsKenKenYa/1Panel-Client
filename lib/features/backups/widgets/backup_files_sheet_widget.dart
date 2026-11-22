import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

class BackupFilesSheetWidget extends StatelessWidget {
  const BackupFilesSheetWidget({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: AppDesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(
                    dense: true,
                    title: Text(items[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
