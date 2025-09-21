import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavShell extends StatelessWidget {
  final Widget child;
  const BottomNavShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(label: 'Training', icon: Icons.fitness_center, route: '/training'),
    _TabItem(label: 'Diet',     icon: Icons.restaurant,      route: '/diet'),
    _TabItem(label: 'Social',   icon: Icons.groups,          route: '/social'),
  ];

  int _indexForLocation(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/diet')) return 1;
    if (loc.startsWith('/social')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _indexForLocation(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) {
          final dest = _tabs[i];
          context.go(dest.route);
        },
        destinations: _tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final String route;
  const _TabItem({required this.label, required this.icon, required this.route});
}
