import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/shared/widgets/operations/module_empty_state_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';

class AsyncStatePageBodyWidget extends StatelessWidget {
  const AsyncStatePageBodyWidget({
    super.key,
    required this.child,
    this.isLoading = false,
    this.isEmpty = false,
    this.errorMessage,
    this.onRetry,
    this.emptyTitle,
    this.emptyDescription,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyActionLabel,
    this.onEmptyAction,
  });

  final Widget child;
  final bool isLoading;
  final bool isEmpty;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String? emptyTitle;
  final String? emptyDescription;
  final IconData emptyIcon;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return ModuleErrorStateWidget(
        message: errorMessage,
        onRetry: onRetry,
      );
    }

    if (isEmpty) {
      return ModuleEmptyStateWidget(
        title: emptyTitle ?? l10n.commonEmpty,
        description: emptyDescription ?? l10n.commonComingSoon,
        icon: emptyIcon,
        actionLabel: emptyActionLabel,
        onAction: onEmptyAction,
      );
    }

    return child;
  }
}
