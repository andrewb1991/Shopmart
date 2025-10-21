import 'package:flutter/material.dart';
import 'inventory_screen.dart';
import 'add_product_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget currentScreen;

    if (_currentIndex == 0) {
      currentScreen = const InventoryScreen();
    } else if (_currentIndex == 1) {
      currentScreen = const AddProductScreen();
    } else {
      currentScreen = const SettingsScreen();
    }

    return Scaffold(
      body: currentScreen,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12.0,
        unselectedFontSize: 12.0,
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Magazzino',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Aggiungi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Impostazioni',
          ),
        ],
      ),
    );
  }
}
