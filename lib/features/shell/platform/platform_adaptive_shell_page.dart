import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/features/files/files_page.dart';
import 'package:onepanelapp_app/features/security/security_verification_page.dart';
import 'package:onepanelapp_app/features/server/server_list_page.dart';
import 'package:onepanelapp_app/features/shell/platform/macos/macos_appearance_channel.dart';
import 'package:onepanelapp_app/features/shell/platform/macos/macos_appearance_context_model.dart';
import 'package:onepanelapp_app/pages/settings/settings_page.dart';
import 'package:onepanelapp_app/widgets/navigation/app_bottom_navigation_bar.dart';

const double _kTabletBreakpoint = 600;
// Material 3 large-screen guidance commonly treats >= 960dp as expanded width.
const double _kAndroidLargeScreenBreakpoint = 960;
const double _kMacosNavRailBorderAlpha = 0.45;
const double _kWindowsRailGroupAlignment = -0.95;
const double _kCupertinoPadSidebarIconSize = 20;

class PlatformAdaptiveShellPage extends StatefulWidget {
  const PlatformAdaptiveShellPage({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  State<PlatformAdaptiveShellPage> createState() =>
      _PlatformAdaptiveShellPageState();
}

class _PlatformAdaptiveShellPageState extends State<PlatformAdaptiveShellPage> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, math.max(0, _pages.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = shortestSide >= _kTabletBreakpoint;
    final isAndroidLargeScreen = width >= _kAndroidLargeScreenBreakpoint;
    final isAndroid = _isPlatform(TargetPlatform.android);
    final isIos = _isPlatform(TargetPlatform.iOS);
    // iPadOS uses iOS target platform in Flutter; tablet form factor splits it.
    final isIpad = isIos && isTablet;

    if (kIsWeb) {
      if (isTablet) {
        return _TabletShellScaffold(
          index: _index,
          pages: pages,
          isAndroidTablet: false,
          onDestinationSelected: _onDestinationSelected,
        );
      }

      return Scaffold(
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: AppBottomNavigationBar(
          currentIndex: _index,
          onTap: _onDestinationSelected,
        ),
      );
    }

    if (_isPlatform(TargetPlatform.macOS)) {
      return _MacosShellScaffold(
        index: _index,
        pages: pages,
        onDestinationSelected: _onDestinationSelected,
      );
    }

    if (_isPlatform(TargetPlatform.windows)) {
      return _WindowsShellScaffold(
        index: _index,
        pages: pages,
        onDestinationSelected: _onDestinationSelected,
      );
    }

    if (isIpad) {
      return _IpadShellScaffold(
        index: _index,
        pages: pages,
        onDestinationSelected: _onDestinationSelected,
      );
    }

    if (isAndroid && isTablet) {
      if (isAndroidLargeScreen) {
        return _AndroidLargeScreenShellScaffold(
          index: _index,
          pages: pages,
          onDestinationSelected: _onDestinationSelected,
        );
      }
      return _AndroidPadShellScaffold(
        index: _index,
        pages: pages,
        onDestinationSelected: _onDestinationSelected,
      );
    }

    if (isTablet) {
      return _TabletShellScaffold(
        index: _index,
        pages: pages,
        isAndroidTablet: false,
        onDestinationSelected: _onDestinationSelected,
      );
    }

    if (isIos) {
      return _IosPhoneShellScaffold(
        index: _index,
        pages: pages,
        onDestinationSelected: _onDestinationSelected,
      );
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _index,
        onTap: _onDestinationSelected,
      ),
    );
  }

  bool _isPlatform(TargetPlatform platform) {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == platform;
  }

  void _onDestinationSelected(int value) {
    setState(() {
      _index = value;
    });
  }

  List<Widget> get _pages => const <Widget>[
        ServerListPage(),
        FilesPage(),
        SecurityVerificationPage(),
        SettingsPage(),
      ];
}

class _MacosShellScaffold extends StatelessWidget {
  const _MacosShellScaffold({
    required this.index,
    required this.pages,
    required this.onDestinationSelected,
  });

