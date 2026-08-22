import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'it_home_screen.dart';
import 'it_support_screen.dart';
import 'it_system_screen.dart';
import 'it_settings_screen.dart';

class ItMainScreen extends StatefulWidget {
  const ItMainScreen({super.key});

  @override
  State<ItMainScreen> createState() => _ItMainScreenState();
}

class _ItMainScreenState extends State<ItMainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final screens = [
      ItHomeScreen(onViewAllTickets: () => _onItemTapped(1)),
      ItSupportScreen(onBack: () => _onItemTapped(0)),
      ItSystemScreen(onBack: () => _onItemTapped(0)),
      ItSettingsScreen(onBack: () => _onItemTapped(0)),
    ];

    return Scaffold(
      backgroundColor: AppThemeColors.background,
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppThemeColors.primary,
        unselectedItemColor: AppThemeColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.help_outline_rounded), label: 'Support'),
          BottomNavigationBarItem(icon: Icon(Icons.dns_outlined), label: 'System'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}