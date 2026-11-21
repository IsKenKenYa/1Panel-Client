part of 'package:onepanel_client/features/files/files_page.dart';

extension _FilesViewContent on _FilesViewState {
  Widget _buildErrorState(
    BuildContext context,
    FilesProvider provider,
    ThemeData theme,
  ) {
    return ModuleErrorStateWidget(
      message: provider.data.error,
      onRetry: () => provider.loadFiles(),
    );
  }

  Widget _buildFileList(
    BuildContext context,
    FilesProvider provider,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return _buildContentScaffold(
      context,
      provider,
      theme,
      l10n,
      child: RefreshIndicator(
        onRefresh: () => provider.refresh(),
        child: ListView.builder(
          padding: AppDesignTokens.pagePadding +
              shellListBottomPadding(context),
          itemCount: provider.data.files.length,
          itemBuilder: (context, index) {
            final file = provider.data.files[index];
            return _buildFileItem(context, provider, file, theme, l10n,
                index: index);
          },
        ),
      ),
    );
  }

  Widget _buildContentScaffold(
    BuildContext context,
    FilesProvider provider,
    ThemeData theme,
    AppLocalizations l10n, {
    required Widget child,
  }) {
    return _buildResponsiveBody(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPathBreadcrumb(context, provider, theme, l10n),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildResponsiveBody(BuildContext context, Widget child) {
    final spec = AdaptiveLayoutSpec.of(context);
    if (spec.isPhone) {
      return child;
    }

    return AdaptiveWidthContainer(
      maxWidth: spec.filesBodyMaxWidth,
      child: child,
    );
  }
}
