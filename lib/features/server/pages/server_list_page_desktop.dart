import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/onboarding/coach_mark_overlay.dart';
import 'package:onepanel_client/features/server/view_models/server_list_view_model.dart';
import 'package:onepanel_client/features/server/widgets/server_card.dart';
import 'package:provider/provider.dart';

class ServerListPageDesktop extends StatelessWidget {
  const ServerListPageDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<ServerListViewModel>();

    return Scaffold(
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: viewModel.searchController,
                          decoration: InputDecoration(
                            hintText: l10n.serverSearchHint,
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        key: viewModel.addKey,
                        onPressed: () => viewModel.openAddServer(context),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.serverAdd),
                      ),
                    ],
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
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisExtent: 220,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = data[index];
                        return ServerCard(
                          key: index == 0 ? viewModel.firstCardKey : null,
                          data: item,
                          onTap: () => viewModel.openDetail(context, item),
                          onDelete: () => viewModel.deleteServer(context, item),
                        );
                      },
                      childCount: data.length,
                    ),
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
