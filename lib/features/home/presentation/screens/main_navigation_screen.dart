import 'package:flutter/material.dart';

import '../../../auth/domain/models/user_profile.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../category/presentation/screens/category_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final UserProfile user;
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    required this.user,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ProfileScreen(user: widget.user),
      CategoryScreen(user: widget.user),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      resizeToAvoidBottomInset: false,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF14141C),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 54,
            backgroundColor: Colors.transparent,
            indicatorColor: const Color(0xFF3B82F6).withValues(alpha: 0.22),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                );
              }
              return TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontWeight: FontWeight.normal,
                fontSize: 11.5,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Color(0xFF60A5FA), size: 22);
              }
              return IconThemeData(
                color: Colors.white.withValues(alpha: 0.5),
                size: 22,
              );
            }),
          ),
          child: NavigationBar(
            height: 54,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.account_circle_outlined),
                selectedIcon: Icon(Icons.account_circle),
                label: 'Profile',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_tree_outlined),
                selectedIcon: Icon(Icons.account_tree_rounded),
                label: 'Category',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
