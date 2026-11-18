import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/features/orchestration/providers/compose_template_provider.dart';
import 'package:onepanel_client/features/orchestration/widgets/compose_template_dialog.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:provider/provider.dart';

/// 编排模版管理页。
/// 对齐 1Panel 前端 `container/template/index.vue`：模版列表 + 创建/编辑/删除。
class ComposeTemplatePage extends StatefulWidget {
  const ComposeTemplatePage({super.key});

  @override
  State<ComposeTemplatePage> createState() => _ComposeTemplatePageState();
}

class _ComposeTemplatePageState extends State<ComposeTemplatePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ComposeTemplateProvider>().loadTemplates();
    });
  }

  Future<void> _editTemplate({ContainerTemplate? template}) async {
    final request =
        await showComposeTemplateEditDialog(context, template: template);
    if (request == null || !mounted) return;
    final provider = context.read<ComposeTemplateProvider>();
    final ok = template == null
        ? await provider.createTemplate(request)
        : await provider.updateTemplate(request);
    if (!mounted) return;
    if (ok) {
      SnackBarUtils.showSuccess(
          context, template == null ? context.l10n.commonCreateSuccess : context.l10n.commonSaveSuccess);
    } else {
      SnackBarUtils.showError(
          context, ErrorMessageUtils.truncateForToast(provider.error ?? context.l10n.commonUnknownError));
    }
  }

  Future<void> _deleteTemplate(ContainerTemplate template) async {
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.commonDelete,
      message: l10n.composeTemplateDeleteConfirm(template.name),
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;
    final provider = context.read<ComposeTemplateProvider>();
    final ok = await provider.deleteTemplates([template.id]);
    if (!mounted) return;
    if (ok) {
      SnackBarUtils.showSuccess(context, l10n.commonDeleted);
    } else {
      SnackBarUtils.showError(
          context, ErrorMessageUtils.truncateForToast(provider.error ?? context.l10n.commonUnknownError));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<ComposeTemplateProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.templates.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null && provider.templates.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ErrorMessageUtils.truncateForToast(provider.error ?? context.l10n.commonUnknownError)),
                TextButton(
                  onPressed: provider.loadTemplates,
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          );
        }
        if (provider.templates.isEmpty) {
          return Center(child: Text(l10n.composeTemplateEmpty));
        }
        return RefreshIndicator(
          onRefresh: provider.loadTemplates,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: provider.templates.length,
            itemBuilder: (context, index) {
              final template = provider.templates[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    template.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (template.description.isNotEmpty)
                        Text(template.description,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        template.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 11),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editTemplate(template: template);
                      }
                      if (value == 'delete') {
                        _deleteTemplate(template);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(l10n.commonEdit),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.commonDelete),
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
