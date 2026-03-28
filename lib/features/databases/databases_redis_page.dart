import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/databases/widgets/database_detail_error_widget.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

import 'databases_provider.dart';

class DatabaseRedisPage extends StatelessWidget {
  const DatabaseRedisPage({
    super.key,
    required this.item,
  });

  final DatabaseListItem item;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DatabaseDetailProvider(item: item)..load(),
      child: const _DatabaseRedisPageView(),
    );
  }
}

class _DatabaseRedisPageView extends StatefulWidget {
  const _DatabaseRedisPageView();

  @override
  State<_DatabaseRedisPageView> createState() => _DatabaseRedisPageViewState();
}

class _DatabaseRedisPageViewState extends State<_DatabaseRedisPageView> {
  final _timeoutController = TextEditingController();
  final _maxClientsController = TextEditingController();
  final _appendOnlyController = TextEditingController();
  final _saveController = TextEditingController();

  @override
  void dispose() {
    _timeoutController.dispose();
    _maxClientsController.dispose();
    _appendOnlyController.dispose();
    _saveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DatabaseDetailProvider>();
    final detail = provider.detail;
    final item = provider.item;

    if (provider.isLoading && detail == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null && detail == null) {
      return Scaffold(
        appBar: AppBar(title: Text(item.name)),
        body: DatabaseDetailErrorWidget(
          error: provider.error!,
          onRetry: provider.load,
        ),
      );
    }

    final config = detail?.redisConfig ?? const <String, dynamic>{};
    final persistence = detail?.redisPersistence ?? const <String, dynamic>{};
    _timeoutController.text = config['timeout']?.toString() ?? '';
    _maxClientsController.text = config['maxclients']?.toString() ?? '';
    _appendOnlyController.text = persistence['appendonly']?.toString() ?? '';
    _saveController.text = persistence['save']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: ListView(
          padding: AppDesignTokens.pagePadding,
          children: [
            AppCard(
              title: context.l10n.databaseStatusTitle,
              child: Text(detail?.status.toString() ?? '-'),
            ),
            const SizedBox(height: AppDesignTokens.spacingMd),
            AppCard(
              title: context.l10n.databaseRedisConfigTitle,
              child: Column(
                children: [
                  TextField(
                    controller: _timeoutController,
                    decoration: InputDecoration(
                      labelText: context.l10n.databaseRedisTimeoutLabel,
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingSm),
                  TextField(
                    controller: _maxClientsController,
                    decoration: InputDecoration(
                      labelText: context.l10n.databaseRedisMaxClientsLabel,
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingMd),
                  FilledButton(
                    onPressed: provider.isSubmitting
                        ? null
                        : () => provider.updateRedisConfig({
                              'dbType': item.engine,
                              'timeout': _timeoutController.text.trim(),
                              'maxclients': _maxClientsController.text.trim(),
                            }),
                    child: Text(context.l10n.commonSave),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesignTokens.spacingMd),
            AppCard(
              title: context.l10n.databaseRedisPersistenceTitle,
              child: Column(
                children: [
                  TextField(
                    controller: _appendOnlyController,
                    decoration: InputDecoration(
                      labelText: context.l10n.databaseRedisAppendOnlyLabel,
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingSm),
                  TextField(
                    controller: _saveController,
                    decoration: InputDecoration(
                      labelText: context.l10n.databaseRedisSaveLabel,
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingMd),
                  FilledButton(
                    onPressed: provider.isSubmitting
                        ? null
                        : () => provider.updateRedisPersistence({
                              'type': item.engine,
                              'dbType': item.engine,
                              'appendonly': _appendOnlyController.text.trim(),
                              'save': _saveController.text.trim(),
                            }),
                    child: Text(context.l10n.commonSave),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
