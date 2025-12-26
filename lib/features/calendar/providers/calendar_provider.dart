import 'package:flutter/material.dart';
import 'package:reprise/shared/models/workout.dart';
import 'package:reprise/services/local_storage_service.dart';

class CalendarProvider extends ChangeNotifier {
  final Map<DateTime, List<Workout>> _workouts = {};

  CalendarProvider() {
    _loadWorkouts();
  }

  Map<DateTime, List<Workout>> get workouts => _workouts;

  List<Workout> getWorkoutsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _workouts[normalizedDay] ?? [];
  }

  // Load workouts from local storage
  void _loadWorkouts() {
    final savedWorkouts = LocalStorageService. getAllWorkouts();
    
    if (savedWorkouts.isEmpty) {
      // First time - initialize with mock data
      _initializeMockData();
    } else {
      // Load from storage
      for (var entry in savedWorkouts. entries) {
        try {
          final workout = Workout.fromJson(entry.value);
          _addWorkoutToMemory(workout);
        } catch (e) {
          debugPrint('Error loading workout: $e');
        }
      }
      notifyListeners();
    }
  }

  // Add workout to memory only (no save)
  void _addWorkoutToMemory(Workout workout) {
    final normalizedDate = DateTime(
      workout.date.year,
      workout.date.month,
      workout.date.day,
    );
    
    if (_workouts[normalizedDate] == null) {
      _workouts[normalizedDate] = [];
    }
    _workouts[normalizedDate]! .add(workout);
  }

  // Add workout and save to storage
  Future<void> addWorkout(Workout workout) async {
    _addWorkoutToMemory(workout);
    await _saveWorkout(workout);
    notifyListeners();
  }

  // Update workout
  Future<void> updateWorkout(Workout workout) async {
    final normalizedDate = DateTime(
      workout.date.year,
      workout.date.month,
      workout.date.day,
    );
    
    final workouts = _workouts[normalizedDate];
    if (workouts != null) {
      final index = workouts.indexWhere((w) => w.id == workout.id);
      if (index != -1) {
        workouts[index] = workout;
        await _saveWorkout(workout);
        notifyListeners();
      }
    }
  }

  // Delete workout
  Future<void> deleteWorkout(String workoutId, DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    _workouts[normalizedDate]?. removeWhere((w) => w.id == workoutId);
    
    if (_workouts[normalizedDate]?.isEmpty ??  false) {
      _workouts.remove(normalizedDate);
    }
    
    // Delete from storage
    await LocalStorageService.deleteWorkout(workoutId);
    notifyListeners();
  }

  // Save workout to storage
  Future<void> _saveWorkout(Workout workout) async {
    await LocalStorageService.saveWorkout(workout.id, workout.toJson());
  }

  // Initialize mock data
  void _initializeMockData() {
    final now = DateTime.now();
    
    final mockWorkouts = [
      Workout(
        id: '1',
        name: 'Push Day',
        date: now.subtract(const Duration(days: 6)),
        muscleGroups:  ['Chest', 'Shoulders', 'Triceps'],
        durationMinutes: 65,
        totalVolume: 12450,
        status: WorkoutStatus.completed,
      ),
      Workout(
        id: '2',
        name: 'Pull Day',
        date: now.subtract(const Duration(days: 5)),
        muscleGroups: ['Back', 'Biceps'],
        durationMinutes: 58,
        totalVolume: 11200,
        status: WorkoutStatus.completed,
      ),
      Workout(
        id: '3',
        name: 'Leg Day',
        date: now. subtract(const Duration(days: 4)),
        muscleGroups: ['Legs'],
        durationMinutes:  75,
        totalVolume: 18200,
        status: WorkoutStatus.completed,
      ),
      Workout(
        id: '4',
        name: 'Push Day',
        date: now. subtract(const Duration(days: 3)),
        muscleGroups: ['Chest', 'Shoulders'],
        status: WorkoutStatus.missed,
      ),
      Workout(
        id: '5',
        name: 'Pull Day',
        date: now.subtract(const Duration(days: 2)),
        muscleGroups:  ['Back', 'Biceps'],
        durationMinutes: 62,
        totalVolume: 11800,
        status: WorkoutStatus.completed,
      ),
      Workout(
        id: '6',
        name: 'Leg Day',
        date: now. subtract(const Duration(days: 1)),
        muscleGroups: ['Legs'],
        durationMinutes: 70,
        totalVolume: 17900,
        status: WorkoutStatus.completed,
      ),
      Workout(
        id: '7',
        name: 'Rest Day',
        date: now,
        muscleGroups: ['Rest'],
        status: WorkoutStatus.completed,
      ),
      Workout(
        id: '8',
        name: 'Push Day',
        date: now. add(const Duration(days: 1)),
        muscleGroups:  ['Chest', 'Shoulders', 'Triceps'],
        status: WorkoutStatus.scheduled,
      ),
      Workout(
        id: '9',
        name: 'Pull Day',
        date: now.add(const Duration(days: 2)),
        muscleGroups:  ['Back', 'Biceps'],
        status: WorkoutStatus.scheduled,
      ),
      Workout(
        id: '10',
        name: 'Leg Day',
        date:  now.add(const Duration(days: 3)),
        muscleGroups: ['Legs'],
        status: WorkoutStatus.scheduled,
      ),
      Workout(
        id: '11',
        name: 'Upper Body',
        date: now.add(const Duration(days: 5)),
        muscleGroups:  ['Chest', 'Back', 'Shoulders'],
        status: WorkoutStatus.scheduled,
      ),
      Workout(
        id: '12',
        name: 'Arms & Core',
        date: now.add(const Duration(days: 6)),
        muscleGroups:  ['Arms', 'Core'],
        status: WorkoutStatus.scheduled,
      ),
    ];

    for (var workout in mockWorkouts) {
      _addWorkoutToMemory(workout);
      _saveWorkout(workout);
    }
    
    notifyListeners();
  }
}