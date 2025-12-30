import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/features/workout/providers/assigned_workout_provider.dart';
import 'package:reprise/shared/models/assigned_workout.dart';

class AssignedWorkoutsListScreen extends StatelessWidget {
  const AssignedWorkoutsListScreen({super. key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Workouts'),
      ),
      body: Consumer<AssignedWorkoutProvider>(
        builder: (context, assignedProvider, child) {
          if (assignedProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final assignedWorkouts = assignedProvider.assignedWorkouts;

          if (assignedWorkouts.isEmpty) {
            return Center(
              child:  Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 80,
                      color: AppColors.textSecondaryLight. withOpacity(0.5),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No Assigned Workouts',
                      style: AppTextStyles.h2(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Your trainer hasn\'t assigned any workouts yet',
                      style: AppTextStyles.body(color: AppColors.textSecondaryLight),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Separate by type
          final soloWorkouts = assignedWorkouts
              .where((w) => w.isSoloWorkout && w.status == AssignedWorkoutStatus. pending)
              .toList();
          final liveSessions = assignedWorkouts
              .where((w) => w.isTrainerLed && w.status == AssignedWorkoutStatus.pending)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Solo Workouts
              if (soloWorkouts. isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.person, color: AppColors.primary, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Solo Workouts (${soloWorkouts.length})', style: AppTextStyles.h3()),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ...soloWorkouts.map((workout) => _buildWorkoutCard(context, workout, assignedProvider)),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Live Sessions
              if (liveSessions.isNotEmpty) ...[
                Row(
                  children:  [
                    const Icon(Icons.people, color: AppColors. secondary, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Live Sessions (${liveSessions.length})', style: AppTextStyles.h3()),
                  ],
                ),
                const SizedBox(height:  AppSpacing.md),
                ...liveSessions.map((workout) => _buildWorkoutCard(context, workout, assignedProvider)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, AssignedWorkout workout, AssignedWorkoutProvider provider) {
    return Card(
      margin: const EdgeInsets. only(bottom: AppSpacing. md),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets. all(8),
          decoration:  BoxDecoration(
            color:  workout.isSoloWorkout
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            workout.isSoloWorkout ? Icons.person :  Icons.people,
            color: workout.isSoloWorkout ? AppColors.primary : AppColors.secondary,
          ),
        ),
        title: Text(workout.workoutName, style: AppTextStyles.h4()),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Due:  ${DateFormat('EEEE, MMM d, yyyy').format(workout.dueDate)}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: workout.isSoloWorkout
                        ? AppColors.primary. withOpacity(0.1)
                        : AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    workout.isSoloWorkout ? 'Solo Workout' : 'Live Session',
                    style: TextStyle(
                      fontSize: 11,
                      color: workout. isSoloWorkout ? AppColors.primary : AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (workout.isOverdue) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors. error.withOpacity(0.1),
                      borderRadius:  BorderRadius.circular(12),
                    ),
                    child:  const Text(
                      'Overdue',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (workout.notes.isNotEmpty) ...[
              const SizedBox(height:  8),
              Text(
                workout.notes,
                style: AppTextStyles.caption(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: workout.canDelete
            ? IconButton(
                icon:  const Icon(Icons.delete, color: AppColors.error),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:  (ctx) => AlertDialog(
                      title: const Text('Delete Workout'),
                      content:  Text('Remove "${workout.workoutName}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(foregroundColor: AppColors.error),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await provider.deleteAssignedWorkout(workout.id);
                    if (context.mounted) {
                      ScaffoldMessenger. of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Workout removed'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  }
                },
              )
            : const Icon(Icons.chevron_right),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content:  Text('Workout details - Coming soon!')),
          );
        },
      ),
    );
  }
}