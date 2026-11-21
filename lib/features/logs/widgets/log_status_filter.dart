import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

/// 登录、操作和任务日志共用的状态筛选。任务日志还显示执行中的数量。
class LogStatusFilter extends StatelessWidget {
  const LogStatusFilter({
    super.key,
    required this.value,
    required this.onChanged,
    this.executingCount,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final int? executingCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = [
      ('', l10n.logsStatusAll),
      ('Success', l10n.logsStatusSuccess),
      ('Failed', l10n.logsStatusFailed),
      if (executingCount != null) ('Executing', l10n.logsStatusExecuting),
    ];
    return Wrap(
      spacing: AppDesignTokens.spacingSm,
      runSpacing: executingCount == null ? 0 : AppDesignTokens.spacingSm,
      children: [
        if (executingCount != null)
          Chip(label: Text(l10n.logsTaskExecutingCountLabel(executingCount!))),
        for (final (status, label) in options)
          ChoiceChip(
            label: Text(label),
            selected: value == status,
            onSelected: (_) => onChanged(status),
          ),
      ],
    );
  }
}
