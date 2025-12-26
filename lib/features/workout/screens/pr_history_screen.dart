import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/features/workout/providers/workout_provider.dart';
import 'package:reprise/shared/models/workout.dart';
import 'package:reprise/services/local_storage_service.dart';
import 'package:intl/intl.dart';

class PRHistoryScreen extends StatelessWidget {
  const PRHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final weightUnit = LocalStorageService.getSetting('weightUnit', defaultValue: 'lbs');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Personal Records', style: AppTextStyles.h2()),
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, child) {
          final prData = _getPRHistoryByExercise(workoutProvider);

          if (prData.isEmpty) {
            return Center(
              child:  Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size:  80,
                      color:  AppColors.warning. withOpacity(0.5),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No PRs Yet',
                      style: AppTextStyles.h2(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Complete workouts and beat your previous records to see your PRs here! ',
                      style: AppTextStyles.body(color: AppColors.textSecondaryLight),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          int totalPRs = 0;
          for (var exerciseData in prData) {
            final prs = exerciseData['prs'] as List<Map<String, dynamic>>;
            totalPRs += prs.length;
          }

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(AppSpacing. md),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:  [
                      AppColors.warning,
                      AppColors.warning.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment. bottomRight,
                  ),
                  borderRadius: BorderRadius. circular(AppSpacing.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size:  48,
                      color:  Colors.white,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment. start,
                        children: [
                          Text(
                            'Total Personal Records',
                            style: AppTextStyles.body(
                              color: Colors. white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalPRs PRs',
                            style: AppTextStyles.h1(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${prData.length} Exercises',
                            style: AppTextStyles.caption(
                              color: Colors.white. withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView. builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: prData.length,
                  itemBuilder: (context, index) {
                    return _buildExercisePRCard(prData[index], weightUnit, context);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getPRHistoryByExercise(WorkoutProvider workoutProvider) {
    final allWorkouts = workoutProvider.getAllWorkouts()
        .where((w) => w.status == WorkoutStatus.completed)
        .toList();

    allWorkouts.sort((a, b) => a.date.compareTo(b. date));

    final Map<String, List<Map<String, dynamic>>> exercisePRs = {};

    for (var workout in allWorkouts) {
      for (var exercise in workout.exercises) {
        Map<String, dynamic>? bestPRSet;
        
        for (var set in exercise.sets) {
          if (set.completed) {
            final isPR = _wasSetAPR(
              workoutProvider,
              workout,
              exercise.name,
              set,
            );

            if (isPR) {
              if (bestPRSet == null) {
                bestPRSet = {
                  'setNumber': set.setNumber,
                  'weight': set.actualWeight,
                  'reps': set.actualReps,
                  'date': workout.date,
                  'workoutName': workout.name,
                };
              } else {
                final currentWeight = bestPRSet['weight'] as double;
                final currentReps = bestPRSet['reps'] as int;
                
                if (set.actualWeight > currentWeight ||
                    (set.actualWeight == currentWeight && set.actualReps > currentReps)) {
                  bestPRSet = {
                    'setNumber': set.setNumber,
                    'weight': set.actualWeight,
                    'reps': set. actualReps,
                    'date': workout.date,
                    'workoutName': workout. name,
                  };
                }
              }
            }
          }
        }

        if (bestPRSet != null) {
          if (!exercisePRs.containsKey(exercise.name)) {
            exercisePRs[exercise.name] = [];
          }
          exercisePRs[exercise.name]!.add(bestPRSet);
        }
      }
    }

    final List<Map<String, dynamic>> result = [];
    
    exercisePRs.forEach((exerciseName, prs) {
      prs.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      
      result.add({
        'exerciseName': exerciseName,
        'prs': prs,
        'totalPRs': prs.length,
        'latestWeight': prs. first['weight'],
        'latestReps':  prs.first['reps'],
      });
    });

    result.sort((a, b) {
      final aDate = (a['prs'] as List)[0]['date'] as DateTime;
      final bDate = (b['prs'] as List)[0]['date'] as DateTime;
      return bDate.compareTo(aDate);
    });

    return result;
  }

  bool _wasSetAPR(
    WorkoutProvider workoutProvider,
    Workout currentWorkout,
    String exerciseName,
    ExerciseSet set,
  ) {
    final allWorkouts = workoutProvider.getAllWorkouts();

    List<Map<String, dynamic>> previousSets = [];

    for (var workout in allWorkouts) {
      if (workout.date.isAfter(currentWorkout.date) ||
          workout.date.isAtSameMomentAs(currentWorkout.date)) {
        continue;
      }

      if (workout.status != WorkoutStatus.completed) continue;

      for (var exercise in workout.exercises) {
        if (exercise.name == exerciseName) {
          for (var prevSet in exercise.sets) {
            if (prevSet.completed) {
              previousSets.add({
                'weight': prevSet.actualWeight,
                'reps': prevSet. actualReps,
              });
            }
          }
        }
      }
    }

    if (previousSets.isEmpty) {
      return true;
    }

    double maxWeight = 0;
    int maxRepsAtMaxWeight = 0;

    for (var prevSet in previousSets) {
      double prevWeight = prevSet['weight'];
      int prevReps = prevSet['reps'];

      if (prevWeight > maxWeight) {
        maxWeight = prevWeight;
        maxRepsAtMaxWeight = prevReps;
      } else if (prevWeight == maxWeight && prevReps > maxRepsAtMaxWeight) {
        maxRepsAtMaxWeight = prevReps;
      }
    }

    if (set.actualWeight > maxWeight) {
      return true;
    }

    if (set.actualWeight == maxWeight && set.actualReps > maxRepsAtMaxWeight) {
      return true;
    }

    return false;
  }

  // ✅ FIXED: Added context parameter
  Widget _buildExercisePRCard(Map<String, dynamic> data, String weightUnit, BuildContext context) {
    final String exerciseName = data['exerciseName'];
    final List<Map<String, dynamic>> prs = List<Map<String, dynamic>>.from(data['prs']);
    final int totalPRs = data['totalPRs'];
    
    final latestPR = prs.first;
    final latestWeight = weightUnit == 'kg'
        ? (latestPR['weight'] * 0.453592).toStringAsFixed(1)
        : (latestPR['weight'] as double).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(AppSpacing.md),
          childrenPadding: const EdgeInsets.only(
            left: AppSpacing. md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
          ),
          leading: Container(
            padding: const EdgeInsets.all(AppSpacing. sm),
            decoration: BoxDecoration(
              color: AppColors.primary. withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          title: Text(
            exerciseName,
            style: AppTextStyles.h3(),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.emoji_events, size: 14, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    'Latest:  $latestWeight $weightUnit × ${latestPR['reps']} reps',
                    style: AppTextStyles.bodySmall(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '$totalPRs PR${totalPRs > 1 ? "s" : ""} total',
                style: AppTextStyles.caption(color: AppColors.textSecondaryLight),
              ),
            ],
          ),
          children: [
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            
            ... prs.asMap().entries.map((entry) {
              final index = entry. key;
              final pr = entry.value;
              final isLatest = index == 0;
              
              final displayWeight = weightUnit == 'kg'
                  ? (pr['weight'] * 0.453592).toStringAsFixed(1)
                  : (pr['weight'] as double).toStringAsFixed(1);
              
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing. sm),
                decoration: BoxDecoration(
                  color: isLatest 
                      ? AppColors.warning.withOpacity(0.1)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  border: isLatest 
                      ? Border.all(color: AppColors.warning, width: 2)
                      :  null,
                ),
                child: Row(
                  children:  [
                    SizedBox(
                      width:  80,
                      child: Text(
                        DateFormat('MMM d, yy').format(pr['date']),
                        style: AppTextStyles.caption(
                          color: isLatest ?  AppColors.warning : AppColors. textSecondaryLight,
                          fontWeight: isLatest ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    
                    Expanded(
                      child: Text(
                        '$displayWeight $weightUnit × ${pr['reps']} reps',
                        style: AppTextStyles.body(
                          fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    
                    if (isLatest)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Current PR',
                          style: AppTextStyles.caption(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.history,
                        size: 16,
                        color: AppColors.textSecondaryLight.withOpacity(0.5),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}