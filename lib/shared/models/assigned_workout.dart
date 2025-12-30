import 'package:cloud_firestore/cloud_firestore.dart';

enum AssignedWorkoutStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

enum ModificationPermission {
  readOnly,
  weightsRepsOnly,
  full,
}

class AssignedWorkout {
  final String id;
  final String trainerId;
  final String traineeId;
  final String workoutTemplateId;
  final String workoutName;
  final DateTime assignedDate;
  final DateTime dueDate;
  final AssignedWorkoutStatus status;
  final String notes;
  final List<Map<String, dynamic>> exercises;
  final ModificationPermission permission;
  final bool canDelete;
  final String sessionType;
  final DateTime?  sessionStartedAt;
  final DateTime? sessionCompletedAt;
  final String? sessionNotes;

  AssignedWorkout({
    required this.id,
    required this.trainerId,
    required this.traineeId,
    required this.workoutTemplateId,
    required this.workoutName,
    required this. assignedDate,
    required this.dueDate,
    required this.status,
    required this.notes,
    required this. exercises,
    required this.permission,
    required this.canDelete,
    this.sessionType = 'solo',
    this.sessionStartedAt,
    this.sessionCompletedAt,
    this.sessionNotes,
  });

  factory AssignedWorkout.fromJson(Map<String, dynamic> json) {
    return AssignedWorkout(
      id: json['id'] ?? '',
      trainerId: json['trainerId'] ?? '',
      traineeId: json['traineeId'] ?? '',
      workoutTemplateId: json['workoutTemplateId'] ?? '',
      workoutName: json['workoutName'] ?? '',
      assignedDate: _parseDate(json['assignedDate']),
      dueDate: _parseDate(json['dueDate']),
      status: AssignedWorkoutStatus.values. firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => AssignedWorkoutStatus.pending,
      ),
      notes: json['notes'] ?? '',
      exercises:  List<Map<String, dynamic>>. from(json['exercises'] ?? []),
      permission: ModificationPermission.values.firstWhere(
        (e) => e.toString().split('.').last == json['permission'],
        orElse: () => ModificationPermission.weightsRepsOnly,
      ),
      canDelete: json['canDelete'] ?? false,
      sessionType: json['sessionType'] ??  'solo',
      sessionStartedAt: json['sessionStartedAt'] != null
          ? _parseDate(json['sessionStartedAt'])
          : null,
      sessionCompletedAt: json['sessionCompletedAt'] != null
          ? _parseDate(json['sessionCompletedAt'])
          : null,
      sessionNotes: json['sessionNotes'],
    );
  }

factory AssignedWorkout. fromFirestore(DocumentSnapshot doc) {
  final data = doc. data() as Map<String, dynamic>;
  
  return AssignedWorkout(
    id:  doc.id,
    trainerId: data['trainerId'] ?? '',
    traineeId: data['traineeId'] ?? '',
    workoutTemplateId: data['workoutTemplateId'] ?? '',
    workoutName: data['workoutName'] ?? 'Unknown Workout',
    assignedDate: _parseDate(data['assignedDate']),
    dueDate: _parseDate(data['dueDate']),
    status: AssignedWorkoutStatus. values.firstWhere(
      (e) => e.toString().split('.').last == data['status'],
      orElse: () => AssignedWorkoutStatus. pending,
    ),
    notes: data['notes'] ?? '',
    exercises: List<Map<String, dynamic>>.from(data['exercises'] ?? []),
    permission: ModificationPermission.values. firstWhere(
      (e) => e.toString().split('.').last == (data['permission'] ??  'weightsRepsOnly'),
      orElse: () => ModificationPermission.weightsRepsOnly,
    ),
    canDelete: data['canDelete'] ?? false,
    sessionType:  data['sessionType'] ??  'solo',
    sessionStartedAt: data['sessionStartedAt'] != null
        ? _parseDate(data['sessionStartedAt'])
        : null,
    sessionCompletedAt: data['sessionCompletedAt'] != null
        ? _parseDate(data['sessionCompletedAt'])
        : null,
    sessionNotes: data['sessionNotes'],
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainerId': trainerId,
      'traineeId': traineeId,
      'workoutTemplateId': workoutTemplateId,
      'workoutName': workoutName,
      'assignedDate': assignedDate.toIso8601String(),
      'dueDate': dueDate. toIso8601String(),
      'status': status.toString().split('.').last,
      'notes': notes,
      'exercises': exercises,
      'permission':  permission.toString().split('.').last,
      'canDelete': canDelete,
      'sessionType':  sessionType,
      'sessionStartedAt': sessionStartedAt?. toIso8601String(),
      'sessionCompletedAt':  sessionCompletedAt?.toIso8601String(),
      'sessionNotes': sessionNotes,
    };
  }

  bool get isSoloWorkout => sessionType == 'solo';
  bool get isTrainerLed => sessionType == 'trainerLed';
  bool get isSessionActive => sessionStartedAt != null && sessionCompletedAt == null;

  bool get isExpired {
    if (status == AssignedWorkoutStatus. completed) return false;
    final expiryTime = dueDate.add(const Duration(hours: 24));
    return DateTime.now().isAfter(expiryTime);
  }

  // ✅ REPLACE the isOverdue getter with this: 
bool get isOverdue {
  if (status != AssignedWorkoutStatus.pending) return false;
  
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  
  // ✅ Overdue if due date has passed (not including today)
  return due.isBefore(today);
}

static DateTime _parseDate(dynamic date) {
  if (date == null) return DateTime.now();
  if (date is Timestamp) return date.toDate();
  if (date is String) return DateTime.parse(date);
  return DateTime.now();
}
}