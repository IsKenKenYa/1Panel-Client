import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/features/files/files_page.dart';
import 'package:onepanelapp_app/features/security/security_verification_page.dart';
import 'package:onepanelapp_app/features/server/server_list_page.dart';
import 'package:onepanelapp_app/pages/settings/settings_page.dart';
import 'package:onepanelapp_app/widgets/navigation/app_bottom_navigation_bar.dart';

const double _kTabletBreakpoint = 600;
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
  static const List<Widget> _pages = <Widget>[
    ServerListPage(),
    FilesPage(),
    SecurityVerificationPage(),
    SettingsPage(),
  ];

  late int _index;

  @override
  void initState() {
    super.initState();
    final maxIndex = _pages.length - 1;
    _index = widget.initialIndex.clamp(0, maxIndex);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = _isTabletLayout(context);
    final isAndroid = _isPlatform(TargetPlatform.android);
    final pages = _pages;

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

    if (_isMacosPlatform) {
      return _MacosShellScaffold(
        index: _index,
        pages: pages,
        onDestinationSelected: _onDestinationSelected,
      );
    }

    if (_isWindowsPlatform) {
      return _WindowsShellScaffold(
        index: _index,
        pages: pages,
        onDestinationSelected: _onDestinationSelected,
      );
    }

    if (isTablet) {
      return _TabletShellScaffold(
        index: _index,
        pages: pages,
        isAndroidTablet: isAndroid && isTablet,
        onDestinationSelected: _onDestinationSelected,
      );
    }

    if (_isIosPlatform) {
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

  bool get _isMacosPlatform {
    return _isPlatform(TargetPlatform.macOS);
  }

  bool get _isWindowsPlatform {
    return _isPlatform(TargetPlatform.windows);
  }

  bool get _isIosPlatform {
    return _isPlatform(TargetPlatform.iOS);
  }

  bool _isPlatform(TargetPlatform platform) {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == platform;
  }

  bool _isTabletLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= _kTabletBreakpoint;
  }

  void _onDestinationSelected(int value) {
    setState(() {
      _index = value;
    });
  }
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
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.none,
            useIndicator: false,
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
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            extended: true,
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
