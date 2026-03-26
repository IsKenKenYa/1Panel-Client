import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
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
    final l10n = AppLocalizations.of(context);
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
    final l10n = AppLocalizations.of(context);
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
    final l10n = AppLocalizations.of(context);
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
  String? _colorName;
  late Color _backgroundColor;
  String? _backgroundColorName;
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
    _colorName = widget.rule.colorName;
    _backgroundColor = widget.rule.backgroundColor ?? Colors.transparent;
    _backgroundColorName = widget.rule.backgroundColorName;
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
      color: _colorName == null && _color != Colors.black ? _color : null,
      colorName: _colorName,
      backgroundColor: _backgroundColorName == null && _backgroundColor != Colors.transparent ? _backgroundColor : null,
      backgroundColorName: _backgroundColorName,
      isBold: _isBold,
      isItalic: _isItalic,
      isUnderline: _isUnderline,
    );
    widget.onSave(updatedRule);
    Navigator.pop(context);
  }

  Widget _buildColorSelector({
    required String label,
    required Color currentColor,
    required String? currentColorName,
    required ValueChanged<Color> onColorChanged,
    required ValueChanged<String?> onColorNameChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final colorMap = {
      'primary': scheme.primary,
      'onPrimary': scheme.onPrimary,
      'primaryContainer': scheme.primaryContainer,
      'onPrimaryContainer': scheme.onPrimaryContainer,
      'secondary': scheme.secondary,
      'onSecondary': scheme.onSecondary,
      'secondaryContainer': scheme.secondaryContainer,
      'onSecondaryContainer': scheme.onSecondaryContainer,
      'tertiary': scheme.tertiary,
      'onTertiary': scheme.onTertiary,
      'tertiaryContainer': scheme.tertiaryContainer,
      'onTertiaryContainer': scheme.onTertiaryContainer,
      'error': scheme.error,
      'onError': scheme.onError,
      'errorContainer': scheme.errorContainer,
      'onErrorContainer': scheme.onErrorContainer,
      'outline': scheme.outline,
      'outlineVariant': scheme.outlineVariant,
      'surface': scheme.surface,
      'onSurface': scheme.onSurface,
      'surfaceVariant': scheme.surfaceContainerHighest,
      'onSurfaceVariant': scheme.onSurfaceVariant,
      'inverseSurface': scheme.inverseSurface,
      'onInverseSurface': scheme.onInverseSurface,
      'inversePrimary': scheme.inversePrimary,
      'shadow': scheme.shadow,
      'scrim': scheme.scrim,
      'surfaceTint': scheme.surfaceTint,
    };

    final displayColor = currentColorName != null
        ? (colorMap[currentColorName] ?? currentColor)
        : currentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: currentColorName,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Custom Color')),
                  ...colorMap.keys.map((name) => DropdownMenuItem(
                    value: name,
                    child: Row(
                      children: [
                        Container(width: 12, height: 12, color: colorMap[name]),
                        const SizedBox(width: 8),
                        Text(name),
                      ],
                    ),
                  )),
                ],
                onChanged: onColorNameChanged,
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: currentColorName == null
                  ? () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Pick a color'),
                          content: SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor: currentColor,
                              onColorChanged: onColorChanged,
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
                    }
                  : null,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: displayColor,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              initialValue: _type,
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
            _buildColorSelector(
              label: l10n.logRuleColor,
              currentColor: _color,
              currentColorName: _colorName,
              onColorChanged: (c) => setState(() => _color = c),
              onColorNameChanged: (n) => setState(() => _colorName = n),
            ),
            const SizedBox(height: 16),
            _buildColorSelector(
              label: l10n.logRuleBackgroundColor,
              currentColor: _backgroundColor,
              currentColorName: _backgroundColorName,
              onColorChanged: (c) => setState(() => _backgroundColor = c),
              onColorNameChanged: (n) => setState(() => _backgroundColorName = n),
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
