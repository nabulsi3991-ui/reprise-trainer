import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/features/workout/providers/workout_provider.dart';
import 'package:reprise/features/workout/screens/workout_screen.dart';
import 'package:reprise/features/workout/screens/workout_history_screen.dart';
import 'package:reprise/features/workout/screens/template_picker_screen.dart';
import 'package:reprise/features/workout/screens/pr_history_screen.dart';
import 'package:reprise/features/schedule/screens/weekly_schedule_screen.dart';
import 'package:reprise/features/analytics/screens/exercise_analytics_screen.dart';
import 'package:reprise/features/measurements/screens/measurements_screen.dart';
import 'package:reprise/shared/models/workout.dart';
import 'package:reprise/services/local_storage_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:reprise/shared/widgets/swipe_to_delete.dart';
import 'package:reprise/features/workout/screens/workout_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RepRise', style: AppTextStyles.h2()),
        actions: [
          IconButton(
            icon: const Icon(Icons. tune),
            onPressed: () => _showDashboardSettings(context),
            tooltip: 'Customize Dashboard',
          ),
        ],
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, child) {
          final streak = workoutProvider.getCurrentStreak();
          final thisWeekCount = workoutProvider.getThisWeekCount();
          final totalPRs = workoutProvider.getTotalPRs();
          final thisMonthCount = _getThisMonthCount(workoutProvider);
          final nextWorkout = workoutProvider.getNextScheduledWorkout();
          final recentWorkouts = workoutProvider.getRecentWorkouts(limit: 3);

          final showWeeklySchedule = LocalStorageService.getSetting('showWeeklySchedule', defaultValue: true);
          final showExerciseAnalytics = LocalStorageService.getSetting('showExerciseAnalytics', defaultValue: true);
          final showMeasurements = LocalStorageService.getSetting('showMeasurements', defaultValue: false);

          final totalWorkouts = workoutProvider.getAllWorkouts()
              .where((w) => w.status == WorkoutStatus.completed)
              .length;
          final level = _calculateLevel(totalWorkouts, totalPRs);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Let\'s Workout!  🔥', style: AppTextStyles. h2()),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Ready to crush your workout? ',
                  style: AppTextStyles.body(color: AppColors.textSecondaryLight),
                ),
                
                // START WORKOUT BUTTON
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width:  double.infinity,
                  child: ElevatedButton. icon(
                    onPressed:  () => _showStartWorkoutOptions(context),
                    icon: const Icon(Icons.fitness_center, size: 24),
                    label: const Text(
                      'Start Workout',
                      style:  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      elevation: 4,
                    ),
                  ),
                ),

                const SizedBox(height:  AppSpacing.lg),

                // ✅ FIXED: Stats Cards with borders/edges
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.local_fire_department,
                        iconColor: AppColors.primary,
                        label: 'Streak',
                        value:  '$streak days',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons. fitness_center,
                        iconColor: AppColors.secondary,
                        label: 'This Week',
                        value:  '$thisWeekCount/7',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height:  AppSpacing.md),
                Row(
                  children:  [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:  (context) => const PRHistoryScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        child: _buildStatCard(
                          icon:  Icons.trending_up,
                          iconColor: AppColors.success,
                          label: 'PRs',
                          value: '$totalPRs',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.calendar_month,
                        iconColor: AppColors.info,
                        label: 'This Month',
                        value:  '$thisMonthCount',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height:  AppSpacing.lg),

                // ✅ REVERTED: Dynamic Action Cards (original logic)
                _buildActionCardsRow(
                  context,
                  showWeeklySchedule,
                  showExerciseAnalytics,
                  showMeasurements,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Next Workout Section
                Text('Next Workout', style: AppTextStyles.h3()),
                const SizedBox(height: AppSpacing.md),
                _buildNextWorkoutCard(context, nextWorkout, workoutProvider),

                const SizedBox(height: AppSpacing.xl),

                // Recent Activity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Activity', style: AppTextStyles. h3()),
                    if (recentWorkouts.isNotEmpty)
                      TextButton(
                        onPressed:  () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WorkoutHistoryScreen(),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                  ],
                ),
                const SizedBox(height:  AppSpacing.md),

                if (recentWorkouts.isEmpty)
                  _buildEmptyState()
                else
                  ... recentWorkouts.map((workout) => _buildRecentActivityCard(
                        context,
                        workout,
                        workoutProvider,
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  int _getThisMonthCount(WorkoutProvider workoutProvider) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now. year, now.month + 1, 0);
    
    return workoutProvider.getAllWorkouts()
        .where((w) => w.status == WorkoutStatus.completed)
        .where((w) => 
            w.date.isAfter(startOfMonth. subtract(const Duration(days: 1))) &&
            w.date.isBefore(endOfMonth.add(const Duration(days: 1))))
        .length;
  }

  int _calculateLevel(int totalWorkouts, int totalPRs) {
    int workoutLevel = totalWorkouts ~/ 5;
    int prBonus = totalPRs ~/ 3;
    return 1 + workoutLevel + prBonus;
  }

  void _showStartWorkoutOptions(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen:  false);
    
    showModalBottomSheet(
      context:  context,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Start Workout', style: AppTextStyles.h2()),
            const SizedBox(height: AppSpacing.lg),
            
            ListTile(
              leading: const Icon(Icons.list_alt, color: AppColors.primary),
              title: const Text('From Template'),
              subtitle: const Text('Choose a saved workout'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                Navigator.pop(sheetContext);
                final template = await Navigator.push<Workout>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TemplatePickerScreen(),
                  ),
                );
                
                if (template != null && context.mounted) {
                  final workout = workoutProvider.createWorkoutFromTemplate(template);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutScreen(workout: workout, autoStart: true),
                    ),
                  );
                }
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.add_circle, color: AppColors.secondary),
              title: const Text('Quick Workout'),
              subtitle: const Text('Start with empty workout'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(sheetContext);
                
                final emptyWorkout = Workout(
                  id: const Uuid().v4(),
                  name: 'Quick Workout',
                  date:  DateTime.now(),
                  muscleGroups: [],
                  status: WorkoutStatus.inProgress,
                  exercises: [],
                );
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutScreen(
                      workout: emptyWorkout,
                      isTemplate: false,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ✅ REVERTED + FIXED: Original logic with size fix
  Widget _buildActionCardsRow(
    BuildContext context,
    bool showWeeklySchedule,
    bool showExerciseAnalytics,
    bool showMeasurements,
  ) {
    List<Widget> cards = [];

    if (showWeeklySchedule) {
      cards.add(Expanded(
        child: _buildActionCard(
          context:  context,
          icon: Icons. calendar_view_week,
          color: AppColors.info,
          title: 'Weekly Schedule',
          subtitle: 'Plan your week',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WeeklyScheduleScreen(),
              ),
            );
          },
        ),
      ));
    }

    if (showExerciseAnalytics) {
      if (cards.isNotEmpty) cards.add(const SizedBox(width: AppSpacing.md));
      cards.add(Expanded(
        child: _buildActionCard(
          context: context,
          icon: Icons.bar_chart,
          color: AppColors.secondary,
          title: 'Exercise Analytics',
          subtitle: 'Track progress',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ExerciseAnalyticsScreen(),
              ),
            );
          },
        ),
      ));
    }

    if (showMeasurements) {
      if (cards.isNotEmpty) cards.add(const SizedBox(width: AppSpacing.md));
      cards.add(Expanded(
        child: _buildActionCard(
          context: context,
          icon: Icons.straighten,
          color: AppColors.warning,
          title: 'Measurements',
          subtitle: 'Body tracking',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MeasurementsScreen(),
              ),
            );
          },
        ),
      ));
    }

    if (cards.isEmpty) {
      return const SizedBox. shrink();
    }
    
    // ✅ FIXED: Don't add empty placeholder, use proper Expanded widgets
    // This ensures all cards have equal width
    if (cards.length == 1) {
      // If only one card, add an empty Expanded to balance
      cards.add(const SizedBox(width: AppSpacing.md));
      cards.add(Expanded(child: const SizedBox. shrink()));
    }

    return Row(children: cards);
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius. circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(title, style: AppTextStyles.h4(), textAlign: TextAlign.center),
              const SizedBox(height:  AppSpacing.xs),
              Text(subtitle, style: AppTextStyles.caption(), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  void _showDashboardSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _DashboardSettingsSheet(
        onSaved: () {
          setState(() {});
        },
      ),
    );
  }

  // ✅ FIXED: Added border/edge to stat cards
  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius:  BorderRadius.circular(AppSpacing.radiusMedium),
        // ✅ NEW: Added border for iOS visibility
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        // ✅ NEW: Added subtle shadow
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size:  AppSpacing.iconLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTextStyles.h3()),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style:  AppTextStyles.caption()),
        ],
      ),
    );
  }

  Widget _buildNextWorkoutCard(BuildContext context, Workout?  nextWorkout, WorkoutProvider workoutProvider) {
    if (nextWorkout == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius. circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.textSecondaryLight. withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available,
              size: 48,
              color: AppColors.textSecondaryLight. withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No upcoming workouts',
              style: AppTextStyles.body(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Schedule a workout in the calendar',
              style: AppTextStyles.caption(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final daysUntil = nextWorkout.date.difference(DateTime.now()).inDays;
    final dayText = daysUntil == 0
        ? 'Today'
        : daysUntil == 1
            ? 'Tomorrow'
            : DateFormat('EEEE').format(nextWorkout.date);

    return InkWell(
      onTap: () {
        if (daysUntil == 0) {
          final activeWorkout = workoutProvider.createWorkoutFromTemplate(nextWorkout);
          workoutProvider.deleteWorkout(nextWorkout.id, nextWorkout.date);
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutScreen(workout: activeWorkout, autoStart:  true),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This workout is scheduled for $dayText'),
              duration: const Duration(milliseconds: 800),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white, size: 40),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nextWorkout.name, style: AppTextStyles.h3(color: Colors.white)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$dayText • ${nextWorkout.muscleGroups.join(", ")}',
                    style:  AppTextStyles.body(color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (daysUntil == 0)
              const Icon(Icons.play_arrow, color: Colors.white, size: 32)
            else
              const Icon(Icons. arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing. xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius. circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(Icons.fitness_center, size: 64, color: AppColors.textSecondaryLight. withOpacity(0.5)),
          const SizedBox(height: AppSpacing.md),
          Text('No workouts yet', style: AppTextStyles.h3()),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Start your first workout to see it here',
            style: AppTextStyles. body(color: AppColors.textSecondaryLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(BuildContext context, Workout workout, WorkoutProvider workoutProvider) {
  final weightUnit = LocalStorageService.getSetting('weightUnit', defaultValue: 'lbs');
  final displayVolume = weightUnit == 'kg'
      ? (workout.totalVolume * 0.453592).toInt()
      : workout.totalVolume;

  final daysAgo = DateTime.now().difference(workout.date).inDays;
  final dateText = daysAgo == 0
      ? 'Today'
      : daysAgo == 1
          ? 'Yesterday'
          :  DateFormat('MMM d').format(workout.date);

  return SwipeToDelete(
    confirmationTitle: 'Delete Workout',
    confirmationMessage: 'Are you sure you want to delete this workout?',
    onDelete: () {
      workoutProvider.deleteWorkout(workout. id, workout.date);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout deleted'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
    },
    child: Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () {
          Navigator. push(
            context,
            MaterialPageRoute(
              builder:  (context) => WorkoutDetailScreen(workout: workout),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing. md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: workout.muscleGroups.isNotEmpty
                      ? AppColors.getMuscleGroupColor(workout.muscleGroups.first)
                          .withOpacity(0.2)
                      : AppColors. primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing. radiusSmall),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color:  workout.muscleGroups.isNotEmpty
                      ? AppColors.getMuscleGroupColor(workout.muscleGroups.first)
                      : AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workout.name, style: AppTextStyles.h4()),
                    const SizedBox(height: 4),
                    if (workout.status == WorkoutStatus.completed) ...[
                      Text(
                        '$displayVolume $weightUnit • ${workout. durationMinutes} min',
                        style: AppTextStyles.caption(),
                      ),
                    ] else ...[
                      Text(
                        'Scheduled',
                        style: AppTextStyles.caption(color: AppColors. warning),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      dateText,
                      style: AppTextStyles.caption(),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondaryLight),
            ],
          ),
        ),
      ),
    ),
  );
}

  void _showDeleteConfirmation(BuildContext context, Workout workout, WorkoutProvider workoutProvider) {
    showDialog(
      context:  context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete Workout', style: AppTextStyles.h3()),
        content: Text('Are you sure you want to delete "${workout.name}"?', style: AppTextStyles.body()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              workoutProvider.deleteWorkout(workout.id, workout.date);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger. of(context).showSnackBar(
                SnackBar(
                  content: Text('${workout.name} deleted'),
                  backgroundColor: AppColors.success,
                  duration: const Duration(milliseconds: 800),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _DashboardSettingsSheet extends StatefulWidget {
  final VoidCallback onSaved;

  const _DashboardSettingsSheet({required this.onSaved});

  @override
  State<_DashboardSettingsSheet> createState() => _DashboardSettingsSheetState();
}

class _DashboardSettingsSheetState extends State<_DashboardSettingsSheet> {
  late bool _showWeeklySchedule;
  late bool _showExerciseAnalytics;
  late bool _showMeasurements;

  @override
  void initState() {
    super.initState();
    _showWeeklySchedule = LocalStorageService.getSetting('showWeeklySchedule', defaultValue: true);
    _showExerciseAnalytics = LocalStorageService.getSetting('showExerciseAnalytics', defaultValue: true);
    _showMeasurements = LocalStorageService.getSetting('showMeasurements', defaultValue: false);
  }

  @override
  Widget build(BuildContext context) {
    int selectedCount = 0;
    if (_showWeeklySchedule) selectedCount++;
    if (_showExerciseAnalytics) selectedCount++;
    if (_showMeasurements) selectedCount++;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Customize Dashboard', style: AppTextStyles.h2()),
          const SizedBox(height: AppSpacing.sm),
          Text('Select up to 2 cards to display', style: AppTextStyles.caption()),
          const SizedBox(height: AppSpacing.lg),
          
          CheckboxListTile(
            title: const Text('Weekly Schedule'),
            subtitle: const Text('Plan your workout week'),
            value: _showWeeklySchedule,
            onChanged: (value) {
              if (value == true && selectedCount >= 2) return;
              setState(() {
                _showWeeklySchedule = value ??  false;
                LocalStorageService.saveSetting('showWeeklySchedule', value);
              });
            },
          ),
          
          CheckboxListTile(
            title: const Text('Exercise Analytics'),
            subtitle: const Text('Track exercise progress'),
            value: _showExerciseAnalytics,
            onChanged: (value) {
              if (value == true && selectedCount >= 2) return;
              setState(() {
                _showExerciseAnalytics = value ?? false;
                LocalStorageService.saveSetting('showExerciseAnalytics', value);
              });
            },
          ),
          
          CheckboxListTile(
            title: const Text('Body Measurements'),
            subtitle: const Text('Track body metrics'),
            value: _showMeasurements,
            onChanged: (value) {
              if (value == true && selectedCount >= 2) return;
              setState(() {
                _showMeasurements = value ?? false;
                LocalStorageService.saveSetting('showMeasurements', value);
              });
            },
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onSaved();
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}