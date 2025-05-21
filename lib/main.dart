import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const LeaffApp());
}

class LeaffApp extends StatefulWidget {
  const LeaffApp({super.key});

  @override
  State<LeaffApp> createState() => _LeaffAppState();
}

class _LeaffAppState extends State<LeaffApp> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    TransactionsScreen(),
    ChatScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leaff',
      theme: ThemeData(primarySwatch: Colors.green),
      home: Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              body: _screens[_selectedIndex],
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Actus'),
                  BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Dépenses'),
                  BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
                  BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Réglages'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 