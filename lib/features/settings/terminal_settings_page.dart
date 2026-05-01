import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';
import 'package:onepanel_client/features/terminal/services/terminal_appearance.dart';
import 'package:provider/provider.dart';

class TerminalSettingsPage extends StatefulWidget {
  const TerminalSettingsPage({
    super.key,
    this.provider,
  });

  final SettingsProvider? provider;

  @override
  State<TerminalSettingsPage> createState() => _TerminalSettingsPageState();
}

class _TerminalSettingsPageState extends State<TerminalSettingsPage> {
  late final SettingsProvider _provider;

  static const List<String> _fontFamilyOptions = <String>[
    'Monaco',
    'Menlo',
    'Consolas',
    'JetBrains Mono',
    'Fira Code',
    'Cascadia Code',
    'Source Code Pro',
    'Ubuntu Mono',
    'DejaVu Sans Mono',
    'Courier New',
    'Noto Sans Mono CJK SC',
    'Source Han Mono SC',
    'monospace',
  ];

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ?? SettingsProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _provider.loadTerminalSettings();
      _provider.loadSSHConnection();
    });
  }

  @override
  void dispose() {
    if (widget.provider == null) {
      _provider.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SettingsProvider>.value(
      value: _provider,
      child: Consumer<SettingsProvider>(
        builder: (context, provider, _) {
          final l10n = context.l10n;
          final theme = Theme.of(context);
          final terminal = provider.data.terminalSettings ?? const TerminalInfo();
          final connection = provider.data.sshConnection;

          return Scaffold(
            appBar: AppBar(title: Text(l10n.terminalSettingsTitle)),
            body: ListView(
              padding: AppDesignTokens.pagePadding,
              children: [
                _buildSectionTitle(context, l10n.terminalSettingsPreview, theme),
                _PreviewCard(settings: terminal),
                const SizedBox(height: AppDesignTokens.spacingMd),
                _buildSectionTitle(context, l10n.terminalSettingsDisplay, theme),
                Card(
                  child: Column(
                    children: [
                      _buildActionTile(
                        context,
                        title: l10n.terminalSettingsCursorStyle,
                        value: _cursorStyleLabel(context, terminal.cursorStyle),
                        icon: Icons.arrow_right_alt_outlined,
                        onTap: () => _showCursorStyleSheet(provider, terminal),
                      ),
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.flash_on_outlined),
                        title: Text(l10n.terminalSettingsCursorBlink),
                        value: (terminal.cursorBlink ?? 'Enable')
                                .toLowerCase() ==
                            'enable',
                        onChanged: (value) async {
                          final success = await provider.updateTerminalSettings(
                            cursorBlink: value ? 'Enable' : 'Disable',
                          );
                          if (context.mounted) {
                            _showResultSnackBar(context, success, l10n);
                          }
                        },
                      ),
                      _buildActionTile(
                        context,
                        title: l10n.terminalSettingsFontSize,
                        value: terminal.fontSize ?? '14',
                        icon: Icons.format_size_outlined,
                        onTap: () => _showNumericSettingSheet(
                          context,
                          title: l10n.terminalSettingsFontSize,
                          initial: double.tryParse(terminal.fontSize ?? '') ?? 14,
                          min: 12,
                          max: 24,
                          step: 1,
                          display: (value) => value.toStringAsFixed(0),
                          onSave: (value) => provider.updateTerminalSettings(
                            fontSize: value.toStringAsFixed(0),
                          ),
                        ),
                      ),
                      _buildActionTile(
                        context,
                        title: l10n.terminalSettingsFontFamily,
                        value: terminal.fontFamily ?? 'Monaco, Menlo, Consolas',
                        icon: Icons.font_download_outlined,
                        onTap: () => _showFontFamilySheet(provider, terminal),
                      ),
                      _buildActionTile(
                        context,
                        title: l10n.terminalSettingsBackgroundColor,
                        value: terminal.backgroundColor ?? '#000000',
                        icon: Icons.format_color_fill_outlined,
                        trailingSwatch:
                            _parseColor(terminal.backgroundColor, const Color(0xFF000000)),
                        onTap: () => _showColorPickerDialog(
                          context,
                          title: l10n.terminalSettingsBackgroundColor,
                          initialColor:
                              _parseColor(terminal.backgroundColor, const Color(0xFF000000)),
                          onSave: (color) => provider.updateTerminalSettings(
                            backgroundColor: _toHex(color),
                          ),
                        ),
                      ),
                      _buildActionTile(
                        context,
                        title: l10n.terminalSettingsForegroundColor,
                        value: terminal.foregroundColor ?? '#f5f5f5',
                        icon: Icons.format_color_text_outlined,
                        trailingSwatch:
                            _parseColor(terminal.foregroundColor, const Color(0xFFF5F5F5)),
                        onTap: () => _showColorPickerDialog(
                          context,
                          title: l10n.terminalSettingsForegroundColor,
                          initialColor:
                              _parseColor(terminal.foregroundColor, const Color(0xFFF5F5F5)),
                          onSave: (color) => provider.updateTerminalSettings(
                            foregroundColor: _toHex(color),
                          ),
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
                      _buildActionTile(
                        context,
                        title: l10n.terminalSettingsScrollback,
                        value: terminal.scrollback ?? '1000',
                        icon: Icons.history_outlined,
                        onTap: () => _showNumericSettingSheet(
                          context,
                          title: l10n.terminalSettingsScrollback,
                          initial:
                              double.tryParse(terminal.scrollback ?? '') ?? 1000,
                          min: 100,
                          max: 10000,
                          step: 100,
                          display: (value) => value.toStringAsFixed(0),
                          onSave: (value) => provider.updateTerminalSettings(
                            scrollback: value.toStringAsFixed(0),
                          ),
                        ),
                      ),
                      _buildActionTile(
                        context,
                        title: l10n.terminalSettingsScrollSensitivity,
                        value: terminal.scrollSensitivity ?? '6',
                        icon: Icons.swipe_outlined,
                        onTap: () => _showNumericSettingSheet(
                          context,
                          title: l10n.terminalSettingsScrollSensitivity,
                          initial:
                              double.tryParse(terminal.scrollSensitivity ?? '') ??
                                  6,
                          min: 0,
                          max: 16,
                          step: 1,
                          display: (value) => value.toStringAsFixed(0),
                          onSave: (value) => provider.updateTerminalSettings(
                            scrollSensitivity: value.toStringAsFixed(0),
                          ),
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
                      _buildActionTile(
                        context,
                        title: l10n.terminalSettingsLineHeight,
                        value: terminal.lineHeight ?? '1.2',
                        icon: Icons.format_line_spacing_outlined,
                        onTap: () => _showNumericSettingSheet(
                          context,
                          title: l10n.terminalSettingsLineHeight,
                          initial:
                              double.tryParse(terminal.lineHeight ?? '') ?? 1.2,
                          min: 1.0,
                          max: 2.0,
                          step: 0.1,
                          display: (value) => value.toStringAsFixed(1),
                          onSave: (value) => provider.updateTerminalSettings(
                            lineHeight: value.toStringAsFixed(1),
                          ),
                        ),
                      ),
                      _buildActionTile(
                        context,
                        title: l10n.terminalSettingsLetterSpacing,
                        value: terminal.letterSpacing ?? '0',
                        icon: Icons.space_bar_outlined,
                        onTap: () => _showNumericSettingSheet(
                          context,
                          title: l10n.terminalSettingsLetterSpacing,
                          initial:
                              double.tryParse(terminal.letterSpacing ?? '') ?? 0,
                          min: 0,
                          max: 3.5,
                          step: 0.5,
                          display: (value) => value.toStringAsFixed(1),
                          onSave: (value) => provider.updateTerminalSettings(
                            letterSpacing: value.toStringAsFixed(1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDesignTokens.spacingMd),
                _buildSectionTitle(
                  context,
                  l10n.terminalSettingsDefaultLocalConnection,
                  theme,
                ),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.computer_outlined),
                        title: Text(l10n.terminalSettingsShowLocalByDefault),
                        subtitle: Text(connection?.summary ?? '-'),
                        value: connection?.isVisibleByDefault ?? false,
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
                        leading: const Icon(Icons.settings_ethernet_outlined),
                        title: Text(l10n.terminalSettingsCurrentConnection),
                        subtitle: Text(connection?.summary ?? '-'),
                        trailing: FilledButton.tonal(
                          onPressed: () =>
                              _showLocalConnectionDialog(context, provider),
                          child: Text(l10n.commonSave),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    ThemeData theme,
  ) {
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

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    Color? trailingSwatch,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingSwatch != null)
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: trailingSwatch,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black12),
              ),
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }

  Future<void> _showCursorStyleSheet(
    SettingsProvider provider,
    TerminalInfo terminal,
  ) async {
    final currentStyle = terminal.cursorStyle ?? 'block';
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.terminalSettingsCursorBlock),
                trailing:
                    currentStyle == 'block' ? const Icon(Icons.check) : null,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final success = await provider.updateTerminalSettings(
                    cursorStyle: 'block',
                  );
                  if (mounted) {
                    _showResultSnackBar(context, success, l10n);
                  }
                },
              ),
              ListTile(
                title: Text(l10n.terminalSettingsCursorUnderline),
                trailing: currentStyle == 'underline'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final success = await provider.updateTerminalSettings(
                    cursorStyle: 'underline',
                  );
                  if (mounted) {
                    _showResultSnackBar(context, success, l10n);
                  }
                },
              ),
              ListTile(
                title: Text(l10n.terminalSettingsCursorBar),
                trailing:
                    currentStyle == 'bar' ? const Icon(Icons.check) : null,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final success = await provider.updateTerminalSettings(
                    cursorStyle: 'bar',
                  );
                  if (mounted) {
                    _showResultSnackBar(context, success, l10n);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showFontFamilySheet(
    SettingsProvider provider,
    TerminalInfo terminal,
  ) async {
    final l10n = context.l10n;
    final selected = <String>{
      ...((terminal.fontFamily ?? '')
          .split(',')
          .map((item) => item.trim().replaceAll("'", ''))
          .where((item) => item.isNotEmpty)),
    };

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.terminalSettingsFontFamily,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.terminalSettingsFontFamilyHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: _fontFamilyOptions.map((option) {
                          return CheckboxListTile(
                            value: selected.contains(option),
                            title: Text(option),
                            onChanged: (checked) {
                              setSheetState(() {
                                if (checked == true) {
                                  selected.add(option);
                                } else {
                                  selected.remove(option);
                                }
                              });
                            },
                          );
                        }).toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              selected
                                ..clear()
                                ..addAll(const <String>[
                                  'Monaco',
                                  'Menlo',
                                  'Consolas',
                                  'Courier New',
                                  'monospace',
                                ]);
                            });
                          },
                          child: Text(context.l10n.commonReset),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () async {
                            final families = selected.isEmpty
                                ? "Monaco, Menlo, Consolas, 'Courier New', monospace"
                                : selected.join(', ');
                            Navigator.pop(sheetContext);
                            final success =
                                await provider.updateTerminalSettings(
                              fontFamily: families,
                            );
                            if (!mounted) return;
                            _showResultSnackBar(this.context, success, l10n);
                          },
                          child: Text(l10n.commonSave),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showNumericSettingSheet(
    BuildContext context, {
    required String title,
    required double initial,
    required double min,
    required double max,
    required double step,
    required String Function(double value) display,
    required Future<bool> Function(double value) onSave,
  }) async {
    final l10n = context.l10n;
    var value = initial.clamp(min, max);

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final divisions = ((max - min) / step).round();
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Text(
                      display(value),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Slider(
                      value: value,
                      min: min,
                      max: max,
                      divisions: divisions <= 0 ? null : divisions,
                      label: display(value),
                      onChanged: (next) {
                        setSheetState(() {
                          value = ((next - min) / step).round() * step + min;
                          value = double.parse(value.toStringAsFixed(2));
                        });
                      },
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: value <= min
                              ? null
                              : () => setSheetState(() {
                                    value = (value - step).clamp(min, max);
                                    value = double.parse(value.toStringAsFixed(2));
                                  }),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: value >= max
                              ? null
                              : () => setSheetState(() {
                                    value = (value + step).clamp(min, max);
                                    value = double.parse(value.toStringAsFixed(2));
                                  }),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: Text(l10n.commonCancel),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            final success = await onSave(value);
                            if (context.mounted) {
                              _showResultSnackBar(context, success, l10n);
                            }
                          },
                          child: Text(l10n.commonSave),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showColorPickerDialog(
    BuildContext context, {
    required String title,
    required Color initialColor,
    required Future<bool> Function(Color color) onSave,
  }) async {
    final l10n = context.l10n;
    Color selected = initialColor;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: selected,
              onColorChanged: (color) {
                selected = color;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final success = await onSave(selected);
                if (context.mounted) {
                  _showResultSnackBar(context, success, l10n);
                }
              },
              child: Text(l10n.commonSave),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLocalConnectionDialog(
    BuildContext context,
    SettingsProvider provider,
  ) async {
    final l10n = context.l10n;
    final current = provider.data.sshConnection;
    final hostController = TextEditingController(text: current?.addr ?? '');
    final portController =
        TextEditingController(text: (current?.port ?? 22).toString());
    final userController = TextEditingController(text: current?.user ?? '');
    final passwordController =
        TextEditingController(text: current?.password ?? '');
    final privateKeyController =
        TextEditingController(text: current?.privateKey ?? '');
    final passPhraseController =
        TextEditingController(text: current?.passPhrase ?? '');
    var authMode = current?.authMode ?? 'password';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.terminalSettingsConnectionSetup),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: hostController,
                      decoration: const InputDecoration(labelText: 'Host'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: portController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Port'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: userController,
                      decoration: const InputDecoration(labelText: 'User'),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(l10n.terminalSettingsConnectionAuthMode),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: <ButtonSegment<String>>[
                        ButtonSegment<String>(
                          value: 'password',
                          label: Text(l10n.terminalSettingsConnectionPassword),
                        ),
                        ButtonSegment<String>(
                          value: 'key',
                          label: Text(l10n.terminalSettingsConnectionPrivateKey),
                        ),
                      ],
                      selected: <String>{authMode},
                      onSelectionChanged: (selection) {
                        setDialogState(() {
                          authMode = selection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    if (authMode == 'password')
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: l10n.terminalSettingsConnectionPassword,
                        ),
                      )
                    else ...[
                      TextField(
                        controller: privateKeyController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: InputDecoration(
                          labelText:
                              l10n.terminalSettingsConnectionPrivateKey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passPhraseController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText:
                              l10n.terminalSettingsConnectionPassPhrase,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l10n.commonCancel),
                ),
                TextButton(
                  onPressed: () async {
                    final ok = await provider.checkSSHConnection(
                      host: hostController.text.trim(),
                      port: int.tryParse(portController.text.trim()),
                      user: userController.text.trim(),
                      authMode: authMode,
                      password: passwordController.text,
                      privateKey: privateKeyController.text.trim().isEmpty
                          ? null
                          : privateKeyController.text.trim(),
                      passPhrase: passPhraseController.text.trim().isEmpty
                          ? null
                          : passPhraseController.text.trim(),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? l10n.commonSaveSuccess
                                : l10n.commonSaveFailed,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(l10n.terminalSettingsTestConnection),
                ),
                FilledButton(
                  onPressed: () async {
                    final ok = await provider.saveSSHConnection(
                      host: hostController.text.trim().isEmpty
                          ? null
                          : hostController.text.trim(),
                      port: int.tryParse(portController.text.trim()),
                      user: userController.text.trim().isEmpty
                          ? null
                          : userController.text.trim(),
                      password: authMode == 'password'
                          ? passwordController.text
                          : null,
                      privateKey: authMode == 'key' &&
                              privateKeyController.text.trim().isNotEmpty
                          ? privateKeyController.text.trim()
                          : null,
                      passPhrase: authMode == 'key' &&
                              passPhraseController.text.trim().isNotEmpty
                          ? passPhraseController.text.trim()
                          : null,
                    );
                    if (!dialogContext.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok ? l10n.commonSaveSuccess : l10n.commonSaveFailed,
                        ),
                      ),
                    );
                    if (ok) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: Text(l10n.commonSave),
                ),
              ],
            );
          },
        );
      },
    );

    hostController.dispose();
    portController.dispose();
    userController.dispose();
    passwordController.dispose();
    privateKeyController.dispose();
    passPhraseController.dispose();
  }

  String _cursorStyleLabel(BuildContext context, String? value) {
    final l10n = context.l10n;
    switch ((value ?? 'block').toLowerCase()) {
      case 'underline':
        return l10n.terminalSettingsCursorUnderline;
      case 'bar':
        return l10n.terminalSettingsCursorBar;
      case 'block':
      default:
        return l10n.terminalSettingsCursorBlock;
    }
  }

  Color _parseColor(String? raw, Color fallback) {
    if (raw == null || raw.trim().isEmpty) {
      return fallback;
    }
    final normalized = raw.trim().replaceFirst('#', '');
    final full = normalized.length == 6 ? 'FF$normalized' : normalized;
    final value = int.tryParse(full, radix: 16);
    if (value == null) {
      return fallback;
    }
    return Color(value);
  }

  String _toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  void _showResultSnackBar(
    BuildContext context,
    bool success,
    AppLocalizations l10n,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? l10n.commonSaveSuccess : l10n.commonSaveFailed,
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.settings,
  });

  final TerminalInfo settings;

  @override
  Widget build(BuildContext context) {
    final terminalTheme = TerminalAppearance.buildTheme(settings);
    final style = TerminalAppearance.buildTextStyle(settings);
    final textStyle = style.toTextStyle(color: terminalTheme.foreground);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: terminalTheme.background,
        child: DefaultTextStyle(
          style: textStyle,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('root@server:~# ls -la'),
              SizedBox(height: 6),
              Text('drwxr-xr-x  2 root root 4096 Apr 28 00:00 .'),
              SizedBox(height: 6),
              Text('中文宽字符 ABC 你好 world'),
            ],
          ),
        ),
      ),
    );
  }
}
