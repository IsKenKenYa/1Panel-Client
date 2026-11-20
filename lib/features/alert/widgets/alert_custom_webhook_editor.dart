import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';

/// Header 或 Form 键值对的编辑控制器。
class AlertPairController {
  AlertPairController({String key = '', String value = ''})
      : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value);

  final TextEditingController keyController;
  final TextEditingController valueController;

  String get key => keyController.text.trim();
  String get value => valueController.text;

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

/// 自定义 Webhook 编辑器：预设、Body 类型、模板、Header 与键值对。
class AlertCustomWebhookEditor extends StatelessWidget {
  const AlertCustomWebhookEditor({
    super.key,
    required this.preset,
    required this.bodyType,
    required this.urlController,
    required this.templateController,
    required this.headers,
    required this.formPairs,
    required this.onPresetChanged,
    required this.onBodyTypeChanged,
    required this.onAddHeader,
    required this.onRemoveHeader,
    required this.onAddPair,
    required this.onRemovePair,
    required this.onTemplateChanged,
    required this.onUrlChanged,
  });

  final String preset;
  final String bodyType;
  final TextEditingController urlController;
  final TextEditingController templateController;
  final List<AlertPairController> headers;
  final List<AlertPairController> formPairs;
  final ValueChanged<String> onPresetChanged;
  final ValueChanged<String> onBodyTypeChanged;
  final VoidCallback onAddHeader;
  final ValueChanged<int> onRemoveHeader;
  final VoidCallback onAddPair;
  final ValueChanged<int> onRemovePair;
  final VoidCallback onTemplateChanged;
  final VoidCallback onUrlChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 12),
        TextField(
          controller: urlController,
          decoration: InputDecoration(
            labelText: l10n.alertChannelWebhookUrlLabel,
            hintText: 'https://example.com/webhook',
          ),
          onChanged: (_) => onUrlChanged(),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: preset,
          decoration:
              InputDecoration(labelText: l10n.alertChannelCustomPresetLabel),
          items: <DropdownMenuItem<String>>[
            DropdownMenuItem(
              value: 'genericJson',
              child: Text(l10n.alertChannelCustomPresetGeneric),
            ),
            DropdownMenuItem(
              value: 'slack',
              child: Text(l10n.alertChannelCustomPresetSlack),
            ),
            DropdownMenuItem(
              value: 'discord',
              child: Text(l10n.alertChannelCustomPresetDiscord),
            ),
            DropdownMenuItem(
              value: 'teams',
              child: Text(l10n.alertChannelCustomPresetTeams),
            ),
            DropdownMenuItem(
              value: 'custom',
              child: Text(l10n.alertChannelCustomPresetCustom),
            ),
          ],
          onChanged: (value) => onPresetChanged(value ?? 'genericJson'),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: <ButtonSegment<String>>[
            ButtonSegment(
              value: 'json',
              label: Text(l10n.alertChannelCustomBodyJson),
            ),
            ButtonSegment(
              value: 'form',
              label: Text(l10n.alertChannelCustomBodyForm),
            ),
            ButtonSegment(
              value: 'text',
              label: Text(l10n.alertChannelCustomBodyText),
            ),
          ],
          selected: <String>{bodyType},
          onSelectionChanged: (values) => onBodyTypeChanged(values.first),
        ),
        const SizedBox(height: 12),
        if (bodyType == 'form')
          AlertPairEditor(
            title: l10n.alertChannelCustomFormPairLabel,
            pairs: formPairs,
            keyLabel: l10n.alertChannelCustomHeaderKeyLabel,
            valueLabel: l10n.alertChannelCustomHeaderValueLabel,
            addLabel: l10n.alertChannelCustomAddPairAction,
            onAdd: onAddPair,
            onRemove: onRemovePair,
            onChanged: onTemplateChanged,
          )
        else ...[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.alertChannelCustomTemplateLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: () => _formatTemplate(context),
                child: Text(l10n.alertChannelCustomFormatAction),
              ),
            ],
          ),
          TextField(
            controller: templateController,
            maxLines: 8,
            minLines: 5,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onChanged: (_) => onTemplateChanged(),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          l10n.alertChannelCustomVariableHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            _VariableChip(
              label: l10n.alertChannelCustomVariableTitle,
              variable: '{{title}}',
              templateController: templateController,
              onInserted: onTemplateChanged,
            ),
            _VariableChip(
              label: l10n.alertChannelCustomVariableMessage,
              variable: '{{message}}',
              templateController: templateController,
              onInserted: onTemplateChanged,
            ),
            _VariableChip(
              label: l10n.alertChannelCustomVariableType,
              variable: '{{type}}',
              templateController: templateController,
              onInserted: onTemplateChanged,
            ),
            _VariableChip(
              label: l10n.alertChannelCustomVariableNode,
              variable: '{{nodeName}}',
              templateController: templateController,
              onInserted: onTemplateChanged,
            ),
            _VariableChip(
              label: l10n.alertChannelCustomVariableTimestamp,
              variable: '{{timestamp}}',
              templateController: templateController,
              onInserted: onTemplateChanged,
            ),
          ],
        ),
        const SizedBox(height: 12),
        AlertPairEditor(
          title: l10n.alertChannelCustomHeadersLabel,
          pairs: headers,
          keyLabel: l10n.alertChannelCustomHeaderKeyLabel,
          valueLabel: l10n.alertChannelCustomHeaderValueLabel,
          addLabel: l10n.alertChannelCustomAddHeaderAction,
          onAdd: onAddHeader,
          onRemove: onRemoveHeader,
          onChanged: onTemplateChanged,
        ),
      ],
    );
  }

  /// 按两空格缩进格式化 JSON 模板；非 JSON 内容保留原文并提示原因。
  void _formatTemplate(BuildContext context) {
    final l10n = context.l10n;
    final raw = templateController.text.trim();
    if (raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      templateController.text = const JsonEncoder.withIndent('  ')
          .convert(decoded);
      onTemplateChanged();
    } on FormatException {
      SnackBarUtils.showError(context, l10n.commonErrorBadRequest);
    }
  }
}

