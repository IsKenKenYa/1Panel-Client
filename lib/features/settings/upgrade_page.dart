import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';

class UpgradePage extends StatefulWidget {
  const UpgradePage({super.key});

  @override
  State<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends State<UpgradePage> {
  Future<dynamic>? _upgradeInfoFuture;
  Future<List<dynamic>?>? _releasesFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final provider = context.read<SettingsProvider>();
    _upgradeInfoFuture = provider.loadUpgradeInfo();
    _releasesFuture = provider.getUpgradeReleases();
  }

  bool _isDowngrade(String currentVersion, String targetVersion) {
    final current = _parseVersion(currentVersion);
    final target = _parseVersion(targetVersion);
    if (current == null || target == null) return false;
    for (var i = 0; i < 3; i++) {
      if (target[i] < current[i]) return true;
      if (target[i] > current[i]) return false;
    }
    return false;
  }

  List<int>? _parseVersion(String version) {
    final match = RegExp(r'v?(\d+)\.(\d+)\.(\d+)').firstMatch(version);
    if (match == null) return null;
    return [
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final provider = context.watch<SettingsProvider>();
    final currentVersion = provider.data.systemSettings?.systemVersion ?? '-';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.upgradeTitle)),
      body: FutureBuilder(
        future: _upgradeInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(l10n.commonLoadFailedTitle),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _loadData();
                      });
                    },
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: AppDesignTokens.pagePadding,
            children: [
              _buildSectionTitle(context, l10n.upgradeCurrentVersion, theme),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.upgradeCurrentVersionLabel),
                  trailing: Text(currentVersion, style: const TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              _buildSectionTitle(context, l10n.upgradeAvailableVersions, theme),
              Card(
                child: FutureBuilder<List<dynamic>?>(
                  future: _releasesFuture,
                  builder: (context, releasesSnapshot) {
                    if (releasesSnapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (releasesSnapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 8),
                              Text(l10n.commonLoadFailedTitle),
                            ],
                          ),
                        ),
                      );
                    }

                    final releases = releasesSnapshot.data;
                    if (releases == null || releases.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 48),
                              const SizedBox(height: 8),
                              Text(l10n.upgradeNoUpdates),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: releases.map((release) {
                        final version = release['version'] as String? ?? 'Unknown';
                        final description = release['description'] as String? ?? '';
                        final isLatest = release['isLatest'] == true;
                        final isDowngrade = _isDowngrade(currentVersion, version);

                        return ListTile(
                          leading: Icon(
                            isLatest
                                ? Icons.new_releases
                                : isDowngrade
                                    ? Icons.history
                                    : Icons.update_outlined,
                            color: isLatest
                                ? Colors.green
                                : isDowngrade
                                    ? Colors.orange
                                    : null,
                          ),
                          title: Row(
                            children: [
                              Text(version),
                              if (isLatest) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    l10n.upgradeLatest,
                                    style: const TextStyle(fontSize: 10, color: Colors.green),
                                  ),
                                ),
                              ],
                              if (isDowngrade) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    l10n.upgradeDowngradeButton,
                                    style: const TextStyle(fontSize: 10, color: Colors.orange),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: description.isNotEmpty ? Text(description, maxLines: 2) : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.notes_outlined),
                            tooltip: l10n.upgradeViewNotes,
                            onPressed: () => _showReleaseNotes(context, provider, l10n, version),
                          ),
                          onTap: () => _showUpgradeDialog(context, provider, l10n, version, isDowngrade),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignTokens.spacingSm),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  void _showReleaseNotes(BuildContext context, SettingsProvider provider, AppLocalizations l10n, String version) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.upgradeNotesTitle(version)),
        content: FutureBuilder<String?>(
          future: provider.getReleaseNotes(version),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 100,
                child: Center(child: Text(l10n.upgradeNotesLoading)),
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return Text(l10n.upgradeNotesError);
            }

            final notes = snapshot.data!;
            if (notes.isEmpty) {
              return Text(l10n.upgradeNotesEmpty);
            }

            return SingleChildScrollView(
              child: Text(notes),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, SettingsProvider provider, AppLocalizations l10n, String version, bool isDowngrade) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDowngrade ? l10n.upgradeDowngradeConfirm : l10n.upgradeConfirm),
        content: Text(isDowngrade ? l10n.upgradeDowngradeMessage(version) : l10n.upgradeConfirmMessage(version)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: isDowngrade ? FilledButton.styleFrom(backgroundColor: Colors.orange) : null,
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.upgrade(version: version);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? l10n.upgradeStarted : l10n.commonSaveFailed)),
                );
              }
            },
            child: Text(isDowngrade ? l10n.upgradeDowngradeButton : l10n.upgradeButton),
          ),
        ],
      ),
    );
  }
}
