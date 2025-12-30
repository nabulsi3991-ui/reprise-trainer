import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/features/workout/providers/workout_provider.dart';
import 'package:reprise/features/workout/screens/workout_screen.dart';
import 'package:reprise/shared/models/workout.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:reprise/shared/widgets/swipe_to_delete.dart';
import 'package:reprise/core/theme/app_theme_manager.dart';

class TemplatePickerScreen extends StatelessWidget {
  final bool isScheduling;
  final DateTime? scheduleDate;
  final bool isPastWorkout; // NEW
  final DateTime? selectedDate; // NEW
  final bool isSelectionMode;

  const TemplatePickerScreen({
    super.key,
    this.isScheduling = false,
    this.scheduleDate,
    this.isPastWorkout = false, // NEW
    this.selectedDate, // NEW
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isScheduling 
              ? 'Schedule Workout' 
              : isPastWorkout 
                  ? 'Log Past Workout'  // NEW
                  : 'Workout Templates',
          style: AppTextStyles.h2(),
        ),
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, child) {
          final templates = workoutProvider.templates;

          if (templates.isEmpty) {
            return Center(
              child:  Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.list_alt,
                      size:  80,
                      color:  AppColors.textSecondaryLight. withOpacity(0.5),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No Templates Yet',
                      style: AppTextStyles.h2(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Create a workout and save it as a template to reuse it anytime',
                      style: AppTextStyles.body(color: AppColors.textSecondaryLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Tap the + button below to get started',
                      style: AppTextStyles.bodySmall(color: AppColors.textSecondaryLight),
                      textAlign:  TextAlign.center,
                    ),
                              const SizedBox(height: AppSpacing. lg),
          // ✅ ADD THIS BUTTON: 
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkoutScreen(
                    workout:  Workout(
                      id:  '',
                      name: 'New Template',
                      date:  DateTime.now(),
                      muscleGroups: [],
                      status: WorkoutStatus.scheduled,
                      exercises: [],
                    ),
                    isTemplate:  true,
                  ),
                ),
              );
              
              // ✅ If scheduling and template was created, stay on this screen
              if (result != null && isScheduling && context.mounted) {
                // The screen will rebuild automatically via Consumer
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Template created!  Select it to schedule. '),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Template'),
            style: ElevatedButton. styleFrom(
              backgroundColor: AppThemeManager.primaryColor, // ✅ Dynamic
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
            ),
          ),

                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing. md),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return _buildTemplateCard(context, template, workoutProvider);
            },
          );
        },
      ),
      floatingActionButton: ! isScheduling && !isPastWorkout
    ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutScreen(
                workout:  Workout(
                  id: '',
                  name: 'New Template',
                  date: DateTime.now(),
                  muscleGroups: [],
                  status: WorkoutStatus.scheduled,
                  exercises: [],
                ),
                isTemplate: true,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Template'),
        backgroundColor: AppThemeManager.primaryColor, // ✅ Dynamic
      )
    : null,
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    Workout template,
    WorkoutProvider workoutProvider,
  ) {
    final exerciseCount = template.exercises.length;
    final totalSets = template.exercises
        .fold<int>(0, (sum, exercise) => sum + exercise.sets.length);
        return SwipeToDelete(
    confirmationTitle: 'Delete Template',
    confirmationMessage: 'Are you sure you want to delete "${template.name}"?',
    onDelete: () {
      workoutProvider.deleteTemplate(template. id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${template.name} deleted'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );}, child: Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap:  () {
          if (isScheduling) {
            _scheduleWorkout(context, template, workoutProvider);
          } else if (isPastWorkout) { // NEW
            _logPastWorkout(context, template, workoutProvider);
          } else {
            _showTemplateOptions(context, template, workoutProvider);
          }
        },
        borderRadius: BorderRadius. circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment:  CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: template.muscleGroups. isNotEmpty
                          ? AppColors.getMuscleGroupColor(template.muscleGroups.first)
                              .withOpacity(0.2)
                          : AppColors. primary.withOpacity(0.2),
                      borderRadius:  BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: Icon(
                      Icons.list_alt,
                      color: template.muscleGroups.isNotEmpty
                          ? AppColors. getMuscleGroupColor(template. muscleGroups.first)
                          : AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment. start,
                      children: [
                        Text(
                          template.name,
                          style: AppTextStyles.h3(),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '$exerciseCount exercises • $totalSets sets',
                          style: AppTextStyles.caption(),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              if (template.muscleGroups.isNotEmpty) ...[
                const SizedBox(height:  AppSpacing.sm),
                Wrap(
                  spacing:  AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: template.muscleGroups.map((group) {
                    return Chip(
                      label:  Text(
                        group,
                        style: AppTextStyles.caption(color: Colors.white),
                      ),
                      backgroundColor: AppColors.getMuscleGroupColor(group),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ],
              if (template.exercises.isNotEmpty) ...[
                const SizedBox(height:  AppSpacing.sm),
                const Divider(),
                const SizedBox(height: AppSpacing.xs),
                ... template.exercises.take(3).map((exercise) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.fiber_manual_record,
                          size: 8,
                          color: AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            '${exercise. name} (${exercise.sets. length} sets)',
                            style: AppTextStyles.bodySmall(),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (template.exercises. length > 3)
                  Padding(
                    padding:  const EdgeInsets.only(top: 4),
                    child: Text(
                      '+ ${template.exercises.length - 3} more exercises',
                      style:  AppTextStyles.caption(),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    ),);
  }

  void _scheduleWorkout(
    BuildContext context,
    Workout template,
    WorkoutProvider workoutProvider,
  ) {
    final scheduledWorkout = template.copyWith(
      id: const Uuid().v4(),
      date: scheduleDate ?? DateTime.now(),
      status: WorkoutStatus.scheduled,
      isAssignedWorkout: false,
    );

    workoutProvider.addScheduledWorkout(scheduledWorkout);
    Navigator.pop(context, scheduledWorkout);
  }

  // FIXED: Handle past workout logging with correct date
void _logPastWorkout(
  BuildContext context,
  Workout template,
  WorkoutProvider workoutProvider, 
) {
  showModalBottomSheet(
    context:  context,
    builder: (sheetContext) => Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            template.name,
            style: AppTextStyles.h2(),
          ),
          const SizedBox(height: AppSpacing. sm),
          
          // Show the selected past date
          if (selectedDate != null)
            Text(
              'Logging for: ${DateFormat('MMMM d, yyyy').format(selectedDate!)}',
              style: AppTextStyles.body(color: AppColors.info),
            ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // PRIMARY OPTION: Log Completed Workout
          ListTile(
            leading: const Icon(Icons.edit, color: AppColors.primary),
            title: const Text('Log Completed Workout'),
            subtitle: const Text('Record workout with this template'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final workout = workoutProvider.createWorkoutFromTemplate(template);
              
              // CRITICAL: Set date to the selected PAST date, not today
              final pastWorkout = workout.copyWith(
                date: selectedDate ??  DateTime.now(),
                status: WorkoutStatus.inProgress,
              );
              
              Navigator.pop(sheetContext); // Close bottom sheet
              Navigator.pop(context, pastWorkout); // Return workout with correct date
            },
          ),
          
          const Divider(),
          
          // SECONDARY OPTIONS:  Edit/Delete Template
          ListTile(
            leading: const Icon(Icons.edit_note, color: AppColors.secondary),
            title: const Text('Edit Template'),
            subtitle: const Text('Modify exercises and sets'),
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:  (context) => WorkoutScreen(
                    workout:  template,
                    isTemplate: true,
                  ),
                ),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.delete, color: AppColors.error),
            title: const Text('Delete Template'),
            subtitle: const Text('Remove this template'),
            onTap: () {
              Navigator.pop(sheetContext);
              _showDeleteConfirmation(context, template, workoutProvider);
            },
          ),
        ],
      ),
    ),
  );
}

  void _showTemplateOptions(
    BuildContext context,
    Workout template,
    WorkoutProvider workoutProvider,
  ) {
    
    if (isSelectionMode) {
      // Just return the selected template
      Navigator.pop(context, template);
      return;
    }
    
    showModalBottomSheet(
      context:  context,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              template.name,
              style: AppTextStyles. h2(),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.play_arrow, color: AppColors. primary),
              title: const Text('Start Workout Now'),
              subtitle: const Text('Begin workout immediately'),
              onTap: () {
                final workout = workoutProvider.createWorkoutFromTemplate(template);
                Navigator.pop(sheetContext);
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutScreen(workout: workout, autoStart: true),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: AppColors. info),
              title: const Text('Schedule for Later'),
              subtitle: const Text('Add to calendar for future date'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showDatePicker(context, template, workoutProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.secondary),
              title: const Text('Edit Template'),
              subtitle: const Text('Modify exercises and sets'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:  (context) => WorkoutScreen(
                      workout: template,
                      isTemplate: true,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Delete Template'),
              subtitle: const Text('Remove this template'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showDeleteConfirmation(context, template, workoutProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDatePicker(
    BuildContext context,
    Workout template,
    WorkoutProvider workoutProvider,
  ) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((selectedDate) {
      if (selectedDate != null) {
        final scheduledWorkout = template.copyWith(
          id: const Uuid().v4(),
          date: selectedDate,
          status: WorkoutStatus.scheduled,
          isAssignedWorkout: false,
        );

        workoutProvider.addScheduledWorkout(scheduledWorkout);
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Workout scheduled for ${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
            ),
            backgroundColor: AppColors. success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Workout template,
    WorkoutProvider workoutProvider,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete Template', style: AppTextStyles.h3()),
        content: Text(
          'Are you sure you want to delete "${template.name}"? This action cannot be undone.',
          style: AppTextStyles.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final templateName = template.name;
              Navigator.pop(dialogContext);
              await Future.delayed(const Duration(milliseconds: 100));
              await workoutProvider.deleteTemplate(template. id);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$templateName deleted'),
                    backgroundColor: AppColors. error,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors. error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}