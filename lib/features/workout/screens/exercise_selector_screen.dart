import 'package:flutter/material.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/shared/models/exercise_library.dart';
import 'package:reprise/features/workout/screens/custom_exercise_screen.dart';
import 'package:reprise/shared/widgets/swipe_to_delete.dart';

class ExerciseSelectorScreen extends StatefulWidget {
  const ExerciseSelectorScreen({super.key});

  @override
  State<ExerciseSelectorScreen> createState() => _ExerciseSelectorScreenState();
}

class _ExerciseSelectorScreenState extends State<ExerciseSelectorScreen> {
  String _selectedMuscleGroup = 'All';
  String _selectedEquipment = 'All';
  String _searchQuery = '';
  bool _showCustomOnly = false;

  @override
  Widget build(BuildContext context) {
    final muscleGroups = ['All', ... ExerciseLibrary.getAllMuscleGroups()];
    final equipment = ['All', ...ExerciseLibrary.getAllEquipmentTypes()];
    
    final allExercises = _showCustomOnly 
        ? ExerciseLibrary.getCustomExercises()
        : ExerciseLibrary.getAllExercises();
    
    final filteredExercises = allExercises.where((exercise) {
      final matchesMuscleGroup = _selectedMuscleGroup == 'All' || 
                                  exercise.muscleGroups.contains(_selectedMuscleGroup);
      final matchesEquipment = _selectedEquipment == 'All' || 
                               exercise.equipment == _selectedEquipment;
      final matchesSearch = _searchQuery.isEmpty ||
                           exercise.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesMuscleGroup && matchesEquipment && matchesSearch;
    }).toList();

    final customCount = ExerciseLibrary.getCustomExercises().length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Exercise', style: AppTextStyles.h2()),
        actions: [
          if (customCount > 0)
            IconButton(
              icon:  Icon(
                _showCustomOnly ? Icons. bookmark :  Icons.bookmark_border,
                color: _showCustomOnly ? AppColors.secondary : null,
              ),
              onPressed: () {
                setState(() {
                  _showCustomOnly = !_showCustomOnly;
                });
              },
              tooltip: _showCustomOnly ? 'Show All' : 'Show Custom Only',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search ${filteredExercises.length} exercises...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor:  Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            color: Theme.of(context).cardColor,
            child: ElevatedButton. icon(
              onPressed: () async {
                final customExercise = await Navigator.push<ExerciseTemplate>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomExerciseScreen(),
                  ),
                );
                
                if (customExercise != null && mounted) {
                  ExerciseLibrary.addCustomExercise(customExercise);
                  setState(() {});
                  Navigator.pop(context, customExercise);
                }
              },
              icon: const Icon(Icons.add_circle_outline),
              label: Text(customCount > 0 
                  ? 'Create Custom Exercise ($customCount saved)'
                  : 'Create Custom Exercise'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),

          const Divider(height: 1),

          Container(
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment:  MainAxisAlignment.spaceBetween,
                    children: [
                      Text('MUSCLE GROUP', style: AppTextStyles.caption()),
                      if (_showCustomOnly)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'CUSTOM ONLY',
                            style: AppTextStyles.caption(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: ListView. builder(
                    scrollDirection:  Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: muscleGroups.length,
                    itemBuilder: (context, index) {
                      final muscleGroup = muscleGroups[index];
                      final isSelected = muscleGroup == _selectedMuscleGroup;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: FilterChip(
                          label: Text(muscleGroup),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedMuscleGroup = muscleGroup;
                            });
                          },
                          backgroundColor:  AppColors.surfaceLight,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing. xs),
                  child: Text('EQUIPMENT', style: AppTextStyles.caption()),
                ),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: equipment.length,
                    itemBuilder: (context, index) {
                      final equip = equipment[index];
                      final isSelected = equip == _selectedEquipment;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: FilterChip(
                          label: Text(equip),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedEquipment = equip;
                            });
                          },
                          backgroundColor:  AppColors.surfaceLight,
                          selectedColor: AppColors. secondary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),

          const Divider(height:  1),

          Expanded(
            child: filteredExercises.isEmpty
                ? Center(
                    child:  Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size:  64,
                          color: AppColors.textSecondaryLight. withOpacity(0.5),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No exercises found',
                          style: AppTextStyles.body(color: AppColors.textSecondaryLight),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton. icon(
                          onPressed:  () async {
                            final customExercise = await Navigator.push<ExerciseTemplate>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CustomExerciseScreen(),
                              ),
                            );
                            
                            if (customExercise != null && mounted) {
                              ExerciseLibrary.addCustomExercise(customExercise);
                              setState(() {});
                              Navigator.pop(context, customExercise);
                            }
                          },
                          icon:  const Icon(Icons.add),
                          label: const Text('Create Custom Exercise'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filteredExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = filteredExercises[index];
                      return _buildExerciseCard(exercise);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(ExerciseTemplate exercise) {
  final isCustom = ExerciseLibrary.isCustomExercise(exercise.id);

  final cardContent = Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    child: InkWell(
      onTap: () {
        Navigator.pop(context, exercise);
      },
      onLongPress: isCustom ? () => _showDeleteConfirmation(exercise) : null,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment:  CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets. all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.getMuscleGroupColor(exercise.muscleGroups.first)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Icon(
                    _getExerciseIcon(exercise. muscleGroups.first),
                    color: AppColors.getMuscleGroupColor(exercise.muscleGroups.first),
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment. start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: AppTextStyles.h3(),
                            ),
                          ),
                          if (isCustom)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'CUSTOM',
                                style: AppTextStyles.caption(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        exercise.muscleGroups.join(', '),
                        style: AppTextStyles.caption(),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondaryLight),
              ],
            ),
            if (exercise.description != null && exercise.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing. sm),
              Text(
                exercise.description!,
                style: AppTextStyles.bodySmall(color: AppColors.textSecondaryLight),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing. sm),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fitness_center, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        exercise.equipment,
                        style: AppTextStyles.caption(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${exercise.defaultSets} × ${exercise.defaultReps}',
                    style: AppTextStyles.caption(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  // Wrap custom exercises with swipe-to-delete
  if (isCustom) {
    return SwipeToDelete(
      confirmationTitle: 'Delete Custom Exercise',
      confirmationMessage:  'Delete "${exercise.name}"?  This will remove it from your library.',
      onDelete: () {
        ExerciseLibrary.deleteCustomExercise(exercise.id);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:  Text('${exercise.name} deleted'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: cardContent,
    );
  }

  return cardContent;
}

  void _showDeleteConfirmation(ExerciseTemplate exercise) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete Custom Exercise? ', style: AppTextStyles.h3()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${exercise.name}"?',
              style: AppTextStyles.body(),
            ),
            const SizedBox(height: 12),
            Text(
              'This will remove it from your exercise library permanently.',
              style: AppTextStyles.caption(color: AppColors.error),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:  const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ExerciseLibrary.deleteCustomExercise(exercise.id);
              Navigator.pop(dialogContext);
              setState(() {});
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${exercise.name} deleted'),
                  backgroundColor: AppColors. error,
                  duration: const Duration(seconds: 2),
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

  IconData _getExerciseIcon(String muscleGroup) {
    switch (muscleGroup) {
      case 'Chest':  return Icons.fitness_center;
      case 'Back': return Icons.airline_seat_recline_normal;
      case 'Legs': return Icons.directions_run;
      case 'Shoulders':  return Icons.expand_less;
      case 'Biceps': 
      case 'Triceps': 
      case 'Forearms': return Icons.sports_martial_arts;
      case 'Core': return Icons.accessibility_new;
      case 'Cardio': return Icons.favorite;
      case 'Glutes': return Icons.chair;
      case 'Traps': return Icons.arrow_upward;
      default: return Icons.fitness_center;
    }
  }

  IconData _getEquipmentIcon(String equipment) {
    switch (equipment) {
      case 'Barbell': return Icons. remove;
      case 'Dumbbell': return Icons.fitness_center;
      case 'Machine': return Icons.settings;
      case 'Cable': return Icons.cable;
      case 'Bodyweight': return Icons.accessibility_new;
      case 'Other': return Icons.help_outline;
      default: return Icons.help_outline;
    }
  }
}