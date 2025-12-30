// lib/features/workout/screens/workout_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/theme/app_theme_manager.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/shared/models/workout.dart';
import 'package:reprise/shared/models/exercise_library.dart';
import 'package:reprise/features/workout/providers/workout_provider.dart';
import 'package:reprise/features/workout/screens/exercise_selector_screen.dart';
import 'package:reprise/services/progressive_overload_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:reprise/services/local_storage_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:reprise/services/workout_notification_service.dart';
import 'package:reprise/shared/widgets/swipe_to_delete.dart';
import 'package:reprise/features/workout/providers/assigned_workout_provider.dart';


class WorkoutScreen extends StatefulWidget {
  final Workout?  workout;
  final bool isTemplate;
  final bool autoStart;
  final bool resumeActive;
  final bool isPastWorkout;

  const WorkoutScreen({
    super.key,
    this. workout,
    this.isTemplate = false,
    this.autoStart = false,
    this. resumeActive = false,
    this.isPastWorkout = false,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> with WidgetsBindingObserver {
  late Workout _currentWorkout;
  
  DateTime?   _workoutStartTime;
  int _elapsedSeconds = 0;
  
  Timer? _timer;
  bool _isRunning = false;
  
  bool _isDisposed = false;
  List<String> _achievedPRs = [];
  bool _isEditingTemplate = false;
  bool _isNavigating = false;
  
  bool _isPastWorkout = false;
  int _manualDurationMinutes = 0;

  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isResting = false;
  int?   _restingExerciseIndex;
  int?   _restingSetIndex;

  // ✅ FIX BUG 3: Track if workout actually started
  bool _workoutHasStarted = false;

@override
void initState() {
  super.initState();
  
  WidgetsBinding.instance.addObserver(this);
  
  final workoutProvider = Provider.of<WorkoutProvider>(context, listen:   false);
    // ✅ FIXED: Get workout from provider if resuming active workout
  if (widget.resumeActive && ! widget.isTemplate) {
    _currentWorkout = workoutProvider.activeWorkout ??  widget.workout ??  _createEmptyWorkout();
    
    // ✅ FIX BUG 2:  Restore the ACTUAL start time from provider
    final providerElapsed = workoutProvider.activeWorkoutElapsedSeconds;
    _workoutStartTime = DateTime.now().subtract(Duration(seconds: providerElapsed));
    _elapsedSeconds = providerElapsed;
    _workoutHasStarted = true;
    
    // ✅ ADD THIS: Recalculate PRs for all exercises when resuming
    for (int i = 0; i < _currentWorkout.exercises.length; i++) {
      _recalculatePRsForExercise(i);
    }
    
    debugPrint('🔄 Resuming workout:  ${_currentWorkout.name}, Start time: $_workoutStartTime, Elapsed: $_elapsedSeconds seconds');
  } else {
    _currentWorkout = widget.workout ??  _createEmptyWorkout();
  }

  // ✅ FIXED: Get workout from provider if resuming active workout
  if (widget.resumeActive && !  widget.isTemplate) {
    _currentWorkout = workoutProvider.activeWorkout ??  widget.workout ??  _createEmptyWorkout();
    
    // ✅ FIX BUG 2: Restore the ACTUAL start time from provider
    final providerElapsed = workoutProvider.activeWorkoutElapsedSeconds;
    _workoutStartTime = DateTime.now().subtract(Duration(seconds: providerElapsed));
    _elapsedSeconds = providerElapsed;
    _workoutHasStarted = true; // ✅ Mark as started when resuming
    
    debugPrint('🔄 Resuming workout:   ${_currentWorkout.name}, Start time: $_workoutStartTime, Elapsed: $_elapsedSeconds seconds');
  } else {
    _currentWorkout = widget.workout ?? _createEmptyWorkout();
  }
  
  _isEditingTemplate = widget.isTemplate;
  
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final workoutDate = DateTime(
    _currentWorkout.date. year,
    _currentWorkout.date.month,
    _currentWorkout.date.day,
  );
  _isPastWorkout = workoutDate.  isBefore(today);
  _isPastWorkout = widget.isPastWorkout || workoutDate.isBefore(today);

  // ✅ Handle resume from active workout
  if (widget.resumeActive && ! _isEditingTemplate && !_isPastWorkout) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isRunning = true;
      });
      _startWorkout();
    });
  } else if (widget.autoStart && !_isEditingTemplate && !_isPastWorkout && _currentWorkout.exercises.isNotEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startWorkout();
    });
  }
  
  if (_isPastWorkout && !  _isEditingTemplate) {
    WidgetsBinding.instance. addPostFrameCallback((_) {
      _showDurationInputDialog();
    });
  }

}

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  super.didChangeAppLifecycleState(state);
  
  // ✅ Only update elapsed time when resuming - global observer handles notifications
  if (state == AppLifecycleState.resumed) {
    if (!_isEditingTemplate && ! _isPastWorkout && _workoutStartTime != null && mounted) {
      final elapsed = DateTime. now().difference(_workoutStartTime!);
      setState(() {
        _elapsedSeconds = elapsed.inSeconds;
      });
    }
  }
}

  @override
void dispose() {
  _isDisposed = true;
  _timer?.cancel();
  _restTimer?.cancel();
  
  WidgetsBinding.instance.removeObserver(this);
  
  if (_isRunning) {
    WakelockPlus.disable();
  }
  
  
  super.dispose();
}

  Workout _createEmptyWorkout() {
    return Workout(
      id: const Uuid().v4(),
      name: 'New Workout',
      date: DateTime.now(),
      muscleGroups: [],
      status: WorkoutStatus.inProgress,
      exercises: [],
    );
  }

  void _startWorkout() {
  if (_isDisposed || _isEditingTemplate || _isPastWorkout) return;
  
  WakelockPlus.enable();
  
  final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
  
  setState(() {
    _isRunning = true;
    // ✅ FIX:  Only set start time if not already set (preserve original)
    if (_workoutStartTime == null) {
      _workoutStartTime = DateTime.now();
    }
    _workoutHasStarted = true;
  });
  
  // ✅ FIX:  Register/update active workout with current start time
  if (! _isEditingTemplate && !_isPastWorkout) {
    workoutProvider.setActiveWorkout(
      _currentWorkout,
      startTime: _workoutStartTime,
    );
  }
  
  _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (_isDisposed || ! mounted) {
      timer.cancel();
      return;
    }
    
    if (_workoutStartTime != null) {
      final elapsed = DateTime.now().difference(_workoutStartTime!);
      setState(() {
        _elapsedSeconds = elapsed.inSeconds;
      });
    
    }
  });
}

