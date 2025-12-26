import 'package:flutter/material.dart';
import 'package:reprise/features/dashboard/screens/dashboard_screen.dart';
import 'package:reprise/features/calendar/screens/calendar_screen.dart';
import 'package:reprise/features/workout/screens/workout_screen.dart';
import 'package:reprise/features/profile/screens/profile_screen.dart';

class AppRouter {
  static const String dashboard = '/';
  static const String calendar = '/calendar';
  static const String workout = '/workout';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case dashboard: 
        return MaterialPageRoute(builder:  (_) => const DashboardScreen());
      case calendar:
        return MaterialPageRoute(builder: (_) => const CalendarScreen());
      case workout:
        return MaterialPageRoute(builder: (_) => const WorkoutScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}