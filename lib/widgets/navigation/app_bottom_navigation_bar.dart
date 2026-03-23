import 'package:flutter/material.dart';

class AppNavigationBarItem {
  const AppNavigationBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.enabled = true,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool enabled;
}

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.destinationKeys,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppNavigationBarItem> items;
  final List<GlobalKey>? destinationKeys;

  @override
  Widget build(BuildContext context) {
    final safeIndex = currentIndex.clamp(0, items.length - 1);
    final disabledColor = Theme.of(context)
        .colorScheme
        .onSurfaceVariant
        .withValues(alpha: 0.42);

    return NavigationBar(
      selectedIndex: safeIndex,
      onDestinationSelected: onTap,
      destinations: [
        for (var index = 0; index < items.length; index++)
          NavigationDestination(
            icon: Icon(
              items[index].icon,
              key: _destinationKey(index),
              color: items[index].enabled ? null : disabledColor,
            ),
            selectedIcon: Icon(
              items[index].selectedIcon,
              key: _destinationKey(index),
              color: items[index].enabled ? null : disabledColor,
            ),
            label: items[index].label,
          ),
      ],
    );
  }

  Key? _destinationKey(int index) {
    if (destinationKeys == null || destinationKeys!.length <= index) {
      return null;
    }
    return destinationKeys![index];
  }
}
