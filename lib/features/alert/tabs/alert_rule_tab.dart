import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/alert_models.dart';
import 'package:onepanel_client/features/alert/alert_types.dart';
import 'package:onepanel_client/features/alert/providers/alert_provider.dart';
import 'package:onepanel_client/features/alert/widgets/alert_rule_form.dart';
import 'package:onepanel_client/features/alert/widgets/alert_configuration_row.dart';
import 'package:onepanel_client/shared/widgets/expressive_section.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';

/// 告警任务分区。
///
/// 顶部为类型与状态筛选胶囊，任务逐条渲染在分区卡片内；每条任务用标题、
/// 规则摘要与两行元数据承载信息，而不是堆叠彩色小标签。
class AlertRuleTab extends StatelessWidget {
  const AlertRuleTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<AlertProvider>();

    return Column(
      children: <Widget>[
        _RuleFilterBar(provider: provider),
        Expanded(
          child: AsyncStatePageBodyWidget(
            isLoading: provider.ruleLoading && provider.rules.isEmpty,
            isEmpty: provider.rules.isEmpty && provider.ruleError == null,
            errorMessage: provider.ruleError,
            onRetry: provider.loadRules,
            emptyTitle: l10n.alertRuleEmptyTitle,
            emptyDescription: l10n.alertRuleEmptyDescription,
            emptyIcon: Icons.notifications_active_outlined,
            emptyActionLabel: l10n.alertRuleCreateAction,
            onEmptyAction: () => showAlertRuleForm(context),
            child: RefreshIndicator(
              onRefresh: provider.loadRules,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppDesignTokens.spacingLg,
                  AppDesignTokens.spacingSm,
                  AppDesignTokens.spacingLg,
                  AppDesignTokens.spacingXl +
                      MediaQuery.paddingOf(context).bottom,
                ),
                children: <Widget>[
                  ExpressiveSection(
                    title: l10n.alertTabRules,
                    isBusy: provider.ruleLoading,
                    children: <Widget>[
                      for (final rule in provider.rules)
                        _RuleRow(rule: rule, provider: provider),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RuleFilterBar extends StatelessWidget {
  const _RuleFilterBar({required this.provider});

  final AlertProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDesignTokens.spacingLg,
        AppDesignTokens.spacingMd,
        AppDesignTokens.spacingLg,
        AppDesignTokens.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ExpressiveFilterBar(
            options: <(String, String)>[
              ('all', l10n.alertRuleFilterAllStatuses),
              ('Enable', l10n.alertRuleStatusEnable),
              ('Disable', l10n.alertRuleStatusDisable),
            ],
            selected: provider.ruleStatus ?? 'all',
            onSelected: (value) => provider.setRuleStatus(
              value == null || value == 'all' ? null : value,
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          ExpressiveFilterBar(
            options: <(String, String)>[
              ('all', l10n.alertRuleFilterAllTypes),
              for (final type in AlertRuleTypes.values)
                (type, AlertTypeLabels.label(l10n, type)),
            ],
            selected: provider.ruleType ?? 'all',
            onSelected: (value) => provider.setRuleType(
              value == null || value == 'all' ? null : value,
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: () => showAlertRuleForm(context),
              icon: const Icon(Icons.add_outlined),
              label: Text(l10n.alertRuleCreateAction),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.rule, required this.provider});

  final AlertInfo rule;
  final AlertProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabled = rule.status != 'Disable';
    final title = rule.title.isEmpty
        ? AlertTypeLabels.label(l10n, rule.type)
        : rule.title;
    final meta = <String>[
      AlertTypeLabels.label(l10n, rule.type),
      AlertRuleFormatter.describe(l10n, rule),
      if (rule.sendMethod.isNotEmpty) rule.sendMethod.join(' / '),
    ];

    return AlertConfigurationRow(
      icon: Icons.notifications_active_outlined,
      title: title,
      subtitle: meta.join(' · '),
      enabled: enabled,
      isMutating: provider.isMutating,
      onToggle: (value) => _toggle(context, value),
      onEdit: () => showAlertRuleForm(context, editing: rule),
      onDelete: () => _delete(context),
    );
  }

  Future<void> _toggle(BuildContext context, bool enable) async {
    final l10n = context.l10n;
    final actionLabel =
        enable ? l10n.alertRuleStatusEnable : l10n.alertRuleStatusDisable;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: actionLabel,
      message: l10n.alertRuleToggleConfirm(actionLabel, rule.title),
      confirmLabel: actionLabel,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await provider.toggleRule(rule.id, enable);
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, l10n.commonOperationSuccess);
    } catch (error) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, error.toString());
    }
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.commonDelete,
      message: l10n.alertRuleDeleteConfirm(rule.title),
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await provider.deleteRule(rule.id);
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, l10n.commonDeleted);
    } catch (error) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, error.toString());
    }
  }
}
