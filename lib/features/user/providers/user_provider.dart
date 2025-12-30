import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reprise/shared/models/app_user.dart';
import 'dart:async';
import 'dart:math';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  AppUser? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  Timer? _codeRefreshTimer;
  int _codeSecondsRemaining = 300;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  int get codeSecondsRemaining => _codeSecondsRemaining;

  UserProvider() {
    _auth.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser != null) {
        _listenToUserChanges(firebaseUser. uid);
      } else {
        _currentUser = null;
        _isInitialized = true;
        _userSubscription?.cancel();
        _codeRefreshTimer?.cancel();
        notifyListeners();
      }
    });
  }

  void _listenToUserChanges(String uid) {
    print('👂 Setting up real-time listener for user:  $uid');
    
    _userSubscription?. cancel();
    _userSubscription = _firestore. collection('users').doc(uid).snapshots().listen(
      (snapshot) {
        if (snapshot.exists) {
          print('📥 User data updated from Firestore');
          final data = {... snapshot.data()!, 'id': snapshot.id};
          _currentUser = AppUser.fromJson(data);
          _isInitialized = true; 
          
          if (_currentUser! .isTrainer && _currentUser!.trainerCode != null) {
            _startCodeRefreshTimer();
          }
          
          notifyListeners();
        } else {
          print('⚠️ User document does not exist');
          _currentUser = null;
          _isInitialized = true;
          notifyListeners();
        }
      },
      onError: (error) {
        print('❌ Error listening to user changes: $error');
        _isInitialized = true;
        notifyListeners();
      },
    );
  }

