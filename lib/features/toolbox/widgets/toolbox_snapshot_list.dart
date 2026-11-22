import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/partial_error_toast_listener.dart';

class ToolboxSnapshotList extends StatelessWidget {
  const ToolboxSnapshotList({
    super.key,
    required this.hasSnapshot,
    required this.isLoading,
    required this.loadError,
    required this.onRetry,
    required this.children,
  });

  final bool hasSnapshot;
  final bool isLoading;
  final String? loadError;
  final VoidCallback onRetry;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rawError = loadError;
    final error = rawError == null
        ? null
        : ErrorMessageUtils.localizeForContext(rawError, context);
    return PartialErrorToastListener(
      errorMessage: error,
      hasCachedData: hasSnapshot,
      onRetry: onRetry,
      child: AsyncStatePageBodyWidget(
        isLoading: !hasSnapshot && error == null,
        errorMessage: hasSnapshot ? null : error,
        onRetry: onRetry,
        child: ListView(
          padding: AppDesignTokens.cardPadding,
          children: [
            if (isLoading) const LinearProgressIndicator(),
            ...children,
          ],
        ),
      ),
    );
  }
}
