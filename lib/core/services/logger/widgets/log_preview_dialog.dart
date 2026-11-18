import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/logger/log_export_service.dart';
import 'package:onepanel_client/core/services/logger/log_format.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';

/// 导出日志预览对话框。
///
/// 两个 Tab：「人读格式」「AI Agent 格式」。
/// - 默认显示 AI Agent 格式
/// - 仅读取日志文件**最后 200 行**（不读取全部）
/// - 「保存此格式」触发 `LogExportService.exportLogs(format: ...)` 走 picker
class LogPreviewDialog extends StatefulWidget {
  const LogPreviewDialog({super.key});

  @override
  State<LogPreviewDialog> createState() => _LogPreviewDialogState();
}

class _LogPreviewDialogState extends State<LogPreviewDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;
  String _aiPreview = '';
  String _humanPreview = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPreviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPreviews() async {
    final export = LogExportService();
    final ai = await export.tailRecentLogs(200, format: LogFormat.aiAgent);
    final human = await export.tailRecentLogs(200, format: LogFormat.humanReadable);
    if (!mounted) return;
    setState(() {
      _aiPreview = ai;
      _humanPreview = human;
      _loading = false;
    });
  }

  Future<void> _saveFormat(LogFormat format) async {
    final result = await LogExportService()
        .exportLogs(minLevel: null, format: format);
    if (!mounted) return;
    final l10n = context.l10n;
    if (result.wasCancelled) {
      Navigator.of(context).pop();
    } else if (result.success) {
      Navigator.of(context).pop();
    } else {
      SnackBarUtils.showError(
        context,
        '${l10n.commonSaveFailed}: ${result.errorMessage ?? ''}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.systemSettingsAppLogsPreviewButton),
      content: SizedBox(
        width: double.maxFinite,
        height: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.systemSettingsAppLogsPreviewTabHuman),
                Tab(text: l10n.systemSettingsAppLogsPreviewTabAi),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? Center(
                      child: Text(l10n.systemSettingsAppLogsPreviewLoading),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _PreviewContent(text: _humanPreview),
                        _PreviewContent(text: _aiPreview),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _loading
              ? null
              : () => _saveFormat(
                    _tabController.index == 0
                        ? LogFormat.humanReadable
                        : LogFormat.aiAgent,
                  ),
          child: Text(l10n.systemSettingsAppLogsPreviewSave),
        ),
      ],
    );
  }
}

class _PreviewContent extends StatelessWidget {
  const _PreviewContent({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      final l10n = context.l10n;
      return Center(child: Text(l10n.systemSettingsAppLogsPreviewEmpty));
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          text,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
