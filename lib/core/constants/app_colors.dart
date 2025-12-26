import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFFFF6584);
  static const Color accent = Color(0xFF4CAF50);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Light Theme
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF2C3E50);
  static const Color textSecondaryLight = Color(0xFF7F8C8D);

  // Dark Theme
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color surfaceDark = Color(0xFF16213E);
  static const Color textPrimaryDark = Color(0xFFECF0F1);
  static const Color textSecondaryDark = Color(0xFFBDC3C7);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8B7FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFFFF8FA3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF66BB6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Muscle Group Colors
  static Color getMuscleGroupColor(String muscleGroup) {
  switch (muscleGroup) {
    case 'Chest':
      return const Color(0xFFE91E63); // Pink
    case 'Back': 
      return const Color(0xFF2196F3); // Blue
    case 'Shoulders':
      return const Color(0xFFFF9800); // Orange
    case 'Legs':
      return const Color(0xFF4CAF50); // Green
    case 'Biceps':
      return const Color(0xFF9C27B0); // Purple
    case 'Triceps':
      return const Color(0xFF673AB7); // Deep Purple
    case 'Core':
      return const Color(0xFFFF5722); // Deep Orange
    case 'Glutes':
      return const Color(0xFFE91E63); // Pink (same as chest)
    case 'Forearms':
      return const Color(0xFF795548); // Brown
    case 'Traps':
      return const Color(0xFF607D8B); // Blue Grey
    case 'Cardio':
      return const Color(0xFFF44336); // Red
    default:
      return const Color(0xFF9E9E9E); // Grey (fallback)
  }
}

  // Workout Status Colors
  static Color getWorkoutStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return success;
      case 'scheduled':
        return warning;
      case 'missed':
        return error;
      case 'inprogress':
        return info;
      default:
        return textSecondaryLight;
    }
  }

  // Intensity Colors
  static Color getIntensityColor(double intensity) {
    if (intensity >= 0.8) return error;
    if (intensity >= 0.6) return warning;
    if (intensity >= 0.4) return info;
    return success;
  }
}