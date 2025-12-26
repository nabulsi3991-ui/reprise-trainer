import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/features/workout/providers/workout_provider.dart';
import 'package:reprise/shared/models/workout.dart';
import 'package:intl/intl.dart';

class MuscleGroupProgressScreen extends StatelessWidget {
  const MuscleGroupProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Muscle Group Progress', style: AppTextStyles.h2()),
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, child) {
          final workouts = workoutProvider.getAllWorkouts()
              .where((w) => w.status == WorkoutStatus.completed)
              .toList();

          if (workouts.isEmpty) {
            return Center(
              child:  Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 80,
                      color: AppColors.textSecondaryLight. withOpacity(0.5),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No Data Yet',
                      style: AppTextStyles.h2(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Complete workouts to see muscle group progress',
                      style:  AppTextStyles.body(color: AppColors.textSecondaryLight),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Calculate stats per muscle group
          final muscleGroupStats = _calculateMuscleGroupStats(workouts);

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing. md),
            itemCount: muscleGroupStats.length,
            itemBuilder: (context, index) {
              final entry = muscleGroupStats. entries.elementAt(index);
              return _buildMuscleGroupCard(entry. key, entry.value);
            },
          );
        },
      ),
    );
  }

  Map<String, MuscleGroupStats> _calculateMuscleGroupStats(List<Workout> workouts) {
    final Map<String, MuscleGroupStats> stats = {};

    for (var workout in workouts) {
      for (var muscleGroup in workout.muscleGroups) {
        if (muscleGroup == 'Rest') continue;

        if (!stats.containsKey(muscleGroup)) {
          stats[muscleGroup] = MuscleGroupStats(
            muscleGroup: muscleGroup,
            totalWorkouts: 0,
            totalVolume: 0,
            totalSets: 0,
            lastWorkoutDate: workout.date,
            workoutDates: [],
          );
        }

        stats[muscleGroup]!.totalWorkouts++;
        stats[muscleGroup]!. totalVolume += workout.totalVolume;
        stats[muscleGroup]!.workoutDates.add(workout. date);

        // Count sets for this muscle group
        for (var exercise in workout.exercises) {
          if (exercise.muscleGroups.contains(muscleGroup)) {
            stats[muscleGroup]!.totalSets += exercise. sets.where((s) => s.completed).length;
          }
        }

        // Update last workout date
        if (workout.date. isAfter(stats[muscleGroup]!.lastWorkoutDate)) {
          stats[muscleGroup]!.lastWorkoutDate = workout.date;
        }
      }
    }

    // Sort by total volume
    final sortedEntries = stats.entries.toList()
      ..sort((a, b) => b.value.totalVolume.compareTo(a.value. totalVolume));

    return Map.fromEntries(sortedEntries);
  }

  Widget _buildMuscleGroupCard(String muscleGroup, MuscleGroupStats stats) {
    final daysSinceLastWorkout = DateTime.now().difference(stats.lastWorkoutDate).inDays;
    final color = AppColors.getMuscleGroupColor(muscleGroup);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child:  Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: color. withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppSpacing. radiusSmall),
                  ),
                  child: Icon(
                    _getMuscleGroupIcon(muscleGroup),
                    color: color,
                    size:  32,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment. start,
                    children: [
                      Text(muscleGroup, style: AppTextStyles.h3()),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Last trained: ${daysSinceLastWorkout == 0 ? "Today" : "$daysSinceLastWorkout days ago"}',
                        style:  AppTextStyles.caption(
                          color: daysSinceLastWorkout > 7 ? AppColors.error : AppColors.textSecondaryLight,
                        ),
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Workouts', '${stats.totalWorkouts}', Icons.fitness_center),
                _buildStatColumn('Volume', '${(stats.totalVolume / 1000).toStringAsFixed(1)}K', Icons.trending_up),
                _buildStatColumn('Sets', '${stats. totalSets}', Icons.repeat),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFrequencyChart(stats. workoutDates),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children:  [
        Icon(icon, size: 20, color: AppColors.textSecondaryLight),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.h3(),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style:  AppTextStyles.caption(),
        ),
      ],
    );
  }

  Widget _buildFrequencyChart(List<DateTime> workoutDates) {
    // Show last 12 weeks
    final now = DateTime.now();
    final weeks = <int>[];
    
    for (int i = 11; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: (i * 7) + now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));
      
      final count = workoutDates.where((date) {
        return date.isAfter(weekStart) && date.isBefore(weekEnd);
      }).length;
      
      weeks.add(count);
    }

    final maxCount = weeks.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Last 12 Weeks', style: AppTextStyles.caption()),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: weeks.map((count) {
            final height = maxCount > 0 ? (count / maxCount) * 40 : 0.0;
            return Container(
              width: 20,
              height: height < 5 && count > 0 ? 5 : height,
              decoration: BoxDecoration(
                color: count > 0 ? AppColors. primary : AppColors.surfaceLight,
                borderRadius:  const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getMuscleGroupIcon(String muscleGroup) {
    switch (muscleGroup. toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.airline_seat_recline_normal;
      case 'legs': 
        return Icons.directions_run;
      case 'shoulders': 
        return Icons.expand_less;
      case 'arms': 
        return Icons.sports_martial_arts;
      case 'core':
        return Icons.accessibility_new;
      default:
        return Icons.fitness_center;
    }
  }
}

class MuscleGroupStats {
  final String muscleGroup;
  int totalWorkouts;
  int totalVolume;
  int totalSets;
  DateTime lastWorkoutDate;
  List<DateTime> workoutDates;

  MuscleGroupStats({
    required this.muscleGroup,
    required this.totalWorkouts,
    required this.totalVolume,
    required this.totalSets,
    required this. lastWorkoutDate,
    required this.workoutDates,
  });
}