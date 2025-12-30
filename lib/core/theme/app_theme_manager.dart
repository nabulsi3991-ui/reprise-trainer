import 'package:flutter/material.dart';
import 'package:reprise/core/constants/app_colors.dart';

class AppThemeManager {
  // Determine if user is trainer
  static bool _isTrainerMode = false;
  
  static void setTrainerMode(bool isTrainer) {
    _isTrainerMode = isTrainer;
  }
  
  static bool get isTrainerMode => _isTrainerMode;
  
  // ✅ Dynamic colors based on mode
  static Color get primaryColor => _isTrainerMode ?  AppColors.trainerPrimary : AppColors.primary;
  static Color get secondaryColor => _isTrainerMode ?  AppColors.trainerSecondary : AppColors.secondary;
  static Color get accentColor => _isTrainerMode ? AppColors.trainerAccent : AppColors.primary;
  
  static LinearGradient get primaryGradient => _isTrainerMode 
      ? AppColors.trainerGradient 
      : AppColors.primaryGradient;
  
  static LinearGradient get secondaryGradient => _isTrainerMode
      ? const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : AppColors.secondaryGradient;
  
  // ✅ Icon for mode
  static IconData get modeIcon => _isTrainerMode ? Icons. people : Icons.person;
  static String get modeLabel => _isTrainerMode ? 'Trainer Mode' : 'Personal Mode';
  
  // ✅ Get color for specific elements
  static Color getStatColor(int index) {
    if (_isTrainerMode) {
      return [
        AppColors.trainerPrimary,
        AppColors. trainerSecondary,
        AppColors.trainerSuccess,
        AppColors.trainerInfo,
      ][index % 4];
    } else {
      return [
        AppColors.primary,
        AppColors.secondary,
        AppColors.success,
        AppColors.info,
      ][index % 4];
    }
  }
}