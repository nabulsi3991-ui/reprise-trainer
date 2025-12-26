import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/features/workout/screens/workout_screen.dart';
import 'package:reprise/features/workout/screens/template_picker_screen.dart';
import 'package:reprise/features/workout/screens/workout_history_screen.dart';
import 'package:reprise/features/workout/screens/workout_detail_screen.dart';
import 'package:reprise/features/workout/providers/workout_provider.dart';
import 'package:reprise/shared/models/workout.dart';
import 'package:uuid/uuid.dart';
import 'package:reprise/shared/widgets/swipe_to_delete.dart';

class WorkoutListScreen extends StatelessWidget {
  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workouts', style: AppTextStyles. h2()),
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, child) {
          final templates = workoutProvider.templates;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Actions
                _buildQuickActions(context, workoutProvider),
                
                const SizedBox(height: AppSpacing.xl),

                // Templates Section
                Row(
                  mainAxisAlignment:  MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Quick Start Templates', style:  AppTextStyles.h3()),
                    TextButton(
                      onPressed:  () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TemplatePickerScreen(),
                          ),
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                
                if (templates.isEmpty)
                  _buildEmptyTemplates(context)
                else
                  _buildTemplatesList(context, templates. take(3).toList(), workoutProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WorkoutProvider workoutProvider) {
  final hasTemplates = workoutProvider.templates.isNotEmpty;

  return Column(
    children:  [
      // Start from Template - ALWAYS VISIBLE NOW
      SizedBox(
        width: double.infinity,
        child: ElevatedButton. icon(
          onPressed: () {
            if (hasTemplates) {
              _showTemplateSelector(context, workoutProvider);
            } else {
              // Show message if no templates
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Please create a template first! '),
                  backgroundColor: AppColors.warning,
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'Create',
                    textColor: Colors.white,
                    onPressed: () {
                      // Navigate to template creation
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TemplatePickerScreen(),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
          },
          icon:  Icon(Icons.list_alt, size: 28, color: hasTemplates ? Colors.white : AppColors.textSecondaryLight),
          label: Text(
            'Start from Template',
            style:  TextStyle(
              fontSize: 18,
              color: hasTemplates ? Colors.white : AppColors.textSecondaryLight,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: hasTemplates ? AppColors.primary : AppColors.surfaceLight,
            foregroundColor: hasTemplates ? Colors.white : AppColors.textSecondaryLight,
            padding:  const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          ),
        ),
      ),
      
      const SizedBox(height: AppSpacing.md),

      // Start Empty Workout
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            _startEmptyWorkout(context);
          },
          icon: const Icon(Icons.add),
          label: const Text('Start Empty Workout'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
        ),
      ),
      
      const SizedBox(height:  AppSpacing.md),

      // Other Actions Row
      Row(
        children:  [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TemplatePickerScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('Templates'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets. symmetric(vertical: AppSpacing. md),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing. sm),
          Expanded(
            child: OutlinedButton. icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:  (context) => const WorkoutHistoryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('History'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

  void _startEmptyWorkout(BuildContext context) {
    final emptyWorkout = Workout(
      id:  const Uuid().v4(),
      name: 'Quick Workout',
      date: DateTime.now(),
      muscleGroups: [],
      status: WorkoutStatus.inProgress,
      exercises: [],
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutScreen(workout: emptyWorkout),
      ),
    );
  }

  void _showTemplateSelector(BuildContext context, WorkoutProvider workoutProvider) {
  showModalBottomSheet(
    context:  context,
    builder: (context) => Container(
      padding:  const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Choose Template', style: AppTextStyles.h2()),
          const SizedBox(height: AppSpacing.lg),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: workoutProvider.templates.length,
              itemBuilder: (context, index) {
                final template = workoutProvider.templates[index];
                return SwipeToDelete(
                  confirmationTitle: 'Delete Template',
                  confirmationMessage: 'Delete "${template.name}"? ',
                  onDelete: () {
                    workoutProvider. deleteTemplate(template.id);
                    Navigator.pop(context); // Close bottom sheet
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${template. name} deleted'),
                        backgroundColor: AppColors.error,
                        duration: const Duration(seconds:  2),
                      ),
                    );
                  },
                  child: ListTile(
                    leading:  Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: template.muscleGroups.isNotEmpty
                            ?  AppColors.getMuscleGroupColor(template.muscleGroups. first)
                                .withOpacity(0.2)
                            : AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius. circular(AppSpacing.radiusSmall),
                      ),
                      child: Icon(
                        Icons.list_alt,
                        color: template.muscleGroups.isNotEmpty
                            ? AppColors.getMuscleGroupColor(template.muscleGroups.first)
                            :  AppColors.primary,
                      ),
                    ),
                    title: Text(template.name, style: AppTextStyles.h4()),
                    subtitle: Text(
                      '${template.exercises.length} exercises',
                      style: AppTextStyles.caption(),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final workout = workoutProvider.createWorkoutFromTemplate(template);
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:  (context) => WorkoutScreen(workout: workout),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildEmptyTemplates(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius:  BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: AppColors.textSecondaryLight. withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.list_alt,
            size: 48,
            color: AppColors. textSecondaryLight. withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No templates yet',
            style: AppTextStyles. body(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Create workouts and save them as templates',
            style: AppTextStyles.caption(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesList(BuildContext context, List<Workout> templates, WorkoutProvider workoutProvider) {
  return Column(
    children: templates.map((template) {
      return SwipeToDelete(
        confirmationTitle: 'Delete Template',
        confirmationMessage: 'Delete "${template.name}"?',
        onDelete: () {
          workoutProvider.deleteTemplate(template.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${template.name} deleted'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            leading:  Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: template.muscleGroups.isNotEmpty
                    ? AppColors. getMuscleGroupColor(template. muscleGroups.first)
                        .withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Icon(
                Icons.list_alt,
                color: template.muscleGroups.isNotEmpty
                    ? AppColors.getMuscleGroupColor(template.muscleGroups.first)
                    :  AppColors.primary,
              ),
            ),
            title: Text(template.name, style: AppTextStyles.h4()),
            subtitle: Text(
              '${template.exercises.length} exercises',
              style: AppTextStyles. caption(),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final workout = workoutProvider.createWorkoutFromTemplate(template);
              Navigator. push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkoutScreen(workout: workout),
                ),
              );
            },
          ),
        ),
      );
    }).toList(),
  );
}
}