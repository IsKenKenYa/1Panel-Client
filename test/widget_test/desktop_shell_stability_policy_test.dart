import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('desktop theme surfaces are not transparent', () async {
    final source = await File(
      'lib/core/theme/app_theme.dart',
    ).readAsString();

    expect(
      source.contains('scaffoldBackgroundColor: scheme.surface'),
      isTrue,
    );
    expect(source.contains('backgroundColor: scheme.surface'), isTrue);
    expect(
      source.contains('Colors.transparent'),
      isFalse,
      reason: 'desktop host surfaces must not be transparent',
    );
  });

  test('desktop native shells honor initialModuleId route arguments', () async {
    final uiRouteHost = await File(
      'lib/ui/routing/ui_route_host.dart',
    ).readAsString();
    final macosShell = await File(
      'lib/ui/desktop/macos/app/macos_shell_content_page.dart',
    ).readAsString();
    final windowsShell = await File(
      'lib/ui/desktop/windows/app/windows_shell_content_page.dart',
    ).readAsString();

    expect(uiRouteHost.contains('initialModuleId: initialModuleId'), isTrue);
    expect(macosShell.contains('this.initialModuleId,'), isTrue);
    expect(windowsShell.contains('this.initialModuleId,'), isTrue);
    expect(macosShell.contains('clientModuleFromId(widget.initialModuleId)'),
        isTrue);
    expect(
      windowsShell.contains('clientModuleFromId(widget.initialModuleId)'),
      isTrue,
    );
  });

  test('desktop shell routes shell modules back into the shell host', () async {
    final shellNavigation = await File(
      'lib/features/shell/shell_navigation.dart',
    ).readAsString();
    final serverDetail = await File(
      'lib/features/server/server_detail_page.dart',
    ).readAsString();
    final serverSwitcher = await File(
      'lib/features/shell/widgets/server_switcher_action.dart',
    ).readAsString();
    final noServerSelected = await File(
      'lib/features/shell/widgets/no_server_selected_state.dart',
    ).readAsString();

    expect(shellNavigation.contains('pushReplacementNamed('), isTrue);
    expect(shellNavigation.contains("'module': module.storageId"), isTrue);
    expect(serverDetail.contains('openRouteRespectingShell(context, route);'),
        isTrue);
    expect(serverSwitcher.contains('openRouteRespectingShell('), isTrue);
    expect(
      noServerSelected.contains(
        'openRouteRespectingShell(context, AppRoutes.server)',
      ),
      isTrue,
    );
  });

  test('high-risk desktop item builders use snapshot wrapper variables',
      () async {
    final filesItem = await File(
      'lib/features/files/files_page/files_page_item_part.dart',
    ).readAsString();
    final websitesList = await File(
      'lib/features/websites/pages/website_list_page_body.dart',
    ).readAsString();

    expect(filesItem.contains('final selectableContent = content;'), isTrue);
    expect(filesItem.contains('final draggableContent = content;'), isTrue);
    expect(filesItem.contains('child: selectableContent,'), isTrue);
    expect(filesItem.contains('child: draggableContent,'), isTrue);

    expect(
        websitesList.contains('final desktopCardContent = content;'), isTrue);
    expect(websitesList.contains('child: desktopCardContent,'), isTrue);
  });
}
