import 'package:flutter/material.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'app_form_save_button.dart';

/// 统一表单页骨架（M3 Expressive / MDUI3 轨道标准件）。
///
/// 全仓所有独立表单页必须复用本组件，统一：
/// - 保存按钮位置：bottomNavigationBar 全宽 [FilledButton]；
/// - 防重复提交：[isSaving] 为 true 时按钮禁用并内嵌 spinner；
/// - FAB 显式禁用（防 Hero 冲突）。
///
/// 页面 body 自行用 `SectionCard` 组织分节字段。
class AppFormScaffold extends StatelessWidget {
  const AppFormScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.onSave,
    this.isSaving = false,
    this.saveLabel,
    this.actions,
    this.saveButtonKey,
  });

  final String title;
  final Widget body;

  /// 保存回调（async）。返回后由页面负责关闭/提示。
  final Future<void> Function() onSave;

  /// 防重复提交状态（一般来自 form provider 的 isSaving）。
  final bool isSaving;

  /// 保存按钮文案，默认 l10n.commonSave。
  final String? saveLabel;

  final List<Widget>? actions;

  /// 测试定位 Key（保存按钮）。
  final Key? saveButtonKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      floatingActionButton: null,
      body: AdaptiveWidthContainer(
        maxWidth: AdaptiveLayoutSpec.of(context).settingsBodyMaxWidth,
        child: SizedBox.expand(child: body),
      ),
      bottomNavigationBar: AppFormSaveBar(
        onSave: onSave,
        isSaving: isSaving,
        label: saveLabel,
        buttonKey: saveButtonKey,
      ),
    );
  }
}
