import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/features/user/providers/user_provider.dart';
import 'package:reprise/features/profile/screens/settings_screen.dart';
import 'package:reprise/features/workout/providers/workout_provider.dart';
import 'package:reprise/shared/models/workout.dart';
import 'package:intl/intl.dart';
import 'package:reprise/features/profile/widgets/trainer_code_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
        title: Text('Profile', style: AppTextStyles.h2()),
        actions: [
          // Settings Icon
          IconButton(
            icon: const Icon(Icons.settings),
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
      body: Consumer2<UserProvider, WorkoutProvider>(
        builder: (context, userProvider, workoutProvider, child) {
          final user = userProvider.currentUser;
          
          if (user == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No user profile found'),
                ],
              ),
            );
          }

          final completedWorkouts = workoutProvider
              .getAllWorkouts()
              .where((w) => w.status == WorkoutStatus.completed)
              .toList();
          
          final totalWorkouts = completedWorkouts.length;
          final currentStreak = workoutProvider.getCurrentStreak();
          final totalPRs = workoutProvider.getTotalPRs();
          final totalVolume = completedWorkouts.fold<int>(
            0,
            (sum, w) => sum + w.totalVolume,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children:  [
                // Profile Info Card
                Card(
                  child: Padding(
                    padding:  const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary. withOpacity(0.2),
                          child: Text(
                            user.name.isNotEmpty 
                                ? user. name.substring(0, 1).toUpperCase()
                                : 'U',
                            style:  const TextStyle(
                              color: AppColors.primary,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          user.name,
                          style: AppTextStyles.h2(),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          user.email,
                          style: AppTextStyles.caption(),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        
                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: user. isTrainer
                                ? AppColors.secondary.withOpacity(0.2)
                                :  AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                user.isTrainer ? Icons.people :  Icons.person,
                                size: 16,
                                color: user.isTrainer
                                    ? AppColors.secondary
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                user.isTrainer ? 'Trainer Mode' : 'Personal Mode',
                                style: AppTextStyles. bodySmall(
                                  color: user.isTrainer
                                      ? AppColors.secondary
                                      : AppColors. primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

  

                        // Trainer Connection Info (for trainees)
                        if (!user.isTrainer && user. hasTrainer) ...[
                          const SizedBox(height:  AppSpacing.md),
                          const Divider(),
                          const SizedBox(height:  AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.fitness_center,
                                size:  20,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Training with ',
                                style: AppTextStyles.bodySmall(),
                              ),
                              Text(
                                user.trainerName ?? 'Unknown',
                                style: AppTextStyles. bodySmall(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing. lg),

                // Stats Grid
                

               

                // Achievements/Milestones - Collapsible
                Card(
                  child: ExpansionTile(
                    leading: const Icon(Icons.emoji_events, color: AppColors.warning),
                    title: Text('Milestones', style: AppTextStyles.h4()),
                    subtitle: Text(
                      '${_getAchievedCount(totalWorkouts, currentStreak, totalPRs, completedWorkouts)}/4 completed',
                      style: AppTextStyles.caption(),
                    ),
                    initiallyExpanded: false,
                    children: [
                      _buildMilestoneCard(
                        icon: Icons.emoji_events,
                        title:  'First Workout',
                        subtitle: completedWorkouts.isNotEmpty
                            ? DateFormat('MMM d, yyyy').format(
                                completedWorkouts.last.date,
                              )
                            :  'Not yet',
                        achieved: completedWorkouts.isNotEmpty,
                      ),
                      _buildMilestoneCard(
                        icon: Icons. military_tech,
                        title:  '10 Workouts',
                        subtitle: totalWorkouts >= 10
                            ? 'Achieved!'
                            : '$totalWorkouts/10 completed',
                        achieved: totalWorkouts >= 10,
                      ),
                      _buildMilestoneCard(
                        icon:  Icons.whatshot,
                        title: '7 Day Streak',
                        subtitle:  currentStreak >= 7
                            ? 'Achieved!'
                            : '$currentStreak/7 days',
                        achieved: currentStreak >= 7,
                      ),
                      _buildMilestoneCard(
                        icon: Icons.star,
                        title: 'First PR',
                        subtitle: totalPRs > 0
                            ? 'Achieved!'
                            : 'Set your first PR',
                        achieved: totalPRs > 0,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper to count achieved milestones
  int _getAchievedCount(int totalWorkouts, int currentStreak, int totalPRs, List<Workout> completedWorkouts) {
    int count = 0;
    if (completedWorkouts.isNotEmpty) count++;
    if (totalWorkouts >= 10) count++;
    if (currentStreak >= 7) count++;
    if (totalPRs > 0) count++;
    return count;
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing. sm),
              decoration: BoxDecoration(
                color: color. withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: AppSpacing. sm),
            Text(
              value,
              style: AppTextStyles.h3(color: color),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.caption(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool achieved,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing. sm),
        decoration: BoxDecoration(
          color: achieved
              ? AppColors.success.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          shape: BoxShape. circle,
        ),
        child: Icon(
          icon,
          color: achieved ? AppColors.success : Colors. grey,
        ),
      ),
      title: Text(title, style: AppTextStyles.h4()),
      subtitle: Text(subtitle, style: AppTextStyles.caption()),
      trailing: achieved
          ? const Icon(Icons.check_circle, color: AppColors.success)
          : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
    );
  }
}