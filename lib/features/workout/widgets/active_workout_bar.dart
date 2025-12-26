import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/shared/models/workout.dart';
import 'package:reprise/features/workout/providers/workout_provider.dart';
import 'package:reprise/features/workout/screens/workout_screen.dart';
import 'package:reprise/services/local_storage_service.dart';  // ✅ ADD THIS

class ActiveWorkoutBar extends StatelessWidget {
  const ActiveWorkoutBar({super.key});

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder:  (context, workoutProvider, child) {
        final activeWorkout = workoutProvider.activeWorkout;
        final elapsedSeconds = workoutProvider.activeWorkoutElapsedSeconds;

        if (activeWorkout == null) {
          return const SizedBox. shrink();
        }

        final completedSets = activeWorkout.exercises
            .expand((e) => e.sets)
            .where((s) => s.completed)
            .length;

        final totalSets = activeWorkout.exercises
            .expand((e) => e.sets)
            .length;

        return Material(
          elevation: 8,
          child: InkWell(
            onTap:  () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkoutScreen(
                    workout: activeWorkout,
                    resumeActive: true,
                  ),
                ),
              );
            },
            child: Container(
              padding:  const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children:  [
                    Container(
                      padding:  const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white. withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize. min,
                        children: [
                          Text(
                            activeWorkout.name,
                            style: AppTextStyles.body(
                              color: Colors. white,
                              fontWeight:  FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$completedSets/$totalSets sets • ${_formatTime(elapsedSeconds)}',
                            style: AppTextStyles.caption(
                              color: Colors. white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ✅ Finish button
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.white, size: 22),
                      onPressed: () {
                        final weightUnit = LocalStorageService.getSetting('weightUnit', defaultValue:  'lbs');
                        
                        final totalVolume = activeWorkout.exercises
                            .expand((e) => e.sets)
                            .where((s) => s.completed)
                            .fold<double>(0, (sum, s) => sum + (s.actualWeight * s.actualReps));
                        
                        final displayVolume = weightUnit == 'kg'
                            ? (totalVolume * 0.453592).toInt()
                            : totalVolume. toInt();
                        
                        showDialog(
                          context: context,
                          builder:  (dialogContext) => AlertDialog(
                            title: Text('Finish Workout?', style: AppTextStyles.h3()),
                            content: Column(
                              mainAxisSize: MainAxisSize. min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Duration: ${_formatTime(elapsedSeconds)}'),
                                Text('Sets: $completedSets / $totalSets'),
                                Text('Total Volume: $displayVolume $weightUnit'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Continue'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(dialogContext);
                                  
                                  // Complete the workout
                                  final completedWorkout = activeWorkout. copyWith(
                                    status: WorkoutStatus.completed,
                                    durationMinutes:  elapsedSeconds ~/ 60,
                                    totalVolume: totalVolume.toInt(),
                                  );
                                  
                                  await workoutProvider.saveCompletedWorkout(completedWorkout);
                                  
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Workout Complete!  💪',
                                            style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height:  4),
                                          Text('Duration: ${_formatTime(elapsedSeconds)}'),
                                          Text('Sets: $completedSets / $totalSets'),
                                          Text('Volume: $displayVolume $weightUnit'),
                                        ],
                                      ),
                                      backgroundColor: AppColors.success,
                                      duration: const Duration(milliseconds: 2000),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: const Text('Finish'),
                              ),
                            ],
                          ),
                        );
                      },
                      tooltip:  'Finish Workout',
                    ),
                    // ✅ Cancel button
                    IconButton(
                      icon:  const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed:  () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text('End Workout?', style: AppTextStyles.h3()),
                            content: Text(
                              'Do you want to cancel this workout?',
                              style: AppTextStyles.body(),
                            ),
                            actions:  [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Keep Active'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await workoutProvider.clearActiveWorkout();
                                  Navigator. pop(dialogContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:  Text('Workout cancelled'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                child: const Text('Cancel Workout'),
                              ),
                            ],
                          ),
                        );
                      },
                      tooltip:  'Cancel Workout',
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}