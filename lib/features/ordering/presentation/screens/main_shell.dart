import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/ordering_controller.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'menu_screen.dart';
import 'order_history_screen.dart';
import 'profile_screen.dart';

/// The app's persistent bottom navigation. Each tab keeps its own Scaffold
/// (so Cart can still show its own sticky checkout footer above this bar) —
/// only the outer tab switching and the bottom nav bar itself live here.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tabIndex = 0;
  final Set<int> _visitedTabs = {0};

  static const _menuTabIndex = 1;

  void _selectTab(int index) {
    setState(() {
      _tabIndex = index;
      _visitedTabs.add(index);
    });
  }

  static const _tabs = [
    (label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home),
    (label: 'Menu', icon: Icons.local_cafe_outlined, activeIcon: Icons.local_cafe),
    (label: 'Cart', icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag),
    (label: 'Orders', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long),
    (label: 'Profile', icon: Icons.person_outline, activeIcon: Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    // Keep the tab subtree independent from frequent ordering-controller
    // notifications (cart changes, realtime updates, background startup).
    // Only the small navigation bar needs to react to the cart count.
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _visitedTabs.contains(0)
              ? HomeScreen(onExploreMenu: () => _selectTab(_menuTabIndex))
              : const SizedBox.shrink(),
          _visitedTabs.contains(1)
              ? const MenuScreen()
              : const SizedBox.shrink(),
          _visitedTabs.contains(2)
              ? const CartScreen()
              : const SizedBox.shrink(),
          _visitedTabs.contains(3)
              ? const OrderHistoryScreen()
              : const SizedBox.shrink(),
          _visitedTabs.contains(4)
              ? const ProfileScreen()
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: Selector<OrderingController, int>(
        selector: (_, controller) => controller.cartCount,
        builder: (context, cartCount, _) => NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: _selectTab,
          destinations: [
            for (final tab in _tabs)
              NavigationDestination(
                icon: tab.label == 'Cart' && cartCount > 0
                    ? Badge(
                        label: Text('$cartCount'),
                        child: Icon(tab.icon),
                      )
                    : Icon(tab.icon),
                selectedIcon: Icon(tab.activeIcon),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }
}
