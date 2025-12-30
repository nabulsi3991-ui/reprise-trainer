import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/features/user/providers/user_provider.dart';

class TrainerCodeCard extends StatefulWidget {
  final String trainerCode;

  const TrainerCodeCard({
    super.key,
    required this.trainerCode,
  });

  @override
  State<TrainerCodeCard> createState() => _TrainerCodeCardState();
}

class _TrainerCodeCardState extends State<TrainerCodeCard> {
  bool _isRegenerating = false;

  Future<void> _manualRefreshCode() async {
    if (_isRegenerating) return;

    setState(() => _isRegenerating = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      await userProvider.regenerateTrainerCode();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('New trainer code generated! '),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:  Text('Failed to generate code: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRegenerating = false);
      }
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.trainerCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.copy, color: Colors.white),
            SizedBox(width: 12),
            Text('Code copied to clipboard! '),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: Duration(seconds:  2),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Use timer from UserProvider
    final userProvider = Provider.of<UserProvider>(context);
    final secondsRemaining = userProvider.codeSecondsRemaining;

    return Container(
      padding:  const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.2),
            AppColors.success. withOpacity(0.1),
          ],
          begin:  Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing. radiusMedium),
        border: Border.all(
          color: AppColors.success. withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children:  [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.qr_code,
                color: AppColors.success,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Your Trainer Code',
                style:  AppTextStyles.h4(color: AppColors.success),
              ),
            ],
          ),
          
          const SizedBox(height:  AppSpacing.sm),
          
          // Code Display
          GestureDetector(
            onTap: _copyToClipboard,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget. trainerCode,
                    style: AppTextStyles.h2(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.copy,
                    color: AppColors.success,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing. sm),
          
          // Timer and Refresh Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:  [
              // Timer
              Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: secondsRemaining <= 30 
                        ? AppColors.error 
                        : AppColors. textSecondaryLight,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expires in ${_formatTime(secondsRemaining)}',
                    style: AppTextStyles.caption(
                      color: secondsRemaining <= 30 
                          ? AppColors.error 
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              
              // Refresh Button
              TextButton. icon(
                onPressed: _isRegenerating ? null : _manualRefreshCode,
                icon: _isRegenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: const Text('Generate New'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing. sm,
                    vertical: AppSpacing.xs,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xs),
          
          // Info Text
          Text(
            'Share this code with trainees to connect • Tap code to copy',
            style: AppTextStyles. caption(color: AppColors.textSecondaryLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}