import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';

class TerminalSettingsPage extends StatelessWidget {
  const TerminalSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final provider = context.watch<SettingsProvider>();
    final terminal = provider.data.terminalSettings;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.terminalSettingsTitle)),
      body: ListView(
        padding: AppDesignTokens.pagePadding,
        children: [
          _buildSectionTitle(context, l10n.terminalSettingsDisplay, theme),
          Card(
            child: Column(
              children: [
                _buildEditableListTile(
                  context,
                  title: l10n.terminalSettingsCursorStyle,
                  value: terminal?.cursorStyle ?? '-',
                  icon: Icons.arrow_right_alt_outlined,
                  onTap: () => _showCursorStyleSelector(
                      context, provider, terminal?.cursorStyle ?? 'block'),
                ),
                _buildEditableListTile(
                  context,
                  title: l10n.terminalSettingsCursorBlink,
                  value: terminal?.cursorBlink ?? '-',
                  icon: Icons.flash_on_outlined,
                  onTap: () => _showBlinkSelector(
                      context, provider, terminal?.cursorBlink ?? 'true'),
                ),
                _buildEditableListTile(
                  context,
                  title: l10n.terminalSettingsFontSize,
                  value: terminal?.fontSize ?? '-',
                  icon: Icons.format_size_outlined,
                  onTap: () => _showFontSizeDialog(
                      context, provider, terminal?.fontSize ?? '14'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          _buildSectionTitle(context, l10n.terminalSettingsScroll, theme),
          Card(
            child: Column(
              children: [
                _buildEditableListTile(
                  context,
                  title: l10n.terminalSettingsScrollSensitivity,
                  value: terminal?.scrollSensitivity ?? '-',
                  icon: Icons.swipe_outlined,
                  onTap: () => _showEditDialog(
                    context,
                    provider,
                    l10n.terminalSettingsScrollSensitivity,
                    'scrollSensitivity',
                    terminal?.scrollSensitivity ?? '1',
                  ),
                ),
                _buildEditableListTile(
                  context,
                  title: l10n.terminalSettingsScrollback,
                  value: terminal?.scrollback ?? '-',
                  icon: Icons.history_outlined,
                  onTap: () => _showEditDialog(
                    context,
                    provider,
                    l10n.terminalSettingsScrollback,
                    'scrollback',
                    terminal?.scrollback ?? '1000',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          _buildSectionTitle(context, l10n.terminalSettingsStyle, theme),
          Card(
            child: Column(
              children: [
                _buildEditableListTile(
                  context,
                  title: l10n.terminalSettingsLineHeight,
                  value: terminal?.lineHeight ?? '-',
                  icon: Icons.format_line_spacing_outlined,
                  onTap: () => _showEditDialog(
                    context,
                    provider,
                    l10n.terminalSettingsLineHeight,
                    'lineHeight',
                    terminal?.lineHeight ?? '1.2',
                  ),
                ),
                _buildEditableListTile(
                  context,
                  title: l10n.terminalSettingsLetterSpacing,
                  value: terminal?.letterSpacing ?? '-',
                  icon: Icons.space_bar_outlined,
                  onTap: () => _showEditDialog(
                    context,
                    provider,
                    l10n.terminalSettingsLetterSpacing,
                    'letterSpacing',
                    terminal?.letterSpacing ?? '0',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      BuildContext context, String title, ThemeData theme) {
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

  Widget _buildEditableListTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: Colors.grey)),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
          ],
        ],
      ),
      onTap: onTap,
    );
  }

  void _showEditDialog(
    BuildContext context,
    SettingsProvider provider,
    String title,
    String field,
    String currentValue,
  ) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.updateTerminalSettings(
                cursorStyle: field == 'cursorStyle' ? controller.text : null,
                cursorBlink: field == 'cursorBlink' ? controller.text : null,
                fontSize: field == 'fontSize' ? controller.text : null,
                scrollSensitivity:
                    field == 'scrollSensitivity' ? controller.text : null,
                scrollback: field == 'scrollback' ? controller.text : null,
                lineHeight: field == 'lineHeight' ? controller.text : null,
                letterSpacing:
                    field == 'letterSpacing' ? controller.text : null,
              );
              if (context.mounted) {
                _showResultSnackBar(context, success, context.l10n);
              }
            },
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
  }

  void _showCursorStyleSelector(
      BuildContext context, SettingsProvider provider, String currentStyle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.terminalSettingsCursorStyle),
        content: RadioGroup<String>(
          groupValue: currentStyle,
          onChanged: (value) async {
            Navigator.pop(context);
            if (value == null) {
              return;
            }
            final success =
                await provider.updateTerminalSettings(cursorStyle: value);
            if (context.mounted) {
              _showResultSnackBar(context, success, context.l10n);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Block'),
                value: 'block',
                selected: currentStyle == 'block',
              ),
              RadioListTile<String>(
                title: const Text('Underline'),
                value: 'underline',
                selected: currentStyle == 'underline',
              ),
              RadioListTile<String>(
                title: const Text('Bar'),
                value: 'bar',
                selected: currentStyle == 'bar',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBlinkSelector(
      BuildContext context, SettingsProvider provider, String currentValue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.terminalSettingsCursorBlink),
        content: RadioGroup<String>(
          groupValue: currentValue,
          onChanged: (value) async {
            Navigator.pop(context);
            if (value == null) {
              return;
            }
            final success =
                await provider.updateTerminalSettings(cursorBlink: value);
            if (context.mounted) {
              _showResultSnackBar(context, success, context.l10n);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text(context.l10n.systemSettingsEnabled),
                value: 'true',
                selected: currentValue == 'true',
              ),
              RadioListTile<String>(
                title: Text(context.l10n.systemSettingsDisabled),
                value: 'false',
                selected: currentValue == 'false',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFontSizeDialog(
      BuildContext context, SettingsProvider provider, String currentSize) {
    final controller = TextEditingController(text: currentSize);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.terminalSettingsFontSize),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(suffixText: 'px'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [12, 14, 16, 18, 20].map((size) {
                return ActionChip(
                  label: Text('$size'),
                  onPressed: () {
                    controller.text = size.toString();
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.updateTerminalSettings(
                  fontSize: controller.text);
              if (context.mounted) {
                _showResultSnackBar(context, success, context.l10n);
              }
            },
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
  }

  void _showResultSnackBar(
      BuildContext context, bool success, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(success ? l10n.commonSaveSuccess : l10n.commonSaveFailed)),
    );
  }
}
