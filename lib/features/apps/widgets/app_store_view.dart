import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/config/app_router.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/data/models/app_models.dart';
import 'package:onepanelapp_app/features/apps/providers/app_store_provider.dart';
import 'package:onepanelapp_app/shared/widgets/app_card.dart';

import 'package:onepanelapp_app/features/apps/widgets/app_icon.dart';
import 'app_install_dialog.dart';

class AppStoreView extends StatefulWidget {
  const AppStoreView({super.key});

  @override
  State<AppStoreView> createState() => _AppStoreViewState();
}

class _AppStoreViewState extends State<AppStoreView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _selectedTags = {};
  // Common tags/categories found in typical app stores
  final List<String> _availableTags = [
    'WebSite',
    'Database',
    'Runtime',
    'Tool',
    'Docker',
    'CI/CD',
    'Monitoring'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApps(refresh: true);
    });
  }

  // _onScroll removed as NotificationListener is used

  Future<void> _loadApps({bool refresh = false}) async {
    if (!mounted) return;
    final provider = context.read<AppStoreProvider>();
    await provider.loadApps(
      refresh: refresh,
      name: _searchController.text.isEmpty ? null : _searchController.text,
      tags: _selectedTags.isEmpty ? null : _selectedTags.toList(),
    );
  }

  Future<void> _syncApps() async {
    final provider = context.read<AppStoreProvider>();
    try {
      await provider.syncApps();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.appStoreSyncSuccess)),
        );
        _loadApps(refresh: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.appStoreSyncFailed}: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        // Search and Filter Section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchBar(
                controller: _searchController,
                hintText: l10n.appStoreSearchHint,
                leading: const Icon(Icons.search),
                trailing: [
                  IconButton(
                    icon: const Icon(Icons.sync),
                    tooltip: l10n.appStoreSync,
                    onPressed: _syncApps,
                  ),
                ],
                onSubmitted: (_) => _loadApps(refresh: true),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                          _loadApps(refresh: true);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // App List
        Expanded(
          child: Consumer<AppStoreProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.apps.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.error != null && provider.apps.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.commonLoadFailedTitle),
                      const SizedBox(height: 8),
                      Text(provider.error!),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => _loadApps(refresh: true),
                        child: Text(l10n.commonRetry),
                      ),
                    ],
                  ),
                );
              }

              if (provider.apps.isEmpty) {
                return Center(child: Text(l10n.commonEmpty));
              }

              return NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 200 &&
                      !provider.isLoading &&
                      provider.hasMore) {
                    _loadApps(refresh: false);
                  }
                  return false;
                },
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadApps(refresh: true);
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisExtent: 200,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: provider.apps.length + (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.apps.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final app = provider.apps[index];
                      return _buildAppCard(context, app, l10n);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppCard(
      BuildContext context, AppItem app, AppLocalizations l10n) {
    return AppCard(
      title: app.name ?? '',
      leading: AppIcon(app: app, size: 40),
      subtitle: Text(
        app.description ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.appDetail, arguments: app);
      },
      trailing: (app.installed == true)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l10n.appStoreInstalled,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontSize: 12,
                ),
              ),
            )
          : FilledButton.tonal(
              onPressed: () {
                _showInstallDialog(context, app);
              },
              child: Text(l10n.appStoreInstall),
            ),
      child: app.tagNames.isNotEmpty
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: app.tagNames
                    .take(3)
                    .map((tag) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Chip(
                            label:
                                Text(tag, style: const TextStyle(fontSize: 10)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ))
                    .toList(),
              ),
            )
          : null,
    );
  }

  Future<void> _showInstallDialog(BuildContext context, AppItem app) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AppInstallDialog(app: app),
    );

    if (!mounted) return;

    // Check if provider has error (e.g. from failed install attempt in dialog)
    final provider = context.read<AppStoreProvider>();
    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    if (result == true) {
      _loadApps(refresh: true);
    }
  }
}
