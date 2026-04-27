import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';
import 'package:provider/provider.dart';

class TerminalSettingsPage extends StatefulWidget {
  const TerminalSettingsPage({super.key});

  @override
  State<TerminalSettingsPage> createState() => _TerminalSettingsPageState();
}

class _TerminalSettingsPageState extends State<TerminalSettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final provider = context.read<SettingsProvider>();
      provider.loadTerminalSettings();
      provider.loadSSHConnection();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final provider = context.watch<SettingsProvider>();
    final terminal = provider.data.terminalSettings;
    final sshConnection = provider.data.sshConnection;

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
                    context,
                    provider,
                    terminal?.cursorStyle ?? 'block',
                  ),
                ),
                _buildEditableListTile(
                  context,
                  title: l10n.terminalSettingsCursorBlink,
                  value: terminal?.cursorBlink ?? '-',
                  icon: Icons.flash_on_outlined,
                  onTap: () => _showBlinkSelector(
                    context,
                    provider,
                    terminal?.cursorBlink ?? 'Enable',
                  ),
                ),
                _buildEditableListTile(
                  context,
                  title: l10n.terminalSettingsFontSize,
                  value: terminal?.fontSize ?? '-',
                  icon: Icons.format_size_outlined,
                  onTap: () => _showEditDialog(
                    context,
                    provider,
                    title: l10n.terminalSettingsFontSize,
                    currentValue: terminal?.fontSize ?? '14',
                    update: (value) =>
                        provider.updateTerminalSettings(fontSize: value),
                  ),
                ),
                _buildEditableListTile(
                  context,
                  title: 'Font Family',
                  value: terminal?.fontFamily ?? '-',
                  icon: Icons.font_download_outlined,
                  onTap: () => _showEditDialog(
                    context,
                    provider,
                    title: 'Font Family',
                    currentValue: terminal?.fontFamily ??
                        "Monaco, Menlo, Consolas, 'Courier New', monospace",
                    update: (value) =>
                        provider.updateTerminalSettings(fontFamily: value),
                  ),
                ),
                _buildEditableListTile(
                  context,
                  title: 'Background',
                  value: terminal?.backgroundColor ?? '#000000',
                  icon: Icons.format_color_fill_outlined,
                  onTap: () => _showEditDialog(
                    context,
                    provider,
                    title: 'Background',
                    currentValue: terminal?.backgroundColor ?? '#000000',
                    update: (value) =>
                        provider.updateTerminalSettings(backgroundColor: value),
                  ),
                ),
                _buildEditableListTile(
                  context,
                  title: 'Foreground',
                  value: terminal?.foregroundColor ?? '#f5f5f5',
                  icon: Icons.format_color_text_outlined,
                  onTap: () => _showEditDialog(
                    context,
                    provider,
                    title: 'Foreground',
                    currentValue: terminal?.foregroundColor ?? '#f5f5f5',
                    update: (value) =>
                        provider.updateTerminalSettings(foregroundColor: value),
                  ),
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
                    title: l10n.terminalSettingsScrollSensitivity,
                    currentValue: terminal?.scrollSensitivity ?? '6',
                    update: (value) =>
                        provider.updateTerminalSettings(scrollSensitivity: value),
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
                    title: l10n.terminalSettingsScrollback,
                    currentValue: terminal?.scrollback ?? '1000',
                    update: (value) =>
                        provider.updateTerminalSettings(scrollback: value),
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
                    title: l10n.terminalSettingsLineHeight,
                    currentValue: terminal?.lineHeight ?? '1.2',
                    update: (value) =>
                        provider.updateTerminalSettings(lineHeight: value),
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
                    title: l10n.terminalSettingsLetterSpacing,
                    currentValue: terminal?.letterSpacing ?? '0',
                    update: (value) =>
                        provider.updateTerminalSettings(letterSpacing: value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          _buildSectionTitle(context, 'Default Local Connection', theme),
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('Show local session by default'),
                  subtitle: Text(sshConnection?.summary ?? '-'),
                  value: sshConnection?.isVisibleByDefault ?? false,
                  onChanged: (value) async {
                    final success =
                        await provider.updateDefaultSSHConnectionVisibility(
                      visible: value,
                    );
                    if (context.mounted) {
                      _showResultSnackBar(context, success, l10n);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Current connection'),
                  subtitle: Text(sshConnection?.summary ?? '-'),
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
      subtitle: value == '-' ? null : Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: onTap == null
          ? null
          : const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    SettingsProvider provider, {
    required String title,
    required String currentValue,
    required Future<bool> Function(String value) update,
  }) async {
    final controller = TextEditingController(text: currentValue);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await update(controller.text.trim());
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

  Future<void> _showCursorStyleSelector(
      BuildContext context, SettingsProvider provider, String currentStyle) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.terminalSettingsCursorStyle),
        content: RadioGroup<String>(
          groupValue: currentStyle,
          onChanged: (selected) async {
            Navigator.pop(dialogContext);
            final success = await provider.updateTerminalSettings(
              cursorStyle: selected,
            );
            if (context.mounted) {
              _showResultSnackBar(context, success, context.l10n);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final value in const <String>['block', 'underline', 'bar'])
                RadioListTile<String>(
                  title: Text(value),
                  value: value,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBlinkSelector(
      BuildContext context, SettingsProvider provider, String currentValue) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.terminalSettingsCursorBlink),
        content: RadioGroup<String>(
          groupValue: currentValue,
          onChanged: (selected) async {
            Navigator.pop(dialogContext);
            final success = await provider.updateTerminalSettings(
              cursorBlink: selected,
            );
            if (context.mounted) {
              _showResultSnackBar(context, success, context.l10n);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final value in const <String>['Enable', 'Disable'])
                RadioListTile<String>(
                  title: Text(value),
                  value: value,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultSnackBar(
      BuildContext context, bool success, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? l10n.commonSaveSuccess : l10n.commonSaveFailed,
        ),
      ),
    );
  }
}
