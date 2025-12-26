import 'package:flutter/material.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/features/dashboard/screens/dashboard_screen.dart';
import 'package:reprise/features/calendar/screens/calendar_screen.dart';
import 'package:reprise/features/workout/screens/workout_list_screen.dart';
import 'package:reprise/features/profile/screens/profile_screen.dart';
import 'package:reprise/features/workout/widgets/active_workout_bar.dart';  // ✅ ADD THIS

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const CalendarScreen(),
    const WorkoutListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  _screens[_currentIndex],
      bottomNavigationBar:  Column(  // ✅ CHANGED:  Wrap in Column
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ ADD THIS: Active workout bar
          const ActiveWorkoutBar(),
          
          // Your existing bottom navigation
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor:  AppColors.textSecondaryLight,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon:  Icon(Icons.calendar_today),
                label: 'Calendar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.fitness_center_outlined),
                activeIcon:  Icon(Icons.fitness_center),
                label: 'Workout',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}