import 'package:flutter/material.dart';

class Workout {
  final String id;
  final String name;
  final DateTime date;
  final List<String> muscleGroups;
  final int durationMinutes;
  final int totalVolume;
  final WorkoutStatus status;
  final List<Exercise> exercises;
  final String? notes;

  Workout({
    required this.id,
    required this. name,
    required this.date,
    required this.muscleGroups,
    this.durationMinutes = 0,
    this.totalVolume = 0,
    this. status = WorkoutStatus.scheduled,
    this.exercises = const [],
    this.notes,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'muscleGroups': muscleGroups,
      'durationMinutes': durationMinutes,
      'totalVolume': totalVolume,
      'status': status.toString(),
      'exercises': exercises. map((e) => e.toJson()).toList(),
      'notes': notes,
    };
  }

  // Create from JSON
  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'],
      name: json['name'],
      date: DateTime.parse(json['date']),
      muscleGroups: List<String>.from(json['muscleGroups']),
      durationMinutes: json['durationMinutes'] ?? 0,
      totalVolume: json['totalVolume'] ?? 0,
      status: WorkoutStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse:  () => WorkoutStatus.scheduled,
      ),
      exercises: json['exercises'] != null
          ?  (json['exercises'] as List).map((e) => Exercise.fromJson(e)).toList()
          : [],
      notes: json['notes'],
    );
  }

  // Copy with method
  Workout copyWith({
    String? id,
    String? name,
    DateTime? date,
    List<String>?  muscleGroups,
    int? durationMinutes,
    int? totalVolume,
    WorkoutStatus? status,
    List<Exercise>? exercises,
    String? notes,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalVolume: totalVolume ?? this.totalVolume,
      status: status ?? this.status,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
    );
  }
}

enum WorkoutStatus {
  scheduled,
  completed,
  missed,
  inProgress,
}

class Exercise {
  final String id;
  final String name;
  final List<String> muscleGroups;
  final List<ExerciseSet> sets;
  final String? notes;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroups,
    this.sets = const [],
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'muscleGroups': muscleGroups,
      'sets': sets.map((s) => s.toJson()).toList(),
      'notes': notes,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      muscleGroups: List<String>.from(json['muscleGroups']),
      sets: json['sets'] != null
          ?  (json['sets'] as List).map((s) => ExerciseSet.fromJson(s)).toList()
          : [],
      notes: json['notes'],
    );
  }
}

class ExerciseSet {
  final int setNumber;
  final int targetReps;
  final double targetWeight;
  final int actualReps;
  final double actualWeight;
  final bool completed;
  final int restSeconds;

  ExerciseSet({
    required this.setNumber,
    this.targetReps = 0,
    this.targetWeight = 0.0,  // ✅ Changed to 0.0
    this.actualReps = 0,
    this.actualWeight = 0.0,  // ✅ Changed to 0.0
    this.completed = false,
    this.restSeconds = 90,
  });

  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'targetReps': targetReps,
      'targetWeight': targetWeight,
      'actualReps':  actualReps,
      'actualWeight': actualWeight,
      'completed': completed,
      'restSeconds': restSeconds,
    };
  }

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      setNumber: json['setNumber'] ?? 1,
      targetReps: json['targetReps'] ?? 0,
      targetWeight: (json['targetWeight'] ??  0).toDouble(),  // ✅ Ensure double
      actualReps: json['actualReps'] ?? 0,
      actualWeight: (json['actualWeight'] ?? 0).toDouble(),  // ✅ Ensure double
      completed:  json['completed'] ?? false,
      restSeconds: json['restSeconds'] ?? 90,
    );
  }

  ExerciseSet copyWith({
    int? setNumber,
    int? targetReps,
    double? targetWeight,
    int?  actualReps,
    double?  actualWeight,
    bool? completed,
    int? restSeconds,
  }) {
    return ExerciseSet(
      setNumber: setNumber ?? this.setNumber,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      actualReps: actualReps ??  this.actualReps,
      actualWeight: actualWeight ?? this. actualWeight,
      completed: completed ?? this.completed,
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }
}