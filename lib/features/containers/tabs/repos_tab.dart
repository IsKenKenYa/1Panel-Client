import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/features/containers/dialogs/repo_create_dialog.dart';
import 'package:onepanelapp_app/shared/widgets/app_card.dart';
import '../containers_provider.dart';

class ReposTab extends StatelessWidget {
  const ReposTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    
    return Consumer<ContainersProvider>(
      builder: (context, provider, _) {
        final repos = provider.data.repos;
        if (provider.data.isLoading && repos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (repos.isEmpty) {
          return Center(child: Text(l10n.commonEmpty));
        }

        return RefreshIndicator(
          onRefresh: provider.loadRepos,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: repos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final repo = repos[index];
              return AppCard(
                child: ListTile(
                  leading: const Icon(Icons.store),
                  title: Text(repo.name),
                  subtitle: Text(repo.downloadUrl),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        showDialog(
                          context: context,
                          builder: (context) => RepoCreateDialog(repo: repo),
                        );
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.commonDelete),
                            content: Text(l10n.commonDeleteRepoConfirm),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(l10n.commonCancel),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(l10n.commonConfirm),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await provider.deleteRepo([repo.id]);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(l10n.commonEdit),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          l10n.commonDelete,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