  final int index;
  final List<Widget> pages;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MacosAppearanceContextModel>(
      future: MacosAppearanceChannel.getAppearanceContext(),
      builder: (context, snapshot) {
        final appearance = snapshot.data ?? MacosAppearanceContextModel.fallback;
        return _MacosShellView(
          index: index,
          pages: pages,
          onDestinationSelected: onDestinationSelected,
          appearance: appearance,
        );
      },
    );
  }
}

class _MacosShellView extends StatelessWidget {
  const _MacosShellView({
    required this.index,
    required this.pages,
    required this.onDestinationSelected,
    required this.appearance,
  });

  final int index;
  final List<Widget> pages;
  final ValueChanged<int> onDestinationSelected;
  final MacosAppearanceContextModel appearance;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceTransparency = appearance.reduceTransparencyEnabled;
    final sidebarAlpha = (reduceTransparency
        ? 1.0
        : appearance.preferredSidebarAlpha.clamp(0.25, 1.0))
        .toDouble();
    final contentAlpha = (reduceTransparency
        ? 1.0
        : appearance.preferredContentAlpha.clamp(0.3, 1.0))
        .toDouble();
    final blurSigma = (reduceTransparency
        ? 0.0
        : appearance.preferredGlassBlurSigma.clamp(0, 40))
        .toDouble();
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.surface,
              scheme.surfaceContainerLowest,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                  ),
                  child: Container(
                    width: 88,
                    decoration: BoxDecoration(
                      // withValues is Flutter's newer API to set alpha/channel values.
                      color: scheme.surface.withValues(
                        alpha: sidebarAlpha,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(
                          alpha: _kMacosNavRailBorderAlpha,
                        ),
                      ),
                    ),
                    child: NavigationRail(
                      selectedIndex: index,
                      onDestinationSelected: onDestinationSelected,
                      labelType: NavigationRailLabelType.none,
                      useIndicator: false,
                      minWidth: 72,
                      minExtendedWidth: 88,
                      destinations: _destinations(context),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow.withValues(
                        alpha: contentAlpha,
                      ),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: IndexedStack(index: index, children: pages),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowsShellScaffold extends StatelessWidget {
  const _WindowsShellScaffold({
    required this.index,
    required this.pages,
    required this.onDestinationSelected,
  });

  final int index;
  final List<Widget> pages;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              border: Border(
                right: BorderSide(color: scheme.outlineVariant),
              ),
            ),
            child: NavigationRail(
              selectedIndex: index,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              extended: true,
              groupAlignment: _kWindowsRailGroupAlignment,
              minExtendedWidth: 280,
              destinations: _destinations(context),
            ),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(color: scheme.surface),
              child: IndexedStack(index: index, children: pages),
            ),
          ),
        ],
      ),
    );
  }
}

class _IpadShellScaffold extends StatelessWidget {
  const _IpadShellScaffold({
    required this.index,
    required this.pages,
    required this.onDestinationSelected,
  });

  final int index;
  final List<Widget> pages;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Row(
          children: [
            Container(
              width: 124,
              color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
              child: CupertinoTheme(
                data: CupertinoTheme.of(context).copyWith(
                  primaryColor: CupertinoColors.activeBlue.resolveFrom(context),
                ),
                child: _CupertinoPadSidebar(
                  selectedIndex: index,
                  onTap: onDestinationSelected,
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: IndexedStack(index: index, children: pages)),
          ],
        ),
      ),
    );
  }
}

class _AndroidPadShellScaffold extends StatelessWidget {
  const _AndroidPadShellScaffold({
    required this.index,
    required this.pages,
    required this.onDestinationSelected,
  });

  final int index;
  final List<Widget> pages;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: onDestinationSelected,
            extended: true,
            minExtendedWidth: 220,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            backgroundColor: scheme.surfaceContainerLowest,
            destinations: _destinations(context),
          ),
          Expanded(
            child: IndexedStack(index: index, children: pages),
          ),
        ],
      ),
    );
  }
}

