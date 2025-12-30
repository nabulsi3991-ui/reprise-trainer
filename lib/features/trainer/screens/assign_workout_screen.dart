import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:reprise/shared/models/assigned_workout.dart';
import 'package:reprise/shared/models/workout.dart';
import 'package:reprise/features/workout/providers/workout_provider.dart';
import 'package:reprise/features/user/providers/user_provider.dart';
import 'package:reprise/features/workout/screens/template_picker_screen.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';

class AssignWorkoutScreen extends StatefulWidget {
  final Map<String, dynamic> trainee;

  const AssignWorkoutScreen({
    super.key,
    required this.trainee,
  });

  @override
  State<AssignWorkoutScreen> createState() => _AssignWorkoutScreenState();
}

class _AssignWorkoutScreenState extends State<AssignWorkoutScreen> {
  Workout? _selectedWorkout;
  DateTime _dueDate = DateTime.now();
  final TextEditingController _notesController = TextEditingController();
  ModificationPermission _permission = ModificationPermission.weightsRepsOnly;
  bool _canDelete = true;
  bool _isAssigning = false;
  String?  _sessionType;
  String? _scheduleType;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final traineeName = (widget.trainee['name']?.toString() ?? 'Unknown');

    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Workout to $traineeName'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child:  Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary. withOpacity(0.2),
                      child: Text(
                        (traineeName. isNotEmpty ? traineeName :  'U').substring(0, 1).toUpperCase(),
                        style: AppTextStyles.h4(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(traineeName, style: AppTextStyles. h4()),
                          const SizedBox(height: 4),
                          Text(
                            widget. trainee['email']?.toString() ?? '',
                            style: AppTextStyles.caption(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height:  AppSpacing.lg),
            Text('Select Workout', style: AppTextStyles.h3()),
            const SizedBox(height: AppSpacing.sm),
            Consumer<WorkoutProvider>(
              builder: (context, workoutProvider, child) {
                final templates = workoutProvider.templates;

                if (templates.isEmpty) {
                  return Card(
                    child:  Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          const Icon(Icons.fitness_center, size: 48, color: Colors. grey),
                          const SizedBox(height: AppSpacing. sm),
                          Text(
                            'No workout templates available',
                            style: AppTextStyles.body(color: Colors.grey),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TemplatePickerScreen(
                                    isSelectionMode: true,
                                  ),
                                ),
                              );
                            },
                            child:  const Text('Create Template'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Card(
                  child: ListTile(
                    leading:  const Icon(Icons.fitness_center, color: AppColors.primary),
                    title: Text(_selectedWorkout?. name ?? 'Choose a workout'),
                    subtitle:  _selectedWorkout != null
                        ? Text('${_selectedWorkout!.exercises.length} exercises')
                        : null,
                    trailing:  const Icon(Icons.chevron_right),
                    onTap: () async {
                      final selected = await Navigator.push<Workout>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TemplatePickerScreen(
                            isSelectionMode: true,
                          ),
                        ),
                      );
                      if (selected != null) {
                        setState(() => _selectedWorkout = selected);
                      }
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            
Text('Session Type', style: AppTextStyles.h3()),
const SizedBox(height: AppSpacing.sm),
Text(
  'Choose how this workout will be completed',
  style: AppTextStyles. caption(),
),
const SizedBox(height: AppSpacing.md),

Card(
  child: Column(
    children: [
      RadioListTile<String>(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Solo Workout', style: TextStyle(fontWeight:  FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(
                    'Trainee completes independently',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        value: 'solo',
        groupValue:  _sessionType,
        onChanged: (value) => setState(() => _sessionType = value),
      ),
      const Divider(height: 1),
      RadioListTile<String>(
        title: Row(
          children:  [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.people, color: AppColors. secondary, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child:  Column(
                crossAxisAlignment:  CrossAxisAlignment.start,
                children: [
                  Text('Live Session', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(
                    'You log weights/reps during session',
                    style: TextStyle(fontSize: 12, color:  Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        value: 'trainerLed',
        groupValue: _sessionType,
        onChanged: (value) => setState(() => _sessionType = value),
      ),
    ],
  ),
),

const SizedBox(height: AppSpacing.lg),

// ✅ NEW: Schedule Date Section
Text('Schedule For', style: AppTextStyles.h3()),
const SizedBox(height: AppSpacing.sm),

Card(
  child: Column(
    children: [
      RadioListTile<String>(
        title: Row(
          children:  [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.today, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today', style: TextStyle(fontWeight:  FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(
                    'Available immediately',
                    style: TextStyle(fontSize: 12, color:  Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        value: 'today',
        groupValue: _scheduleType,
        onChanged: (value) {
          setState(() {
            _scheduleType = value;
            _dueDate = DateTime.now();
          });
        },
      ),
      const Divider(height: 1),
      RadioListTile<String>(
        title: Row(
          children:  [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_today, color: AppColors. info, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child:  Column(
                crossAxisAlignment:  CrossAxisAlignment.start,
                children: [
                  Text('Future Date', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height:  4),
                  Text(
                    'Schedule for specific date',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        value: 'future',
        groupValue: _scheduleType,
        onChanged: (value) => setState(() => _scheduleType = value),
      ),
    ],
  ),
),

// Show date picker only if "Future Date" is selected
if (_scheduleType == 'future') ...[
  const SizedBox(height: AppSpacing.md),
  Card(
    child: ListTile(
      leading: const Icon(Icons.calendar_today, color: AppColors.info),
      title: Text(DateFormat('EEEE, MMM d, yyyy').format(_dueDate)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dueDate. isAfter(DateTime.now()) ? _dueDate : DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime. now().add(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() => _dueDate = picked);
        }
      },
    ),
  ),
],
            const SizedBox(height: AppSpacing.lg),
            Text('Notes (Optional)', style: AppTextStyles. h3()),
            const SizedBox(height: AppSpacing. sm),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add instructions or notes for the trainee...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Modification Permissions', style: AppTextStyles. h3()),
            const SizedBox(height: AppSpacing. sm),
            Card(
              child: Column(
                children: [
                  RadioListTile<ModificationPermission>(
                    title: const Text('Read Only'),
                    subtitle: const Text('Trainee cannot modify anything'),
                    value: ModificationPermission.readOnly,
                    groupValue: _permission,
                    onChanged: (value) => setState(() => _permission = value! ),
                  ),
                  RadioListTile<ModificationPermission>(
                    title: const Text('Weights & Reps Only'),
                    subtitle: const Text('Can adjust weights and reps'),
                    value: ModificationPermission. weightsRepsOnly,
                    groupValue: _permission,
                    onChanged: (value) => setState(() => _permission = value!),
                  ),
                  RadioListTile<ModificationPermission>(
                    title:  const Text('Full Control'),
                    subtitle: const Text('Can modify anything'),
                    value: ModificationPermission.full,
                    groupValue: _permission,
                    onChanged: (value) => setState(() => _permission = value! ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: SwitchListTile(
                title: const Text('Allow Deletion'),
                subtitle: const Text('Trainee can delete this assignment'),
                value: _canDelete,
                onChanged: (value) => setState(() => _canDelete = value),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAssigning ?  null : _assignWorkout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  backgroundColor: AppColors.secondary,
                ),
                child: _isAssigning
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Assign Workout',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignWorkout() async {
    if (_sessionType == null) {
      ScaffoldMessenger. of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a workout type'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_scheduleType == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select when to schedule this workout'),
        backgroundColor: AppColors.error,
      ),
    );
    return;
  }

    if (_selectedWorkout == null) {
      ScaffoldMessenger. of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a workout'),
          backgroundColor:  AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isAssigning = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final trainerId = userProvider.currentUser! .id;
      final traineeId = widget.trainee['id'];

      final exercisesData = _selectedWorkout!.exercises.map((exercise) {
        return {
          'name': exercise. name,
          'muscleGroup': exercise.muscleGroups.isNotEmpty
              ? exercise.muscleGroups.first
              : 'Other',
          'sets': exercise. sets. map((set) => {
                'weight': set.targetWeight,
                'reps':  set.targetReps,
                'isCompleted': false,
                'isPR': false,
              }).toList(),
        };
      }).toList();

      final assignedWorkout = AssignedWorkout(
        id: const Uuid().v4(),
        trainerId:  trainerId,
        traineeId: traineeId,
        workoutTemplateId: _selectedWorkout!.id,
        workoutName: _selectedWorkout! .name,
        assignedDate: DateTime.now(),
        dueDate: _dueDate,
        status: AssignedWorkoutStatus. pending,
        notes: _notesController.text. trim(),
        exercises: exercisesData,
        permission: _permission,
        canDelete: _canDelete,
        sessionType:  _sessionType! ,
      );

      await FirebaseFirestore.instance
          . collection('assigned_workouts')
          .doc(assignedWorkout.id)
          .set(assignedWorkout.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:  Text(
              _sessionType == 'solo'
                  ? 'Solo workout assigned to ${widget.trainee['name']}'
                  : 'Live session scheduled with ${widget.trainee['name']}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Error assigning workout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign workout:  ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }
}