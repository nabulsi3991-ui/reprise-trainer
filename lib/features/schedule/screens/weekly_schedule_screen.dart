import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/features/workout/providers/workout_provider.dart';
import 'package:reprise/features/workout/screens/template_picker_screen.dart';
import 'package:reprise/shared/models/workout.dart';
import 'package:uuid/uuid.dart';

class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  late DateTime _currentWeekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('Weekly Schedule', style: AppTextStyles.h2()),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                final now = DateTime.now();
                _currentWeekStart = now. subtract(Duration(days: now. weekday - 1));
              });
            },
          ),
        ],
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, child) {
          return Column(
            children: [
              // Week Navigation
              Container(
                padding: const EdgeInsets.all(AppSpacing. md),
                color: Theme.of(context).cardColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
                        });
                      },
                    ),
                    Text(_getWeekRangeText(), style: AppTextStyles.h3()),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Week Days
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final day = _currentWeekStart. add(Duration(days: index));
                    final workouts = workoutProvider.getWorkoutsForDay(day);
                    final isToday = _isToday(day);

                    return _buildDayCard(context, day, workouts, isToday, workoutProvider);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getWeekRangeText() {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    return '${_formatDate(_currentWeekStart)} - ${_formatDate(weekEnd)}';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _getDayName(DateTime date) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date. weekday - 1];
  }

  Widget _buildDayCard(
    BuildContext context,
    DateTime day,
    List<Workout> workouts,
    bool isToday,
    WorkoutProvider workoutProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color:  isToday ? AppColors.primary. withOpacity(0.1) : Theme.of(context).cardColor,
        borderRadius: BorderRadius. circular(AppSpacing.radiusMedium),
        border: isToday ?  Border.all(color: AppColors.primary, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:  CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDayName(day),
                        style:  AppTextStyles.h3(
                          color: isToday ?  AppColors.primary : null,
                        ),
                      ),
                      Text(
                        _formatDate(day),
                        style: AppTextStyles.caption(),
                      ),
                    ],
                  ),
                ),
                if (workouts.length < 5)
                  OutlinedButton. icon(
                    onPressed:  () => _showAddWorkoutDialog(context, day, workoutProvider),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('Add${workouts.isEmpty ? "" : " (${workouts.length})"}'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing. sm,
                        vertical: AppSpacing.xs,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          if (workouts.isNotEmpty) ...[
            const Divider(height: 1),
            ...workouts.map((workout) => _buildWorkoutItem(workout, workoutProvider)),
          ] else
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              child: Text(
                'No workouts scheduled',
                style: AppTextStyles. body(color: AppColors.textSecondaryLight),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkoutItem(Workout workout, WorkoutProvider workoutProvider) {
    IconData statusIcon;
    Color statusColor;
    
    switch (workout.status) {
      case WorkoutStatus.completed:
        statusIcon = Icons. check_circle;
        statusColor = AppColors.success;
        break;
      case WorkoutStatus.missed:
        statusIcon = Icons. cancel;
        statusColor = AppColors.error;
        break;
      case WorkoutStatus.scheduled:
        statusIcon = Icons. schedule;
        statusColor = AppColors.warning;
        break;
      case WorkoutStatus.inProgress:
        statusIcon = Icons.play_circle;
        statusColor = AppColors. info;
        break;
    }

    return ListTile(
      leading: Icon(statusIcon, color: statusColor),
      title: Text(workout.name, style: AppTextStyles.h4()),
      subtitle: Text(
        '${workout.exercises.length} exercises',
        style: AppTextStyles.caption(),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 20),
        color: AppColors.error,
        onPressed: () {
          workoutProvider.deleteWorkout(workout. id, workout.date);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout removed'),
              duration: Duration(milliseconds: 800),
            ),
          );
        },
      ),
    );
  }

  void _showAddWorkoutDialog(
    BuildContext context,
    DateTime day,
    WorkoutProvider workoutProvider,
  ) {
    showModalBottomSheet(
      context:  context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing. lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Schedule for ${_getDayName(day)}',
              style: AppTextStyles.h2(),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            ListTile(
              leading: const Icon(Icons.list_alt, color: AppColors.primary),
              title: const Text('From Template'),
              subtitle: const Text('Choose from saved templates'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                Navigator.pop(context);
                final scheduled = await Navigator.push<Workout>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TemplatePickerScreen(
                      isScheduling: true,
                      scheduleDate: day,
                    ),
                  ),
                );
                
                if (scheduled != null && context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger. of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Workout scheduled'),
                      duration: Duration(milliseconds: 800),
                    ),
                  );
                }
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.fitness_center, color: AppColors. secondary),
              title: const Text('Rest Day'),
              subtitle: const Text('Mark as rest/recovery day'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final restDay = Workout(
                  id: const Uuid().v4(),
                  name: 'Rest Day',
                  date: day,
                  muscleGroups: ['Rest'],
                  status: WorkoutStatus.scheduled,
                  exercises: [],
                );
                workoutProvider.addScheduledWorkout(restDay);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger. of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rest day scheduled'),
                    duration: Duration(milliseconds: 800),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}