Future<void> logout() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      _isInitialized = false;
      _userSubscription?.cancel();
      _codeRefreshTimer?.cancel();
      notifyListeners();
      print('✅ User logged out successfully');
    } catch (e) {
      print('❌ Error logging out: $e');
      rethrow;
    }
  }

  Future<void> loadCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      
      if (doc.exists) {
        final data = {... doc.data()!, 'id': doc.id};
        _currentUser = AppUser.fromJson(data);
        
        if (_currentUser!.isTrainer && _currentUser!.trainerCode != null) {
          _startCodeRefreshTimer();
        }
      } else {
        _currentUser = null;
      }
    } catch (e) {
      print('❌ Error loading user: $e');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startCodeRefreshTimer() {
    _codeRefreshTimer?.cancel();
    
    if (_currentUser?.trainerCodeUpdatedAt == null) return;
    
    final updatedAt = DateTime.parse(_currentUser!.trainerCodeUpdatedAt!);
    final expiryTime = updatedAt.add(const Duration(minutes: 5));
    final now = DateTime.now();
    
    if (now.isAfter(expiryTime)) {
      _codeSecondsRemaining = 0;
      _autoRefreshTrainerCode();
      return;
    }
    
    _codeSecondsRemaining = expiryTime.difference(now).inSeconds;
    
    _codeRefreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _codeSecondsRemaining--;
      
      if (_codeSecondsRemaining <= 0) {
        print('⏰ Timer expired, auto-refreshing code.. .');
        _autoRefreshTrainerCode();
        timer.cancel();
      }
      
      notifyListeners();
    });
  }

  Future<void> _autoRefreshTrainerCode() async {
    try {
      await regenerateTrainerCode();
    } catch (e) {
      print('❌ Auto-refresh failed: $e');
    }
  }

  String _generateTrainerCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final code = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    return 'TRN-$code';
  }

  Future<void> regenerateTrainerCode() async {
    if (_currentUser == null || ! _currentUser!.isTrainer) return;

    try {
      final newCode = _generateTrainerCode();
      final now = DateTime.now();
      
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      await _firestore.collection('users').doc(uid).update({
        'trainerCode':  newCode,
        'trainerCodeUpdatedAt': now.toIso8601String(),
      });

      print('✅ Trainer code regenerated:  $newCode');
    } catch (e) {
      print('❌ Error regenerating trainer code: $e');
      rethrow;
    }
  }

    Future<void> connectToTrainer(String trainerCode) async {
    if (_currentUser == null || _currentUser!. isTrainer) {
      throw Exception('Only personal users can connect to trainers');
    }

    if (_currentUser!.hasTrainer) {
      throw Exception('Already connected to a trainer');
    }

    try {
      print('🔍 Searching for trainer with code: $trainerCode');

      final trainerQuery = await _firestore
          .collection('users')
          .where('trainerCode', isEqualTo: trainerCode)
          .limit(1)
          .get();

      if (trainerQuery.docs.isEmpty) {
        throw Exception('Invalid trainer code');
      }

      final trainerDoc = trainerQuery.docs.first;
      final trainerData = trainerDoc.data();
      
      if (trainerData['trainerCodeUpdatedAt'] != null) {
        final updatedAt = DateTime.parse(trainerData['trainerCodeUpdatedAt']);
        final expiryTime = updatedAt.add(const Duration(minutes: 5));
        
        if (DateTime.now().isAfter(expiryTime)) {
          throw Exception('Trainer code has expired');
        }
      }

      final trainerId = trainerDoc.id;
      final trainerName = trainerData['name'] ?? 'Unknown Trainer';

      print('✅ Found trainer: $trainerName');

      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final traineeData = {
        'id': uid,
        'name': _currentUser!.name,
        'email': _currentUser!. email,
        'connectedAt': DateTime.now().toIso8601String(),
      };

      await _firestore. collection('users').doc(uid).update({
        'trainerId':  trainerId,
        'trainerName': trainerName,
      });

      final currentTrainees = List<Map<String, dynamic>>.from(trainerData['trainees'] ?? []);
      
      if (! currentTrainees.any((t) => t['id'] == uid)) {
        currentTrainees.add(traineeData);
        
        await _firestore.collection('users').doc(trainerId).update({
          'trainees': currentTrainees,
          'traineeIds': FieldValue.arrayUnion([uid]),
        });
        
        print('✅ Added to trainer\'s trainees list');
      }

      print('✅ Connected to trainer successfully');
    } catch (e) {
      print('❌ Error connecting to trainer: $e');
      rethrow;
    }
  }


  Future<void> removeTrainee(String traineeId, String traineeName) async {
    if (_currentUser == null || !_currentUser!.isTrainer) return;

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      print('🗑️ Removing trainee: $traineeName ($traineeId)');

      await _firestore.collection('users').doc(traineeId).update({
        'trainerId': null,
        'trainerName': null,
      });

      print('✅ Cleared trainer link from trainee document');

      final trainerData = (await _firestore.collection('users').doc(uid).get()).data();
      
      if (trainerData != null) {
        final trainees = List<Map<String, dynamic>>.from(trainerData['trainees'] ??  []);
        trainees.removeWhere((t) => t['id'] == traineeId);
        
        await _firestore. collection('users').doc(uid).update({
          'trainees':  trainees,
          'traineeIds': FieldValue.arrayRemove([traineeId]),
        });
        
        print('✅ Removed trainee from trainer document');
      }

      print('✅ Trainee removed successfully');
    } catch (e) {
      print('❌ Error removing trainee: $e');
      rethrow;
    }
  }

  Future<void> disconnectFromTrainer() async {
    if (_currentUser == null || _currentUser! .isTrainer) return;

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final trainerId = _currentUser!.trainerId;

      print('🔌 Disconnecting from trainer.. .');

      await _firestore. collection('users').doc(uid).update({
        'trainerId':  null,
        'trainerName': null,
      });

      print('✅ Cleared trainer link from trainee');

      if (trainerId != null) {
        final trainerQuery = await _firestore
            .collection('users')
            .where('trainerCode', isEqualTo: trainerId)
            .limit(1)
            .get();

        if (trainerQuery.docs. isNotEmpty) {
          final trainerDocId = trainerQuery.docs.first.id;
          final trainerData = trainerQuery.docs.first.data();
          
          final trainees = List<Map<String, dynamic>>.from(trainerData['trainees'] ?? []);
          trainees.removeWhere((t) => t['id'] == uid);
          
          await _firestore.collection('users').doc(trainerDocId).update({
            'trainees': trainees,
            'traineeIds': FieldValue.arrayRemove([uid]),
          });
          
          print('✅ Removed from trainer document');
        }
      }

      print('✅ Disconnected from trainer successfully');
    } catch (e) {
      print('❌ Error disconnecting from trainer: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _codeRefreshTimer?.cancel();
    super.dispose();
  }
}