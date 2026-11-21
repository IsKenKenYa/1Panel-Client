import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/onboarding/coach_mark_overlay.dart';
import 'package:onepanel_client/features/server/server_list_interactions.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/server/view_models/server_list_view_model.dart';
import 'package:onepanel_client/features/server/widgets/server_card_sliver.dart';
import 'package:onepanel_client/features/shell/widgets/shell_drawer_scope.dart';
import 'package:onepanel_client/shared/widgets/module_search_field.dart';
import 'package:onepanel_client/shared/widgets/operations/module_empty_state_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/partial_error_toast_listener.dart';
import 'package:provider/provider.dart';

class ServerListView extends StatelessWidget {
  const ServerListView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ServerListViewModel>();
    final spec = AdaptiveLayoutSpec.of(context);
    final l10n = context.l10n;
    Future<void> addServer() async {
      await openServerForm(context);
    }

    final searchHeader = SliverToBoxAdapter(
      child: Padding(
        padding: spec.isDesktop
            ? const EdgeInsets.fromLTRB(24, 24, 24, 16)
            : spec.pagePadding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
            return Row(
              children: [
                Expanded(
                  child: ModuleSearchField(
                    controller: viewModel.searchController,
                    hintText: l10n.serverSearchHint,
                  ),
                ),
                if (!spec.isPhone) ...[
                  const SizedBox(width: AppDesignTokens.spacingMd),
                  if (constraints.maxWidth >= 360 * scale)
                    FilledButton.icon(
                      key: viewModel.addKey,
                      onPressed: addServer,
                      icon: const Icon(Icons.add_outlined),
                      label: Text(l10n.serverAdd),
                    )
                  else
                    IconButton.filledTonal(
                      key: viewModel.addKey,
                      onPressed: addServer,
                      icon: const Icon(Icons.add_outlined),
                      tooltip: l10n.serverAdd,
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: spec.isPhone
          ? AppBar(
              leading: Navigator.of(context).canPop()
                  ? const BackButton()
                  : buildShellDrawerLeading(
                      context,
                      key: const Key('shell-drawer-menu-button'),
                    ),
              title: Text(l10n.serverPageTitle),
              actions: [
                IconButton(
                  key: viewModel.addKey,
                  onPressed: addServer,
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: l10n.serverAdd,
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          AdaptiveWidthContainer(
            maxWidth: spec.contentMaxWidth,
            child: RefreshIndicator(
              onRefresh: viewModel.refresh,
              child: _ServerListScrollView(header: searchHeader),
            ),
          ),
          Selector<ServerListViewModel, List<CoachMarkStep>>(
            selector: (_, vm) => vm.coachSteps,
            builder: (_, steps, __) => steps.isEmpty
                ? const SizedBox.shrink()
                : CoachMarkOverlay(
                    steps: steps, onFinished: viewModel.completeCoach),
          ),
        ],
      ),
    );
  }
}

class _ServerListScrollView extends StatelessWidget {
  const _ServerListScrollView({required this.header});

  final Widget header;

  @override
  Widget build(BuildContext context) {
    final (configs, ready, error) = context.select(
        (ServerProvider p) => (p.configs, p.hasDirectory, p.directoryError));
    final viewModel = context.read<ServerListViewModel>();
    final query = context.select((ServerListViewModel vm) => vm.query);
    final l10n = context.l10n;
    final servers = query.isEmpty
        ? configs
        : configs
            .where((config) =>
                config.name.toLowerCase().contains(query) ||
                config.url.toLowerCase().contains(query))
            .toList(growable: false);
    final Widget body;
    if (!ready && error == null) {
      body = const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()));
    } else if (error != null && configs.isEmpty) {
      body = SliverFillRemaining(
          hasScrollBody: false,
          child: ModuleErrorStateWidget(
              message: error, onRetry: viewModel.refresh));
    } else if (servers.isEmpty) {
      final searching = query.isNotEmpty;
      final showAdd = !AdaptiveLayoutSpec.of(context).isDesktop;
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: ModuleEmptyStateWidget(
          title: searching ? l10n.logNoMatches : l10n.serverListEmptyTitle,
          description: searching ? null : l10n.serverListEmptyDesc,
          icon: searching ? Icons.search_off_outlined : Icons.dns_outlined,
          actionLabel:
              searching ? l10n.commonClear : (showAdd ? l10n.serverAdd : null),
          onAction: searching
              ? viewModel.searchController.clear
              : (showAdd ? () => openServerForm(context) : null),
        ),
      );
    } else {
      body = ServerCardSliver(
        servers: servers,
        firstCardKey: viewModel.firstCardKey,
        onOpen: (config) => viewModel.openDetail(context, config),
        onEdit: (config) => openServerForm(context, serverId: config.id),
        onDelete: (config) => confirmAndDeleteServer(context, config),
      );
    }
    return PartialErrorToastListener(
      errorMessage: error,
      hasCachedData: configs.isNotEmpty,
      onRetry: viewModel.refresh,
      child: CustomScrollView(
        semanticChildCount: servers.length,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [header, body],
      ),
    );
  }
}
