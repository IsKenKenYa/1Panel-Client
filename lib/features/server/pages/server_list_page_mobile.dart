import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/onboarding/coach_mark_overlay.dart';
import 'package:onepanel_client/features/server/view_models/server_list_view_model.dart';
import 'package:onepanel_client/features/server/widgets/server_card.dart';
import 'package:onepanel_client/features/shell/widgets/shell_drawer_scope.dart';
import 'package:provider/provider.dart';

class ServerListPageMobile extends StatelessWidget {
  const ServerListPageMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<ServerListViewModel>();
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              )
            : buildShellDrawerLeading(
                context,
                key: const Key('shell-drawer-menu-button'),
              ),
        title: Text(l10n.serverPageTitle),
        actions: [
          IconButton(
            key: viewModel.addKey,
            onPressed: () => viewModel.openAddServer(context),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.serverAdd,
          ),
        ],
      ),
      body: _buildBody(context, viewModel, l10n),
    );
  }

  Widget _buildBody(BuildContext context, ServerListViewModel viewModel,
      AppLocalizations l10n) {
    if (viewModel.serverProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = viewModel.filteredServers;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: viewModel.refresh,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppDesignTokens.pagePadding,
                  child: TextField(
                    controller: viewModel.searchController,
                    decoration: InputDecoration(
                      hintText: l10n.serverSearchHint,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
              ),
              if (data.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: AppDesignTokens.pagePadding,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.dns_outlined, size: 56),
                          const SizedBox(height: AppDesignTokens.spacingLg),
                          Text(
                            l10n.serverListEmptyTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppDesignTokens.spacingSm),
                          Text(l10n.serverListEmptyDesc,
                              textAlign: TextAlign.center),
                          const SizedBox(height: AppDesignTokens.spacingLg),
                          FilledButton(
                            onPressed: () => viewModel.openAddServer(context),
                            child: Text(l10n.serverAdd),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ServerCard(
                          key: index == 0 ? viewModel.firstCardKey : null,
                          data: item,
                          onTap: () => viewModel.openDetail(context, item),
                          onDelete: () => viewModel.deleteServer(context, item),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        if (viewModel.coachSteps.isNotEmpty)
          CoachMarkOverlay(
            steps: viewModel.coachSteps,
            onFinished: viewModel.completeCoach,
          ),
      ],
    );
  }
}
