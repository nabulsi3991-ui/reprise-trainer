import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/features/user/providers/user_provider.dart';
import 'package:reprise/features/workout/providers/workout_provider.dart';
import 'package:reprise/services/local_storage_service.dart';
import 'package:reprise/features/auth/screens/logout_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final weightUnit = LocalStorageService.getSetting('weightUnit', defaultValue:  'lbs');
    final restTimerEnabled = LocalStorageService.getSetting('restTimerEnabled', defaultValue: true);
    final defaultRestTime = LocalStorageService.getSetting('defaultRestTime', defaultValue: 90);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.h2()),
      ),
      body: Consumer<UserProvider>(
        builder:  (context, userProvider, child) {
          final user = userProvider.currentUser;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Account Section
              Text('Account', style: AppTextStyles.h3()),
              const SizedBox(height: AppSpacing.sm),

              if (user != null) ...[
                Card(
                  child:  Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary. withOpacity(0.2),
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name. substring(0, 1).toUpperCase()
                                : 'U',
                            style:  AppTextStyles.h4(color: AppColors.primary),
                          ),
                        ),
                        title: Text(user.name, style: AppTextStyles.h4()),
                        subtitle: Text(user.email, style: AppTextStyles.caption()),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          user.isTrainer ?  Icons.people : Icons.person,
                          color: user.isTrainer ?  AppColors.secondary : AppColors.primary,
                        ),
                        title: Text(
                          user.isTrainer ?  'Trainer Mode' : 'Personal Mode',
                          style: AppTextStyles.body(),
                        ),
                        subtitle: Text(
                          user.isTrainer
                              ? 'Managing ${user.traineeIds.length} trainee(s)'
                              : user.hasTrainer
                                  ? 'Training with ${user.trainerName}'
                                  : 'Training independently',
                          style:  AppTextStyles.caption(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Trainer Connection (for personal users)
              if (user != null && ! user.isTrainer) ...[
                Text('Trainer Connection', style: AppTextStyles.h3()),
                const SizedBox(height: AppSpacing.sm),

                Card(
                  child: Column(
                    children:  [
                      if (! user.hasTrainer)
                        ListTile(
                          leading: const Icon(Icons.person_add, color: AppColors.secondary),
                          title: const Text('Connect to Trainer'),
                          subtitle: const Text('Enter your trainer\'s code'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showConnectTrainerDialog(userProvider),
                        )
                      else ...[
                        ListTile(
                          leading: const Icon(Icons.fitness_center, color: AppColors.success),
                          title: Text('Trainer:  ${user.trainerName}'),
                          subtitle: Text('Connected', style: AppTextStyles.caption()),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.link_off, color: AppColors.error),
                          title: const Text('Disconnect from Trainer'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showDisconnectTrainerDialog(userProvider),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height:  AppSpacing.lg),
              ],

              // Workout Preferences
              Text('Workout Preferences', style: AppTextStyles. h3()),
              const SizedBox(height: AppSpacing. sm),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.scale, color: AppColors.info),
                      title: const Text('Weight Unit'),
                      subtitle: Text(weightUnit, style: AppTextStyles.caption()),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showWeightUnitDialog(),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.timer, color: AppColors.warning),
                      title: const Text('Rest Timer'),
                      subtitle: const Text('Auto-start rest timer after sets'),
                      value: restTimerEnabled,
                      onChanged: (value) {
                        setState(() {
                          LocalStorageService.saveSetting('restTimerEnabled', value);
                        });
                      },
                    ),
                    if (restTimerEnabled) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading:  const Icon(Icons.timelapse, color: AppColors.primary),
                        title: const Text('Default Rest Time'),
                        subtitle: Text('$defaultRestTime seconds', style: AppTextStyles.caption()),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showRestTimeDialog(defaultRestTime),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Data Management
              Text('Data Management', style: AppTextStyles.h3()),
              const SizedBox(height: AppSpacing.sm),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons. download, color: AppColors.success),
                      title: const Text('Export Data'),
                      subtitle: const Text('Download your workout data'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showExportDialog(),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: AppColors.error),
                      title: const Text('Clear All Data'),
                      subtitle: const Text('Delete all workouts and templates'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap:  () => _showClearDataDialog(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height:  AppSpacing.lg),

              // Account Actions
              Text('Account Actions', style: AppTextStyles.h3()),
              const SizedBox(height: AppSpacing.sm),

              Card(
                child: ListTile(
                  leading:  const Icon(Icons.logout, color: AppColors.error),
                  title: const Text('Logout'),
                  subtitle:  const Text('Sign out of your account'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLogoutConfirmation(userProvider),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // App Info
              Center(
                child: Column(
                  children: [
                    Text(
                      'RepRise',
                      style:  AppTextStyles.h4(color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Version 1.0.0',
                      style: AppTextStyles.caption(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing. xl),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutConfirmation(UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Logout? ', style: AppTextStyles.h3()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout, color: AppColors.warning, size: 48),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to logout? ',
              style: AppTextStyles.body(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your data is safely stored and will be available when you log back in.',
              style: AppTextStyles.bodySmall(color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:  const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LogoutScreen(),
                ),
              );
            },
            style:  ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // ✅ IMPROVED: Connect to trainer with validation
  void _showConnectTrainerDialog(UserProvider userProvider) {
    final trainerCodeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Connect to Trainer', style:  AppTextStyles.h3()),
          content: Form(
            key: formKey,
            child:  Column(
              mainAxisSize:  MainAxisSize.min,
              children: [
                const Icon(
                  Icons.fitness_center,
                  size: 64,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter your trainer\'s code',
                  style:  AppTextStyles.body(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller:  trainerCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Trainer Code',
                    hintText: 'e.g., TRN-ABC123',
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                  textCapitalization:  TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value. isEmpty) {
                      return 'Please enter trainer code';
                    }
                    if (! value.startsWith('TRN-')) {
                      return 'Invalid trainer code format';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  :  () async {
                      if (! formKey.currentState!.validate()) return;

                      setDialogState(() => isLoading = true);

                      try {
                        final trainerCode = trainerCodeController.text.trim().toUpperCase();
                        
                        // Find trainer by code
                        final trainerQuery = await FirebaseFirestore.instance
                            .collection('users')
                            .where('trainerCode', isEqualTo:  trainerCode)
                            . limit(1)
                            .get();

                        if (trainerQuery.docs.isEmpty) {
                          throw 'Trainer not found.  Please check the code.';
                        }

                        final trainerData = trainerQuery.docs. first.data();
                        final trainerName = trainerData['name'] ?? 'Unknown';

                        // Connect to trainer
                        await userProvider.connectToTrainer(trainerCode);

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons. check_circle, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child:  Text('Connected to $trainerName! '),
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          setState(() {});
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDisconnectTrainerDialog(UserProvider userProvider) {
    showDialog(
      context:  context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Disconnect from Trainer? ', style: AppTextStyles.h3()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, color: AppColors.warning, size: 48),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to disconnect from your trainer?',
              style: AppTextStyles.body(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You will lose access to assigned workouts.',
              style: AppTextStyles. bodySmall(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:  const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await userProvider.disconnectFromTrainer();
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  ScaffoldMessenger. of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Disconnected from trainer'),
                      backgroundColor: AppColors. info,
                    ),
                  );
                  setState(() {});
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to disconnect: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  void _showWeightUnitDialog() {
    final currentUnit = LocalStorageService.getSetting('weightUnit', defaultValue: 'lbs');

    showDialog(
      context:  context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Weight Unit', style: AppTextStyles.h3()),
        content: Column(
          mainAxisSize: MainAxisSize. min,
          children: [
            RadioListTile<String>(
              title: const Text('Pounds (lbs)'),
              value: 'lbs',
              groupValue: currentUnit,
              onChanged: (value) {
                LocalStorageService.saveSetting('weightUnit', value);
                Navigator.pop(dialogContext);
                setState(() {});
              },
            ),
            RadioListTile<String>(
              title: const Text('Kilograms (kg)'),
              value: 'kg',
              groupValue: currentUnit,
              onChanged: (value) {
                LocalStorageService.saveSetting('weightUnit', value);
                Navigator.pop(dialogContext);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRestTimeDialog(int currentTime) {
    final controller = TextEditingController(text:  currentTime.toString());

    showDialog(
      context:  context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Default Rest Time', style: AppTextStyles.h3()),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Seconds',
            hintText:  'Enter rest time in seconds',
          ),
        ),
        actions: [
          TextButton(
            onPressed:  () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTime = int.tryParse(controller.text);
              if (newTime != null && newTime > 0) {
                LocalStorageService.saveSetting('defaultRestTime', newTime);
                Navigator.pop(dialogContext);
                setState(() {});
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Clear All Data? ', style: AppTextStyles.h3()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons. warning, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'This will permanently delete all your workouts, templates, and exercise history.',
              style: AppTextStyles.body(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone! ',
              style: AppTextStyles.bodySmall(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:  const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
              await workoutProvider.clearAllData();
              if (context.mounted) {
                Navigator. pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }
}