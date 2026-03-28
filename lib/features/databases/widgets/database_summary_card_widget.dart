import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

class DatabaseSummaryCardWidget extends StatelessWidget {
  const DatabaseSummaryCardWidget({
    super.key,
    required this.item,
  });

  final DatabaseListItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      title: l10n.databaseOverviewTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${l10n.commonName}: ${item.name}'),
          Text('${l10n.databaseEngineLabel}: ${item.engine}'),
          Text('${l10n.databaseScopeLabel}: ${item.scope.value}'),
        ],
      ),
    );
  }
}
