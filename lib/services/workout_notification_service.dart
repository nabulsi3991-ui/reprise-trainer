import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform;

class WorkoutNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static Timer?  _updateTimer;
  static DateTime?  _workoutStartTime;
  static String? _workoutName;
  static String? _sets;

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission:  true,
      requestSoundPermission: true, // ✅ Changed to true for initial permission
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS:  iosSettings,
    );

    await _notifications.initialize(settings);
    
    // ✅ Request notification permission for Android 13+
    if (Platform.isAndroid) {
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final bool? granted = await androidImplementation.requestNotificationsPermission();
        print('🔔 Notification permission granted: $granted');
        
        // Create notification channel
        const androidChannel = AndroidNotificationChannel(
          'active_workout_channel',
          'Active Workout',
          description: 'Shows active workout progress',
          importance:  Importance.high,
          enableVibration: false,
          playSound: false,
        );
        
        await androidImplementation.createNotificationChannel(androidChannel);
        print('🔔 Notification channel created');
      }
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
    
    // Update every second
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _updateNotification();
    });
  }

  static Future<void> _updateNotification() async {
    if (_workoutStartTime == null || _workoutName == null || _sets == null) return;
    
    final elapsed = DateTime.now().difference(_workoutStartTime! );
    final duration = _formatTime(elapsed.inSeconds);
    
    final androidDetails = AndroidNotificationDetails(
      'active_workout_channel',
      'Active Workout',
      channelDescription: 'Shows active workout progress',
      importance: Importance. high,
      priority: Priority. high,
      ongoing: true, // ✅ Keeps notification persistent
      autoCancel: false,
      showWhen: false, // ✅ Don't show system time
      usesChronometer:  false,
      playSound: false,
      enableVibration:  false,
      color: const Color(0xFF6C63FF),
      colorized: true,
      visibility: NotificationVisibility. public,
      icon: '@mipmap/ic_launcher', // ✅ Explicit icon
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'), // ✅ Large icon
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge:  true,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS:  iosDetails,
    );

    try {
      await _notifications.show(
        999,
        _workoutName!,
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

  // ✅ NEW: Manual permission request method (for settings page)
  static Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final bool? granted = await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }
    }
    return true; // iOS permissions handled during initialize
  }

  // ✅ NEW:  Check if permission is granted
  static Future<bool> checkPermission() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final bool? granted = await androidImplementation.areNotificationsEnabled();
        return granted ?? false;
      }
    }
    return true;
  }
}