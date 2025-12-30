import 'package:flutter/material.dart';
import 'dart:async';
import 'package:reprise/shared/models/workout.dart';
import 'package:reprise/services/local_storage_service.dart';
import 'package:uuid/uuid.dart';
import 'package:reprise/shared/models/assigned_workout.dart';

class WorkoutProvider extends ChangeNotifier {
  final Map<DateTime, List<Workout>> _workouts = {};
  final List<Workout> _templates = [];
  Workout? _activeWorkout;
  bool _isInitialized = false;

  // Track active workout state
  DateTime? _activeWorkoutStartTime;
  int _activeWorkoutElapsedSeconds = 0;
  Timer? _activeWorkoutTimer;

  WorkoutProvider() {
    _loadData();
    _startActiveWorkoutTimer();
  }

  Map<DateTime, List<Workout>> get workouts => _workouts;
  List<Workout> get templates => _templates;
  Workout? get activeWorkout => _activeWorkout;
  int get activeWorkoutElapsedSeconds => _activeWorkoutElapsedSeconds;
  DateTime? get activeWorkoutStartTime => _activeWorkoutStartTime;
  
  // Start active workout timer
  void _startActiveWorkoutTimer() {
    _activeWorkoutTimer?.cancel();
    _activeWorkoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeWorkoutStartTime != null) {
        final elapsed = DateTime.now().difference(_activeWorkoutStartTime!);
        _activeWorkoutElapsedSeconds = elapsed.inSeconds;
        notifyListeners();
      }
    });
  }

  // Set active workout with proper start time preservation
  Future<void> setActiveWorkout(Workout workout, {DateTime? startTime, int? elapsedSeconds}) async {
    _activeWorkout = workout;
    
    // Use provided start time or calculate from elapsed seconds
    if (startTime != null) {
      _activeWorkoutStartTime = startTime;
    } else if (elapsedSeconds != null) {
      _activeWorkoutStartTime = DateTime.now().subtract(Duration(seconds: elapsedSeconds));
    } else {
      _activeWorkoutStartTime = DateTime.now();
    }
    
    // Calculate elapsed time
    final elapsed = DateTime.now().difference(_activeWorkoutStartTime!);
    _activeWorkoutElapsedSeconds = elapsed.inSeconds;
    
    // Save to persistent storage
    await LocalStorageService.saveSetting('activeWorkout', workout.toJson());
    await LocalStorageService.saveSetting(
      'activeWorkoutStartTime',
      _activeWorkoutStartTime! .toIso8601String(),
    );
    
    debugPrint('✅ Active workout set: ${workout.name}, Start time: $_activeWorkoutStartTime, Elapsed:  $_activeWorkoutElapsedSeconds seconds');
    notifyListeners();
  }

  // Get workouts for a specific date including assigned workouts
  List<Workout> getWorkoutsForDateWithAssigned(DateTime date, List<AssignedWorkout> assignedWorkouts) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    // Get regular workouts
    final regularWorkouts = getWorkoutsForDay(date);
    
    // Convert assigned workouts to Workout objects for the calendar
    final assignedAsWorkouts = assignedWorkouts. where((assigned) {
      final assignedDate = DateTime(
        assigned. dueDate.year,
        assigned.dueDate.month,
        assigned.dueDate.day,
      );
      return assignedDate.isAtSameMomentAs(dateOnly) && 
             assigned.status == AssignedWorkoutStatus.pending;
    }).map((assigned) {
      return Workout(
        id: assigned.id,
        name: assigned.workoutName,
        date: assigned.dueDate,
        muscleGroups: ['Assigned'],
        status: WorkoutStatus. scheduled,
        exercises: [],
        isAssignedWorkout: true,
        assignedWorkoutData: assigned,
      );
    }).toList();
    
    // Filter out duplicates
    final filteredRegularWorkouts = regularWorkouts. where((workout) {
      return !assignedAsWorkouts.any((assigned) => assigned.id == workout.id);
    }).toList();
    
    return [... filteredRegularWorkouts, ... assignedAsWorkouts];
  }

  // Update active workout (when sets are completed)
  Future<void> updateActiveWorkout(Workout workout) async {
    _activeWorkout = workout;
    
    // Save updated state
    await LocalStorageService.saveSetting('activeWorkout', workout.toJson());
    
    debugPrint('✅ Active workout updated');
    notifyListeners();
  }

  // Clear active workout
  Future<void> clearActiveWorkout() async {
    _activeWorkout = null;
    _activeWorkoutStartTime = null;
    _activeWorkoutElapsedSeconds = 0;
    
    // Remove from persistent storage
    await LocalStorageService.saveSetting('activeWorkout', null);
    await LocalStorageService.saveSetting('activeWorkoutStartTime', null);
    
    debugPrint('✅ Active workout cleared');
    notifyListeners();
  }

  // Load active workout on app start
  Future<void> _loadActiveWorkout() async {
    try {
      final activeWorkoutJson = LocalStorageService.getSetting('activeWorkout');
      final startTimeString = LocalStorageService.getSetting('activeWorkoutStartTime');
      
      if (activeWorkoutJson != null && activeWorkoutJson is Map<String, dynamic>) {
        _activeWorkout = Workout.fromJson(activeWorkoutJson);
        
        if (startTimeString != null && startTimeString is String) {
          _activeWorkoutStartTime = DateTime.parse(startTimeString);
          
          // Calculate elapsed time
          final elapsed = DateTime.now().difference(_activeWorkoutStartTime!);
          _activeWorkoutElapsedSeconds = elapsed.inSeconds;
        }
        
        debugPrint('✅ Restored active workout: ${_activeWorkout! .name}');
      }
    } catch (e) {
      debugPrint('❌ Error loading active workout: $e');
    }
  }

  // Load data properly
  Future<void> _loadData() async {
    if (_isInitialized) return;
    
    await _loadWorkouts();
    await _loadTemplates();
    await _loadActiveWorkout();
    
    _isInitialized = true;
    notifyListeners();
  }

  // Get all workouts sorted by date
  List<Workout> getAllWorkouts() {
    final allWorkouts = <Workout>[];
    for (var workoutList in _workouts.values) {
      allWorkouts.addAll(workoutList);
    }
    allWorkouts.sort((a, b) => b.date.compareTo(a. date));
    return allWorkouts;
  }

  // Get recent workouts (last 10)
  List<Workout> getRecentWorkouts({int limit = 10}) {
    return getAllWorkouts().take(limit).toList();
  }

  // Get next scheduled workout
  Workout? getNextScheduledWorkout() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final futureWorkouts = getAllWorkouts()
        .where((w) => w.status == WorkoutStatus.scheduled)
        .where((w) {
          final workoutDate = DateTime(w.date.year, w.date.month, w.date. day);
          return workoutDate.isAfter(today) || workoutDate.isAtSameMomentAs(today);
        })
        .toList();
    
    futureWorkouts.sort((a, b) => a.date.compareTo(b. date));
    return futureWorkouts.isNotEmpty ? futureWorkouts. first : null;
  }

  // Get workouts for specific day
  List<Workout> getWorkoutsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _workouts[normalizedDay] ?? [];
  }

  // Get current streak
  int getCurrentStreak() {
    final now = DateTime.now();
    int streak = 0;
    
    for (int i = 0; i < 365; i++) {
      final checkDate = now.subtract(Duration(days: i));
      final workouts = getWorkoutsForDay(checkDate);
      final hasCompletedWorkout = workouts. any((w) => w.status == WorkoutStatus.completed);
      
      if (hasCompletedWorkout) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    
    return streak;
  }

  // Get this week's completed workouts count
  int getThisWeekCount() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    int count = 0;
    
    for (int i = 0; i < 7; i++) {
      final checkDate = startOfWeek.add(Duration(days: i));
      final workouts = getWorkoutsForDay(checkDate);
      if (workouts.any((w) => w.status == WorkoutStatus.completed)) {
        count++;
      }
    }
    
    return count;
  }

  // Load workouts from storage
  Future<void> _loadWorkouts() async {
    debugPrint('📂 Loading workouts from Hive.. .');
    
    _workouts.clear();
    final allData = await LocalStorageService.getAllWorkouts();
    
    int loadedCount = 0;
    for (var entry in allData. entries) {
      final key = entry.key;
      final data = entry.value;
      
      if (key. startsWith('template_')) continue;
      
      try {
        final workout = Workout.fromJson(data);
        _addWorkoutToMemory(workout);
        loadedCount++;
      } catch (e) {
        debugPrint('❌ Error loading workout with key $key: $e');
      }
    }
    
    debugPrint('✅ Loaded $loadedCount workouts');
  }

  // Load templates from storage
  Future<void> _loadTemplates() async {
    debugPrint('📂 Loading templates from Hive.. .');
    
    _templates. clear();
    final allData = await LocalStorageService.getAllWorkouts();
    
    int loadedCount = 0;
    for (var entry in allData. entries) {
      final key = entry.key;
      final data = entry.value;
      
      if (! key.startsWith('template_')) continue;
      
      try {
        final template = Workout.fromJson(data);
        _templates.add(template);
        loadedCount++;
      } catch (e) {
        debugPrint('❌ Error loading template with key $key: $e');
      }
    }
    
    debugPrint('✅ Loaded $loadedCount templates');
  }

  // Add workout to memory
  void _addWorkoutToMemory(Workout workout) {
    final normalizedDate = DateTime(
      workout.date.year,
      workout.date.month,
      workout.date.day,
    );
    
    if (_workouts[normalizedDate] == null) {
      _workouts[normalizedDate] = [];
    }
    
    _workouts[normalizedDate]!.removeWhere((w) => w.id == workout.id);
    _workouts[normalizedDate]!.add(workout);
  }

  // Save workout (completed)
  Future<void> saveCompletedWorkout(Workout workout) async {
    debugPrint('💾 Saving completed workout: ${workout.name}');
    
    final completedWorkout = workout.copyWith(
      status: WorkoutStatus.completed,
    );
    
    _addWorkoutToMemory(completedWorkout);
    await LocalStorageService.saveWorkout(completedWorkout. id, completedWorkout.toJson());
    
    debugPrint('✅ Workout saved to Hive with key: ${completedWorkout.id}');
    
    // Clear active workout when completing
    await clearActiveWorkout();
    
    notifyListeners();
  }

  // Schedule workout
  Future<void> scheduleWorkout(Workout workout) async {
    debugPrint('📅 Scheduling workout: ${workout.name}');
    
    _addWorkoutToMemory(workout);
    await LocalStorageService.saveWorkout(workout.id, workout.toJson());
    
    debugPrint('✅ Workout scheduled');
    
    notifyListeners();
  }

  // Delete workout
  Future<void> deleteWorkout(String workoutId, DateTime date) async {
    debugPrint('🗑️ Deleting workout: $workoutId');
    
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    if (_workouts[normalizedDate] != null) {
      _workouts[normalizedDate]!. removeWhere((w) => w.id == workoutId);
      
      if (_workouts[normalizedDate]!.isEmpty) {
        _workouts.remove(normalizedDate);
      }
    }
    
    await LocalStorageService.deleteWorkout(workoutId);
    
    debugPrint('✅ Workout deleted');
    
    notifyListeners();
  }

  // Clear all data including measurements
  Future<void> clearAllData() async {
    debugPrint('🗑️ Clearing all data.. .');
    
    // Clear in-memory data
    _workouts.clear();
    _templates.clear();
    await clearActiveWorkout();
    
    // Clear from Hive
    await LocalStorageService.clearAllWorkouts();
    
    // Clear measurements
    await LocalStorageService. saveSetting('measurements', []);
    
    debugPrint('✅ All data cleared (workouts, templates, measurements, active workout)');
    
    notifyListeners();
  }

  // Save template with duplicate name check
  Future<void> saveTemplate(Workout template) async {
    debugPrint('💾 Saving template: ${template.name}');
    
    // Check if template with same name already exists (case-insensitive)
    final duplicates = _templates.where((t) => 
      t.name.trim().toLowerCase() == template.name.trim().toLowerCase() && 
      t.id != template.id
    ).toList();
    
    if (duplicates.isNotEmpty) {
      debugPrint('❌ Template with name "${template.name}" already exists');
      throw Exception('DUPLICATE_NAME');
    }
    
    // Always generate a new ID for new templates
    final isNewTemplate = ! _templates.any((t) => t.id == template.id);
    
    final templateToSave = template.copyWith(
      id: isNewTemplate ?  const Uuid().v4() : template.id,
      status: WorkoutStatus.scheduled,
      date: DateTime.now(),
    );
    
    // Remove old version if updating
    _templates.removeWhere((t) => t.id == templateToSave.id);
    _templates.add(templateToSave);
    
    await LocalStorageService.saveWorkout(
      'template_${templateToSave.id}',
      templateToSave.toJson(),
    );
    
    debugPrint('✅ Template saved with key: template_${templateToSave.id}');
    
    notifyListeners();
  }

  // Delete template
  Future<void> deleteTemplate(String templateId) async {
    debugPrint('🗑️ Deleting template:  $templateId');
    
    _templates.removeWhere((t) => t.id == templateId);
    await LocalStorageService.deleteWorkout('template_$templateId');
    
    debugPrint('✅ Template deleted');
    
    notifyListeners();
  }

  // ✅ FIXED: Create workout from template without copyWith
  Workout createWorkoutFromTemplate(Workout template) {
    return Workout(
      id: const Uuid().v4(),
      name: template.name,
      date: DateTime.now(),
      muscleGroups: template.muscleGroups,
      status: WorkoutStatus.inProgress,
      isAssignedWorkout: false,
      exercises: template.exercises. map((exercise) {
        return Exercise(
          id: '${template.id}_${exercise.name}_${DateTime.now().millisecondsSinceEpoch}',
          name: exercise. name,
          muscleGroups: exercise.muscleGroups,
          sets: exercise.sets. map((set) {
            return ExerciseSet(
              setNumber: set.setNumber,
              targetWeight: set.targetWeight,
              targetReps: set.targetReps,
              actualWeight: set.targetWeight,
              actualReps:  0,
            );
          }).toList(),
        );
      }).toList(),
      notes: template.notes,
    );
  }

  // Get total PRs count
  int getTotalPRs() {
    int totalPRs = 0;
    final allWorkouts = getAllWorkouts()
        .where((w) => w.status == WorkoutStatus.completed)
        .toList();

    // Sort by date (oldest first)
    allWorkouts.sort((a, b) => a.date.compareTo(b. date));

    // Track PRs per exercise
    final Map<String, List<Map<String, dynamic>>> exerciseHistory = {};

    for (var workout in allWorkouts) {
      for (var exercise in workout.exercises) {
        // Find best set in this workout
        ExerciseSet? bestSet;
        
        for (var set in exercise. sets) {
          if (set.completed) {
            if (bestSet == null ||
                set.actualWeight > bestSet.actualWeight ||
                (set.actualWeight == bestSet.actualWeight && set. actualReps > bestSet.actualReps)) {
              bestSet = set;
            }
          }
        }

        if (bestSet != null) {
          // Check if this is a PR
          if (! exerciseHistory. containsKey(exercise.name)) {
            exerciseHistory[exercise.name] = [];
            totalPRs++; // First time doing this exercise
          } else {
            final history = exerciseHistory[exercise.name]!;
            final lastBest = history.last;
            
            if (bestSet.actualWeight > lastBest['weight'] ||
                (bestSet. actualWeight == lastBest['weight'] && bestSet.actualReps > lastBest['reps'])) {
              totalPRs++; // New PR
            }
          }

          exerciseHistory[exercise.name]! .add({
            'weight': bestSet.actualWeight,
            'reps': bestSet. actualReps,
          });
        }
      }
    }

    return totalPRs;
  }

  // Add scheduled workout
  Future<void> addScheduledWorkout(Workout workout) async {
    debugPrint('📅 Adding scheduled workout:  ${workout.name}');
    
    final scheduledWorkout = workout.copyWith(
      status: WorkoutStatus.scheduled,
    );
    
    _addWorkoutToMemory(scheduledWorkout);
    await LocalStorageService.saveWorkout(scheduledWorkout.id, scheduledWorkout.toJson());
    
    debugPrint('✅ Scheduled workout added');
    
    notifyListeners();
  }

  // Update scheduled workout
  Future<void> updateScheduledWorkout(Workout workout) async {
    debugPrint('📝 Updating scheduled workout: ${workout.name}');
    
    _addWorkoutToMemory(workout);
    await LocalStorageService.saveWorkout(workout. id, workout.toJson());
    
    debugPrint('✅ Scheduled workout updated');
    
    notifyListeners();
  }

  @override
  void dispose() {
    _activeWorkoutTimer?.cancel();
    super.dispose();
  }
}