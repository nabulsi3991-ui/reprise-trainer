import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reprise/shared/models/assigned_workout.dart';
import 'dart:async';

class AssignedWorkoutProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<AssignedWorkout> _assignedWorkouts = [];
  bool _isLoading = false;

  StreamSubscription<QuerySnapshot>? _assignedWorkoutsSubscription;  

  String? _currentTraineeId;  // ✅ ADD THIS to track current trainee
  bool _isDeleting = false;   // ✅ ADD THIS

  List<AssignedWorkout> get assignedWorkouts => _assignedWorkouts;
  bool get isLoading => _isLoading;

// ✅ Mark assigned workout as completed
Future<void> completeAssignedWorkout(String workoutId) async {
  try {
    await _firestore.collection('assigned_workouts').doc(workoutId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
    
    final index = _assignedWorkouts.indexWhere((w) => w.id == workoutId);
    if (index != -1) {
      _assignedWorkouts. removeAt(index);
      notifyListeners();
    }
    
    print('✅ Marked assigned workout as completed:  $workoutId');
  } catch (e) {
    print('❌ Error completing assigned workout: $e');
    rethrow;
  }
}
 
 // ✅ ADD THIS METHOD
Future<void> cleanupOldOverdueWorkouts() async {
  try {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    
    // Get workouts that are 2+ days overdue
    final oldOverdue = _assignedWorkouts. where((workout) {
      if (workout.status != AssignedWorkoutStatus.pending) return false;
      
      final due = DateTime(
        workout.dueDate.year,
        workout.dueDate.month,
        workout. dueDate.day,
      );
      
      return due.isBefore(yesterday);
    }).toList();
    
    // Delete them
    for (var workout in oldOverdue) {
      await _firestore
          .collection('assigned_workouts')
          .doc(workout. id)
          .delete();
      
      _assignedWorkouts.removeWhere((w) => w.id == workout.id);
      print('🗑️ Auto-removed overdue workout: ${workout.workoutName}');
    }
    
    if (oldOverdue.isNotEmpty) {
      notifyListeners();
    }
  } catch (e) {
    print('❌ Error cleaning up old workouts: $e');
  }
}
 
 
 Future<void> loadAssignedWorkoutsForTrainee(String traineeId) async {
  // Prevent duplicate loads
  if (_currentTraineeId == traineeId && _assignedWorkoutsSubscription != null) {
    print('⚠️ Already listening for trainee: $traineeId');
    return;
  }
  
  _isLoading = true;
  _currentTraineeId = traineeId;
  notifyListeners();
  
  try {
    print('📥 Loading assigned workouts for trainee:   $traineeId');
    
    _assignedWorkoutsSubscription?. cancel();
    
    // ✅ SIMPLIFIED QUERY - Only filter by traineeId and status
    _assignedWorkoutsSubscription = _firestore
        .collection('assigned_workouts')
        .where('traineeId', isEqualTo: traineeId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(
          (snapshot) {
            print('📦 Received ${snapshot.docs. length} documents from Firestore');
            
            _assignedWorkouts = snapshot.docs
                .map((doc) {
                  print('  - Document ID: ${doc.id}, data: ${doc.data()}');
                  return AssignedWorkout.fromFirestore(doc);
                })
                .toList();
            
            // ✅ Sort by due date manually (no orderBy in query to avoid index issues)
            _assignedWorkouts.sort((a, b) => a.dueDate.compareTo(b.dueDate));
            
            _isLoading = false;
            notifyListeners();
            
            print('✅ Loaded ${_assignedWorkouts.length} assigned workouts');
            
            // Clean up old workouts
            cleanupOldOverdueWorkouts();
          },
          onError: (error) {
            print('❌ Error in assigned workouts listener: $error');
            _isLoading = false;
            notifyListeners();
          },
        );
  } catch (e) {
    print('❌ Error setting up assigned workouts listener: $e');
    _isLoading = false;
    notifyListeners();
  }
}

// ✅ ADD THIS METHOD
Future<void> loadAssignedWorkoutsForTrainer(String traineeId, String trainerId) async {
  _isLoading = true;
  notifyListeners();
  
  try {
    print('📥 Loading assigned workouts for trainee: $traineeId, trainer: $trainerId');
    
    _assignedWorkoutsSubscription?. cancel();
    
    _assignedWorkoutsSubscription = _firestore
        .collection('assigned_workouts')
        .where('traineeId', isEqualTo: traineeId)
        .where('trainerId', isEqualTo:  trainerId)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            print('📦 Received ${snapshot.docs. length} documents from Firestore');
            
            _assignedWorkouts = snapshot.docs
                .map((doc) {
                  print('  - Document ID: ${doc.id}');
                  return AssignedWorkout.fromFirestore(doc);
                })
                .toList();
            
            _isLoading = false;
            notifyListeners();
            
            print('✅ Loaded ${_assignedWorkouts. length} assigned workouts');
          },
          onError: (error) {
            print('❌ Error in assigned workouts listener: $error');
            _isLoading = false;
            notifyListeners();
          },
        );
  } catch (e) {
    print('❌ Error setting up assigned workouts listener: $e');
    _isLoading = false;
    notifyListeners();
  }
}

  // ✅ Load workouts assigned BY a trainer (for trainer view)
  Future<void> loadAssignedWorkoutsByTrainer(String trainerId, String traineeId) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('📥 Loading assigned workouts for trainee: $traineeId');
      
      final snapshot = await _firestore
          .collection('assigned_workouts')
          .where('trainerId', isEqualTo:  trainerId)
          .where('traineeId', isEqualTo: traineeId)
          .orderBy('dueDate', descending: false)
          .get();

      _assignedWorkouts = snapshot.docs
          .map((doc) => AssignedWorkout.fromJson(doc.data()))
          .toList();

      // ✅ AUTO-DELETE EXPIRED WORKOUTS
      await _cleanupExpiredWorkouts();

      print('✅ Loaded ${_assignedWorkouts.length} assigned workouts');
    } catch (e) {
      print('❌ Error loading assigned workouts: $e');
      _assignedWorkouts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ NEW: Auto-cleanup expired workouts (24 hours after due date)
  Future<void> _cleanupExpiredWorkouts() async {
    final expiredWorkouts = _assignedWorkouts.where((w) => w.isExpired).toList();
    
    if (expiredWorkouts. isEmpty) return;

    print('🗑️ Cleaning up ${expiredWorkouts.length} expired workouts');

    for (final workout in expiredWorkouts) {
      try {
        await _firestore.collection('assigned_workouts').doc(workout.id).delete();
        _assignedWorkouts.removeWhere((w) => w.id == workout.id);
        print('✅ Deleted expired workout: ${workout.workoutName}');
      } catch (e) {
        print('❌ Error deleting expired workout: $e');
      }
    }
  }

  // ✅ Get solo workouts (for trainee calendar)
  List<AssignedWorkout> getSoloWorkouts() {
    return _assignedWorkouts
        .where((w) => w.isSoloWorkout && w.status == AssignedWorkoutStatus.pending)
        .toList();
  }

  // ✅ Get trainer-led sessions (for pending sessions)
  List<AssignedWorkout> getTrainerLedSessions() {
    return _assignedWorkouts
        .where((w) => w.isTrainerLed && w.status == AssignedWorkoutStatus.pending)
        .toList();
  }

  // ✅ Get overdue workouts
  List<AssignedWorkout> getOverdueWorkouts() {
    return _assignedWorkouts
        .where((w) => w.isOverdue && ! w.isExpired && w. status == AssignedWorkoutStatus.pending)
        .toList();
  }


  Future<void> deleteAssignedWorkout(String workoutId) async {
    if (_isDeleting) {
      print('⚠️ Already deleting, skipping...');
      return;
    }
    
    _isDeleting = true;
    
    try {
      print('🗑️ Deleting assigned workout: $workoutId');
      
      // Remove from local list first
      _assignedWorkouts. removeWhere((w) => w.id == workoutId);
      notifyListeners();
      
      // Delete from Firestore
      await _firestore.collection('assigned_workouts').doc(workoutId).delete();
      
      print('✅ Deleted assigned workout:  $workoutId');
    } catch (e) {
      print('❌ Error deleting assigned workout: $e');
      rethrow;
    } finally {
      _isDeleting = false;
    }
  }

Future<void> assignWorkout({
  required String trainerId,
  required String traineeId,
  required String workoutTemplateId,
  required String workoutName,
  required List<Map<String, dynamic>> exercises,
  required DateTime dueDate,
  required String notes,
  required String sessionType,
}) async {
  try {
    print('📤 Assigning workout:  $workoutName to trainee: $traineeId');
    
    final workoutData = {
      'trainerId':  trainerId,
      'traineeId': traineeId,
      'workoutTemplateId': workoutTemplateId,
      'workoutName': workoutName,
      'exercises': exercises,
      'dueDate': Timestamp.fromDate(dueDate),
      'assignedDate': FieldValue.serverTimestamp(),
      'status': 'pending',
      'notes': notes,
      'sessionType': sessionType,
      'isTrainerLed': sessionType == 'trainerLed',
      'permission':  'weightsRepsOnly',
      'canDelete': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
    
    final docRef = await _firestore. collection('assigned_workouts').add(workoutData);
    
    print('✅ Workout assigned with ID: ${docRef.id}');
    
  } catch (e) {
    print('❌ Error assigning workout: $e');
    rethrow;
  }
}

  // ✅ Update workout status
  Future<void> updateWorkoutStatus(String workoutId, AssignedWorkoutStatus status) async {
    try {
      await _firestore.collection('assigned_workouts').doc(workoutId).update({
        'status': status.toString().split('.').last,
      });
      
      final index = _assignedWorkouts.indexWhere((w) => w.id == workoutId);
      if (index != -1) {
        final doc = await _firestore.collection('assigned_workouts').doc(workoutId).get();
        if (doc.exists) {
          _assignedWorkouts[index] = AssignedWorkout.fromJson(doc.data()!);
          notifyListeners();
        }
      }
      
      print('✅ Updated workout status: $workoutId');
    } catch (e) {
      print('❌ Error updating workout status: $e');
      rethrow;
    }
  }

  void clear() {
    _assignedWorkouts = [];
    notifyListeners();
    
  }
}