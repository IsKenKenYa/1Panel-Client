import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

import 'databases_provider.dart';

class DatabaseRemotePage extends StatelessWidget {
  const DatabaseRemotePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DatabasesProvider(scope: DatabaseScope.remote)..load(),
      child: Consumer<DatabasesProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(context.l10n.databaseRemoteTab),
              actions: [
                IconButton(
                  onPressed: provider.refresh,
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.databaseForm,
                    arguments: {'scope': DatabaseScope.remote.value},
                  ),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            body: provider.state.isLoading && provider.state.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: AppDesignTokens.pagePadding,
                    itemCount: provider.state.items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDesignTokens.spacingSm),
                    itemBuilder: (context, index) {
                      final item = provider.state.items[index];
                      return AppCard(
                        title: item.name,
                        subtitle: Text(item.engine),
                        child: Text(
                          item.address == null
                              ? '-'
                              : '${item.address}:${item.port ?? '-'}',
                        ),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.databaseDetail,
                          arguments: item,
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
