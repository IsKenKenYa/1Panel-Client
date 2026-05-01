import 'package:flutter/material.dart';
import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:xterm/ui.dart';

class TerminalAppearance {
  const TerminalAppearance._();

  static const List<String> _defaultFontFallback = <String>[
    'Monaco',
    'Menlo',
    'Consolas',
    'Courier New',
    'Noto Sans Mono CJK SC',
    'Source Han Mono SC',
    'Noto Color Emoji',
    'monospace',
  ];

  static TerminalStyle buildTextStyle(TerminalInfo? info) {
    final families = _parseFontFamilies(info?.fontFamily);
    final fontSize = double.tryParse(info?.fontSize ?? '') ?? 13;
    final lineHeight = double.tryParse(info?.lineHeight ?? '') ?? 1.2;

    return TerminalStyle(
      fontSize: fontSize,
      height: lineHeight,
      fontFamily: families.first,
      fontFamilyFallback: families.skip(1).toList(growable: false),
    );
  }

  static TerminalTheme buildTheme(TerminalInfo? info) {
    final background = _parseColor(info?.backgroundColor, const Color(0xFF000000));
    final foreground = _parseColor(info?.foregroundColor, const Color(0xFFF5F5F5));
    const base = TerminalThemes.defaultTheme;

    return TerminalTheme(
      cursor: foreground.withValues(alpha: 0.72),
      selection: base.selection,
      foreground: foreground,
      background: background,
      black: base.black,
      white: base.white,
      red: base.red,
      green: base.green,
      yellow: base.yellow,
      blue: base.blue,
      magenta: base.magenta,
      cyan: base.cyan,
      brightBlack: base.brightBlack,
      brightRed: base.brightRed,
      brightGreen: base.brightGreen,
      brightYellow: base.brightYellow,
      brightBlue: base.brightBlue,
      brightMagenta: base.brightMagenta,
      brightCyan: base.brightCyan,
      brightWhite: base.brightWhite,
      searchHitBackground: base.searchHitBackground,
      searchHitBackgroundCurrent: base.searchHitBackgroundCurrent,
      searchHitForeground: base.searchHitForeground,
    );
  }

  static int resolveScrollback(TerminalInfo? info) {
    final value = int.tryParse(info?.scrollback ?? '');
    if (value == null || value < 100) {
      return 1000;
    }
    return value;
  }

  static double resolveLetterSpacing(TerminalInfo? info) {
    return double.tryParse(info?.letterSpacing ?? '') ?? 0;
  }

  static List<String> _parseFontFamilies(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return _defaultFontFallback;
    }

    final values = raw
        .split(',')
        .map((item) => item.trim().replaceAll("'", ''))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (values.isEmpty) {
      return _defaultFontFallback;
    }

    final merged = <String>[
      ...values,
      ..._defaultFontFallback.where((item) => !values.contains(item)),
    ];
    return merged;
  }

  static Color _parseColor(String? raw, Color fallback) {
    if (raw == null || raw.trim().isEmpty) {
      return fallback;
    }
    final normalized = raw.trim().replaceFirst('#', '');
    final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
    final value = int.tryParse(hex, radix: 16);
    if (value == null) {
      return fallback;
    }
    return Color(value);
  }
}
