import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/views/emi_list_sccreen.dart';
import 'package:personal_finance/views/expense_list.dart';
import 'package:personal_finance/views/manage_assets_screen.dart';
import 'package:personal_finance/views/income_screen.dart'; // Import IncomeScreen
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:personal_finance/widgets/glass_container.dart';

import 'dashboard_screen.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = ref.watch(accentColorProvider);

    List<_NavItem> navItems = [
      _NavItem(
        id: 0,
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Dash',
        screen: const DashboardScreen(),
      ),
      _NavItem(
        id: 1,
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        label: 'Exp',
        screen: const ExpenseListScreen(),
      ),
      _NavItem(
        id: 2,
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet,
        label: 'EMIs',
        screen: const EmiListScreen(),
      ),
      _NavItem(
        id: 3,
        icon: Icons.account_balance_outlined,
        selectedIcon: Icons.account_balance,
        label: 'Asset',
        screen: const ManageAssetsScreen(),
      ),
      _NavItem(
        id: 4,
        icon: Icons.attach_money_outlined,
        selectedIcon: Icons.attach_money,
        label: 'Inc',
        screen: const IncomeScreen(),
      ),
    ];

    return Scaffold(
      body: Center(child: navItems[_selectedIndex].screen),
      extendBody: true, // Allows body to go behind the floating nav bar
      bottomNavigationBar: GlassContainer(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        blur: 20,
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: navItems.map((item) {
            final isSelected = item.id == _selectedIndex;
            return GestureDetector(
              onTap: () => _onItemTapped(item.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final int id;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget screen;

  _NavItem({
    required this.id,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.screen,
  });
}
