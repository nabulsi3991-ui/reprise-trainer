import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/theme/app_theme_manager.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/features/workout/providers/workout_provider.dart';
import 'package:reprise/features/workout/screens/workout_screen.dart';
import 'package:reprise/features/workout/screens/workout_detail_screen.dart';
import 'package:reprise/features/workout/screens/template_picker_screen.dart';
import 'package:reprise/shared/models/workout.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:reprise/shared/widgets/swipe_to_delete.dart';
import 'package:reprise/features/workout/providers/assigned_workout_provider.dart';
import 'package:reprise/shared/models/assigned_workout.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final assignedProvider = Provider.of<AssignedWorkoutProvider>(context, listen:  false);
        assignedProvider. loadAssignedWorkoutsForTrainee(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
        title: Text('Calendar', style: AppTextStyles.h2()),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, child) {
          return Column(
            children: [
              _buildCalendar(workoutProvider),
              const Divider(height: 1),
              Expanded(
                child: _buildWorkoutList(workoutProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton. extended(
        onPressed: () => _handleAddWorkout(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Workout'),
        backgroundColor: AppThemeManager.primaryColor,
      ),
    );
  }

  void _handleAddWorkout(BuildContext context) {
    if (_selectedDay == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);

    if (selected.isBefore(today)) {
      _showPastWorkoutOptions(context);
    } else if (selected.isAtSameMomentAs(today)) {
      _showTodayWorkoutOptions(context);
    } else {
      _showFutureWorkoutOptions(context);
    }
  }

  void _showPastWorkoutOptions(BuildContext context) {
    showModalBottomSheet(
      context:  context,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Log Past Workout', style: AppTextStyles.h2()),
            const SizedBox(height: AppSpacing.sm),
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay!),
              style: AppTextStyles.body(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: Icon(Icons.fitness_center, color: AppThemeManager.primaryColor),
              title: const Text('Log Workout'),
              subtitle: const Text('Record a completed workout'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator. pop(sheetContext);
                _createPastWorkout(context, isFromTemplate: false);
              },
            ),
            ListTile(
              leading: Icon(Icons.list_alt, color: AppThemeManager.secondaryColor),
              title: const Text('Log from Template'),
              subtitle: const Text('Use a saved workout'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(sheetContext);
                _createPastWorkout(context, isFromTemplate: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTodayWorkoutOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(AppSpacing. lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add Workout for Today', style: AppTextStyles.h2()),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.play_arrow, color: AppColors.success),
              title: const Text('Start Workout Now'),
              subtitle: const Text('Begin with live timer'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                Navigator.pop(sheetContext);

                final result = await showDialog<String>(
                  context: context,
                  builder:  (dialogContext) => AlertDialog(
                    title: Text('Start Workout', style: AppTextStyles.h3()),
                    content: Column(
                      mainAxisSize:  MainAxisSize.min,
                      children: [
                        ListTile(
                          leading:  const Icon(Icons.list_alt),
                          title: const Text('From Template'),
                          onTap: () => Navigator.pop(dialogContext, 'template'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.add_circle),
                          title: const Text('Empty Workout'),
                          onTap: () => Navigator.pop(dialogContext, 'empty'),
                        ),
                      ],
                    ),
                  ),
                );

                if (result == 'template' && context.mounted) {
                  final template = await Navigator.push<Workout>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TemplatePickerScreen(),
                    ),
                  );

                  if (template != null && context.mounted) {
                    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
                    final workout = workoutProvider.createWorkoutFromTemplate(template);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutScreen(workout: workout, autoStart: true),
                      ),
                    );
                  }
                } else if (result == 'empty' && context.mounted) {
                  final emptyWorkout = Workout(
                    id: const Uuid().v4(),
                    name: 'Quick Workout',
                    date: DateTime.now(),
                    muscleGroups: [],
                    status: WorkoutStatus.inProgress,
                    exercises: [],
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutScreen(workout: emptyWorkout, autoStart: true),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.info),
              title: const Text('Log Completed Workout'),
              subtitle: const Text('Record workout with manual duration'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(sheetContext);
                _showLogWorkoutOptions(context);
              },
            ),
            ListTile(
              leading:  const Icon(Icons.schedule, color: AppColors.warning),
              title: const Text('Schedule for Later Today'),
              subtitle: const Text('Add to calendar'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(sheetContext);
                _scheduleWorkout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogWorkoutOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Container(
        padding:  const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Log Workout', style: AppTextStyles.h2()),
            const SizedBox(height: AppSpacing.sm),
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay!),
              style: AppTextStyles.body(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: Icon(Icons.fitness_center, color: AppThemeManager.primaryColor),
              title: const Text('Log Workout'),
              subtitle:  const Text('Record a completed workout'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(sheetContext);
                _createPastWorkout(context, isFromTemplate: false);
              },
            ),
            ListTile(
              leading: Icon(Icons. list_alt, color: AppThemeManager.secondaryColor),
              title: const Text('Log from Template'),
              subtitle: const Text('Use a saved workout'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator. pop(sheetContext);
                _createPastWorkout(context, isFromTemplate: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFutureWorkoutOptions(BuildContext context) {
    showModalBottomSheet(
      context:  context,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Schedule Workout', style: AppTextStyles.h2()),
            const SizedBox(height: AppSpacing.sm),
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay!),
              style: AppTextStyles.body(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height:  AppSpacing.lg),
            ListTile(
              leading:  Icon(Icons.list_alt, color: AppThemeManager.primaryColor),
              title: const Text('Schedule from Template'),
              subtitle: const Text('Choose a saved workout'),
              trailing:  const Icon(Icons.chevron_right),
              onTap:  () {
                Navigator.pop(sheetContext);
                _scheduleWorkout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createPastWorkout(BuildContext context, {required bool isFromTemplate}) async {
    if (isFromTemplate) {
      final template = await Navigator.push<Workout>(
        context,
        MaterialPageRoute(
          builder: (context) => TemplatePickerScreen(
            isPastWorkout: true,
            selectedDate: _selectedDay,
          ),
        ),
      );

      if (template != null && context.mounted) {
        final workoutProvider = Provider.of<WorkoutProvider>(context, listen:  false);
        final workout = workoutProvider.createWorkoutFromTemplate(template);

        final pastWorkout = Workout(
          id: workout.id,
          name: workout.name,
          date: _selectedDay!,
          muscleGroups: workout.muscleGroups,
          status: WorkoutStatus.scheduled,
          exercises: workout.exercises,
          notes: workout.notes,
        );

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutScreen(
              workout: pastWorkout,
              autoStart: false,
              isPastWorkout: true,
            ),
          ),
        );
      }
    } else {
      final emptyWorkout = Workout(
        id: const Uuid().v4(),
        name: 'Logged Workout',
        date: _selectedDay!,
        muscleGroups: [],
        status:  WorkoutStatus.scheduled,
        exercises: [],
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutScreen(
            workout: emptyWorkout,
            autoStart: false,
            isPastWorkout: true,
          ),
        ),
      );
    }
  }

  void _scheduleWorkout(BuildContext context) async {
    final scheduledWorkout = await Navigator.push<Workout>(
      context,
      MaterialPageRoute(
        builder: (context) => TemplatePickerScreen(
          isScheduling: true,
          scheduleDate: _selectedDay,
        ),
      ),
    );

    if (scheduledWorkout != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Workout scheduled for ${DateFormat('MMM d, yyyy').format(scheduledWorkout.date)}',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildCalendar(WorkoutProvider workoutProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        
        eventLoader: (day) {
          final assignedProvider = Provider.of<AssignedWorkoutProvider>(context, listen:  false);
          return workoutProvider.getWorkoutsForDateWithAssigned(day, assignedProvider.assignedWorkouts);
        },
        
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppThemeManager.primaryColor,
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: BoxDecoration(
            color: AppThemeManager.primaryColor,
            shape: BoxShape.circle,
          ),
          selectedTextStyle:  const TextStyle(
            color:  Colors.white,
            fontWeight: FontWeight.bold,
          ),
          markerDecoration: BoxDecoration(
            color: AppThemeManager.primaryColor,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
          defaultTextStyle: const TextStyle(
            color: AppColors.textPrimary,
          ),
          weekendTextStyle:  const TextStyle(
            color:  AppColors.textPrimary,
          ),
          outsideTextStyle: TextStyle(
            color: AppColors.textSecondary. withOpacity(0.5),
          ),
        ),
        
        headerStyle: HeaderStyle(
          formatButtonVisible:  false,
          titleCentered: true,
          titleTextStyle: AppTextStyles.h3(),
          leftChevronIcon:  Icon(
            Icons.chevron_left,
            color: AppThemeManager.primaryColor,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: AppThemeManager.primaryColor,
          ),
        ),
        
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;
            
            final workouts = events.cast<Workout>();
            final hasAssigned = workouts.any((w) => w.isAssignedWorkout ??  false);
            final hasRegular = workouts.any((w) => !(w.isAssignedWorkout ?? false));

            if (hasAssigned && hasRegular) {
              return Positioned(
                bottom: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color:  AppThemeManager.secondaryColor,
                        shape:  BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppThemeManager.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            } else if (hasAssigned) {
              return Positioned(
                bottom: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppThemeManager.secondaryColor,
                    shape: BoxShape. circle,
                  ),
                ),
              );
            } else if (hasRegular) {
              return Positioned(
                bottom: 4,
                child:  Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppThemeManager.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            
            return null;
          },
          
          defaultBuilder: (context, date, _) {
            final workouts = workoutProvider.getWorkoutsForDay(date);
            if (workouts.isEmpty) return null;
            
            final workout = workouts.first;
            Color?  backgroundColor;
            
            if (workout.status == WorkoutStatus.completed) {
              backgroundColor = AppColors.success. withOpacity(0.1);
            } else if (workout. status == WorkoutStatus.missed) {
              backgroundColor = AppColors.error.withOpacity(0.1);
            }
            
            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape. circle,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: workout.status == WorkoutStatus.completed
                        ? AppColors.success
                        : workout.status == WorkoutStatus.missed
                            ? AppColors.error
                            : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          },
        ),
        
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  Widget _buildWorkoutList(WorkoutProvider workoutProvider) {
    return Consumer<AssignedWorkoutProvider>(
      builder: (context, assignedProvider, child) {
        final workouts = workoutProvider.getWorkoutsForDateWithAssigned(
          _selectedDay! ,
          assignedProvider.assignedWorkouts,
        );
        
        if (workouts. isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 64,
                  color: AppColors.textSecondaryLight. withOpacity(0.5),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('No workouts', style: AppTextStyles.h3()),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  DateFormat('MMMM d, yyyy').format(_selectedDay!),
                  style: AppTextStyles.body(color: AppColors. textSecondaryLight),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Tap the + button to add a workout',
                  style: AppTextStyles.caption(),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              DateFormat('EEEE, MMMM d').format(_selectedDay!),
              style: AppTextStyles.h3(),
            ),
            const SizedBox(height: AppSpacing.md),
            ...workouts.map((workout) {
              if (workout.isAssignedWorkout && workout.assignedWorkoutData != null) {
                return _buildAssignedWorkoutCard(workout, workout.assignedWorkoutData!);
              }
              return _buildWorkoutCard(workout, workoutProvider);
            }),
          ],
        );
      },
    );
  }

  Widget _buildAssignedWorkoutCard(Workout workout, AssignedWorkout assignedData) {
    final isLiveSession = assignedData.isTrainerLed;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final workoutDate = DateTime(workout.date.year, workout.date.month, workout.date.day);
    final isToday = workoutDate.isAtSameMomentAs(today);
    final isFuture = workoutDate.isAfter(today);
    final isOverdue = assignedData.isOverdue;
    
    final assignedProvider = Provider.of<AssignedWorkoutProvider>(context, listen:  false);
    
    return SwipeToDelete(
      confirmationTitle: 'Remove Assigned Workout',
      confirmationMessage: 'Remove "${assignedData.workoutName}" from your calendar?',
      onDelete: () async {
        await assignedProvider. deleteAssignedWorkout(assignedData.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout removed'),
              backgroundColor: AppColors.success,
            ),
          );
          setState(() {});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isOverdue
              ? AppColors.error.withOpacity(0.05)
              : (isLiveSession 
                  ? AppThemeManager.secondaryColor.withOpacity(0.05)
                  : AppThemeManager.primaryColor.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border(
            left: BorderSide(
              color: isOverdue
                  ? AppColors.error
                  : (isLiveSession ?  AppThemeManager.secondaryColor : AppThemeManager. primaryColor),
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? AppColors.error. withOpacity(0.1)
                        : (isLiveSession
                            ? AppThemeManager. secondaryColor.withOpacity(0.1)
                            :  AppThemeManager.primaryColor. withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isOverdue
                        ? Icons.warning
                        : (isLiveSession ?  Icons.video_call : Icons.fitness_center),
                    color: isOverdue
                        ? AppColors.error
                        : (isLiveSession ? AppThemeManager.secondaryColor : AppThemeManager.primaryColor),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(workout.name, style: AppTextStyles.h3()),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? AppColors.error.withOpacity(0.2)
                        : (isLiveSession
                            ? AppThemeManager.secondaryColor.withOpacity(0.2)
                            : AppThemeManager. primaryColor.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isLiveSession ? 'Live' : 'Solo',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOverdue
                          ? AppColors. error
                          : (isLiveSession ? AppThemeManager. secondaryColor : AppThemeManager.primaryColor),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.assignment, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Assigned by trainer',
                  style: AppTextStyles.caption(
                    color: isOverdue ?  AppColors.error : null,
                  ),
                ),
              ],
            ),
            if (isOverdue) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, size: 16, color: AppColors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'This workout is overdue',
                        style: AppTextStyles.bodySmall(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isLiveSession) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing. radiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock, size: 16, color:  AppColors.warning),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child:  Text(
                        'Waiting for trainer',
                        style: AppTextStyles.bodySmall(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isToday || ! isFuture) ...[
              const SizedBox(height:  AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _startAssignedWorkout(assignedData),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeManager.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startAssignedWorkout(AssignedWorkout assignedData) {
    final exercises = assignedData.exercises. map((exerciseData) {
      final sets = (exerciseData['sets'] as List).asMap().entries.map((entry) {
        final setIndex = entry.key;
        final setData = entry.value;
        return ExerciseSet(
          setNumber: setIndex + 1,
          targetWeight: (setData['weight'] ??  0).toDouble(),
          targetReps: setData['reps'] ?? 0,
          actualWeight: 0.0,
          actualReps:  0,
        );
      }).toList();

      return Exercise(
        id:  '${assignedData.id}_${exerciseData['name']}',
        name: exerciseData['name'] ?? 'Unknown Exercise',
        muscleGroups: [exerciseData['muscleGroup'] ??  'Other'],
        sets: sets,
      );
    }).toList();

    final workout = Workout(
      id:  assignedData.id,
      name: assignedData.workoutName,
      date: _selectedDay ??  DateTime.now(),
      muscleGroups: exercises. expand((e) => e.muscleGroups).toSet().toList(),
      status: WorkoutStatus.inProgress,
      exercises: exercises,
      isAssignedWorkout: true,
      assignedWorkoutData: assignedData,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutScreen(workout: workout, autoStart: true),
      ),
    );
  }

  Widget _buildWorkoutCard(Workout workout, WorkoutProvider workoutProvider) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final workoutDate = DateTime(workout.date.year, workout.date.month, workout.date.day);
    final isFutureWorkout = workoutDate.isAfter(today);
    
    IconData statusIcon;
    Color statusColor;
    
    switch (workout.status) {
      case WorkoutStatus.completed:
        statusIcon = Icons. check_circle;
        statusColor = AppColors.success;
        break;
      case WorkoutStatus.missed:
        statusIcon = Icons.cancel;
        statusColor = AppColors.error;
        break;
      case WorkoutStatus.scheduled:
        statusIcon = Icons. schedule;
        statusColor = AppColors.warning;
        break;
      case WorkoutStatus.inProgress:
        statusIcon = Icons.play_circle;
        statusColor = AppColors.info;
        break;
    }

    return SwipeToDelete(
      confirmationTitle: 'Delete Workout',
      confirmationMessage: 'Delete "${workout.name}"?',
      onDelete: () {
        workoutProvider.deleteWorkout(workout.id, workout.date);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:  Text('${workout.name} deleted'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: InkWell(
        onTap: () {
          if (workout.status == WorkoutStatus.completed) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutDetailScreen(workout: workout),
              ),
            );
          } else if (workout.status == WorkoutStatus.scheduled && isFutureWorkout) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'This workout is scheduled for ${DateFormat('MMMM d, yyyy').format(workout.date)}',
                ),
                backgroundColor: AppColors.info,
                duration: const Duration(milliseconds: 1500),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color:  Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppSpacing. radiusMedium),
            border:  Border(
              left: BorderSide(
                color: AppColors.getMuscleGroupColor(workout.muscleGroups. first),
                width: 4,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(workout.name, style: AppTextStyles.h3()),
                  ),
                  Icon(statusIcon, color: statusColor, size: 24),
                ],
              ),
              const SizedBox(height: AppSpacing. sm),
              
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: workout.muscleGroups.map((group) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing. sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getMuscleGroupColor(group),
                      borderRadius: BorderRadius.circular(AppSpacing. radiusSmall),
                    ),
                    child: Text(
                      group,
                      style: AppTextStyles.caption(color: Colors.white),
                    ),
                  );
                }).toList(),
              ),
              
              if (workout.status == WorkoutStatus.completed) ...[
                const SizedBox(height: AppSpacing. md),
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 16,
                      color: AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${workout.totalVolume. toStringAsFixed(0)} lbs',
                      style: AppTextStyles.bodySmall(),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Icon(
                      Icons.access_time,
                      size:  16,
                      color:  AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${workout. durationMinutes} min',
                      style: AppTextStyles.bodySmall(),
                    ),
                  ],
                ),
              ],
              
              if (workout.status == WorkoutStatus.scheduled) ...[
                const SizedBox(height: AppSpacing.md),
                if (isFutureWorkout) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing. radiusSmall),
                      border: Border.all(color: AppColors.info. withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Scheduled for ${DateFormat('MMM d, yyyy').format(workout.date)}',
                            style: AppTextStyles.bodySmall(color: AppColors.info),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          final activeWorkout = workoutProvider.createWorkoutFromTemplate(workout);
                          workoutProvider.deleteWorkout(workout.id, workout.date);
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WorkoutScreen(workout: activeWorkout, autoStart: true),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label:  const Text('Start Workout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeManager.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}