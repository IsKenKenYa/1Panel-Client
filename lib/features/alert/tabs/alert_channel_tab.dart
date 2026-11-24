import 'package:flutter/material.dart';
import 'package:onepanel_client/features/alert/alert_types.dart';
import 'package:onepanel_client/features/alert/widgets/alert_configuration_row.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/alert_models.dart';
import 'package:onepanel_client/features/alert/providers/alert_provider.dart';
import 'package:onepanel_client/features/alert/widgets/alert_channel_form.dart';
import 'package:onepanel_client/shared/widgets/expressive_section.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';

/// 通知渠道分区：六类渠道、状态切换与测试。
class AlertChannelTab extends StatelessWidget {
  const AlertChannelTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<AlertProvider>();

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDesignTokens.spacingLg,
            AppDesignTokens.spacingMd,
            AppDesignTokens.spacingLg,
            AppDesignTokens.spacingSm,
          ),
          child: Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                tooltip: l10n.commonRefresh,
                onPressed: provider.isMutating ? null : provider.loadChannels,
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () => showAlertChannelForm(context),
                icon: const Icon(Icons.add_outlined),
                label: Text(l10n.alertChannelCreateAction),
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncStatePageBodyWidget(
            isLoading: provider.channelLoading && provider.channels.isEmpty,
            isEmpty:
                provider.channels.isEmpty && provider.channelError == null,
            errorMessage: provider.channelError,
            onRetry: provider.loadChannels,
            emptyTitle: l10n.alertChannelEmptyTitle,
            emptyDescription: l10n.alertChannelEmptyDescription,
            emptyIcon: Icons.campaign_outlined,
            emptyActionLabel: l10n.alertChannelCreateAction,
            onEmptyAction: () => showAlertChannelForm(context),
            child: RefreshIndicator(
              onRefresh: provider.loadChannels,
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
                    title: l10n.alertTabChannels,
                    isBusy: provider.channelLoading,
                    children: <Widget>[
                      for (final channel in provider.channels)
                        _ChannelRow(channel: channel, provider: provider),
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

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.channel, required this.provider});

  final AlertConfigInfo channel;
  final AlertProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabled = channel.status != 'Disable';
    final title = channel.title.isEmpty ? channel.type : channel.title;

    return AlertConfigurationRow(
      icon: AlertChannelUI.icon(channel.type),
      title: title,
      titleLines: 1,
      subtitle: AlertChannelUI.label(l10n, channel.type),
      description: channel.config.isEmpty ? null : _summary(channel.config),
      enabled: enabled,
      isMutating: provider.isMutating,
      onToggle: (value) => _toggle(context, value),
      onEdit: () => showAlertChannelForm(context, editing: channel),
      onDelete: () => _delete(context),
    );
  }

  /// 渠道配置摘要：过长时截断，避免单条记录撑高列表。
  String _summary(String config) {
    if (config.length <= 160) return config;
    return '${config.substring(0, 160)}…';
  }

  Future<void> _toggle(BuildContext context, bool enable) async {
    final l10n = context.l10n;
    try {
      await provider.toggleChannel(channel.id, enable);
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(
        context,
        enable ? l10n.alertChannelEnabledLabel : l10n.alertChannelDisabledLabel,
      );
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
      message: l10n.alertChannelDeleteConfirm(channel.title),
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await provider.deleteChannel(channel.id);
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, l10n.commonDeleted);
    } catch (error) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, error.toString());
    }
  }
}

/// 渠道类型的界面标签与图标。
class AlertChannelUI {
  const AlertChannelUI._();

  static String label(AppLocalizations l10n, String type) {
    switch (type) {
      case AlertChannelTypes.email:
        return l10n.alertChannelTypeEmail;
      case AlertChannelTypes.bark:
        return l10n.alertChannelTypeBark;
      case AlertChannelTypes.weCom:
        return l10n.alertChannelTypeWeCom;
      case AlertChannelTypes.dingTalk:
        return l10n.alertChannelTypeDingTalk;
      case AlertChannelTypes.feiShu:
        return l10n.alertChannelTypeFeiShu;
      case AlertChannelTypes.custom:
        return l10n.alertChannelTypeCustom;
      default:
        return type;
    }
  }

  static IconData icon(String type) {
    switch (type) {
      case AlertChannelTypes.email:
        return Icons.mail_outline;
      case AlertChannelTypes.bark:
        return Icons.notifications_active_outlined;
      case AlertChannelTypes.weCom:
      case AlertChannelTypes.dingTalk:
      case AlertChannelTypes.feiShu:
        return Icons.chat_bubble_outline;
      case AlertChannelTypes.custom:
        return Icons.webhook_outlined;
      default:
        return Icons.campaign_outlined;
    }
  }
}
