import 'package:flutter/material.dart';
import 'dart:ui';
import 'home_with_tabs_screen.dart';
import 'saved_recipes_screen.dart';
import 'add_product_screen.dart';
import 'shopping_list_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onNavItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          HomeWithTabsScreen(), // 0: In casa (con tab "Tutti" e "In scadenza")
          SavedRecipesScreen(), // 1: Ricette salvate
          AddProductScreen(), // 2: Aggiungi (centrale)
          ShoppingListScreen(), // 3: Lista spesa
          SettingsScreen(), // 4: Impostazioni
        ],
      ),
      extendBody: true,
      bottomNavigationBar: _buildLiquidGlassBottomBar(),
    );
  }

  Widget _buildLiquidGlassBottomBar() {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 20),
      height: 85,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Barra di navigazione
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: -5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.8),
                          Colors.white.withOpacity(0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Pulsante 1: In casa
                        _buildNavItem(
                          icon: Icons.kitchen_outlined,
                          activeIcon: Icons.kitchen,
                          label: 'In casa',
                          index: 0,
                        ),
                        // Pulsante 2: Ricette
                        _buildNavItem(
                          icon: Icons.restaurant_outlined,
                          activeIcon: Icons.restaurant,
                          label: 'Ricette',
                          index: 1,
                        ),
                        // Spazio per il pulsante centrale
                        const SizedBox(width: 70),
                        // Pulsante 4: Lista spesa (placeholder - puoi cambiarlo)
                        _buildNavItem(
                          icon: Icons.shopping_cart_outlined,
                          activeIcon: Icons.shopping_cart,
                          label: 'Spesa',
                          index: 3,
                        ),
                        // Pulsante 5: Impostazioni
                        _buildNavItem(
                          icon: Icons.settings_outlined,
                          activeIcon: Icons.settings,
                          label: 'Altro',
                          index: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Pulsante centrale elevato (sopra la barra)
          Positioned(
            left: 0,
            right: 0,
            top: 10,
            child: Center(
              child: _buildCenterButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _onNavItemTapped(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? Colors.blue[700] : Colors.grey[600],
                  size: 26,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.blue[700] : Colors.grey[600],
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    final isSelected = _currentIndex == 2;
    return GestureDetector(
      onTap: () => _onNavItemTapped(2),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [
                    Colors.blue[400]!,
                    Colors.blue[700]!,
                  ]
                : [
                    Colors.blue[300]!,
                    Colors.blue[600]!,
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
        ),
        child: Icon(
          isSelected ? Icons.add_circle : Icons.add_circle_outline,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
