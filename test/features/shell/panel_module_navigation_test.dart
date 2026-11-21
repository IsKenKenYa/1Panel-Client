import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/widgets/desktop_module_navigation.dart';
import 'package:onepanel_client/widgets/navigation/app_navigation_icon.dart';

void main() {
  testWidgets('navigation icons follow the system motion preference',
      (tester) async {
    for (final reduced in [false, true]) {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: const AppNavigationIcon(child: SizedBox()),
        ),
      );
      expect(find.byType(AnimatedSwitcher), reduced ? findsNothing : findsOneWidget);
    }
  });

  test('shell routes prefer a named module and bound the tab index', () {
    expect(initialShellModule(1, 'websites'), ClientModule.websites);
    expect(initialShellModule(1, 'unknown'), ClientModule.files);
    expect(initialShellModule(-1, null), ClientModule.servers);
    expect(initialShellModule(2, null), ClientModule.containers);
    expect(initialShellModule(20, null), ClientModule.settings);
  });

  test('selection follows the server while shared pages stay available', () {
    final other = ApiConfig(
      id: 'other',
      name: 'Other',
      url: 'https://panel.invalid',
      panelType: 'other',
      apiKey: '',
    );
    final onePanel = ApiConfig(
      id: 'panel',
      name: 'Panel',
      url: 'https://panel.invalid',
      apiKey: '',
    );
    expect(ClientModule.apps.forServer(null), ClientModule.servers);
    expect(ClientModule.apps.forServer(other), ClientModule.servers);
    expect(ClientModule.apps.forServer(onePanel), ClientModule.apps);
    expect(ClientModule.settings.forServer(null), ClientModule.settings);
    expect(ClientModule.settings.forServer(other), ClientModule.settings);
  });

  const pins = [ClientModule.apps, ClientModule.files];
  test('compact navigation retains the active module alongside both pins', () {
    expect(
      shellModulesForPanel(
        ApiConfig.onePanelType,
        pins,
        compact: true,
        activeModule: ClientModule.websites,
      ),
      [ClientModule.servers, ...pins, ClientModule.websites, ClientModule.settings],
    );
    expect(
      shellModulesForPanel(
        'other',
        pins,
        compact: true,
        activeModule: ClientModule.websites,
      ),
      [ClientModule.servers, ClientModule.settings],
    );
  });
  for (final (modifier, physicalKey) in [
    (LogicalKeyboardKey.control, LogicalKeyboardKey.controlLeft),
    (LogicalKeyboardKey.meta, LogicalKeyboardKey.metaLeft),
  ]) {
    testWidgets('desktop number shortcuts use ${modifier.keyLabel}',
        (tester) async {
      ClientModule? selected;
      await tester.pumpWidget(MaterialApp(
        home: DesktopModuleShortcuts(
          modifier: modifier,
          modules: const [ClientModule.servers, ClientModule.settings],
          onSelect: (module) => selected = module,
          child: const SizedBox.shrink(),
        ),
      ));
      await tester.pump();
      await tester.sendKeyDownEvent(physicalKey);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.sendKeyUpEvent(physicalKey);
      expect(selected, ClientModule.settings);
    });
  }
  for (final compact in [false, true]) {
    test('non-1Panel only exposes shared destinations (compact=$compact)', () {
      expect(
        shellModulesForPanel('other', pins, compact: compact),
        [ClientModule.servers, ClientModule.settings],
      );
      expect(
        shellModulesForPanel(ApiConfig.onePanelType, pins, compact: compact)
            .take(3),
        [ClientModule.servers, ...pins],
      );
    });
  }
}