/// 键值对编辑器，用于 Form Body 与自定义 Header。
class AlertPairEditor extends StatelessWidget {
  const AlertPairEditor({
    super.key,
    required this.title,
    required this.pairs,
    required this.keyLabel,
    required this.valueLabel,
    required this.addLabel,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  final String title;
  final List<AlertPairController> pairs;
  final String keyLabel;
  final String valueLabel;
  final String addLabel;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: Text(addLabel),
            ),
          ],
        ),
        for (var index = 0; index < pairs.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: pairs[index].keyController,
                    decoration:
                        InputDecoration(labelText: keyLabel, isDense: true),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: pairs[index].valueController,
                    decoration:
                        InputDecoration(labelText: valueLabel, isDense: true),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => onRemove(index),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 模板变量插入按钮。
class _VariableChip extends StatelessWidget {
  const _VariableChip({
    required this.label,
    required this.variable,
    required this.templateController,
    required this.onInserted,
  });

  final String label;
  final String variable;
  final TextEditingController templateController;
  final VoidCallback onInserted;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      tooltip: variable,
      onPressed: () {
        final current = templateController.text;
        final selection = templateController.selection;
        final insertAt = selection.isValid
            ? selection.start
            : current.length;
        final next = current.replaceRange(
          selection.isValid ? selection.start : current.length,
          selection.isValid ? selection.end : current.length,
          variable,
        );
        templateController.text = next;
        templateController.selection =
            TextSelection.collapsed(offset: insertAt + variable.length);
        onInserted();
      },
    );
  }
}

/// 各预设的 Body 模板。
class AlertWebhookPresets {
  const AlertWebhookPresets._();

  static String? template(String preset) {
    switch (preset) {
      case 'genericJson':
        return '{\n  "title": "{{title}}",\n  "message": "{{message}}",\n'
            '  "type": "{{type}}",\n  "node": "{{nodeName}}",\n'
            '  "timestamp": "{{timestamp}}"\n}';
      case 'slack':
        return '{\n  "text": "{{title}}\\n{{message}}"\n}';
      case 'discord':
        return '{\n  "content": "{{title}}\\n{{message}}"\n}';
      case 'teams':
        return '{\n  "type": "message",\n  "attachments": [\n    {\n'
            '      "contentType": "application/vnd.microsoft.card.adaptive",\n'
            '      "content": {\n        "type": "AdaptiveCard",\n'
            '        "body": [\n          { "type": "TextBlock", '
            '"text": "{{title}}" },\n          { "type": "TextBlock", '
            '"text": "{{message}}" }\n        ]\n      }\n    }\n  ]\n}';
      default:
        return null;
    }
  }
}
