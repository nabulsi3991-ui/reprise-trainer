import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class WorkoutNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static Timer? _updateTimer;
  static DateTime?  _workoutStartTime;
  static String?  _workoutName;
  static String? _sets;

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission:  true,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    
    const androidChannel = AndroidNotificationChannel(
      'active_workout_channel',
      'Active Workout',
      description: 'Shows active workout progress',
      importance:  Importance.high,
    );

    final androidPlugin = _notifications. resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin. createNotificationChannel(androidChannel);
      print('🔔 Notification channel created');
    }
    
    print('🔔 Notification service initialized');
  }

  static String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  static Future<void> showActiveWorkoutNotification({
    required String workoutName,
    required DateTime startTime,
    required String sets,
  }) async {
    print('🔔 Showing notification:  $workoutName, $sets');
    
    // Store values for updates
    _workoutStartTime = startTime;
    _workoutName = workoutName;
    _sets = sets;
    
    // Cancel any existing timer
    _updateTimer?.cancel();
    
    // Show initial notification
    await _updateNotification();
    
    // ✅ Update every second
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _updateNotification();
    });
  }

  static Future<void> _updateNotification() async {
    if (_workoutStartTime == null || _workoutName == null || _sets == null) return;
    
    final elapsed = DateTime.now().difference(_workoutStartTime!);
    final duration = _formatTime(elapsed.inSeconds);
    
    final androidDetails = AndroidNotificationDetails(
      'active_workout_channel',
      'Active Workout',
      channelDescription: 'Shows active workout progress',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      usesChronometer: false,
      playSound: false,
      enableVibration: false,
      color: const Color(0xFF6C63FF),
      colorized: true,
      visibility:  NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications. show(
        999,
        '$_workoutName',
        '⏱️ $duration • 💪 $_sets',
        details,
        payload: 'workout_active',
      );
    } catch (e) {
      print('🔔 ERROR:  $e');
    }
  }

  static Future<void> updateWorkoutSets(String sets) async {
    _sets = sets;
    await _updateNotification();
  }

  static Future<void> cancelWorkoutNotification() async {
    print('🔔 Cancelling notification');
    _updateTimer?.cancel();
    _updateTimer = null;
    _workoutStartTime = null;
    _workoutName = null;
    _sets = null;
    await _notifications.cancel(999);
  }
}