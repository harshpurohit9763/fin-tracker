import 'package:flutter/material.dart';
import 'package:personal_finance/emi_list_sccreen.dart';
import 'package:personal_finance/expense_list.dart';
import 'package:personal_finance/manage_assets_screen.dart';
import 'package:personal_finance/income_screen.dart'; // Import IncomeScreen

import 'dashboard_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

      static const List<Widget> _widgetOptions = <Widget>[
      DashboardScreen(),
      ExpenseListScreen(),
      EmiListScreen(),
      ManageAssetsScreen(),
      IncomeScreen(), // Added IncomeScreen
    ];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'EMIs',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: 'Assets',
          ),
          NavigationDestination(
            icon: Icon(Icons.attach_money_outlined), // Choose an appropriate icon
            selectedIcon: Icon(Icons.attach_money),
            label: 'Income',
          ),
        ],
      ),
    );
  }
}
