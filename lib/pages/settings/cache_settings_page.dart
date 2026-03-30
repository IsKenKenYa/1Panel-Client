import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'package:onepanel_client/core/services/cache/file_preview_cache_manager.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

class CacheSettingsPage extends StatelessWidget {
  const CacheSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsCacheTitle)),
      body: ListView(
        padding: AppDesignTokens.pagePadding,
        children: [
          Text(l10n.settingsCacheStrategy,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppDesignTokens.spacingSm),
          Card(
            child: Padding(
              padding: AppDesignTokens.pagePadding,
              child: Consumer<AppSettingsController>(
                builder: (context, settings, _) {
                  return _CacheStrategySelector(settings: settings);
                },
              ),
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingLg),
          Text(l10n.settingsCacheLimit,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppDesignTokens.spacingSm),
          Card(
            child: Padding(
              padding: AppDesignTokens.pagePadding,
              child: Consumer<AppSettingsController>(
                builder: (context, settings, _) {
                  return _CacheSizeSelector(settings: settings);
                },
              ),
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingLg),
          Text(l10n.settingsCacheStatus,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppDesignTokens.spacingSm),
          Card(
            child: Padding(
              padding: AppDesignTokens.pagePadding,
              child: _CacheStatsDisplay(),
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingLg),
          Card(
            child: Padding(
              padding: AppDesignTokens.pagePadding,
              child: _ClearCacheButton(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CacheStrategySelector extends StatelessWidget {
  const _CacheStrategySelector({required this.settings});

  final AppSettingsController settings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    String strategyLabel(CacheStrategy strategy) {
      switch (strategy) {
        case CacheStrategy.hybrid:
          return l10n.settingsCacheStrategyHybrid;
        case CacheStrategy.memoryOnly:
          return l10n.settingsCacheStrategyMemoryOnly;
        case CacheStrategy.diskOnly:
          return l10n.settingsCacheStrategyDiskOnly;
      }
    }

    String strategyDescription(CacheStrategy strategy) {
      switch (strategy) {
        case CacheStrategy.hybrid:
          return l10n.settingsCacheStrategyHybridDesc;
        case CacheStrategy.memoryOnly:
          return l10n.settingsCacheStrategyMemoryOnlyDesc;
        case CacheStrategy.diskOnly:
          return l10n.settingsCacheStrategyDiskOnlyDesc;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsCacheStrategy,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        DropdownButton<CacheStrategy>(
          value: settings.cacheStrategy,
          isExpanded: true,
          itemHeight: null,
          selectedItemBuilder: (context) => CacheStrategy.values
              .map(
                (strategy) => Text(
                  strategyLabel(strategy),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) {
              settings.updateCacheStrategy(value);
            }
          },
          items: CacheStrategy.values.map((strategy) {
            return DropdownMenuItem(
              value: strategy,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strategyLabel(strategy),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    strategyDescription(strategy),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}

class _CacheSizeSelector extends StatelessWidget {
  const _CacheSizeSelector({required this.settings});

  final AppSettingsController settings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsCacheMaxSize,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        DropdownButton<int>(
          value: settings.cacheMaxSizeMB,
          isExpanded: true,
          onChanged: (value) {
            if (value != null) {
              settings.updateCacheMaxSizeMB(value);
              FilePreviewCacheManager().initialize(
                strategy: settings.cacheStrategy,
                maxSizeMB: value,
              );
            }
          },
          items: [50, 100, 200, 500].map((size) {
            return DropdownMenuItem(
              value: size,
              child: Text('${size}MB'),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CacheStatsDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stats = FilePreviewCacheManager().getMemoryCacheStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatRow(
          context,
          l10n.settingsCacheItemCount,
          '${stats['itemCount']}',
        ),
        const SizedBox(height: 8),
        _buildStatRow(
          context,
          l10n.settingsCacheCurrentSize,
          '${stats['currentSizeMB']}MB / ${stats['maxSizeMB']}MB',
        ),
        const SizedBox(height: 8),
        _buildStatRow(
          context,
          l10n.settingsCacheExpiration,
          '${stats['expirationMinutes']} ${l10n.settingsCacheExpirationUnit}',
        ),
      ],
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }
}

class _ClearCacheButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ElevatedButton.icon(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.settingsCacheClearConfirm),
            content: Text(l10n.settingsCacheClearConfirmMessage),
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

        if (confirmed == true && context.mounted) {
          await FilePreviewCacheManager().clearAllCache();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.settingsCacheCleared)),
            );
          }
        }
      },
      icon: const Icon(Icons.delete_outline),
      label: Text(l10n.settingsCacheClear),
    );
  }
}
