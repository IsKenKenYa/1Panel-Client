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

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final provider = context.read<FilesProvider>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(l10n.filesEmptyTitle),
          const SizedBox(height: 8),
          Text(l10n.filesEmptyDesc, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => showCreateDirectoryDialog(context, provider),
                icon: const Icon(Icons.create_new_folder_outlined),
                label: Text(l10n.filesActionNewFolder),
              ),
              OutlinedButton.icon(
                onPressed: () => showCreateFileDialog(context, provider),
                icon: const Icon(Icons.note_add_outlined),
                label: Text(l10n.filesActionNewFile),
              ),
            ],
          ),
        ],
      ),
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
          padding: AppDesignTokens.pagePadding,
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
