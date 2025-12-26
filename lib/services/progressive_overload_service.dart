import 'package:reprise/shared/models/workout.dart';

class ProgressiveOverloadService {
  // Calculate suggested weight based on previous performance
  static double calculateSuggestedWeight({
    required String exerciseId,
    required List<Workout> workoutHistory,
    required int targetReps,
  }) {
    // Find all previous instances of this exercise
    final previousSets = <ExerciseSet>[];
    
    for (var workout in workoutHistory) {
      for (var exercise in workout.exercises) {
        if (exercise.id == exerciseId || exercise.name. toLowerCase().contains(exerciseId.toLowerCase())) {
          previousSets. addAll(exercise.sets. where((s) => s.completed));
        }
      }
    }

    if (previousSets.isEmpty) {
      return 0; // No history, user will enter first time
    }

    // Sort by date (most recent first)
    previousSets.sort((a, b) => b.setNumber.compareTo(a.setNumber));

    // Get the most recent completed set
    final lastSet = previousSets.first;
    
    // Progressive overload rules:
    // 1. If last time hit target reps easily, increase weight by 5%
    // 2. If last time barely hit target reps, keep same weight
    // 3. If last time failed to hit target reps, decrease by 5%
    
    if (lastSet.actualReps >= targetReps + 2) {
      // Hit reps with 2+ extra, increase weight
      return lastSet.actualWeight * 1.05;
    } else if (lastSet.actualReps >= targetReps) {
      // Hit target reps, keep weight
      return lastSet.actualWeight;
    } else {
      // Failed to hit reps, decrease slightly
      return lastSet.actualWeight * 0.95;
    }
  }

  // Check if current performance is a Personal Record
  static bool isPR({
    required String exerciseId,
    required double weight,
    required int reps,
    required List<Workout> workoutHistory,
  }) {
    for (var workout in workoutHistory) {
      for (var exercise in workout.exercises) {
        if (exercise.id == exerciseId || exercise.name == exerciseId) {
          for (var set in exercise.sets) {
            if (set.completed) {
              // Check if previous weight was higher or equal with same/more reps
              if (set. actualWeight >= weight && set.actualReps >= reps) {
                return false;
              }
            }
          }
        }
      }
    }
    return true;
  }

  // Get exercise history summary
  static ExerciseHistory getExerciseHistory({
    required String exerciseName,
    required List<Workout> workoutHistory,
  }) {
    final sessions = <ExerciseSession>[];
    
    for (var workout in workoutHistory) {
      for (var exercise in workout.exercises) {
        if (exercise.name == exerciseName) {
          final completedSets = exercise.sets. where((s) => s.completed).toList();
          if (completedSets.isNotEmpty) {
            sessions.add(ExerciseSession(
              date: workout.date,
              sets: completedSets,
              totalVolume: completedSets.fold(
                0.0,
                (sum, s) => sum + (s.actualWeight * s.actualReps),
              ),
            ));
          }
        }
      }
    }

    sessions.sort((a, b) => b.date.compareTo(a.date));

    // Calculate PRs
    double maxWeight = 0;
    int maxReps = 0;
    double maxVolume = 0;

    for (var session in sessions) {
      if (session.totalVolume > maxVolume) {
        maxVolume = session. totalVolume;
      }
      for (var set in session.sets) {
        if (set.actualWeight > maxWeight) {
          maxWeight = set.actualWeight;
        }
        if (set.actualReps > maxReps) {
          maxReps = set. actualReps;
        }
      }
    }

    return ExerciseHistory(
      exerciseName: exerciseName,
      sessions: sessions,
      maxWeight: maxWeight,
      maxReps: maxReps,
      maxVolume: maxVolume,
      totalSessions: sessions.length,
    );
  }

  // Calculate volume progress percentage
  static double calculateVolumeProgress({
    required List<Workout> workoutHistory,
    required int daysToCompare,
  }) {
    if (workoutHistory.isEmpty) return 0;

    final now = DateTime.now();
    final currentPeriodStart = now.subtract(Duration(days: daysToCompare));
    final previousPeriodStart = now.subtract(Duration(days: daysToCompare * 2));

    double currentVolume = 0;
    double previousVolume = 0;

    for (var workout in workoutHistory) {
      if (workout.date. isAfter(currentPeriodStart)) {
        currentVolume += workout.totalVolume;
      } else if (workout.date.isAfter(previousPeriodStart) && 
                 workout.date.isBefore(currentPeriodStart)) {
        previousVolume += workout.totalVolume;
      }
    }

    if (previousVolume == 0) return 0;
    
    return ((currentVolume - previousVolume) / previousVolume) * 100;
  }
}

class ExerciseHistory {
  final String exerciseName;
  final List<ExerciseSession> sessions;
  final double maxWeight;
  final int maxReps;
  final double maxVolume;
  final int totalSessions;

  ExerciseHistory({
    required this.exerciseName,
    required this.sessions,
    required this.maxWeight,
    required this.maxReps,
    required this.maxVolume,
    required this.totalSessions,
  });
}

class ExerciseSession {
  final DateTime date;
  final List<ExerciseSet> sets;
  final double totalVolume;

  ExerciseSession({
    required this.date,
    required this.sets,
    required this.totalVolume,
  });
}