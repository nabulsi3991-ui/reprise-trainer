import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/shared/models/workout.dart';
import 'package:reprise/features/workout/providers/workout_provider.dart';
import 'package:reprise/services/local_storage_service.dart';
import 'package:intl/intl.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailScreen({
    super.key,
    required this.workout,
  });

  @override
  Widget build(BuildContext context) {
    final weightUnit = LocalStorageService.getSetting('weightUnit', defaultValue: 'lbs');
    
    final displayVolume = weightUnit == 'kg'
        ? (workout. totalVolume * 0.453592).toInt()
        : workout.totalVolume;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(workout.name, style: AppTextStyles.h2()),
        actions: [
          IconButton(
            icon:  const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context),
            tooltip: 'Delete Workout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment:  CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets. all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(workout.date),
                    style: AppTextStyles.body(color: Colors.white70),
                  ),
                  const SizedBox(height:  AppSpacing.sm),
                  
                  if (workout. status == WorkoutStatus.completed) ...[
                    Row(
                      children: [
                        _buildSummaryItem(
                          Icons.fitness_center,
                          '$displayVolume $weightUnit',
                          'Total Volume',
                        ),
                        const SizedBox(width:  AppSpacing.xl),
                        _buildSummaryItem(
                          Icons.access_time,
                          '${workout. durationMinutes} min',
                          'Duration',
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // ✅ FIXED: Simple colored chips like the image
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing:  AppSpacing.sm,
                    children: workout.muscleGroups
                        .map((group) => Chip(
                              label: Text(
                                group,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight:  FontWeight.w600,
                                ),
                              ),
                              backgroundColor: AppColors.getMuscleGroupColor(group),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ))
                        . toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Text('Exercises', style: AppTextStyles.h3()),
            const SizedBox(height: AppSpacing.md),

            ...workout.exercises.map((exercise) {
              return _buildExerciseCard(exercise, weightUnit);
            }),

            if (workout. notes != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Text('Notes', style: AppTextStyles.h3()),
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets. all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors. surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child:  Text(
                  workout.notes!,
                  style: AppTextStyles.body(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children:  [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              value,
              style: AppTextStyles.h3(color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style:  AppTextStyles.caption(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(Exercise exercise, String weightUnit) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.getMuscleGroupColor(exercise.muscleGroups.first)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color:  AppColors.getMuscleGroupColor(exercise.muscleGroups. first),
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.name, style: AppTextStyles.h4()),
                      const SizedBox(height: 4),
                      Text(
                        exercise. muscleGroups.join(', '),
                        style: AppTextStyles.caption(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height:  AppSpacing.sm),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text('SET', style: AppTextStyles.caption()),
                  ),
                  Expanded(
                    child: Text('WEIGHT', style: AppTextStyles.caption()),
                  ),
                  Expanded(
                    child: Text('REPS', style: AppTextStyles.caption()),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ),
            
            ... exercise.sets.map((set) {
              final displayWeight = weightUnit == 'kg'
                  ? (set.actualWeight * 0.453592).toStringAsFixed(1)
                  : set.actualWeight.toStringAsFixed(1);
              
              return Container(
                padding:  const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: set.completed 
                      ? AppColors.success.withOpacity(0.1)
                      : null,
                  borderRadius: BorderRadius. circular(4),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${set. setNumber}',
                        style: AppTextStyles.body(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        set.completed
                            ? '$displayWeight $weightUnit'
                            : '-',
                        style:  AppTextStyles.body(),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        set. completed ?  '${set.actualReps}' : '-',
                        style: AppTextStyles.body(),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      child: set.completed
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 20,
                            )
                          :  null,
                    ),
                  ],
                ),
              );
            }),
            
            if (exercise.notes != null) ...[
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.note, size: 16, color: AppColors. textSecondaryLight),
                  const SizedBox(width:  AppSpacing.xs),
                  Expanded(
                    child: Text(
                      exercise. notes!,
                      style:  AppTextStyles.bodySmall(color: AppColors.textSecondaryLight),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete Workout', style: AppTextStyles.h3()),
        content: Text(
          'Are you sure you want to delete "${workout.name}"?',
          style: AppTextStyles.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
              workoutProvider.deleteWorkout(workout.id, workout.date);
              
              Navigator.pop(dialogContext);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${workout.name} deleted'),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}