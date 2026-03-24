part of 'package:onepanelapp_app/features/files/files_page.dart';

extension _FilesViewScaffold on _FilesViewState {
  Widget _buildPageScaffold(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              )
            : null,
        title: Consumer<FilesProvider>(
          builder: (context, provider, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.filesPageTitle,
                overflow: TextOverflow.ellipsis,
              ),
              if (provider.data.currentServer != null)
                Text(
                  provider.data.currentServer!.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          if (canPop)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => showSearchDialog(context),
              tooltip: l10n.filesActionSearch,
            ),
          _buildServerSelector(context),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => context.read<FilesProvider>().refresh(),
            tooltip: l10n.systemSettingsRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: _buildPageBody(context, theme, l10n),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOptions(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.filesActionNew),
      ),
      bottomNavigationBar: Consumer<FilesProvider>(
        builder: (context, provider, _) {
          if (!provider.data.hasSelection) {
            return const SizedBox.shrink();
          }
          return _buildSelectionBar(context, provider, l10n);
        },
      ),
    );
  }

  Widget _buildPageBody(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Consumer<FilesProvider>(
      builder: (context, provider, _) {
        if (provider.data.isLoading && provider.data.files.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.data.error != null) {
          return _buildContentScaffold(
            context,
            provider,
            theme,
            l10n,
            child: _buildErrorState(context, provider, theme),
          );
        }

        if (provider.data.files.isEmpty) {
          return _buildContentScaffold(
            context,
            provider,
            theme,
            l10n,
            child: _buildEmptyState(context, l10n, theme),
          );
        }

        return _buildFileList(context, provider, theme, l10n);
      },
    );
  }
}
