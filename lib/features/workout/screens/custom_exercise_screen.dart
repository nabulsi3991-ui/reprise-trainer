import 'package:flutter/material.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/shared/models/exercise_library.dart';

class CustomExerciseScreen extends StatefulWidget {
  const CustomExerciseScreen({super.key});

  @override
  State<CustomExerciseScreen> createState() => _CustomExerciseScreenState();
}

class _CustomExerciseScreenState extends State<CustomExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String?  _selectedMuscleGroup;
  String _selectedEquipment = 'Dumbbell';
  int _defaultSets = 3;
  int _defaultReps = 10;

  final List<String> _availableMuscleGroups = [
    'Chest',
    'Back',
    'Shoulders',
    'Legs',
    'Biceps',
    'Triceps',
    'Core',
    'Glutes',
    'Forearms',
    'Traps',
    'Cardio',
  ];

  final List<String> _availableEquipment = [
    'Barbell',
    'Dumbbell',
    'Machine',
    'Cable',
    'Bodyweight',
    'Other',
  ];

  @override
  void dispose() {
    _nameController. dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Custom Exercise', style: AppTextStyles. h3()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding:  const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing. radiusMedium),
                  border: Border.all(color: AppColors.info. withOpacity(0.3)),
                ),
                child:  Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child:  Text(
                        'Create your own exercise!',
                        style: AppTextStyles.bodySmall(color: AppColors. info),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height:  AppSpacing.xl),

              // Exercise Name
              Text('Exercise Name *', style: AppTextStyles.h4()),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Reverse Grip Cable Row',
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter exercise name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // Muscle Group
              Text('Primary Muscle Group *', style: AppTextStyles.h4()),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: _selectedMuscleGroup,
                decoration: const InputDecoration(
                  hintText: 'Select muscle group',
                  prefixIcon: Icon(Icons.accessibility_new),
                ),
                items: _availableMuscleGroups.map((group) {
                  return DropdownMenuItem(
                    value:  group,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.getMuscleGroupColor(group),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(group),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMuscleGroup = value;
                  });
                },
                validator:  (value) {
                  if (value == null) {
                    return 'Please select a muscle group';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // Equipment
              Text('Equipment', style: AppTextStyles.h4()),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: _selectedEquipment,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.build),
                ),
                items: _availableEquipment.map((equipment) {
                  return DropdownMenuItem(
                    value: equipment,
                    child: Text(equipment),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEquipment = value! ;
                  });
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // Description (Optional)
              Text('Description (Optional)', style: AppTextStyles. h4()),
              const SizedBox(height: AppSpacing. sm),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Add notes about form, tips, etc.',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization. sentences,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Default Sets & Reps Section
              Text('Default Workout Settings', style: AppTextStyles.h3()),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:  CrossAxisAlignment.start,
                      children: [
                        Text('Sets', style: AppTextStyles.bodySmall()),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                            border: Border.all(color: AppColors.textSecondaryLight. withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: _defaultSets > 1
                                    ? () => setState(() => _defaultSets--)
                                    : null,
                              ),
                              Text('$_defaultSets', style: AppTextStyles.h3()),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _defaultSets < 10
                                    ? () => setState(() => _defaultSets++)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing. md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reps', style: AppTextStyles. bodySmall()),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius:  BorderRadius.circular(AppSpacing.radiusSmall),
                            border: Border.all(color: AppColors.textSecondaryLight.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment. spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: _defaultReps > 1
                                    ? () => setState(() => _defaultReps--)
                                    : null,
                              ),
                              Text('$_defaultReps', style: AppTextStyles.h3()),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _defaultReps < 50
                                    ? () => setState(() => _defaultReps++)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Create Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton. icon(
                  onPressed:  _createExercise,
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Create Exercise'),
                  style:  ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                ),
              ),

              const SizedBox(height:  AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  void _createExercise() {
    if (_formKey.currentState! .validate()) {
      // Create custom exercise with default 90 second rest
      final customExercise = ExerciseTemplate(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        muscleGroups: [_selectedMuscleGroup!],
        equipment: _selectedEquipment,
        description: _descriptionController.text.trim().isEmpty
            ? 'Custom exercise'
            : _descriptionController. text.trim(),
        defaultSets: _defaultSets,
        defaultReps: _defaultReps,
        defaultRestSeconds: 90, // Fixed default rest time
      );

      // Return the custom exercise
      Navigator.pop(context, customExercise);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${customExercise.name} created!  🎉'),
          backgroundColor: AppColors.success,
          duration: const Duration(milliseconds: 1200),
        ),
      );
    }
  }
}