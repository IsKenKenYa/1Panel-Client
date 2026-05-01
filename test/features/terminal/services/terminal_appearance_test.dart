import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:onepanel_client/features/terminal/services/terminal_appearance.dart';

void main() {
  group('TerminalAppearance', () {
    test('buildTextStyle respects font family and fallback', () {
      const info = TerminalInfo(
        fontSize: '14',
        fontFamily: "JetBrains Mono, Noto Sans Mono CJK SC, monospace",
        lineHeight: '1.4',
      );

      final style = TerminalAppearance.buildTextStyle(info);
      expect(style.fontSize, 14);
      expect(style.height, 1.4);
      expect(style.fontFamily, 'JetBrains Mono');
      expect(style.fontFamilyFallback, contains('Noto Sans Mono CJK SC'));
    });

    test('buildTheme respects background and foreground colors', () {
      const info = TerminalInfo(
        backgroundColor: '#000000',
        foregroundColor: '#f5f5f5',
      );

      final theme = TerminalAppearance.buildTheme(info);
      expect(theme.background.toARGB32(), 0xFF000000);
      expect(theme.foreground.toARGB32(), 0xFFF5F5F5);
    });
  });
}
