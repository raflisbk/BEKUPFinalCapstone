import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/logger.dart';
import '../home/home_screen.dart';
import '../explore/explore_screen.dart';
import '../guides/guides_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const String _tag = 'MainScreen';
  int _currentIndex = 0;

  final List<String> _tabNames = ['Home', 'Explore', 'Guides', 'Profile'];

  final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const GuidesScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    AppLogger.debug(_tag, 'Main screen initialized', {
      'initialTab': _tabNames[_currentIndex],
    });
  }

  @override
  void dispose() {
    AppLogger.debug(_tag, 'Disposing main screen resources');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.divider,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (_currentIndex != index) {
              AppLogger.action('User switched tab', {
                'from': _tabNames[_currentIndex],
                'to': _tabNames[index],
                'tabIndex': index,
              });
            }
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Guides',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
