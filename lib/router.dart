import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/camera_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/history_screen.dart';

// Private navigators
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        // Camera Screen
        GoRoute(
          path: '/',
          builder: (context, state) => const CameraScreen(),
        ),
        // Inventory Screen, now accepts an optional search query
        GoRoute(
          path: '/inventory',
          builder: (context, state) {
            // Extract the search query from the route parameters.
            final query = state.uri.queryParameters['q'];
            return InventoryScreen(searchQuery: query);
          },
        ),
        // History Screen
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
      ],
    ),
  ],
);

/// A scaffold with a bottom navigation bar.
class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNavBar({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int idx) => _onItemTapped(idx, context),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Scan'),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/inventory')) return 1;
    if (location.startsWith('/history')) return 2;
    return 0; // Default to Camera/Scan screen
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        // When navigating to inventory from the nav bar, there is no search query.
        context.go('/inventory');
        break;
      case 2:
        context.go('/history');
        break;
    }
  }
}
