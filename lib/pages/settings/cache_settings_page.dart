import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/settings/widgets/settings_scaffold.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/services/cache/file_preview_cache_manager.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/settings/widgets/system_settings_tiles.dart';
import 'package:onepanel_client/features/settings/widgets/settings_save_action.dart';
import 'package:onepanel_client/shared/widgets/label_value_row.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';
import 'package:provider/provider.dart';

class CacheSettingsPage extends StatefulWidget {
  const CacheSettingsPage({super.key});

  @override
  State<CacheSettingsPage> createState() => _CacheSettingsPageState();
}

class _CacheSettingsPageState extends State<CacheSettingsPage> {
  bool _busy = false;

  Future<void> _apply(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await saveAppPreference(context, action);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearCache() async {
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.settingsCacheClearConfirm,
      message: l10n.settingsCacheClearConfirmMessage,
      confirmLabel: l10n.settingsCacheClear,
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;
    await _apply(() async {
      await FilePreviewCacheManager().clearAllCache();
      if (mounted)
        SnackBarUtils.showSuccess(context, l10n.settingsCacheCleared);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<AppSettingsController>();
    final strategy = kIsWeb ? CacheStrategy.memoryOnly : settings.cacheStrategy;
    final sizes = {50, 100, 200, 500, settings.cacheMaxSizeMB}.toList()..sort();
    final stats = FilePreviewCacheManager().getMemoryCacheStats();
    return SettingsScaffold(
      title: l10n.settingsCacheTitle,
      body: ListView(
        padding: AppDesignTokens.scrollPagePadding(context),
        children: [
          SectionCard(
            title: l10n.settingsPreviewCache,
            padding: AppDesignTokens.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!kIsWeb)
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.settingsCacheStrategy,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<CacheStrategy>(
                        isExpanded: true,
                        value: strategy,
                        items: [
                          for (final value in CacheStrategy.values)
                            DropdownMenuItem(
                              value: value,
                              child: Text(switch (value) {
                                CacheStrategy.hybrid =>
                                  l10n.settingsCacheStrategyHybrid,
                                CacheStrategy.memoryOnly =>
                                  l10n.settingsCacheStrategyMemoryOnly,
                                CacheStrategy.diskOnly =>
                                  l10n.settingsCacheStrategyDiskOnly,
                              }),
                            ),
                        ],
                        onChanged: _busy
                            ? null
                            : (value) {
                                if (value != null)
                                  _apply(
                                    () => settings.updateCacheStrategy(value),
                                  );
                              },
                      ),
                    ),
                  ),
                if (strategy != CacheStrategy.diskOnly) ...[
                  if (!kIsWeb)
                    const SizedBox(height: AppDesignTokens.spacingMd),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.settingsCacheMaxSize,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: settings.cacheMaxSizeMB,
                        isExpanded: true,
                        items: [
                          for (final size in sizes)
                            DropdownMenuItem(
                              value: size,
                              child: Text('$size MB'),
                            ),
                        ],
                        onChanged: _busy
                            ? null
                            : (value) {
                                if (value != null)
                                  _apply(
                                    () => settings.updateCacheMaxSizeMB(value),
                                  );
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingMd),
                  LabelValueRow(
                    label: l10n.settingsCacheStatus,
                    value:
                        '${stats['currentSizeMB']} MB / ${settings.cacheMaxSizeMB} MB',
                  ),
                  LabelValueRow(
                    label: l10n.settingsCacheItemCount,
                    value: '${stats['itemCount']}',
                  ),
                  LabelValueRow(
                    label: l10n.settingsCacheExpiration,
                    value:
                        '${stats['expirationMinutes']} ${l10n.settingsCacheExpirationUnit}',
                  ),
                ],
                const SizedBox(height: AppDesignTokens.spacingMd),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _clearCache,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.settingsCacheClear),
                ),
              ],
            ),
          ),
          if (!kIsWeb) ...[
            const SizedBox(height: AppDesignTokens.spacingLg),
            const FileExportSettingsSection(),
          ],
        ],
      ),
    );
  }
}
