import 'package:flutter/material.dart';
import '../widgets/navigation/app_drawer.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: child,
    );
  }
}
