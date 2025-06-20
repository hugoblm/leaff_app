import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'expenses_screen.dart';
import 'community_screen.dart';
import 'settings_screen.dart';
import 'scan_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    ExpensesScreen(),
    const ScanScreen(),
    const CommunityScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.search_rounded,
                    index: 0,
                    label: 'Explore',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.receipt_long_rounded,
                    index: 1,
                    label: 'Expenses',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.bar_chart_rounded,
                    index: 2,
                    label: 'Wealth',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.chat_outlined,
                    index: 3,
                    label: 'Community',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.account_circle_rounded,
                    index: 4,
                    label: 'Profile',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF366444)
                  : const Color(0xFF212529),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF366444)
                    : const Color(0xFF212529),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
