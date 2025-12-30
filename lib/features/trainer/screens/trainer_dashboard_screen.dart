import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/features/user/providers/user_provider.dart';
import 'package:reprise/features/workout/providers/workout_provider.dart';

class TrainerDashboardScreen extends StatelessWidget {
  const TrainerDashboardScreen({super. key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trainer Dashboard', style: AppTextStyles.h2()),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.currentUser;
          
          if (user == null || !user.isTrainer) {
            return Center(
              child: Text('Not in trainer mode', style: AppTextStyles. body()),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trainer Info Card
                _buildTrainerInfoCard(user),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Quick Stats
                Text('Quick Stats', style: AppTextStyles.h3()),
                const SizedBox(height: AppSpacing.md),
                _buildQuickStats(user),
                
                const SizedBox(height:  AppSpacing.lg),
                
                // Trainees List
                Text('My Trainees', style: AppTextStyles.h3()),
                const SizedBox(height: AppSpacing.md),
                
                if (user.traineeIds.isEmpty)
                  _buildEmptyTraineesState()
                else
                  _buildTraineesList(user. traineeIds),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton. extended(
        onPressed: () {
          // TODO: Add trainee functionality
          ScaffoldMessenger. of(context).showSnackBar(
            const SnackBar(
              content: Text('Add trainee feature coming soon!'),
            ),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Trainee'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  Widget _buildTrainerInfoCard(dynamic user) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people,
                    size: 40,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment. start,
                    children: [
                      Text(user.name, style: AppTextStyles.h2()),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Trainer Mode',
                        style: AppTextStyles.caption(color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.key, size: 20, color: AppColors.textSecondaryLight),
                const SizedBox(width: AppSpacing.sm),
                Text('Trainer Code: ', style: AppTextStyles.bodySmall()),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors. secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing. radiusSmall),
                  ),
                  child: Text(
                    user.trainerCode ??  'N/A',
                    style:  AppTextStyles.body(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Share this code with your trainees so they can connect to you',
              style: AppTextStyles. caption(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(dynamic user) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.people,
            label: 'Trainees',
            value: '${user.traineeIds.length}',
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width:  AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            icon: Icons.fitness_center,
            label: 'Templates',
            value: '0', // TODO: Add template count
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding:  const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: AppTextStyles.h2(color: color),
            ),
            Text(
              label,
              style: AppTextStyles.caption(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTraineesState() {
    return Card(
      child:  Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors. textSecondaryLight. withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Trainees Yet',
              style: AppTextStyles.h3(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Share your trainer code with people who want to train with you',
              style: AppTextStyles.caption(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraineesList(List<String> traineeIds) {
    return Column(
      children: traineeIds.map((traineeId) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:  AppColors.primary.withOpacity(0.2),
              child: const Icon(Icons.person, color: AppColors. primary),
            ),
            title: Text('Trainee $traineeId', style: AppTextStyles.h4()),
            subtitle: Text('Last active: Today', style: AppTextStyles.caption()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to trainee detail
            },
          ),
        );
      }).toList(),
    );
  }
}