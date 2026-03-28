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
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      DatabaseDetailSectionsWidget(
                        item: item,
                        detail: detail,
                      ),
                      DatabaseDetailManagementWidget(item: item),
                      const DatabaseDetailActionsWidget(),
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
    );
  }
}
