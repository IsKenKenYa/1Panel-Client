import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

class DatabaseDetailSectionsWidget extends StatelessWidget {
  const DatabaseDetailSectionsWidget({
    super.key,
    required this.item,
    required this.detail,
  });

  final DatabaseListItem item;
  final DatabaseDetailData? detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        AppCard(
          title: l10n.databaseOverviewTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: l10n.commonName, value: item.name),
              _DetailRow(label: l10n.databaseEngineLabel, value: item.engine),
              _DetailRow(label: l10n.databaseSourceLabel, value: item.source),
              _DetailRow(
                label: l10n.databaseAddressLabel,
                value: item.address ?? '-',
              ),
              _DetailRow(
                label: l10n.databaseUsernameLabel,
                value: item.username ?? '-',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDesignTokens.spacingMd),
        AppCard(
          title: l10n.databaseConfigTitle,
          child: Text(detail?.rawConfigFile ?? '-'),
        ),
        if (detail?.baseInfo != null) ...[
          const SizedBox(height: AppDesignTokens.spacingMd),
          AppCard(
            title: l10n.databaseBaseInfoTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  label: l10n.databaseContainerLabel,
                  value: detail!.baseInfo!.containerName ?? '-',
                ),
                _DetailRow(
                  label: l10n.databasePortLabel,
                  value: detail!.baseInfo!.port?.toString() ?? '-',
                ),
                _DetailRow(
                  label: l10n.databaseRemoteAccessLabel,
                  value: detail!.baseInfo!.remoteConn == true
                      ? l10n.commonYes
                      : l10n.commonNo,
                ),
              ],
            ),
          ),
        ],
        if (detail?.status != null) ...[
          const SizedBox(height: AppDesignTokens.spacingMd),
          AppCard(
            title: l10n.databaseStatusTitle,
            child: Text(detail!.status.toString()),
          ),
        ],
        if (detail?.variables != null) ...[
          const SizedBox(height: AppDesignTokens.spacingMd),
          AppCard(
            title: l10n.databaseVariablesTitle,
            child: Text(detail!.variables.toString()),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesignTokens.spacingXs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: AppDesignTokens.spacingSm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
