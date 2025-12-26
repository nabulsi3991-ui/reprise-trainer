import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/features/workout/providers/workout_provider.dart';
import 'package:reprise/services/progressive_overload_service.dart';
import 'package:reprise/shared/models/workout.dart';
import 'package:reprise/services/local_storage_service.dart';
import 'package:intl/intl.dart';

class ExerciseAnalyticsScreen extends StatefulWidget {
  const ExerciseAnalyticsScreen({super.key});

  @override
  State<ExerciseAnalyticsScreen> createState() => _ExerciseAnalyticsScreenState();
}

class _ExerciseAnalyticsScreenState extends State<ExerciseAnalyticsScreen> {
  String?  _selectedExercise;

  @override
  Widget build(BuildContext context) {
    final weightUnit = LocalStorageService. getSetting('weightUnit', defaultValue: 'lbs');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Exercise Analytics', style: AppTextStyles.h2()),
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
                      size:  80,
                      color:  AppColors.textSecondaryLight. withOpacity(0.5),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No Data Yet',
                      style: AppTextStyles.h2(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Complete workouts to see analytics',
                      style: AppTextStyles.body(color: AppColors.textSecondaryLight),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Get all unique exercises
          final allExercises = <String>{};
          for (var workout in workouts) {
            for (var exercise in workout. exercises) {
              allExercises.add(exercise.name);
            }
          }

          final exerciseList = allExercises.toList().. sort();

          return Column(
            children: [
              // Exercise Selector
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                color: Theme.of(context).cardColor,
                child: DropdownButtonFormField<String>(
                  value: _selectedExercise,
                  decoration: InputDecoration(
                    labelText: 'Select Exercise',
                    prefixIcon: const Icon(Icons. fitness_center),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius. circular(AppSpacing.radiusSmall),
                    ),
                  ),
                  items: exerciseList.map((exercise) {
                    return DropdownMenuItem(
                      value:  exercise,
                      child: Text(exercise),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedExercise = value;
                    });
                  },
                ),
              ),

              // Analytics Content
              Expanded(
                child: _selectedExercise == null
                    ? Center(
                        child: Text(
                          'Select an exercise to view analytics',
                          style: AppTextStyles.body(color: AppColors.textSecondaryLight),
                        ),
                      )
                    : _buildExerciseAnalytics(
                        _selectedExercise!,
                        workouts,
                        weightUnit,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExerciseAnalytics(String exerciseName, List<Workout> workouts, String weightUnit) {
    final history = ProgressiveOverloadService.getExerciseHistory(
      exerciseName:  exerciseName,
      workoutHistory: workouts,
    );

    if (history.sessions.isEmpty) {
      return Center(
        child: Text(
          'No data for this exercise',
          style: AppTextStyles.body(color: AppColors.textSecondaryLight),
        ),
      );
    }

    // FIXED: Convert weight values based on unit
    final maxWeight = weightUnit == 'kg' 
        ? history.maxWeight * 0.453592 
        : history.maxWeight;
    final maxVolume = weightUnit == 'kg'
        ? history.maxVolume * 0.453592
        : history.maxVolume;

    // Sort sessions by date (newest first) for display
    final sortedSessions = history.sessions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.fitness_center,
                  label: 'Max Weight',
                  value: '${maxWeight.toInt()} $weightUnit',
                  color:  AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing. sm),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.repeat,
                  label: 'Max Reps',
                  value:  '${history.maxReps}',
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.trending_up,
                  label:  'Max Volume',
                  value: '${maxVolume.toInt()} $weightUnit',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.calendar_today,
                  label:  'Sessions',
                  value: '${history.totalSessions}',
                  color: AppColors.info,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Progress Chart
          Text('Weight Progress', style: AppTextStyles. h3()),
          const SizedBox(height: AppSpacing. md),
          _buildProgressChart(history, weightUnit),

          const SizedBox(height: AppSpacing. xl),

          // Session History
          Text('Session History (Recent)', style: AppTextStyles.h3()),
          const SizedBox(height: AppSpacing.md),
          
          // Display sorted sessions (newest first), take 10
          ... sortedSessions
              .take(10)
              .map((session) => _buildSessionCard(session, weightUnit)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing. md),
      decoration: BoxDecoration(
        color: color. withOpacity(0.1),
        borderRadius: BorderRadius. circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.h3(color: color),
          ),
          const SizedBox(height:  AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.caption(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart(ExerciseHistory history, String weightUnit) {
    // Sort sessions oldest to newest for proper chart progression
    final sessions = history.sessions.toList()
      ..sort((a, b) => a.date.compareTo(b. date)); // Oldest first
    
    // Take last 10 sessions (most recent)
    final recentSessions = sessions.length > 10 
        ? sessions.sublist(sessions.length - 10) 
        : sessions;

    // FIXED: Convert max weight for chart scaling
    final maxWeight = weightUnit == 'kg'
        ? history.maxWeight * 0.453592
        :  history.maxWeight;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppSpacing. md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius:  BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:  recentSessions.map((session) {
                final maxSessionWeight = session.sets.isNotEmpty
                    ? session. sets.map((s) => s.actualWeight).reduce((a, b) => a > b ? a : b)
                    : 0.0;
                
                // FIXED: Convert weight for display
                final displayWeight = weightUnit == 'kg'
                    ? maxSessionWeight * 0.453592
                    : maxSessionWeight;
                    
                final heightPercentage = maxWeight > 0 ? displayWeight / maxWeight : 0;

                return Expanded(
                  child:  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (displayWeight > 0)
                          Text(
                            '${displayWeight.toInt()}',
                            style: AppTextStyles.caption(),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          height: 120.0 * heightPercentage,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppColors. primary,
                                AppColors.primary.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:  [
              Text('Oldest', style: AppTextStyles.caption()),
              Text('Most Recent', style: AppTextStyles. caption()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(ExerciseSession session, String weightUnit) {
    // FIXED: Convert weights for display
    final maxWeight = session.sets.isNotEmpty
        ? session.sets.map((s) => s.actualWeight).reduce((a, b) => a > b ? a : b)
        : 0.0;
    
    final displayMaxWeight = weightUnit == 'kg'
        ? (maxWeight * 0.453592).toInt()
        : maxWeight. toInt();
    
    final displayVolume = weightUnit == 'kg'
        ? (session.totalVolume * 0.453592).toInt()
        : session.totalVolume.toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:  [
                Text(
                  DateFormat('MMM d, yyyy').format(session.date),
                  style: AppTextStyles. h4(),
                ),
                Text(
                  '$displayVolume $weightUnit',
                  style: AppTextStyles.body(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: session.sets.map((set) {
                final displayWeight = weightUnit == 'kg'
                    ? (set.actualWeight * 0.453592).toInt()
                    : set.actualWeight.toInt();
                    
                return Chip(
                  label: Text(
                    '$displayWeight × ${set.actualReps}',
                    style:  AppTextStyles.caption(color: Colors.white),
                  ),
                  backgroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.fitness_center, size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 4),
                Text(
                  'Max:  $displayMaxWeight $weightUnit',
                  style: AppTextStyles.caption(),
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(Icons.list, size: 14, color:  AppColors.textSecondaryLight),
                const SizedBox(width: 4),
                Text(
                  '${session.sets.length} sets',
                  style: AppTextStyles.caption(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}