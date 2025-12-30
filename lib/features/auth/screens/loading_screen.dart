import 'package:flutter/material.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor:  AppColors.backgroundDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Login Icon Animation
              TweenAnimationBuilder(
                tween:  Tween<double>(begin:  0, end: 1),
                duration: const Duration(milliseconds: 800),
                builder: (context, double value, child) {
                  return Transform. scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.success. withOpacity(0.2),
                        shape: BoxShape. circle,
                      ),
                      child: const Icon(
                        Icons.login,
                        size: 64,
                        color: AppColors.success,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Loading Indicator
              const CircularProgressIndicator(
                color: AppColors.success,
              ),
              
              const SizedBox(height: 24),
              
              // Loading Text
              Text(
                'Logging in...',
                style: AppTextStyles.h3(color: AppColors.textPrimaryDark),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Getting your workouts ready!',
                style:  AppTextStyles.body(color: AppColors.textSecondaryDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}