class _TabletShellScaffold extends StatelessWidget {
  const _TabletShellScaffold({
    required this.index,
    required this.pages,
    required this.isAndroidTablet,
    required this.onDestinationSelected,
  });

  final int index;
  final List<Widget> pages;
  final bool isAndroidTablet;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: onDestinationSelected,
            extended: isAndroidTablet,
            destinations: _destinations(context),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(index: index, children: pages),
          ),
        ],
      ),
    );
  }
}

class _AndroidLargeScreenShellScaffold extends StatelessWidget {
  const _AndroidLargeScreenShellScaffold({
    required this.index,
    required this.pages,
    required this.onDestinationSelected,
  });

  final int index;
  final List<Widget> pages;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final activeMeta = _navigationMetaForIndex(context, index);
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: onDestinationSelected,
            extended: true,
            minExtendedWidth: 220,
            destinations: _destinations(context),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 4,
            child: IndexedStack(index: index, children: pages),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(color: scheme.surfaceContainerLowest),
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      l10n.appName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Card.filled(
                      child: ListTile(
                        leading: const Icon(Icons.dashboard_customize_outlined),
                        title: Text(activeMeta.title),
                        subtitle: Text(activeMeta.subtitle),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.tips_and_updates_outlined),
                        title: Text(l10n.commonComingSoon),
                        subtitle: Text(activeMeta.subtitle),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IosPhoneShellScaffold extends StatelessWidget {
  const _IosPhoneShellScaffold({
    required this.index,
    required this.pages,
    required this.onDestinationSelected,
  });

  final int index;
  final List<Widget> pages;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: index,
        onTap: onDestinationSelected,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.desktopcomputer),
            label: l10n.navServer,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.folder),
            label: l10n.navFiles,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.shield),
            label: l10n.navSecurity,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.gear),
            label: l10n.navSettings,
          ),
        ],
      ),
      tabBuilder: (context, tabIndex) => pages[tabIndex],
    );
  }
}

class _CupertinoPadSidebar extends StatelessWidget {
  const _CupertinoPadSidebar({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (CupertinoIcons.desktopcomputer, l10n.navServer),
      (CupertinoIcons.folder, l10n.navFiles),
      (CupertinoIcons.shield, l10n.navSecurity),
      (CupertinoIcons.gear, l10n.navSettings),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      itemCount: items.length,
      itemBuilder: (context, idx) {
        final isSelected = idx == selectedIndex;
        final item = items[idx];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: isSelected
                ? CupertinoColors.systemGrey4.resolveFrom(context)
                : CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
            onPressed: () => onTap(idx),
            child: Row(
              children: [
                Icon(item.$1, size: _kCupertinoPadSidebarIconSize),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.$2,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavigationMeta {
  const _NavigationMeta({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

_NavigationMeta _navigationMetaForIndex(BuildContext context, int pageIndex) {
  final l10n = context.l10n;
  switch (pageIndex) {
    case 0:
      return _NavigationMeta(
        title: l10n.navServer,
        subtitle: l10n.serverPageTitle,
      );
    case 1:
      return _NavigationMeta(
        title: l10n.navFiles,
        subtitle: l10n.filesPageTitle,
      );
    case 2:
      return _NavigationMeta(
        title: l10n.navSecurity,
        subtitle: l10n.securityPageTitle,
      );
    default:
      return _NavigationMeta(
        title: l10n.navSettings,
        subtitle: l10n.settingsPageTitle,
      );
  }
}

List<NavigationRailDestination> _destinations(BuildContext context) {
  final l10n = context.l10n;
  return [
    NavigationRailDestination(
      icon: const Icon(Icons.dns_outlined),
      selectedIcon: const Icon(Icons.dns),
      label: Text(l10n.navServer),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.folder_outlined),
      selectedIcon: const Icon(Icons.folder),
      label: Text(l10n.navFiles),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.verified_user_outlined),
      selectedIcon: const Icon(Icons.verified_user),
      label: Text(l10n.navSecurity),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.settings_outlined),
      selectedIcon: const Icon(Icons.settings),
      label: Text(l10n.navSettings),
    ),
  ];
}
