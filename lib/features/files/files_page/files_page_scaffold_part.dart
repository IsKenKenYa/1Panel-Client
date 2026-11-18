part of 'package:onepanel_client/features/files/files_page.dart';

extension _FilesViewScaffold on _FilesViewState {
  Widget _buildPageScaffold(BuildContext context) {
    final spec = AdaptiveLayoutSpec.of(context);
    if (spec.isDesktop) {
      return _buildDesktopScaffold(context);
    }
    final provider = context.watch<FilesProvider>();
    final path = provider.data.currentPath;
    final inSubdirectory = path.isNotEmpty && path != '/';
    final canPopRoute = Navigator.canPop(context);

    return PopScope(
      canPop: !inSubdirectory && (canPopRoute || spec.isTablet),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && inSubdirectory) {
          provider.navigateUp();
        }
      },
      child: spec.isTablet
          ? _buildTabletScaffold(context, showDirectoryBack: inSubdirectory)
          : _buildMobileScaffold(
              context,
              showBack: canPopRoute || inSubdirectory,
              showSearch: canPopRoute,
            ),
    );
  }

  Widget _buildMobileScaffold(
    BuildContext context, {
    required bool showBack,
    required bool showSearch,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final provider = context.read<FilesProvider>();

    return Shortcuts(
      shortcuts: {
        KeyboardUtils.modifierPlus(LogicalKeyboardKey.keyA):
            const SelectAllIntent(),
        const SingleActivator(LogicalKeyboardKey.delete):
            const DeleteSelectedIntent(),
        const SingleActivator(LogicalKeyboardKey.backspace):
            const DeleteSelectedIntent(),
        const SingleActivator(LogicalKeyboardKey.escape):
            const ClearSelectionIntent(),
      },
      child: Actions(
        actions: {
          SelectAllIntent: CallbackAction<SelectAllIntent>(
            onInvoke: (_) => provider.selectAll(),
          ),
          DeleteSelectedIntent: CallbackAction<DeleteSelectedIntent>(
            onInvoke: (_) {
              if (provider.data.hasSelection) {
                showDeleteConfirmDialog(context, provider, l10n);
              }
              return null;
            },
          ),
          ClearSelectionIntent: CallbackAction<ClearSelectionIntent>(
            onInvoke: (_) => provider.clearSelection(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              leading: showBack
                  ? const BackButton()
                  : buildShellDrawerLeading(
                      context,
                      key: const Key('shell-drawer-menu-button'),
                    ),
              title: Column(
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
              actions: [
                if (showSearch)
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => showSearchDialog(context),
                    tooltip: l10n.filesActionSearch,
                  ),
                _buildServerSelector(context),
                IconButton(
                  icon: const Icon(Icons.refresh_outlined),
                  onPressed: () => provider.refresh(),
                  tooltip: l10n.systemSettingsRefresh,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  tooltip: context.l10n.commonMore,
                  onPressed: () => _showMoreOptions(context),
                ),
              ],
            ),
            body: _buildPageBody(context, theme, l10n),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'files_page_create_fab',
              onPressed: () => _showCreateOptions(context),
              icon: const Icon(Icons.add_outlined),
              label: Text(l10n.filesActionNew),
            ),
            bottomNavigationBar: !provider.data.hasSelection
                ? const SizedBox.shrink()
                : _buildSelectionBar(context, provider, l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopScaffold(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final provider = context.watch<FilesProvider>();

    return Shortcuts(
      shortcuts: {
        KeyboardUtils.modifierPlus(LogicalKeyboardKey.keyA):
            const SelectAllIntent(),
        const SingleActivator(LogicalKeyboardKey.delete):
            const DeleteSelectedIntent(),
        const SingleActivator(LogicalKeyboardKey.backspace):
            const DeleteSelectedIntent(),
        const SingleActivator(LogicalKeyboardKey.escape):
            const ClearSelectionIntent(),
      },
      child: Actions(
        actions: {
          SelectAllIntent: CallbackAction<SelectAllIntent>(
            onInvoke: (_) => provider.selectAll(),
          ),
          DeleteSelectedIntent: CallbackAction<DeleteSelectedIntent>(
            onInvoke: (_) {
              if (provider.data.hasSelection) {
                showDeleteConfirmDialog(context, provider, l10n);
              }
              return null;
            },
          ),
          ClearSelectionIntent: CallbackAction<ClearSelectionIntent>(
            onInvoke: (_) => provider.clearSelection(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            body: Column(
              children: [
                // Desktop specific toolbar area
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      bottom:
                          BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                  child: Row(
                    children: [
                      FilledButton.icon(
                        onPressed: () => _showCreateOptions(context),
                        icon: const Icon(Icons.add_outlined),
                        label: Text(l10n.filesActionNew),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh_outlined),
                        onPressed: () => provider.refresh(),
                        tooltip: l10n.systemSettingsRefresh,
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => showSearchDialog(context),
                        tooltip: l10n.filesActionSearch,
                      ),
                      const Spacer(),
                      if (provider.data.hasSelection)
                        _buildDesktopSelectionActions(context, provider, l10n),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        tooltip: context.l10n.commonMore,
                        onPressed: () => _showMoreOptions(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildPageBody(context, theme, l10n),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletScaffold(
    BuildContext context, {
    required bool showDirectoryBack,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final provider = context.read<FilesProvider>();
    final spec = AdaptiveLayoutSpec.of(context);

    return Shortcuts(
      shortcuts: {
        KeyboardUtils.modifierPlus(LogicalKeyboardKey.keyA):
            const SelectAllIntent(),
        const SingleActivator(LogicalKeyboardKey.delete):
            const DeleteSelectedIntent(),
        const SingleActivator(LogicalKeyboardKey.backspace):
            const DeleteSelectedIntent(),
        const SingleActivator(LogicalKeyboardKey.escape):
            const ClearSelectionIntent(),
      },
      child: Actions(
        actions: {
          SelectAllIntent: CallbackAction<SelectAllIntent>(
            onInvoke: (_) => provider.selectAll(),
          ),
          DeleteSelectedIntent: CallbackAction<DeleteSelectedIntent>(
            onInvoke: (_) {
              if (provider.data.hasSelection) {
                showDeleteConfirmDialog(context, provider, l10n);
              }
              return null;
            },
          ),
          ClearSelectionIntent: CallbackAction<ClearSelectionIntent>(
            onInvoke: (_) => provider.clearSelection(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              leading: showDirectoryBack ? const BackButton() : null,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.filesPageTitle),
                  if (provider.data.currentServer != null)
                    Text(
                      provider.data.currentServer!.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => showSearchDialog(context),
                  tooltip: l10n.filesActionSearch,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_outlined),
                  onPressed: () => provider.refresh(),
                  tooltip: l10n.systemSettingsRefresh,
                ),
                FilledButton.icon(
                  onPressed: () => _showCreateOptions(context),
                  icon: const Icon(Icons.add_outlined),
                  label: Text(l10n.filesActionNew),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  tooltip: context.l10n.commonMore,
                  onPressed: () => _showMoreOptions(context),
                ),
                SizedBox(width: spec.pagePadding.right),
              ],
            ),
            body: _buildPageBody(context, theme, l10n),
            bottomNavigationBar: !provider.data.hasSelection
                ? null
                : _buildSelectionBar(context, provider, l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSelectionActions(
    BuildContext context,
    FilesProvider provider,
    AppLocalizations l10n,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.filesSelectedCount(provider.data.selectionCount),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.copy_outlined),
          tooltip: l10n.filesActionCopy,
          onPressed: () => showBatchCopyDialog(context, provider, l10n),
        ),
        IconButton(
          icon: const Icon(Icons.cut_outlined),
          tooltip: l10n.filesActionMove,
          onPressed: () => showBatchMoveDialog(context, provider, l10n),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: l10n.commonDelete,
          onPressed: () => showDeleteConfirmDialog(context, provider, l10n),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.commonCancel,
          onPressed: () => provider.clearSelection(),
        ),
      ],
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
