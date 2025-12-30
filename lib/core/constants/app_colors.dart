import 'package:flutter/material.dart';

class AppColors {
  // ✅ TRAINEE/PERSONAL COLORS (Purple/Pink theme)
  static const Color primary = Color(0xFF6C63FF); // Purple
  static const Color secondary = Color(0xFFFF6584); // Pink
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color error = Color(0xFFE53935); // Red
  static const Color warning = Color(0xFFFFA726); // Orange
  static const Color info = Color(0xFF29B6F6); // Blue
  
  // ✅ TRAINER COLORS (Cyan/Teal theme)
  static const Color trainerPrimary = Color(0xFF00BCD4); // Cyan
  static const Color trainerSecondary = Color(0xFF9C27B0); // Purple
  static const Color trainerAccent = Color(0xFFFF9800); // Orange
  static const Color trainerSuccess = Color(0xFF66BB6A); // Light Green
  static const Color trainerInfo = Color(0xFF26C6DA); // Cyan accent
  static const Color trainerWarning = Color(0xFFFFCA28); // Amber
  
  // ✅ SHARED COLORS - Light Theme
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textPrimaryLight = Color(0xFFFFFFFF);
  static const Color textSecondaryLight = Color(0xFFBDBDBD);
  
  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  
  // ✅ SHARED COLORS - Dark Theme (if needed in future)
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFBDBDBD);
  static const Color surfaceDark = Color(0xFF303030);
  static const Color backgroundDark = Color(0xFF121212);
  
  // ✅ GRADIENTS
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFFF6584), Color(0xFFFF4F6D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient trainerGradient = LinearGradient(
    colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ✅ Muscle group colors (your existing code)
  static Color getMuscleGroupColor(String muscleGroup) {
    switch (muscleGroup. toLowerCase()) {
      case 'chest':
        return const Color(0xFFE57373);
      case 'back':
        return const Color(0xFF64B5F6);
      case 'legs':
        return const Color(0xFF81C784);
      case 'shoulders':
        return const Color(0xFFFFD54F);
      case 'arms':
        return const Color(0xFFBA68C8);
      case 'core':
        return const Color(0xFFFF8A65);
      case 'cardio':
        return const Color(0xFF4FC3F7);
      case 'full body':
        return const Color(0xFF9575CD);
      default:
        return const Color(0xFF90A4AE);
    }
  }

  // ✅ Status colors
  static const Color statusScheduled = Color(0xFF29B6F6);
  static const Color statusInProgress = Color(0xFFFFA726);
  static const Color statusCompleted = Color(0xFF66BB6A);
  static const Color statusCancelled = Color(0xFFE57373);
}