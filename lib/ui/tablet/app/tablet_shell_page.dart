import 'package:flutter/material.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/widgets/adaptive_shell_navigation_widget.dart';
import 'package:onepanel_client/ui/routing/ui_target.dart';

class TabletShellPage extends StatelessWidget {
  const TabletShellPage({
    super.key,
    required this.tabletKind,
    required this.modules,
    required this.selectedIndex,
    required this.hasServer,
    required this.onSelect,
    required this.body,
  });

  final TabletKind tabletKind;
  final List<ClientModule> modules;
  final int selectedIndex;
  final bool hasServer;
  final ValueChanged<ClientModule> onSelect;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final spec = AdaptiveLayoutSpec.of(context);
    final railTheme = Theme.of(context);
    final isIpad = tabletKind == TabletKind.ipad;
    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            right: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, isIpad ? 20 : 16, 8, 16),
              child: NavigationRail(
                scrollable: true,
                minWidth: isIpad ? 88 : 96,
                minExtendedWidth: isIpad ? 220 : 236,
                groupAlignment: -0.92,
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) => onSelect(modules[index]),
                labelType: modules.length > 8
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                useIndicator: true,
                indicatorColor: railTheme.colorScheme.primaryContainer,
                destinations: shellRailDestinations(
                  context,
                  modules,
                  hasServer: hasServer,
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: SafeArea(
              bottom: false,
              child: AdaptiveWidthContainer(
                maxWidth: spec.contentMaxWidth,
                child: body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
