import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Headings
 static TextStyle h4({
  Color color = AppColors.textPrimary,
  FontWeight?  fontWeight,
}) {
  return TextStyle(
    fontSize:  16,
    fontWeight:  fontWeight ?? FontWeight.w600,
    color: color,
    height: 1.4,
  );
}

  static TextStyle h1({Color?  color, FontWeight? fontWeight}) {
    return GoogleFonts.inter(
      fontSize: 32,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color ?? AppColors.textPrimary, 
      height: 1.2,
    );
  }
  
  static TextStyle h2({Color? color, FontWeight?  fontWeight}) {
    return GoogleFonts.inter(
      fontSize: 24,
      fontWeight: fontWeight ?? FontWeight. bold,
      color: color ?? AppColors.textPrimary, 
      height: 1.3,
    );
  }
  
  static TextStyle h3({Color? color, FontWeight?  fontWeight}) {
    return GoogleFonts.inter(
      fontSize: 20,
      fontWeight: fontWeight ?? FontWeight. w600,
      color: color ??  AppColors.textPrimary,
      height: 1.4,
    );
  }
  
  // Body Text
  static TextStyle body({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ??  AppColors.textPrimary,
      height: 1.5,
    );
  }
  
  static TextStyle bodySmall({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ??  AppColors.textPrimary,
      height:  1.5,
    );
  }
  
  static TextStyle caption({Color? color, FontWeight?  fontWeight}) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: fontWeight ?? FontWeight. normal,
      color: color ??  AppColors.textPrimary,
      height: 1.4,
    );
  }
  
  // Numbers (for weights, reps, etc.)
  static TextStyle numberLarge({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.robotoMono(
      fontSize: 24,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color ??  AppColors.textPrimary,
    );
  }
  
  static TextStyle number({Color? color, FontWeight?  fontWeight}) {
    return GoogleFonts.robotoMono(
      fontSize: 18,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color ??  AppColors.textPrimary,
    );
  }
  
  // Button Text
  static TextStyle button({Color? color}) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color ??  AppColors.textPrimary,
      letterSpacing: 0.5,
    );
  }

  
}