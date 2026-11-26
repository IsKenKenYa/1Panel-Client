import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/settings/widgets/settings_scaffold.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/theme/theme_controller.dart';
import 'package:onepanel_client/features/settings/widgets/settings_save_action.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  static const List<Color> _presetColors = [
    AppDesignTokens.seedColor,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.brown,
    Colors.blueGrey,
    Colors.grey,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeController = context.watch<ThemeController>();
    final hasSystemPalette = context.watch<ColorScheme?>() != null;

    return SettingsScaffold(
      title: l10n.settingsTheme,
      body: ListView(
        padding: AppDesignTokens.scrollPagePadding(context),
        children: [
          SectionCard(
            child: RadioGroup<ThemeMode>(
              groupValue: themeController.themeMode,
              onChanged: (value) {
                if (value != null) {
                  saveAppPreference(
                    context,
                    () => themeController.updateThemeMode(value),
                  );
                }
              },
              child: Column(
                children: [
                  RadioListTile(
                    value: ThemeMode.system,
                    title: Text(l10n.themeSystem),
                  ),
                  RadioListTile(
                    value: ThemeMode.light,
                    title: Text(l10n.themeLight),
                  ),
                  RadioListTile(
                    value: ThemeMode.dark,
                    title: Text(l10n.themeDark),
                  ),
                ],
              ),
            ),
          ),
          if (hasSystemPalette) ...[
            const SizedBox(height: AppDesignTokens.spacingMd),
            SectionCard(
              child: SwitchListTile(
                title: Text(l10n.themeDynamicColor),
                subtitle: Text(l10n.themeDynamicColorDesc),
                value: themeController.useDynamicColor,
                onChanged: (value) => saveAppPreference(
                  context,
                  () => themeController.updateUseDynamicColor(value),
                ),
              ),
            ),
          ],
          if (!hasSystemPalette || !themeController.useDynamicColor) ...[
            const SizedBox(height: AppDesignTokens.spacingMd),
            SectionCard(
              title: l10n.themeSeedColor,
              padding: const EdgeInsets.all(AppDesignTokens.spacingMd),
              child: Wrap(
                spacing: AppDesignTokens.spacingSm,
                runSpacing: AppDesignTokens.spacingSm,
                children: [
                  for (final color in _presetColors)
                    _SeedColorButton(
                      color: color,
                      selected: themeController.seedColor.toARGB32() ==
                          color.toARGB32(),
                      onPressed: () => saveAppPreference(
                        context,
                        () => themeController.updateSeedColor(color),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeedColorButton extends StatelessWidget {
  const _SeedColorButton({
    required this.color,
    required this.selected,
    required this.onPressed,
  });

  final Color color;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final rgb = color.toARGB32() & 0xffffff;
    return Semantics(
      selected: selected,
      child: IconButton(
        tooltip: '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}',
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: color,
          foregroundColor:
              ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                  ? Colors.white
                  : Colors.black,
          minimumSize: const Size.square(kMinInteractiveDimension),
        ),
        icon: selected ? const Icon(Icons.check) : const SizedBox.shrink(),
      ),
    );
  }
}
