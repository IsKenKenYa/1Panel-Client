import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';
import 'package:onepanel_client/shared/security_gateway/utils/security_gateway_utils.dart';

class RiskNoticeBanner extends StatelessWidget {
  const RiskNoticeBanner({
    super.key,
    required this.notices,
    this.title = 'Risk notices',
    this.bannerKey,
  });

  final List<RiskNotice> notices;
  final String title;
  final Key? bannerKey;

  @override
  Widget build(BuildContext context) {
    if (notices.isEmpty) {
      return const SizedBox.shrink();
    }

    final highestLevel = notices
        .map((notice) => notice.level.index)
        .reduce((current, next) => current > next ? current : next);
    final color = _colorForLevel(
      RiskLevel.values[highestLevel],
      Theme.of(context).colorScheme,
    );

    return Card(
      key: bannerKey,
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: color),
                const SizedBox(width: AppDesignTokens.spacingSm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppDesignTokens.spacingSm),
            for (final notice in notices) ...[
              Text(
                '${describeRiskLevel(notice.level)} · ${notice.title}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppDesignTokens.spacingXs),
              Text(notice.message),
              const SizedBox(height: AppDesignTokens.spacingSm),
            ],
          ],
        ),
      ),
    );
  }

  Color _colorForLevel(RiskLevel level, ColorScheme scheme) {
    switch (level) {
      case RiskLevel.low:
        return AppDesignTokens.warning;
      case RiskLevel.medium:
        return scheme.tertiary;
      case RiskLevel.high:
        return scheme.error;
    }
  }
}
