import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/features/workout/providers/workout_provider.dart';
import 'package:reprise/services/local_storage_service.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _weightUnit = 'lbs';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _weightUnit = LocalStorageService.getSetting('weightUnit', defaultValue: 'lbs');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.h2()),
      ),
      body: ListView(
        padding: const EdgeInsets. all(AppSpacing.md),
        children: [
          // Workout Settings
          Text('Workout Settings', style: AppTextStyles.h3()),
          const SizedBox(height: AppSpacing.md),
          
          _buildSettingCard(
            title: 'Weight Unit',
            subtitle: 'Choose your preferred weight unit',
            trailing: DropdownButton<String>(
              value: _weightUnit,
              items: const [
                DropdownMenuItem(value: 'lbs', child: Text('lbs')),
                DropdownMenuItem(value: 'kg', child: Text('kg')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _weightUnit = value;
                  });
                  LocalStorageService.saveSetting('weightUnit', value);
                  
                  // Force UI refresh
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Weight unit changed to $value'),
                      backgroundColor: AppColors.success,
                      duration: const Duration(milliseconds: 800),
                    ),
                  );
                }
              },
            ),
          ),

          const SizedBox(height:  AppSpacing.xl),

          // Data Management
          Text('Data Management', style: AppTextStyles.h3()),
          const SizedBox(height: AppSpacing.md),

          _buildSettingCard(
            title: 'Export Data',
            subtitle: 'Backup your workout history as JSON',
            trailing: _isExporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            onTap: _isExporting ?  null : _exportData,
          ),

          _buildSettingCard(
            title: 'Share Workout Summary',
            subtitle: 'Share your progress with friends',
            trailing: const Icon(Icons.share),
            onTap: _shareWorkoutSummary,
          ),

          _buildSettingCard(
            title: 'Clear All Data',
            subtitle: 'Delete all workouts and templates',
            titleColor: AppColors.error,
            trailing: const Icon(Icons.delete_forever, color: AppColors.error),
            onTap: _showClearDataConfirmation,
          ),

          const SizedBox(height: AppSpacing.xl),

          // App Info
          Text('About', style: AppTextStyles.h3()),
          const SizedBox(height: AppSpacing.md),

          _buildSettingCard(
            title: 'Version',
            subtitle: '1.0.0',
            trailing: const SizedBox. shrink(),
          ),

          _buildSettingCard(
            title: 'App Info',
            subtitle: 'RepRise - Your Fitness Companion',
            trailing: const Icon(Icons.info_outline),
            onTap: _showAppInfo,
          ),

          const SizedBox(height:  AppSpacing.xl),

          // Credits
          Center(
            child: Text(
              'Made with 💪 for fitness enthusiasts',
              style: AppTextStyles.caption(),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required Widget trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets. only(bottom: AppSpacing. sm),
      child: ListTile(
        title: Text(
          title,
          style: titleColor != null 
              ? AppTextStyles.h4(color: titleColor)
              : AppTextStyles.h4(),
        ),
        subtitle: Text(subtitle, style: AppTextStyles.caption()),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
      final allWorkouts = workoutProvider.getAllWorkouts();
      final templates = workoutProvider.templates;
      final measurements = LocalStorageService.getSetting('measurements', defaultValue: []);

      final exportData = {
        'version': '1.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'workouts': allWorkouts.map((w) => w.toJson()).toList(),
        'templates': templates.map((t) => t.toJson()).toList(),
        'measurements': measurements,
        'settings': {
          'weightUnit':  _weightUnit,
        },
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/reprise_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'RepRise Workout Data Backup',
          text: 'My RepRise workout data backup',
        );

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully!  📦'),
            backgroundColor: AppColors. success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _shareWorkoutSummary() async {
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
    final completedWorkouts = workoutProvider. getAllWorkouts()
        .where((w) => w.status. toString().contains('completed'));
    
    final totalWorkouts = completedWorkouts. length;
    final totalVolume = completedWorkouts.fold<int>(0, (sum, w) => sum + w.totalVolume);
    final streak = workoutProvider.getCurrentStreak();
    final prs = workoutProvider.getTotalPRs();

    // Convert total volume to user's preferred unit
    final displayVolume = _weightUnit == 'kg' 
        ? (totalVolume * 0.453592 / 1000).toStringAsFixed(1)
        : (totalVolume / 1000).toStringAsFixed(1);

    final summary = '''
🏋️ My RepRise Fitness Stats 💪

📊 Total Workouts: $totalWorkouts
🔥 Current Streak: $streak days
📈 Total Volume: ${displayVolume}K $_weightUnit
🏆 Personal Records: $prs

Keep pushing!  💯

#RepRise #FitnessJourney #WorkoutTracker
    ''';

    await Share.share(summary, subject: 'My Fitness Progress');
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary. withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child:  const Icon(Icons.fitness_center, color: AppColors. primary, size: 32),
            ),
            const SizedBox(width: 12),
            Text('RepRise', style: AppTextStyles.h2()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0', style: AppTextStyles.body()),
            const SizedBox(height: 12),
            Text(
              'RepRise is your ultimate fitness companion for tracking workouts, monitoring progress, and achieving your fitness goals.',
              style: AppTextStyles.bodySmall(),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Text('Features:', style: AppTextStyles.h4()),
            const SizedBox(height: 8),
            _buildFeatureItem('✅ 100+ Exercise Library'),
            _buildFeatureItem('✅ Custom Workout Templates'),
            _buildFeatureItem('✅ Progressive Overload Tracking'),
            _buildFeatureItem('✅ PR Detection & Celebrations'),
            _buildFeatureItem('✅ Body Measurements'),
            _buildFeatureItem('✅ Exercise Analytics'),
            _buildFeatureItem('✅ Calendar Integration'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: AppTextStyles.bodySmall()),
    );
  }

  void _showClearDataConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Clear All Data? ', style: AppTextStyles.h3()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'This will permanently delete: ',
              style: AppTextStyles.body(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('• All workout history', style: AppTextStyles.body()),
            Text('• All templates', style: AppTextStyles.body()),
            Text('• All measurements', style: AppTextStyles.body()),
            Text('• All calendar entries', style: AppTextStyles.body()),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone! ',
              style: AppTextStyles.body(color: AppColors. error, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed:  () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // UPDATED: Use the new clearAllData method from provider
              final workoutProvider = Provider.of<WorkoutProvider>(context, listen:  false);
              await workoutProvider.clearAllData();
              
              if (mounted) {
                Navigator.pop(dialogContext);
                
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared successfully'),
                    backgroundColor: AppColors. success,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}