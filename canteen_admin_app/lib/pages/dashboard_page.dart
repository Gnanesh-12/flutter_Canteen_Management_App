import 'package:canteen_admin_app/pages/live_orders_view.dart';
import 'package:canteen_admin_app/pages/menu_management_view.dart';
import 'package:canteen_admin_app/pages/settings_view.dart'; // Import the new settings view
import 'package:canteen_admin_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  // Add the SettingsView to the list of pages
  static const List<Widget> _pages = <Widget>[
    LiveOrdersView(),
    MenuManagementView(),
    SettingsView(), // New page
  ];

  // A list of titles corresponding to the pages
  static const List<String> _pageTitles = <String>[
    'Live Orders',
    'Menu Management',
    'Canteen Settings', // New title
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]), // Use the dynamic title
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Live Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          // Add the new item to the navigation bar
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF8A1038),
        onTap: _onItemTapped,
      ),
    );
  }
}
