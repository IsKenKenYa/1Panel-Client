import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/ai/providers/model_downloader_provider.dart';
import 'package:onepanel_client/features/ai/widgets/model_downloader_sections.dart';
import 'package:onepanel_client/features/ai/widgets/model_downloader_settings_sheet.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/partial_error_toast_listener.dart';

/// AI 模块的模型下载分区：推荐、搜索、任务、本地四块。
class ModelDownloaderTabWidget extends StatefulWidget {
  const ModelDownloaderTabWidget({super.key});

  @override
  State<ModelDownloaderTabWidget> createState() =>
      _ModelDownloaderTabWidgetState();
}

class _ModelDownloaderTabWidgetState extends State<ModelDownloaderTabWidget> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOnce());
  }

  void _loadOnce() {
    if (_initialized || !mounted) return;
    _initialized = true;
    context.read<ModelDownloaderProvider>().loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<ModelDownloaderProvider>();

    if (provider.featuredError != null &&
        provider.featured.items.isEmpty &&
        provider.taskError != null &&
        provider.tasks.isEmpty) {
      return ModuleErrorStateWidget(
        message: provider.featuredError,
        onRetry: provider.loadAll,
      );
    }

    return PartialErrorToastListener(
      errorMessage: provider.featuredError ??
          provider.searchError ??
          provider.localError,
      hasCachedData: provider.featured.items.isNotEmpty ||
          provider.localModels.isNotEmpty,
      onRetry: provider.loadAll,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppDesignTokens.spacingLg,
          AppDesignTokens.spacingMd,
          AppDesignTokens.spacingLg,
          AppDesignTokens.spacingXl +
              MediaQuery.paddingOf(context).bottom,
        ),
        children: <Widget>[
          ModelFeaturedSection(provider: provider),
          const SizedBox(height: AppDesignTokens.spacingXl),
          ModelSearchSection(provider: provider),
          const SizedBox(height: AppDesignTokens.spacingXl),
          ModelTasksSection(provider: provider),
          const SizedBox(height: AppDesignTokens.spacingXl),
          ModelLocalSection(provider: provider),
          const SizedBox(height: AppDesignTokens.spacingLg),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => showModelDownloaderSettings(context),
              icon: const Icon(Icons.settings_outlined),
              label: Text(l10n.modelDownloaderSettingsAction),
            ),
          ),
        ],
      ),
    );
  }
}

/// 打开下载设置抽屉。
Future<void> showModelDownloaderSettings(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const ModelDownloaderSettingsSheet(),
  );
}

/// 显示下载已启动的提示。
void notifyDownloadStarted(BuildContext context) {
  SnackBarUtils.showSuccess(
    context,
    context.l10n.modelDownloaderDownloadStarted,
  );
}
