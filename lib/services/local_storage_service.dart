import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  static const String _workoutsBoxName = 'workouts';
  static const String _settingsBoxName = 'settings';

  // Workouts Box
  static Box get _workoutsBox => Hive.box(_workoutsBoxName);
  static Box get _settingsBox => Hive.box(_settingsBoxName);

  // FIXED: Save workout (ensure proper type)
  static Future<void> saveWorkout(String key, Map<String, dynamic> workout) async {
    print('💾 LocalStorage: Saving to Hive with key: $key');
    
    // Convert to Map<String, dynamic> explicitly
    final Map<String, dynamic> data = Map<String, dynamic>.from(workout);
    await _workoutsBox.put(key, data);
    
    // Verify save
    final saved = _workoutsBox.get(key);
    if (saved != null) {
      print('✅ LocalStorage: Verified saved - Type: ${saved.runtimeType}');
    } else {
      print('❌ LocalStorage:  Save verification FAILED! ');
    }
  }

  // FIXED: Get workout (proper casting)
  static Map<String, dynamic>? getWorkout(String key) {
    final data = _workoutsBox.get(key);
    if (data == null) return null;
    
    // Handle both Map<dynamic, dynamic> and Map<String, dynamic>
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    
    return null;
  }

  // FIXED: Get all workouts (proper casting)
  static Map<String, Map<String, dynamic>> getAllWorkouts() {
    print('📦 LocalStorage: Loading all workouts from Hive');
    print('📦 LocalStorage: Box has ${_workoutsBox.keys.length} keys');
    
    final Map<String, Map<String, dynamic>> allWorkouts = {};
    
    for (var key in _workoutsBox.keys) {
      final workout = _workoutsBox.get(key);
      if (workout != null) {
        try {
          // CRITICAL FIX: Handle Map<dynamic, dynamic> from Hive
          if (workout is Map<String, dynamic>) {
            allWorkouts[key. toString()] = workout;
          } else if (workout is Map) {
            // Convert Map<dynamic, dynamic> to Map<String, dynamic>
            allWorkouts[key.toString()] = _deepCastMap(workout);
          }
          print('   ✓ Loaded:  $key');
        } catch (e) {
          print('   ❌ Error loading $key: $e');
        }
      }
    }
    
    print('✅ LocalStorage:  Returning ${allWorkouts.length} workouts');
    return allWorkouts;
  }

  // HELPER: Deep cast Map<dynamic, dynamic> to Map<String, dynamic>
  static Map<String, dynamic> _deepCastMap(Map map) {
    final result = <String, dynamic>{};
    
    map.forEach((key, value) {
      if (value is Map) {
        // Recursively cast nested maps
        result[key. toString()] = _deepCastMap(value);
      } else if (value is List) {
        // Handle lists that might contain maps
        result[key.toString()] = _deepCastList(value);
      } else {
        result[key.toString()] = value;
      }
    });
    
    return result;
  }

  // HELPER: Deep cast List items
  static List<dynamic> _deepCastList(List list) {
    return list.map((item) {
      if (item is Map) {
        return _deepCastMap(item);
      } else if (item is List) {
        return _deepCastList(item);
      } else {
        return item;
      }
    }).toList();
  }

  // Delete workout
  static Future<void> deleteWorkout(String key) async {
    print('🗑️ LocalStorage: Deleting key: $key');
    await _workoutsBox.delete(key);
    print('✅ LocalStorage:  Deleted');
  }

  // Clear all workouts
  static Future<void> clearAllWorkouts() async {
    print('🗑️ LocalStorage: Clearing ALL workouts');
    await _workoutsBox.clear();
    print('✅ LocalStorage:  All cleared (${_workoutsBox.keys.length} items remaining)');
  }

  // Save setting
  static Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  // Get setting
  static dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue:  defaultValue);
  }
}