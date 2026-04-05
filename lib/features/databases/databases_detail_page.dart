import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/data/models/database_models.dart';

import 'databases_provider.dart';
import 'databases_service.dart';
import 'widgets/database_detail_actions_widget.dart';
import 'widgets/database_detail_error_widget.dart';
import 'widgets/database_detail_management_widget.dart';
import 'widgets/database_detail_sections_widget.dart';

class DatabaseDetailPage extends StatelessWidget {
  const DatabaseDetailPage({
    super.key,
    required this.item,
    this.service,
  });

  final DatabaseListItem item;
  final DatabasesService? service;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DatabaseDetailProvider(
        item: item,
        service: service,
      )..load(),
      child: const _DatabaseDetailPageView(),
    );
  }
}

class _DatabaseDetailPageView extends StatelessWidget {
  const _DatabaseDetailPageView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DatabaseDetailProvider>();
    final detail = provider.detail;
    final item = provider.item;

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: provider.isLoading && detail == null
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null && detail == null
              ? DatabaseDetailErrorWidget(
                  error: provider.error!,
                  onRetry: provider.load,
                )
              : RefreshIndicator(
                  onRefresh: provider.load,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 1080;
                      final content = DatabaseDetailSectionsWidget(
                        item: item,
                        detail: detail,
                      );
                      final management =
                          DatabaseDetailManagementWidget(item: item);
                      const actions = DatabaseDetailActionsWidget();

                      if (!isWide) {
                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            content,
                            management,
                            actions,
                            if (provider.error != null) ...[
                              const SizedBox(height: 16),
                              DatabaseDetailErrorWidget(
                                error: provider.error!,
                                onRetry: provider.load,
                              ),
                            ],
                          ],
                        );
                      }

                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 11,
                              child: Column(
                                children: [
                                  content,
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 7,
                              child: Column(
                                children: [
                                  management,
                                  actions,
                                  if (provider.error != null) ...[
                                    const SizedBox(height: 16),
                                    DatabaseDetailErrorWidget(
                                      error: provider.error!,
                                      onRetry: provider.load,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
