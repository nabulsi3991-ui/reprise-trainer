import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/features/user/providers/user_provider.dart';

class LogoutScreen extends StatefulWidget {
  const LogoutScreen({super.key});

  @override
  State<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen> {
  @override
  void initState() {
    super.initState();
    _performLogout();
  }

  Future<void> _performLogout() async {
    try {
      // Small delay so user sees the screen
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (! mounted) return;
      
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.logout();
      
      print('✅ Logout complete, popping to root');
      
      // ✅ FIX: Pop back to root, AuthGate will show LoginScreen
      if (mounted) {
        Navigator. of(context).popUntil((route) => route.isFirst);
      }
      
    } catch (e) {
      print('❌ Logout error: $e');
      
      if (mounted) {
        Navigator. of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logout Icon Animation
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors. error. withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout,
                        size: 64,
                        color: AppColors.error,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height:  32),
              
              // Loading Indicator
              const CircularProgressIndicator(
                color: AppColors.error,
              ),
              
              const SizedBox(height: 24),
              
              // Logout Text
              Text(
                'Logging out.. .',
                style: AppTextStyles.h3(color: AppColors.textPrimaryDark),
              ),
              
              const SizedBox(height:  12),
              
              Text(
                'See you next workout!',
                style: AppTextStyles.body(color: AppColors.textSecondaryDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}