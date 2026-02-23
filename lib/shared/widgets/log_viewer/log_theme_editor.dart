import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:onepanelapp_app/l10n/generated/app_localizations.dart';
import 'log_viewer_controller.dart';

class LogThemeEditor extends StatefulWidget {
  final LogViewerController controller;

  const LogThemeEditor({super.key, required this.controller});

  @override
  State<LogThemeEditor> createState() => _LogThemeEditorState();
}

class _LogThemeEditorState extends State<LogThemeEditor> {
  late LogTheme _theme;

  @override
  void initState() {
    super.initState();
    _theme = widget.controller.settings.theme;
  }

  void _updateTheme(LogTheme newTheme) {
    setState(() {
      _theme = newTheme;
    });
    widget.controller.updateSettings(widget.controller.settings.copyWith(theme: newTheme));
  }

  void _addRule() {
    final l10n = AppLocalizations.of(context)!;
    final newRule = LogHighlightRule(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pattern: l10n.logRulePattern,
      color: Colors.red,
    );
    _updateTheme(_theme.copyWith(
      rules: [..._theme.rules, newRule],
    ));
    _editRule(newRule);
  }

  void _editRule(LogHighlightRule rule) {
    showDialog(
      context: context,
      builder: (context) => _RuleEditorDialog(
        rule: rule,
        onSave: (updatedRule) {
          final newRules = List<LogHighlightRule>.from(_theme.rules);
          final index = newRules.indexOf(rule);
          if (index != -1) {
            newRules[index] = updatedRule;
            _updateTheme(_theme.copyWith(rules: newRules));
          }
        },
      ),
    );
  }

  void _deleteRule(LogHighlightRule rule) {
    final newRules = List<LogHighlightRule>.from(_theme.rules)..remove(rule);
    _updateTheme(_theme.copyWith(rules: newRules));
  }

  void _reorderRules(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final newRules = List<LogHighlightRule>.from(_theme.rules);
    final rule = newRules.removeAt(oldIndex);
    newRules.insert(newIndex, rule);
    _updateTheme(_theme.copyWith(rules: newRules));
  }

  void _importTheme() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(l10n.logImportTheme),
          content: TextField(
            controller: controller,
            maxLines: 10,
            decoration: const InputDecoration(hintText: 'Paste JSON here'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () {
                try {
                  final json = jsonDecode(controller.text);
                  final theme = LogTheme.fromJson(json);
                  _updateTheme(theme);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.logImportSuccess)),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.logInvalidJson}: $e')),
                  );
                }
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }

  void _exportTheme() {
    final l10n = AppLocalizations.of(context)!;
    final json = jsonEncode(_theme.toJson());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.logExportTheme),
          content: SelectableText(json),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonClose),
            ),
            TextButton(
              onPressed: () {
                // Copy to clipboard
              },
              child: Text(l10n.commonCopy),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.logThemeEditor),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: l10n.logImportTheme,
            onPressed: _importTheme,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: l10n.logExportTheme,
            onPressed: _exportTheme,
          ),
        ],
      ),
      body: ReorderableListView.builder(
        itemCount: _theme.rules.length,
        onReorder: _reorderRules,
        itemBuilder: (context, index) {
          final rule = _theme.rules[index];
          return ListTile(
            key: ValueKey(rule),
            leading: Container(
              width: 24,
              height: 24,
              color: rule.color ?? Colors.transparent,
              child: rule.backgroundColor != null
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        color: rule.backgroundColor,
                      ),
                    )
                  : null,
            ),
            title: Text(rule.pattern),
            subtitle: Text(
              '${rule.type.name.toUpperCase()} • ${rule.caseSensitive ? l10n.logRuleCaseSensitive : l10n.logRuleCaseInsensitive}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editRule(rule),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteRule(rule),
                ),
                const Icon(Icons.drag_handle),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRule,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RuleEditorDialog extends StatefulWidget {
  final LogHighlightRule rule;
  final ValueChanged<LogHighlightRule> onSave;

  const _RuleEditorDialog({
    required this.rule,
    required this.onSave,
  });

  @override
  State<_RuleEditorDialog> createState() => _RuleEditorDialogState();
}

class _RuleEditorDialogState extends State<_RuleEditorDialog> {
  late TextEditingController _patternController;
  late HighlightType _type;
  late bool _caseSensitive;
  late Color _color;
  late Color _backgroundColor;
  late bool _isBold;
  late bool _isItalic;
  late bool _isUnderline;

  @override
  void initState() {
    super.initState();
    _patternController = TextEditingController(text: widget.rule.pattern);
    _type = widget.rule.type;
    _caseSensitive = widget.rule.caseSensitive;
    _color = widget.rule.color ?? Colors.black;
    _backgroundColor = widget.rule.backgroundColor ?? Colors.transparent;
    _isBold = widget.rule.isBold;
    _isItalic = widget.rule.isItalic;
    _isUnderline = widget.rule.isUnderline;
  }

  @override
  void dispose() {
    _patternController.dispose();
    super.dispose();
  }

  void _save() {
    final updatedRule = widget.rule.copyWith(
      pattern: _patternController.text,
      type: _type,
      caseSensitive: _caseSensitive,
      color: _color == Colors.black ? null : _color, // Simplification
      backgroundColor: _backgroundColor == Colors.transparent ? null : _backgroundColor,
      isBold: _isBold,
      isItalic: _isItalic,
      isUnderline: _isUnderline,
    );
    widget.onSave(updatedRule);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.logEditTheme),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _patternController,
              decoration: InputDecoration(labelText: l10n.logRulePattern),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<HighlightType>(
              value: _type,
              decoration: InputDecoration(labelText: l10n.logRuleType),
              items: HighlightType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            SwitchListTile(
              title: Text(l10n.logRuleCaseSensitive),
              value: _caseSensitive,
              onChanged: (value) => setState(() => _caseSensitive = value),
            ),
            const Divider(),
            ListTile(
              title: Text(l10n.logRuleColor),
              trailing: Container(
                width: 24,
                height: 24,
                color: _color,
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Pick a color'),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: _color,
                        onColorChanged: (color) => setState(() => _color = color),
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Done'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              title: Text(l10n.logRuleBackgroundColor),
              trailing: Container(
                width: 24,
                height: 24,
                color: _backgroundColor,
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Pick a background color'),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: _backgroundColor,
                        onColorChanged: (color) => setState(() => _backgroundColor = color),
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Done'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ToggleButtons(
                  isSelected: [_isBold, _isItalic, _isUnderline],
                  onPressed: (index) {
                    setState(() {
                      if (index == 0) _isBold = !_isBold;
                      if (index == 1) _isItalic = !_isItalic;
                      if (index == 2) _isUnderline = !_isUnderline;
                    });
                  },
                  children: const [
                    Icon(Icons.format_bold),
                    Icon(Icons.format_italic),
                    Icon(Icons.format_underline),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
