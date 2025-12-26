import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/features/workout/providers/workout_provider.dart';
import 'package:reprise/features/workout/screens/workout_detail_screen.dart';
import 'package:reprise/shared/models/workout.dart';
import 'package:reprise/services/local_storage_service.dart';
import 'package:intl/intl.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  String _filterStatus = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
        title: Text('Workout History', style: AppTextStyles.h2()),
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, child) {
          var workouts = workoutProvider.getAllWorkouts();

          // Filter workouts
          if (_filterStatus == 'Completed') {
            workouts = workouts
                .where((w) => w.status == WorkoutStatus.completed)
                .toList();
          } else if (_filterStatus == 'Scheduled') {
            workouts = workouts
                .where((w) => w.status == WorkoutStatus. scheduled)
                .toList();
          }

          if (workouts.isEmpty) {
            return Center(
              child:  Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 80,
                      color: AppColors.textSecondaryLight. withOpacity(0.5),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No Workouts Yet',
                      style: AppTextStyles.h2(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Start your first workout to see it here',
                      style: AppTextStyles.body(color: AppColors.textSecondaryLight),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Filter Chips
              Container(
                padding: const EdgeInsets.all(AppSpacing. md),
                color: Theme.of(context).cardColor,
                child: Row(
                  children: [
                    Text('Filter:  ', style: AppTextStyles.body()),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('All'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Completed'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Scheduled'),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Workout List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    return _buildWorkoutCard(workouts[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterStatus == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = label;
        });
      },
      backgroundColor: AppColors.surfaceLight,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimaryLight,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildWorkoutCard(Workout workout) {
    final weightUnit = LocalStorageService.getSetting('weightUnit', defaultValue: 'lbs');
    
    final daysAgo = DateTime.now().difference(workout.date).inDays;
    final dateText = daysAgo == 0 
        ? 'Today' 
        : daysAgo == 1 
            ? 'Yesterday' 
            : DateFormat('MMM d, yyyy').format(workout.date);

    final displayVolume = weightUnit == 'kg'
        ? (workout.totalVolume * 0.453592).toInt()
        : workout.totalVolume;

    return Card(
      margin: const EdgeInsets. only(bottom: AppSpacing. md),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutDetailScreen(workout: workout),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:  [
                  Expanded(
                    child: Text(workout.name, style: AppTextStyles.h3()),
                  ),
                  Text(dateText, style: AppTextStyles.caption()),
                ],
              ),
              const SizedBox(height:  AppSpacing.sm),
              
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing. sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: workout.status == WorkoutStatus.completed
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors. info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child:  Text(
                  workout.status == WorkoutStatus.completed 
                      ? 'Completed' 
                      : 'Scheduled',
                  style: AppTextStyles.caption(
                    color: workout.status == WorkoutStatus.completed
                        ? AppColors.success
                        : AppColors.info,
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              Wrap(
                spacing: AppSpacing.sm,
                children: workout.muscleGroups
                    .map((group) => Chip(
                          label: Text(
                            group,
                            style:  AppTextStyles.caption(color: Colors.white),
                          ),
                          backgroundColor: AppColors.getMuscleGroupColor(group),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ))
                    . toList(),
              ),
              
              if (workout.status == WorkoutStatus.completed) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.fitness_center, size: 16, color:  AppColors.textSecondaryLight),
                    const SizedBox(width: AppSpacing.xs),
                    Text('$displayVolume $weightUnit', style: AppTextStyles.bodySmall()),
                    const SizedBox(width: AppSpacing.md),
                    const Icon(Icons.access_time, size: 16, color: AppColors.textSecondaryLight),
                    const SizedBox(width: AppSpacing.xs),
                    Text('${workout.durationMinutes} min', style: AppTextStyles.bodySmall()),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}