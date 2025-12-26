import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/features/workout/providers/workout_provider.dart';
import 'package:reprise/features/profile/screens/settings_screen.dart';
import 'package:reprise/features/analytics/screens/exercise_analytics_screen.dart';
import 'package:reprise/features/measurements/screens/measurements_screen.dart';
import 'package:reprise/shared/models/workout.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: AppTextStyles.h2()),
        actions: [
          IconButton(
            icon: const Icon(Icons. settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children:  [
            // Profile Header
            CircleAvatar(
              radius:  60,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Icon(
                Icons.person,
                size: 60,
                color:  AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing. md),
            Text('Fitness Enthusiast', style: AppTextStyles. h2()),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Member since ${DateTime.now().year}',
              style: AppTextStyles.caption(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Menu Items
            _buildMenuItem(
              icon: Icons.bar_chart,
              title: 'Exercise Analytics',
              subtitle: 'Track progress per exercise',
              onTap:  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExerciseAnalyticsScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.straighten,
              title: 'Body Measurements',
              subtitle: 'Track your body measurements',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:  (context) => const MeasurementsScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.person,
              title: 'Personal Info',
              subtitle: 'Update your profile details',
              onTap: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile edit coming soon!'),
                    duration: Duration(milliseconds: 800),
                  ),
                );
              },
            ),
            _buildMenuItem(
              icon:  Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help with the app',
              onTap:  () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Support coming soon!'),
                    duration:  Duration(milliseconds: 800),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: AppTextStyles.h4()),
        subtitle: Text(subtitle, style: AppTextStyles.caption()),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}