Future<void> _promptForDuration() async {
  final durationController = TextEditingController();
  
  final result = await showDialog<int? >(
    context: context,
    barrierDismissible: false, // Prevent dismissing by tapping outside
    builder:  (dialogContext) => AlertDialog(
      title: Text('Workout Duration', style: AppTextStyles. h3()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How long was this workout?',
            style: AppTextStyles. body(),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: durationController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration:  const InputDecoration(
              labelText: 'Duration (minutes)',
              hintText: 'e.g., 45',
              prefixIcon: Icon(Icons.access_time),
            ),
            onSubmitted: (value) {
              final minutes = int.tryParse(value);
              if (minutes != null && minutes > 0) {
                Navigator.pop(dialogContext, minutes);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext, null); // Return null for cancel
          },
          child:  const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final minutes = int.tryParse(durationController.text);
            if (minutes != null && minutes > 0) {
              Navigator. pop(dialogContext, minutes);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid duration'),
                  backgroundColor: AppColors.error,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          child:  const Text('Continue'),
        ),
      ],
    ),
  );

  durationController.dispose();

  // ✅ Handle the result
  if (result == null) {
    // User pressed cancel - show warning dialog
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Cancel Workout Log? ', style: AppTextStyles.h3()),
        content: Text(
          'A duration is required to log a completed workout. If you go back, this workout will not be saved.\n\nWhat would you like to do?',
          style: AppTextStyles.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false), // Stay
            child: const Text('Enter Duration'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true), // Exit
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors. error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      // User chose to go back - exit workout screen
      Navigator.pop(context);
    } else {
      // User chose to stay - prompt again for duration
      await _promptForDuration();
    }
  } else if (result > 0) {
    // Valid duration entered
    setState(() {
      _manualDurationMinutes = result;
    });
  }
}

  void _pauseWorkout() {
    if (_isDisposed) return;
    
    _timer?.cancel();
    
    WakelockPlus.disable();
    
    if (mounted) {
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _resumeWorkout() {
    if (_workoutStartTime != null && ! _isDisposed) {
      final elapsed = DateTime.now().difference(_workoutStartTime!);
      setState(() {
        _elapsedSeconds = elapsed.inSeconds;
      });
      _startWorkout();
    } else {
      _startWorkout();
    }
  }

  void _startRestTimer(int exerciseIndex, int setIndex, int restSeconds) {
    if (_isDisposed || _isEditingTemplate) return;
    
    if (restSeconds <= 0) return;
    
    _restTimer?.cancel();
    
    setState(() {
      _isResting = true;
      _restSecondsRemaining = restSeconds;
      _restingExerciseIndex = exerciseIndex;
      _restingSetIndex = setIndex;
    });
    
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed || ! mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _restSecondsRemaining--;
        
        if (_restSecondsRemaining <= 0) {
          _restTimer?.cancel();
          _isResting = false;
          _restingExerciseIndex = null;
          _restingSetIndex = null;
          
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rest complete!   Ready for next set 💪'),
                duration: Duration(seconds: 2),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restSecondsRemaining = 0;
      _restingExerciseIndex = null;
      _restingSetIndex = null;
    });
  }

  void _addRestTime() {
    setState(() {
      _restSecondsRemaining += 30;
    });
  }

  bool _isPRSet(String exerciseName, double weight, int reps) {
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen:  false);
    final allWorkouts = workoutProvider.getAllWorkouts();
    
    List<Map<String, dynamic>> previousSets = [];
    
    for (var workout in allWorkouts) {
      if (workout.id == _currentWorkout.id) continue;
      if (workout.status != WorkoutStatus.completed) continue;
      
      for (var exercise in workout.exercises) {
        if (exercise.name == exerciseName) {
          for (var set in exercise.sets) {
            if (set.completed) {
              previousSets. add({
                'weight': set.actualWeight,
                'reps':   set.actualReps,
              });
            }
          }
        }
      }
    }
    
    for (var exercise in _currentWorkout.exercises) {
      if (exercise.name == exerciseName) {
        for (var set in exercise.sets) {
          if (set.completed && set.actualWeight > 0 && set.actualReps > 0) {
            previousSets.add({
              'weight':   set.actualWeight,
              'reps':  set.actualReps,
            });
          }
        }
        break;
      }
    }
    
    if (previousSets.isEmpty) {
      return true;
    }
    
    double maxWeight = 0;
    int maxRepsAtMaxWeight = 0;
    
    for (var set in previousSets) {
      double prevWeight = set['weight'];
      int prevReps = set['reps'];
      
      if (prevWeight > maxWeight) {
        maxWeight = prevWeight;
        maxRepsAtMaxWeight = prevReps;
      } else if (prevWeight == maxWeight && prevReps > maxRepsAtMaxWeight) {
        maxRepsAtMaxWeight = prevReps;
      }
    }
    
    if (weight > maxWeight) {
      return true;
    }
    
    if (weight == maxWeight && reps > maxRepsAtMaxWeight) {
      return true;
    }
    
    int matchCount = 0;
    for (var set in previousSets) {
      if (set['weight'] == weight && set['reps'] == reps) {
        matchCount++;
      }
    }
    
    if (matchCount > 1) {
      return false;
    }
    
    return false;
  }

  void _completeSet(int exerciseIndex, int setIndex, int reps, double weight) {
  if (_isDisposed || !   mounted) return;
  
  final exercise = _currentWorkout.exercises[exerciseIndex];
  final set = exercise.sets[setIndex];
  
  final updatedSet = set.copyWith(
    actualReps: reps,
    actualWeight: weight,
    completed: true,
  );
  
  final updatedSets = List<ExerciseSet>.from(exercise.sets);
  updatedSets[setIndex] = updatedSet;
  
  final updatedExercise = Exercise(
    id: exercise.id,
    name: exercise.name,
    muscleGroups:  exercise.muscleGroups,
    sets: updatedSets,
    notes: exercise.notes,
  );
  
  final updatedExercises = List<Exercise>.from(_currentWorkout. exercises);
  updatedExercises[exerciseIndex] = updatedExercise;
  
  setState(() {
    _currentWorkout = _currentWorkout. copyWith(exercises: updatedExercises);
    _recalculatePRsForExercise(exerciseIndex);
  });

  // ✅ NEW: Update active workout in provider
  if (!  _isEditingTemplate && ! _isPastWorkout) {
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
    workoutProvider.updateActiveWorkout(_currentWorkout);
    
    // ✅ ADD THIS: Update notification with new set count
    final completedSets = _currentWorkout.exercises
        .expand((e) => e.sets)
        .where((s) => s.completed)
        .length;
    final totalSets = _currentWorkout.exercises
        .expand((e) => e.sets)
        .length;
    
    WorkoutNotificationService.updateWorkoutSets('$completedSets/$totalSets sets');
  }

  if (! _isEditingTemplate && !  _isPastWorkout) {
    final isLastSet = setIndex == exercise.sets.length - 1;
    if (!  isLastSet) {
      _startRestTimer(exerciseIndex, setIndex, set.restSeconds);
    }
  }
}

  void _recalculatePRsForExercise(int exerciseIndex) {
    final exercise = _currentWorkout.exercises[exerciseIndex];
    
    _achievedPRs.  removeWhere((pr) => pr.startsWith('${exercise.name}_'));
    
    int?   bestSetIndex;
    double bestWeight = 0;
    int bestReps = 0;
    
    for (int i = 0; i < exercise. sets.length; i++) {
      final set = exercise.sets[i];
      
      if (set.completed) {
        if (set.actualWeight > bestWeight) {
          bestWeight = set.actualWeight;
          bestReps = set.actualReps;
          bestSetIndex = i;
        } else if (set.actualWeight == bestWeight && set.actualReps > bestReps) {
          bestReps = set.actualReps;
          bestSetIndex = i;
        }
      }
    }
    
    if (bestSetIndex != null) {
      final isPR = _isPRAgainstHistory(exercise.name, bestWeight, bestReps);
      
      if (isPR) {
        _achievedPRs.  add('${exercise.name}_$bestSetIndex');
      }
    }
  }

  bool _isPRAgainstHistory(String exerciseName, double weight, int reps) {
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen:  false);
    final allWorkouts = workoutProvider.getAllWorkouts();
    
    List<Map<String, dynamic>> historicalSets = [];
    
    for (var workout in allWorkouts) {
      if (workout.id == _currentWorkout.  id) continue;
      if (workout.status != WorkoutStatus.  completed) continue;
      
      for (var exercise in workout.exercises) {
        if (exercise.  name == exerciseName) {
          for (var set in exercise.  sets) {
            if (set. completed) {
              historicalSets.add({
                'weight': set.actualWeight,
                'reps': set.actualReps,
              });
            }
          }
        }
      }
    }
    
    if (historicalSets.isEmpty) {
      return true;
    }
    
    double maxHistoricalWeight = 0;
    int maxHistoricalReps = 0;
    
    for (var set in historicalSets) {
      double prevWeight = set['weight'];
      int prevReps = set['reps'];
      
      if (prevWeight > maxHistoricalWeight) {
        maxHistoricalWeight = prevWeight;
        maxHistoricalReps = prevReps;
      } else if (prevWeight == maxHistoricalWeight && prevReps > maxHistoricalReps) {
        maxHistoricalReps = prevReps;
      }
    }
    
    if (weight > maxHistoricalWeight) {
      return true;
    }
    
    if (weight == maxHistoricalWeight && reps > maxHistoricalReps) {
      return true;
    }
    
    return false;
  }

  String?   _getPRReason(String exerciseName, double weight, int reps) {
    final workoutProvider = Provider. of<WorkoutProvider>(context, listen: false);
    final allWorkouts = workoutProvider.getAllWorkouts();
    final weightUnit = LocalStorageService.getSetting('weightUnit', defaultValue: 'lbs');
    
    double maxHistoricalWeight = 0;
    int maxHistoricalReps = 0;
    bool hasHistory = false;
    
    for (var workout in allWorkouts) {
      if (workout.id == _currentWorkout.id) continue;
      if (workout.  status != WorkoutStatus. completed) continue;
      
      for (var exercise in workout.exercises) {
        if (exercise. name == exerciseName) {
          for (var set in exercise. sets) {
            if (set.completed) {
              hasHistory = true;
              
              if (set.actualWeight > maxHistoricalWeight) {
                maxHistoricalWeight = set.actualWeight;
                maxHistoricalReps = set.actualReps;
              } else if (set.actualWeight == maxHistoricalWeight && 
                         set.actualReps > maxHistoricalReps) {
                maxHistoricalReps = set.actualReps;
              }
            }
          }
        }
      }
    }
    
    if (!  hasHistory) {
      return 'First time!   🎉';
    }
    
    final weightDiff = weight - maxHistoricalWeight;
    final weightIncreased = weightDiff > 0.1;
    final sameWeight = weightDiff.  abs() <= 0.1;
    final repsIncreased = reps > maxHistoricalReps;
    
    if (weightIncreased && repsIncreased) {
      final increase = weightUnit == 'kg' 
          ? (weightDiff * 0.453592)
          : weightDiff;
      return '+${increase.toStringAsFixed(1)} $weightUnit & +${reps - maxHistoricalReps} reps';
    } else if (weightIncreased) {
      final increase = weightUnit == 'kg' 
          ? (weightDiff * 0.453592)
          : weightDiff;
      return '+${increase.toStringAsFixed(1)} $weightUnit';
    } else if (sameWeight && repsIncreased) {
      final repIncrease = reps - maxHistoricalReps;
      return '+$repIncrease rep${repIncrease > 1 ? "s" : ""}';
    }
    
    return null;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _addExercise() async {
  final selectedExercise = await Navigator.push<ExerciseTemplate>(
    context,
    MaterialPageRoute(
      builder: (context) => const ExerciseSelectorScreen(),
    ),
  );

  if (selectedExercise != null && mounted) {
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen:   false);
    
    final suggestedWeight = ProgressiveOverloadService.calculateSuggestedWeight(
      exerciseId: selectedExercise.name,
      workoutHistory: workoutProvider.getAllWorkouts(),
      targetReps: selectedExercise.defaultReps,
    );

    final newExercise = Exercise(
      id: selectedExercise. id,
      name: selectedExercise.name,
      muscleGroups: selectedExercise. muscleGroups,
      sets: List. generate(
        selectedExercise.  defaultSets,
        (index) => ExerciseSet(
          setNumber: index + 1,
          targetReps: selectedExercise.  defaultReps,
          targetWeight: suggestedWeight,
          restSeconds: selectedExercise.defaultRestSeconds,
        ),
      ),
    );

    setState(() {
      final updatedExercises = List<Exercise>.from(_currentWorkout.exercises);
      updatedExercises.  add(newExercise);
      _currentWorkout = _currentWorkout.copyWith(exercises: updatedExercises);
      
      final allMuscleGroups = <String>{};
      for (var ex in updatedExercises) {
        if (ex.muscleGroups.  isNotEmpty) {
          allMuscleGroups.add(ex.muscleGroups.  first);
        }
      }
      _currentWorkout = _currentWorkout.copyWith(
        muscleGroups: allMuscleGroups.  toList(),
      );
    });

    // ✅ NEW: Update active workout immediately after adding exercise
    if (! _isEditingTemplate && ! _isPastWorkout) {
      workoutProvider.updateActiveWorkout(_currentWorkout);
    }

    // ✅ FIX BUG 1: Only show snackbar if weight > 0 (has history)
    if (suggestedWeight > 0 && ! _isEditingTemplate) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '💡 Suggested weight: ${suggestedWeight.toStringAsFixed(1)} lbs (based on history)',
          ),
          backgroundColor: AppColors.info,
          duration: const Duration(milliseconds: 1200),
        ),
      );
    }
  }
}

  void _addSet(int exerciseIndex) {
  final exercise = _currentWorkout.exercises[exerciseIndex];
  final lastSet = exercise.sets.isNotEmpty 
      ? exercise.sets.last 
      : ExerciseSet(
          setNumber: 1,
          targetReps:   10,
          targetWeight: 0,
          restSeconds: 90,
        );
  
  final newSet = ExerciseSet(
    setNumber: exercise.sets.length + 1,
    targetReps: lastSet.targetReps,
    targetWeight: lastSet.targetWeight,
    restSeconds: lastSet.restSeconds,
  );

  final updatedSets = List<ExerciseSet>.from(exercise.sets).. add(newSet);
  final updatedExercise = Exercise(
    id: exercise.id,
    name: exercise.name,
    muscleGroups: exercise.muscleGroups,
    sets: updatedSets,
    notes: exercise. notes,
  );

  final updatedExercises = List<Exercise>.from(_currentWorkout.  exercises);
  updatedExercises[exerciseIndex] = updatedExercise;

  setState(() {
    _currentWorkout = _currentWorkout.  copyWith(exercises: updatedExercises);
  });
  
  // ✅ NEW: Update active workout
  if (!_isEditingTemplate && !_isPastWorkout) {
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen:   false);
    workoutProvider.  updateActiveWorkout(_currentWorkout);
  }
}

  void _removeSet(int exerciseIndex, int setIndex) {
  final exercise = _currentWorkout.exercises[exerciseIndex];
  if (exercise.sets.length <= 1) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exercise must have at least 1 set'),
        duration: Duration(milliseconds: 800),
      ),
    );
    return;
  }

  final updatedSets = List<ExerciseSet>.from(exercise.sets);
  updatedSets.removeAt(setIndex);
  
  // Renumber the sets
  for (int i = 0; i < updatedSets.length; i++) {
    updatedSets[i] = ExerciseSet(
      setNumber: i + 1,
      targetReps: updatedSets[i].targetReps,
      actualReps: updatedSets[i].actualReps,
      targetWeight: updatedSets[i].targetWeight,
      actualWeight: updatedSets[i].actualWeight,
      completed: updatedSets[i].  completed,
      restSeconds: updatedSets[i].restSeconds,
    );
  }

  final updatedExercise = Exercise(
    id: exercise.  id,
    name: exercise.  name,
    muscleGroups: exercise. muscleGroups,
    sets: updatedSets,
    notes: exercise.notes,
  );

  final updatedExercises = List<Exercise>.from(_currentWorkout.exercises);
  updatedExercises[exerciseIndex] = updatedExercise;

  setState(() {
    _currentWorkout = _currentWorkout. copyWith(exercises: updatedExercises);
  });
  
  // ✅ NEW: Update active workout
  if (! _isEditingTemplate && !_isPastWorkout) {
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen:   false);
    workoutProvider. updateActiveWorkout(_currentWorkout);
  }
}

 void _deleteExercise(int exerciseIndex) {
  final exercise = _currentWorkout.exercises[exerciseIndex];
  
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Remove Exercise', style: AppTextStyles.h3()),
      content: Text(
        'Are you sure you want to remove "${exercise.name}" from this ${_isEditingTemplate ? 'template' : 'workout'}?',
        style: AppTextStyles.body(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              final updatedExercises = List<Exercise>.from(_currentWorkout.  exercises);
              updatedExercises.removeAt(exerciseIndex);
              _currentWorkout = _currentWorkout.copyWith(exercises: updatedExercises);
            });
            
            // ✅ NEW: Update active workout after deleting exercise
            if (!_isEditingTemplate && !_isPastWorkout) {
              final workoutProvider = Provider.of<WorkoutProvider>(context, listen:   false);
              workoutProvider. updateActiveWorkout(_currentWorkout);
            }
            
            Navigator.pop(dialogContext);
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${exercise.name} removed'),
                backgroundColor: AppColors.error,
                duration: const Duration(milliseconds: 800),
              ),
            );
          },
          style: TextButton.styleFrom(foregroundColor: AppColors. error),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
}

  void _addWorkoutNotes() {
    final notesController = TextEditingController(text: _currentWorkout.notes);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Workout Notes', style: AppTextStyles.h3()),
        content: TextField(
          controller: notesController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText:   'How did the workout feel?   Any observations?',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentWorkout = _currentWorkout.copyWith(
                  notes: notesController.  text.  trim().isEmpty 
                      ? null 
                      : notesController.text. trim(),
                );
              });
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger. of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notes saved'),
                  duration: Duration(milliseconds: 800),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final updatedExercises = List<Exercise>.from(_currentWorkout.exercises);
      final exercise = updatedExercises.  removeAt(oldIndex);
      updatedExercises.insert(newIndex, exercise);
      _currentWorkout = _currentWorkout.copyWith(exercises: updatedExercises);
    });
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exercise reordered'),
        duration: Duration(milliseconds: 600),
      ),
    );
  }

    void _saveAsTemplate() {
    if (_currentWorkout.exercises.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add exercises before saving template'),
          duration: Duration(milliseconds: 800),
        ),
      );
      return;
    }

    final nameController = TextEditingController(text: _currentWorkout.name);
    
    showDialog(
      context:   context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Save Workout Template', style: AppTextStyles.h3()),
        content: Column(
          mainAxisSize:  MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration:   const InputDecoration(
                labelText: 'Template Name',
                hintText: 'e.g., Push Day, Leg Day',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:   const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final templateName = nameController.text.trim();
              if (templateName.  isEmpty) {
                return;
              }

              final template = _currentWorkout.copyWith(
                id: const Uuid().v4(),
                name: templateName,
                status: WorkoutStatus.scheduled,
              );

              final workoutProvider = Provider.of<WorkoutProvider>(context, listen:  false);
              
              try {
                await workoutProvider.  saveTemplate(template);

                if (mounted) {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);

                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.  of(context).showSnackBar(
                        SnackBar(
                          content: Text('Template "$templateName" saved!   💾'),
                          backgroundColor: AppColors.success,
                          duration: const Duration(milliseconds: 800),
                        ),
                      );
                    }
                  });
                }
              } catch (e) {
                if (e.  toString().contains('DUPLICATE_NAME')) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger. of(context).showSnackBar(
                    SnackBar(
                      content: Text('A template named "$templateName" already exists! '),
                      backgroundColor: AppColors.  error,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to save template'),
                      backgroundColor: AppColors.error,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSaveTemplatePrompt(WorkoutProvider workoutProvider) {
    final nameController = TextEditingController(text: '');
    
    showDialog(
      context: context,
      builder:  (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.bookmark, color: AppColors.primary),
            const SizedBox(width:   8),
            Text('Save as Template?  ', style: AppTextStyles.h3()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Would you like to save this workout as a template for future use?',
              style:   AppTextStyles.body(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration:  const InputDecoration(
                labelText: 'Template Name',
                hintText: 'e.g., Push Day, Leg Day',
                prefixIcon: Icon(Icons.fitness_center),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed:  () async {
              final templateName = nameController.text.trim();
              if (templateName.  isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a template name'),
                    duration: Duration(milliseconds: 800),
                  ),
                );
                return;
              }

              final template = _currentWorkout.copyWith(
                id: const Uuid().v4(),
                name: templateName,
                status: WorkoutStatus.scheduled,
              );

              try {
                await workoutProvider.  saveTemplate(template);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger. of(context).showSnackBar(
                    SnackBar(
                      content: Text('Template "$templateName" saved!  💾'),
                      backgroundColor: AppColors.success,
                      duration: const Duration(milliseconds: 1200),
                    ),
                  );
                }
              } catch (e) {
                if (e. toString().contains('DUPLICATE_NAME')) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.  of(context).showSnackBar(
                    SnackBar(
                      content: Text('A template named "$templateName" already exists!'),
                      backgroundColor:   AppColors. error,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger. of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to save template'),
                      backgroundColor: AppColors.  error,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text('Save Template'),
          ),
        ],
      ),
    );
  }

void _showDurationInputDialog() {
  final durationController = TextEditingController(
    text: _manualDurationMinutes > 0 ? _manualDurationMinutes.toString() : '',
  );
  
  showDialog(
    context: context,
    barrierDismissible:  false,
    builder: (dialogContext) => AlertDialog(
      title:  Text('Workout Duration', style:  AppTextStyles.h3()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How long did this workout take?',
            style: AppTextStyles. body(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: durationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              hintText: 'e.g., 60',
              prefixIcon:  Icon(Icons.timer),
              suffixText: 'min',
            ),
            autofocus: true,
            onSubmitted: (_) {
              final duration = int.tryParse(durationController.text) ?? 0;
              if (duration > 0 && duration <= 600) {
                setState(() {
                  _manualDurationMinutes = duration;
                });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Duration set to $duration minutes'),
                    duration: const Duration(milliseconds: 800),
                  ),
                );
              }
            },
          ),
        ],
      ),
      actions: [
        // ✅ FIXED: Always show Cancel button
        TextButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            
            // ✅ Show warning if no duration set yet
            if (_manualDurationMinutes == 0) {
              final shouldExit = await showDialog<bool>(
                context: context,
                builder: (warningContext) => AlertDialog(
                  title: Text('Cancel Workout Log? ', style: AppTextStyles.h3()),
                  content: Text(
                    'A duration is required to log a completed workout. If you go back, this workout will not be saved.\n\nWhat would you like to do?',
                    style: AppTextStyles.body(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(warningContext, false),
                      child:  const Text('Enter Duration'),
                    ),
                    ElevatedButton(
                      onPressed:  () => Navigator.pop(warningContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );

              if (shouldExit == true && mounted) {
                // User chose to exit - go back to calendar
                Navigator.pop(context);
              } else if (mounted) {
                // User chose to enter duration - show dialog again
                _showDurationInputDialog();
              }
            }
            // If duration already set, just close dialog (existing behavior)
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:  () {
            final duration = int.tryParse(durationController.text) ?? 0;
            if (duration > 0 && duration <= 600) {
              setState(() {
                _manualDurationMinutes = duration;
              });
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Duration set to $duration minutes'),
                  duration: const Duration(milliseconds: 800),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid duration (1-600 minutes)'),
                  duration: Duration(milliseconds: 800),
                ),
              );
            }
          },
          child: const Text('Set'),
        ),
      ],
    ),
  );
}


  void _finishWorkout() {
    if (widget.workout?.isAssignedWorkout == true && widget.workout?. assignedWorkoutData != null) {
    final assignedProvider = Provider.of<AssignedWorkoutProvider>(context, listen: false);
    assignedProvider.completeAssignedWorkout(widget.workout!.id);
  }
  WorkoutNotificationService.cancelWorkoutNotification(); 

  final weightUnit = LocalStorageService.getSetting('weightUnit', defaultValue: 'lbs');
  
  final completedSets = _currentWorkout.exercises
      .expand((e) => e.sets)
      .where((s) => s.completed)
      .length;
  
  final totalSets = _currentWorkout.exercises
      .expand((e) => e.sets)
      .length;
  
  final totalVolume = _currentWorkout.exercises
      .expand((e) => e.sets)
      .where((s) => s.completed)
      .fold<double>(0, (sum, s) => sum + (s.actualWeight * s.actualReps));
  
  _timer?. cancel();
  
  if (mounted) {
    final durationMinutes = _isPastWorkout 
        ? _manualDurationMinutes 
        :   _elapsedSeconds ~/ 60;
    
    final completedWorkout = _currentWorkout.copyWith(
      status: WorkoutStatus.completed,
      durationMinutes: durationMinutes,
      totalVolume: totalVolume.  toInt(),
    );
    
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
    workoutProvider.saveCompletedWorkout(completedWorkout);
    
    final isQuickWorkout = _currentWorkout.name == 'Quick Workout';
    if (isQuickWorkout && _currentWorkout.exercises.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          _showSaveTemplatePrompt(workoutProvider);
        }
      });
    }
    
    Navigator.of(context).pop();
    
    final displayVolume = weightUnit == 'kg'
        ? (totalVolume * 0.453592).toInt()
        : totalVolume.  toInt();
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:   Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Workout Complete!   💪',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                if (_isPastWorkout)
                  Text('Duration: $durationMinutes min')
                else
                  Text('Duration: ${_formatTime(_elapsedSeconds)}'),
                Text('Sets: $completedSets / $totalSets'),
                Text('Volume: $displayVolume $weightUnit'),
                if (_achievedPRs. isNotEmpty)
                  Text('🏆 PRs: ${_achievedPRs.length}', 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(milliseconds:   2000),
            behavior: SnackBarBehavior.  floating,
          ),
        );
      }
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return PopScope(
  canPop: false,
  onPopInvoked: (bool didPop) async {
    if (didPop) return;
    
    if (mounted) {
      setState(() {
        _isNavigating = true;
      });
    }
    
    _timer?.cancel();
    
    final hasCompletedSets = _currentWorkout.exercises.any((e) => e.sets.any((s) => s.completed));
    final hasExercises = _currentWorkout.exercises. isNotEmpty;
    
    // ✅ Case 1: Template editing
    if (_isEditingTemplate && hasExercises) {
      final shouldExit = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Exit Template? ', style: AppTextStyles.h3()),
          content: Text(
            'Do you want to save this as a template?',
            style: AppTextStyles.body(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, 'stay');
              },
              child:  const Text('Stay'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, 'save_template');
              },
              child: const Text('Save Template'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, 'discard');
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      
      if (shouldExit == 'stay') {
        if (mounted) {
          setState(() {
            _isNavigating = false;
          });
        }
        return;
      } else if (shouldExit == 'save_template') {
        _saveAsTemplate();
        return;
      } else if (shouldExit == 'discard') {
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
    }
    
    // ✅ Case 2: Workout has started (timer running) - offer Keep Active
    else if (hasExercises && _workoutHasStarted) {
      final shouldExit = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Exit Workout?', style: AppTextStyles.h3()),
          content: Text(
            'Your workout is in progress. What would you like to do?',
            style: AppTextStyles.body(),
          ),
          actions:  [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, 'stay');
              },
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, 'keep_active');
              },
              child: const Text('Keep Active'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, 'cancel');
              },
              style:  TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Cancel Workout'),
            ),
          ],
        ),
      );
      
      if (shouldExit == 'stay') {
        if (mounted) {
          setState(() {
            _isNavigating = false;
          });
        }
        return;
      } else if (shouldExit == 'keep_active') {
        // Keep workout active - just exit
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      } else if (shouldExit == 'cancel') {
        // Cancel workout - clear active workout
        WorkoutNotificationService.cancelWorkoutNotification();
        final workoutProvider = Provider.of<WorkoutProvider>(context, listen:  false);
        await workoutProvider.clearActiveWorkout();
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
    }
    
    // ✅ Case 3: Workout NOT started but has exercises - warn about losing data
    else if (hasExercises && !_workoutHasStarted) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Discard Workout?', style: AppTextStyles.h3()),
          content: Text(
            'You have ${_currentWorkout.exercises.length} exercise(s) added.  Going back will remove all exercises.',
            style: AppTextStyles. body(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child:  const Text('Stay'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      
      if (shouldExit == true) {
        // Clear active workout and exit
        final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
        await workoutProvider.clearActiveWorkout();
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          setState(() {
            _isNavigating = false;
          });
        }
      }
      return;
    }
    
    // ✅ Case 4: No exercises, just exit
    else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  },
  child: Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon:  const Icon(Icons.arrow_back),
        onPressed: () {
          if (mounted) {
            setState(() {
              _isNavigating = true;
            });
          }
          Navigator.of(context).maybePop();
        },
      ),
      title: _isEditingTemplate
          ? Text('Build Template', style: AppTextStyles. h3())
          : _isPastWorkout
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_currentWorkout.name, style: AppTextStyles.h3()),
                    Text(
                      _manualDurationMinutes > 0 
                          ? '$_manualDurationMinutes min'
                          : 'Set duration',
                      style: AppTextStyles.caption(),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment:  CrossAxisAlignment.start,
                  children: [
                    Text(_currentWorkout.name, style: AppTextStyles.h3()),
                    Text(
                      _formatTime(_elapsedSeconds),
                      style: AppTextStyles.caption(),
                    ),
                  ],
                ),
      actions: [
        if (!_isEditingTemplate && !_isPastWorkout) ...[
          if (_isRunning)
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: _pauseWorkout,
            )
          else if (_currentWorkout.exercises.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed:  _resumeWorkout,
              tooltip: 'Resume Timer',
            ),
        ],
        
        if (! _isEditingTemplate && _isPastWorkout && _currentWorkout.exercises.isNotEmpty)
          IconButton(
            icon: const Icon(Icons. timer_outlined),
            onPressed: _showDurationInputDialog,
            tooltip: 'Change Duration',
            color: _manualDurationMinutes > 0 ? AppThemeManager.primaryColor : null,
          ),
        
        IconButton(
          icon: Icon(
            _currentWorkout.notes != null ?  Icons.note :  Icons.note_outlined,
            color: _currentWorkout.notes != null ?  AppThemeManager.primaryColor :   null,
          ),
          onPressed: _addWorkoutNotes,
          tooltip: 'Add Notes',
        ),
        
        if (_isEditingTemplate && _currentWorkout.exercises.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAsTemplate,
            tooltip: 'Save as Template',
            color:  AppThemeManager.primaryColor, 
          ),
        
        if (! _isEditingTemplate && _currentWorkout.exercises.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _showFinishWorkoutDialog,
            tooltip: 'Finish Workout',
            color:  AppThemeManager.primaryColor, 
          ),
      ],
    ),
    body: Column(
      children: [
        if (_isResting && _restingExerciseIndex != null)
          _buildRestTimerBanner(),
        Expanded(
          child: _currentWorkout.exercises.isEmpty
              ? _buildEmptyState()
              : ReorderableListView. builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _currentWorkout.exercises. length,
                  onReorder: _reorderExercises,
                  itemBuilder: (context, index) {
                    final exercise = _currentWorkout.exercises[index];
                    return Container(
                      key: ValueKey(exercise.id),
                      child: _buildExerciseCard(index),
                    );
                  },
                ),
        ),
      ],
    ),
    floatingActionButton:  _isNavigating 
    ? null 
    : FloatingActionButton.extended(
        onPressed: _addExercise,
        icon: const Icon(Icons.add),
        label: const Text('Add Exercise'),
        backgroundColor: AppThemeManager.primaryColor, // ✅ Dynamic
      ),
  ),
);
  }

  Widget _buildRestTimerBanner() {
  // Format rest time as MM:SS
  final minutes = _restSecondsRemaining ~/ 60;
  final seconds = _restSecondsRemaining % 60;
  final timeDisplay = '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
  
  return Container(
    width: double. infinity,
    color: AppColors.info,
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Row(
      children: [
        const Icon(Icons.timer, color: Colors.white),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rest Timer',
                style: AppTextStyles.body(color: Colors.white).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                timeDisplay,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _addRestTime,
          child: const Text('+30s', style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: _skipRest,
          child: const Text('Skip', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

  Widget _buildEmptyState() {
    return Center(
      child:  Column(
        mainAxisAlignment:  MainAxisAlignment.center,
        children: [
          Icon(
            Icons.  fitness_center,
            size: 80,
            color: AppColors.  textSecondaryLight.  withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _isEditingTemplate ?   'Build Your Template' :  'Start Your Workout',
            style:   AppTextStyles.h2(),
          ),
          const SizedBox(height: AppSpacing. sm),
          Text(
            'Add exercises to begin',
            style: AppTextStyles. body(color: AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }


  Widget _buildExerciseCard(int exerciseIndex) {
    final exercise = _currentWorkout.exercises[exerciseIndex];
    final allSetsCompleted = exercise.sets.every((set) => set.completed);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border(
          left: BorderSide(
            color: AppColors.getMuscleGroupColor(exercise.muscleGroups. first),
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing. md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:  CrossAxisAlignment.start,
                    children: [
                      Text(exercise.name, style: AppTextStyles.h3()),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        exercise.muscleGroups. join(', '),
                        style: AppTextStyles.caption(),
                      ),
                    ],
                  ),
                ),
                if (allSetsCompleted && ! _isEditingTemplate)
                  const Icon(Icons.check_circle, color: AppColors.success, size: 32),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.error,
                  onPressed: () => _deleteExercise(exerciseIndex),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Remove Exercise',
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                SizedBox(
                  width:  40,
                  child: Text('SET', style: AppTextStyles.caption()),
                ),
                Expanded(
                  child: Text('PREVIOUS', style: AppTextStyles.caption()),
                ),
                Expanded(
                  child: Text('WEIGHT', style: AppTextStyles.caption()),
                ),
                Expanded(
                  child: Text('REPS', style: AppTextStyles.caption()),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          
          ... exercise.sets.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final set = entry.value;
            return _buildSetRow(exerciseIndex, setIndex, set);
          }),
          
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _addSet(exerciseIndex),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('Add Set (${exercise.sets.length + 1})'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppThemeManager.primaryColor,
                  ),
                ),
                if (exercise.sets.length > 1) ...[
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => _removeSet(exerciseIndex, exercise.sets.length - 1),
                    icon: const Icon(Icons.remove, size: 18),
                    label: const Text('Remove Set'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(int exerciseIndex, int setIndex, ExerciseSet set) {
    final weightUnit = LocalStorageService.getSetting('weightUnit', defaultValue: 'lbs');
    
    final targetWeightDisplay = weightUnit == 'kg'
        ? (set.targetWeight * 0.453592).toStringAsFixed(1)
        : set.targetWeight.toStringAsFixed(1);
    
    final actualWeightDisplay = weightUnit == 'kg'
        ? (set.actualWeight * 0.453592).toStringAsFixed(1)
        : set.actualWeight.toStringAsFixed(1);

    final isPR = set.completed && _achievedPRs.contains(
      '${_currentWorkout.exercises[exerciseIndex].name}_$setIndex'
    );

    String?  prReason;
    if (isPR) {
      prReason = _getPRReason(
        _currentWorkout.exercises[exerciseIndex].name,
        set.actualWeight,
        set.actualReps,
      );
    }

    return InkWell(
      onTap: _isEditingTemplate 
          ? null 
          :  () {
              _showSetInputDialog(
                exerciseIndex,
                setIndex,
                set. completed ?  set.actualWeight : set.targetWeight,
                set.completed ? set.actualReps : set.targetReps,
                isEditing: set.completed,
              );
            },
      onLongPress: _isEditingTemplate || ! set.completed
          ? null
          : () => _showResetSetDialog(exerciseIndex, setIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration:  BoxDecoration(
          color:  isPR
              ? AppColors.warning. withOpacity(0.15)
              : set.completed
                  ? AppColors.success.withOpacity(0.1)
                  : null,
          border: isPR
              ? Border(
                  left: BorderSide(
                    color: AppColors.warning,
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width:  40,
                  child:  Row(
                    children: [
                      Text(
                        '${set.setNumber}',
                        style:  AppTextStyles.body(fontWeight: FontWeight.bold),
                      ),
                      if (isPR)
                        const Padding(
                          padding: EdgeInsets.only(left: 2),
                          child: Icon(
                            Icons.emoji_events,
                            size: 12,
                            color: AppColors.warning,
                          ),
                        ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: Text(
                    set.completed
                        ? '$actualWeightDisplay × ${set.actualReps}'
                        : '$targetWeightDisplay × ${set.targetReps}',
                    style: AppTextStyles.bodySmall(
                      color: set.completed
                          ? AppColors.textSecondaryLight
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                
                Expanded(
                  child: set.completed
                      ? Text(
                          '$actualWeightDisplay $weightUnit',
                          style:  TextStyle(
                            fontSize: 16,
                            fontWeight: isPR ? FontWeight.bold : FontWeight.w600,
                            color: isPR ? AppColors.warning : AppColors.textPrimaryLight,
                          ),
                        )
                      : Text(
                          targetWeightDisplay,
                          style: AppTextStyles.body(),
                        ),
                ),
                
                Expanded(
                  child: set.completed
                      ? Text(
                          '${set.actualReps}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:  isPR ? FontWeight.bold :  FontWeight.w600,
                            color: isPR ? AppColors.warning : AppColors.textPrimaryLight,
                          ),
                        )
                      : Text(
                          '${set.targetReps}',
                          style: AppTextStyles.body(),
                        ),
                ),
                
                SizedBox(
                  width:  40,
                  child:  _isEditingTemplate
                      ? const SizedBox. shrink()
                      : set.completed
                          ? Icon(
                              isPR ? Icons.emoji_events :  Icons.check_circle,
                              color: isPR ? AppColors.warning : AppColors.success,
                              size: isPR ? 20 : 24,
                            )
                          : const Icon(
                              Icons.check_circle_outline,
                              color: AppColors.textSecondaryLight,
                            ),
                ),
              ],
            ),
            
            if (isPR && prReason != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning. withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:  Row(
                  mainAxisSize:  MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size:  12,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      prReason,
                      style: const TextStyle(
                        fontSize:  11,
                        fontWeight: FontWeight.w600,
                        color: AppColors. warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showResetSetDialog(int exerciseIndex, int setIndex) {
    final exercise = _currentWorkout.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Reset Set ${setIndex + 1}', style: AppTextStyles.h3()),
        content: Text(
          'Do you want to reset this set?\n\n'
          'Current:  ${set.actualWeight. toStringAsFixed(1)} lbs × ${set.actualReps} reps',
          style: AppTextStyles.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final updatedSet = set.copyWith(
                actualReps: 0,
                actualWeight: 0.0,
                completed: false,
              );
              
              final updatedSets = List<ExerciseSet>.from(exercise.sets);
              updatedSets[setIndex] = updatedSet;
              
              final updatedExercise = Exercise(
                id: exercise.id,
                name: exercise.name,
                muscleGroups:  exercise.muscleGroups,
                sets: updatedSets,
                notes: exercise.notes,
              );
              
              final updatedExercises = List<Exercise>.from(_currentWorkout.exercises);
              updatedExercises[exerciseIndex] = updatedExercise;
              
              setState(() {
                _currentWorkout = _currentWorkout.copyWith(exercises: updatedExercises);
                _recalculatePRsForExercise(exerciseIndex);
              });
              
              Navigator.pop(dialogContext);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Set reset'),
                  duration: Duration(milliseconds: 800),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showSetInputDialog(
    int exerciseIndex,
    int setIndex,
    double defaultWeight,
    int defaultReps,
    {bool isEditing = false}
  ) {
    final weightUnit = LocalStorageService.getSetting('weightUnit', defaultValue:  'lbs');
    
    final displayWeight = weightUnit == 'kg' 
        ? (defaultWeight * 0.453592).toStringAsFixed(1)
        : defaultWeight.toStringAsFixed(1);
    
    final weightController = TextEditingController(text:  displayWeight);
    final repsController = TextEditingController(text: defaultReps.toString());
    
    showDialog(
      context:  context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isEditing 
              ? 'Edit Set ${setIndex + 1}'
              : 'Complete Set ${setIndex + 1}',
          style: AppTextStyles.h3(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEditing) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 16, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Editing completed set.  Long press to reset.',
                        style: AppTextStyles.caption(color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration:  InputDecoration(
                labelText:  'Weight ($weightUnit)',
                prefixIcon: const Icon(Icons.fitness_center),
                hintText: '135.5',
              ),
              autofocus: true,
              onSubmitted: (_) {
                FocusScope.of(dialogContext).nextFocus();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Reps',
                prefixIcon: Icon(Icons.repeat),
              ),
              onSubmitted: (_) {
                _submitSetInput(
                  dialogContext,
                  exerciseIndex,
                  setIndex,
                  weightController.text,
                  repsController.text,
                  weightUnit,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:  const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _submitSetInput(
                dialogContext,
                exerciseIndex,
                setIndex,
                weightController.text,
                repsController.text,
                weightUnit,
              );
            },
            child: Text(isEditing ? 'Update' : 'Done'),
          ),
        ],
      ),
    );
  }

  void _submitSetInput(
    BuildContext dialogContext,
    int exerciseIndex,
    int setIndex,
    String weightText,
    String repsText,
    String weightUnit,
  ) {
    var weight = double.tryParse(weightText) ?? 0;
    final reps = int.tryParse(repsText) ?? 0;
    
    if (weightUnit == 'kg') {
      weight = weight / 0.453592;
    }
    
    if (weight > 0 && reps > 0) {
      Navigator.pop(dialogContext);
      _completeSet(exerciseIndex, setIndex, reps, weight);
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid weight and reps'),
          duration:  Duration(milliseconds: 800),
        ),
      );
    }
  }

  void _showFinishWorkoutDialog() {
    final weightUnit = LocalStorageService.getSetting('weightUnit', defaultValue:  'lbs');
    
    final completedSets = _currentWorkout.exercises
        .expand((e) => e.sets)
        .where((s) => s.completed)
        .length;
    
    final totalSets = _currentWorkout.exercises
        .expand((e) => e.sets)
        .length;
    
    final totalVolume = _currentWorkout.exercises
        .expand((e) => e.sets)
        .where((s) => s.completed)
        .fold<double>(0, (sum, s) => sum + (s.actualWeight * s.actualReps));
    
    final displayVolume = weightUnit == 'kg'
        ? (totalVolume * 0.453592).toInt()
        : totalVolume. toInt();
    
    if (_isPastWorkout && _manualDurationMinutes == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set workout duration before finishing'),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 2),
        ),
      );
      _showDurationInputDialog();
      return;
    }
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Finish Workout? ', style: AppTextStyles.h3()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isPastWorkout)
              Text('Duration: $_manualDurationMinutes min')
            else
              Text('Duration: ${_formatTime(_elapsedSeconds)}'),
            Text('Sets: $completedSets / $totalSets'),
            Text('Total Volume: $displayVolume $weightUnit'),
            if (_achievedPRs.isNotEmpty)
              Text(
                '🏆 Personal Records: ${_achievedPRs.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:  const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _finishWorkout();
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }
}