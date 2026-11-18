import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/features/onboarding/coach_mark_overlay.dart';
import 'package:onepanel_client/features/server/server_list_interactions.dart';
import 'package:onepanel_client/features/server/view_models/server_list_view_model.dart';
import 'package:onepanel_client/features/server/widgets/server_card.dart';
import 'package:provider/provider.dart';

class ServerListPageTablet extends StatelessWidget {
  const ServerListPageTablet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<ServerListViewModel>();
    final spec = AdaptiveLayoutSpec.of(context);

    return Scaffold(
      body: Stack(
        children: [
          AdaptiveWidthContainer(
            maxWidth: spec.contentMaxWidth,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: spec.pagePadding,
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
                          onPressed: () => openServerForm(context, viewModel),
                          icon: const Icon(Icons.add_outlined),
                          label: Text(l10n.serverAdd),
                        ),
                      ],
                    ),
                  ),
                ),
                ..._buildSlivers(context, viewModel, spec),
              ],
            ),
          ),
          if (viewModel.coachSteps.isNotEmpty)
            CoachMarkOverlay(
              steps: viewModel.coachSteps,
              onFinished: viewModel.completeCoach,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildSlivers(
    BuildContext context,
    ServerListViewModel viewModel,
    AdaptiveLayoutSpec spec,
  ) {
    final l10n = context.l10n;

    if (viewModel.serverProvider.isLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    final data = viewModel.filteredServers.toList(growable: false);
    if (data.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: spec.pagePadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.dns_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    l10n.serverListEmptyTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.serverListEmptyDesc, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => openServerForm(context, viewModel),
                    icon: const Icon(Icons.add_outlined),
                    label: Text(l10n.serverAdd),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          spec.pagePadding.horizontal / 2,
          0,
          spec.pagePadding.horizontal / 2,
          spec.pagePadding.bottom,
        ),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: spec.serverGridMaxCrossAxisExtent,
            mainAxisExtent: 252,
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
                onDelete: () => confirmAndDeleteServer(context, viewModel, item),
              );
            },
            childCount: data.length,
          ),
        ),
      ),
    ];
  }
}
