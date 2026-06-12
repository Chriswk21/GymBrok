import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'exercises_screen.dart';
import 'history_screen.dart';
import 'weight_tracker_screen.dart';
import '../widgets/rest_timer_banner.dart';
import '../theme/app_theme.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ExercisesScreen(),
    HistoryScreen(),
    WeightTrackerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Floating Rest Timer Banner (shows only when active)
          const RestTimerBanner(),
          BottomNavigationBar(
            currentIndex: _selectedIndex,
            type: BottomNavigationBarType.fixed, // Ensure it fits 4 tabs nicely
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard, color: AppTheme.primary),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.fitness_center_outlined),
                activeIcon: Icon(Icons.fitness_center, color: AppTheme.primary),
                label: 'Exercises',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history, color: AppTheme.primary),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.monitor_weight_outlined),
                activeIcon: Icon(Icons.monitor_weight, color: AppTheme.primary),
                label: 'Weight',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
