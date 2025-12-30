import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reprise/core/theme/app_theme_manager.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/features/workout/providers/workout_provider.dart';
import 'package:reprise/features/workout/providers/assigned_workout_provider.dart';
import 'package:reprise/features/user/providers/user_provider.dart';
import 'package:reprise/features/workout/screens/workout_screen.dart';
import 'package:reprise/features/workout/screens/workout_history_screen.dart';
import 'package:reprise/features/workout/screens/template_picker_screen.dart';
import 'package:reprise/features/workout/screens/pr_history_screen.dart';
import 'package:reprise/features/schedule/screens/weekly_schedule_screen.dart';
import 'package:reprise/features/analytics/screens/exercise_analytics_screen.dart';
import 'package:reprise/features/measurements/screens/measurements_screen.dart';
import 'package:reprise/features/trainer/screens/assign_workout_screen.dart';
import 'package:reprise/shared/models/workout.dart';
import 'package:reprise/shared/models/assigned_workout.dart';
import 'package:reprise/services/local_storage_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:reprise/shared/widgets/swipe_to_delete.dart';
import 'package:reprise/features/workout/screens/workout_detail_screen.dart';
import 'package:reprise/features/trainer/screens/trainee_detail_screen.dart';
import 'package:reprise/features/workout/screens/assigned_workouts_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _hasLoadedAssignedWorkouts = false;

    @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider. of<UserProvider>(context, listen: false);
      final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
      
      // Load assigned workouts for trainee
      if (! userProvider.currentUser!.isTrainer && userProvider.currentUser! .hasTrainer) {
        final assignedWorkoutProvider = Provider.of<AssignedWorkoutProvider>(context, listen: false);
        assignedWorkoutProvider. loadAssignedWorkoutsForTrainee(userProvider.currentUser!.id);
      }
      // Load workout templates
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: Consumer<UserProvider>(
        builder:  (context, userProvider, child) {
          final user = userProvider.currentUser;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RepRise', style: AppTextStyles.h2()),
              if (user != null)
                Row(
                  children: [
                    Icon(
                      AppThemeManager.modeIcon,
                      size: 14,
                      color: AppThemeManager.primaryColor,
                    ),
                    const SizedBox(width:  4),
                    Text(
                      AppThemeManager.modeLabel,
                      style: AppTextStyles.caption(
                        color: AppThemeManager.primaryColor,
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: () => _showDashboardSettings(context),
          tooltip: 'Customize Dashboard',
        ),
      ],
    ),
    body: Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        
        if (user != null && ! user.isTrainer && user.hasTrainer && ! _hasLoadedAssignedWorkouts) {
          _hasLoadedAssignedWorkouts = true;
          Future.microtask(() {
            Provider.of<AssignedWorkoutProvider>(context, listen: false)
                .loadAssignedWorkoutsForTrainee(user.id);
          });
        }
        
        // ✅ Set theme mode
        AppThemeManager.setTrainerMode(user?. isTrainer ?? false);
        
        if (user?. isTrainer == true) {
          return _buildTrainerDashboard(context, user! );
        } else {
          return _buildPersonalDashboard(context, user);
        }
      },
    ),
  );
 }

  Widget _buildTrainerDashboard(BuildContext context, dynamic user) {
  return RefreshIndicator(
    onRefresh: () async {
      setState(() {});
    },
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Trainer header card (updated with trainer colors)
          _buildTrainerHeaderCardWithColors(user),
          
          const SizedBox(height: AppSpacing.xl),
          
          // ✅ SECTION 1: MY TRAINEES (Trainer color theme)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors. trainerPrimary. withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.people,
                      color: AppColors.trainerPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('My Trainees', style: AppTextStyles.h2()),
                ],
              ),
              TextButton. icon(
                onPressed: () {
                  _showAddTraineeDialog(context, user);
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.trainerPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // ✅ Trainee stats (trainer colors)
          Row(
            children: [
              Expanded(
                child: _buildTrainerStatCard(
                  icon:  Icons.people,
                  label: 'Active Trainees',
                  value: '${user.trainees. length}',
                  color:  AppColors.trainerPrimary,
                  onTap:  () {},
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Consumer<WorkoutProvider>(
                  builder: (context, workoutProvider, child) {
                    return _buildTrainerStatCard(
                      icon: Icons.assignment,
                      label: 'Templates',
                      value: '${workoutProvider.templates.length}',
                      color: AppThemeManager.secondaryColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:  (context) => const TemplatePickerScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // ✅ Trainees list (with trainer color accents)
          if (user.trainees.isEmpty)
            _buildEmptyTraineesCardWithColors(user)
          else
            _buildTraineesListWithColors(user.trainees),
          
          const SizedBox(height: AppSpacing.xl),
          
          // ✅ Divider with trainer gradient
          Container(
            height:  3,
            decoration: BoxDecoration(
              gradient: AppColors.trainerGradient,
              borderRadius: BorderRadius. circular(2),
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // ✅ SECTION 2: MY WORKOUTS (Trainer color theme)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.trainerPrimary.withOpacity(0.2),
                          borderRadius: BorderRadius. circular(8),
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: AppColors. trainerPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width:  AppSpacing.sm),
                      Text('My Workouts', style: AppTextStyles.h2()),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: Text(
                      'Track your own fitness journey',
                      style:  AppTextStyles.caption(color: AppColors.trainerPrimary),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // ✅ Start Workout button (trainer gradient)
          Consumer<WorkoutProvider>(
            builder: (context, workoutProvider, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: AppColors.trainerGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.trainerPrimary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _showStartWorkoutOptions(context),
                  icon: const Icon(Icons.fitness_center, size: 24),
                  label: const Text(
                    'Start Workout',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    minimumSize: const Size(double. infinity, 0),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: AppSpacing. lg),
          
          // ✅ Dashboard stats (trainer colors)
          Consumer<WorkoutProvider>(
            builder: (context, workoutProvider, child) {
              final streak = workoutProvider.getCurrentStreak();
              final thisWeekCount = workoutProvider.getThisWeekCount();
              final totalPRs = workoutProvider.getTotalPRs();
              final thisMonthCount = _getThisMonthCount(workoutProvider);
              
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.local_fire_department,
                          iconColor: AppColors.trainerPrimary,
                          label:  'Streak',
                          value: '$streak days',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child:  _buildStatCard(
                          icon: Icons.fitness_center,
                          iconColor: AppColors.trainerSecondary,
                          label: 'This Week',
                          value: '$thisWeekCount/7',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PRHistoryScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          child: _buildStatCard(
                            icon:  Icons.trending_up,
                            iconColor: AppColors.trainerSuccess,
                            label: 'PRs',
                            value:  '$totalPRs',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.calendar_month,
                          iconColor: AppColors. trainerInfo,
                          label: 'This Month',
                          value: '$thisMonthCount',
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // ✅ Next Workout section (trainer color)
          Row(
            children: [
              Icon(Icons.upcoming, color: AppColors.trainerPrimary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text('Next Workout', style: AppTextStyles.h3()),
            ],
          ),
          const SizedBox(height:  AppSpacing.md),
          Consumer<WorkoutProvider>(
            builder: (context, workoutProvider, child) {
              final nextWorkout = workoutProvider.getNextScheduledWorkout();
              return _buildTrainerNextWorkoutCard(context, nextWorkout, workoutProvider);
            },
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // ✅ Recent Activity section (trainer color)
          Consumer<WorkoutProvider>(
            builder: (context, workoutProvider, child) {
              final recentWorkouts = workoutProvider.getRecentWorkouts(limit: 3);
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history, color: AppColors.trainerPrimary, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Recent Activity', style: AppTextStyles.h3()),
                        ],
                      ),
                      if (recentWorkouts.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:  (context) => const WorkoutHistoryScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.trainerPrimary,
                          ),
                          child:  const Text('View All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  if (recentWorkouts.isEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 48,
                                color: AppColors. trainerPrimary. withOpacity(0.5),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'No workouts yet',
                                style: AppTextStyles.h3(),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Start your first workout to see it here',
                                style: AppTextStyles.body(color: AppColors. textSecondaryLight),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ... recentWorkouts.map((workout) =>
                        _buildRecentActivityCard2(context, workout, workoutProvider)),
                ],
              );
            },
          ),
        ],
      ),
    ),
    
  );

  
}

Widget _buildUnifiedHeaderCard(dynamic user) {
  return Card(
    elevation: 4,
    child: Container(
      decoration: BoxDecoration(
        gradient: AppThemeManager.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets. all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppThemeManager.modeIcon,
                size: 32,
                color: Colors.white, // ✅ Icon stays white (looks good on gradient)
              ),
            ),
            const SizedBox(width:  AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: AppTextStyles.caption(color: Colors.white), // ✅ This is fine - subtitle
                  ),
                  Text(
                    user.name,
                    style: AppTextStyles.h2(color: Colors. white), // ✅ This is fine - name on gradient
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // Unified start workout button
  Widget _buildUnifiedStartWorkoutButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppThemeManager.primaryGradient,
        borderRadius:  BorderRadius.circular(AppSpacing.radiusMedium),
        boxShadow: [
          BoxShadow(
            color:  AppThemeManager.primaryColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton. icon(
        onPressed: () => _showStartWorkoutOptions(context),
        icon: const Icon(Icons.fitness_center, size: 24),
        label: const Text(
          'Start Workout',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          minimumSize: const Size(double. infinity, 0),
        ),
      ),
    );
  }

  // Unified next workout card
  Widget _buildUnifiedNextWorkoutCard(BuildContext context, Workout?  nextWorkout, WorkoutProvider workoutProvider) {
    if (nextWorkout == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppThemeManager.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppThemeManager.primaryColor. withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available,
              size: 48,
              color: AppThemeManager.primaryColor. withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No upcoming workouts',
              style: AppTextStyles.body(color: AppThemeManager. primaryColor),
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
          workoutProvider.deleteWorkout(nextWorkout. id, nextWorkout.date);
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutScreen(workout: activeWorkout, autoStart: true),
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
          gradient: AppThemeManager.primaryGradient,
          borderRadius:  BorderRadius.circular(AppSpacing.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppThemeManager.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
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
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }


// ✅ NEW: Empty trainees card with trainer colors
Widget _buildEmptyTraineesCardWithColors(dynamic user) {
  return Card(
    child:  Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors. trainerPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 48,
              color: AppColors. trainerPrimary. withOpacity(0.7),
            ),
          ),
          const SizedBox(height:  AppSpacing.md),
          Text(
            'No Trainees Yet',
            style: AppTextStyles.h3(),
          ),
          const SizedBox(height:  AppSpacing.sm),
          Text(
            'Share your trainer code with people who want to train with you',
            style: AppTextStyles.caption(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () {
              _showAddTraineeDialog(context, user);
            },
            icon: const Icon(Icons.person_add, size: 20),
            label: const Text('Add Trainee'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.trainerPrimary,
            ),
          ),
        ],
      ),
    ),
  );
}

// ✅ NEW: Trainees list with trainer color accents
Widget _buildTraineesListWithColors(List<Map<String, dynamic>> trainees) {
  return Column(
    children: trainees.map((trainee) {
      final name = trainee['name'] ?? 'Unknown';
      final email = trainee['email'] ?? '';
      final connectedAt = trainee['connectedAt'] != null 
          ? DateTime.parse(trainee['connectedAt']) 
          : null;
      
      final daysConnected = connectedAt != null 
          ? DateTime.now().difference(connectedAt).inDays 
          : 0;

      return Card(
        margin:  const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor:  AppColors.trainerPrimary.withOpacity(0.2),
                child: Text(
                  name. isNotEmpty ? name. substring(0, 1).toUpperCase() : 'U',
                  style:  AppTextStyles.h4(color: AppColors.trainerPrimary),
                ),
              ),
              title: Text(name, style: AppTextStyles.h4()),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:  AppColors.trainerSuccess,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        daysConnected == 0 
                            ? 'Connected today' 
                            : 'Connected $daysConnected days ago',
                        style: AppTextStyles.caption(),
                      ),
                    ],
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style:  AppTextStyles.caption(color: AppColors.textSecondaryLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showTraineeActions(context, trainee);
              },
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.sm,
              ),
              child:  Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AssignWorkoutScreen(trainee: trainee),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Assign Workout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.trainerPrimary,
                        side: BorderSide(color: AppColors.trainerPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:  (context) => TraineeDetailScreen(trainee: trainee),
                        ),
                      ).then((_) {
                        setState(() {});
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppThemeManager. secondaryColor,
                      side:  BorderSide(color: AppThemeManager.secondaryColor),
                    ),
                    child:  const Text('Details'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}
// ✅ NEW:  Trainer header with trainer gradient
Widget _buildTrainerHeaderCardWithColors(dynamic user) {
  final userProvider = Provider.of<UserProvider>(context);
  final secondsRemaining = userProvider.codeSecondsRemaining;
  
  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  return Card(
    elevation: 4,
    child: Container(
      decoration: BoxDecoration(
        gradient: AppColors.trainerGradient, // ✅ Trainer gradient
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Padding(
        padding:  const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people,
                    size: 32,
                    color: Colors. white,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment. start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: AppTextStyles.caption(color: Colors.white. withOpacity(0.9)),
                      ),
                      Text(
                        user.name,
                        style: AppTextStyles.h2(color: Colors. white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height:  AppSpacing.lg),
            const Divider(color: Colors.white24),
            const SizedBox(height: AppSpacing.sm),
            
            Row(
              children: [
                const Icon(Icons.qr_code, size: 20, color: Colors.white70),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Your Trainer Code',
                  style: AppTextStyles.bodySmall(color: Colors.white70),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: user.trainerCode ??  ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.copy, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Trainer code copied! '),
                          ],
                        ),
                        duration: Duration(seconds: 2),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing. md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSpacing. radiusSmall),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Row(
                      children: [
                        Text(
                          user.trainerCode ?? 'N/A',
                          style:  AppTextStyles.h4(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.copy, size: 16, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:  [
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: secondsRemaining <= 30 
                          ? Colors.red. shade300 
                          : Colors.white60,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Expires in ${formatTime(secondsRemaining)}',
                      style:  AppTextStyles.caption(
                        color: secondsRemaining <= 30 
                            ?  Colors.red.shade300 
                            : Colors.white60,
                      ),
                    ),
                  ],
                ),
                TextButton. icon(
                  onPressed:  () async {
                    try {
                      await userProvider.regenerateTrainerCode();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 12),
                                Text('New code generated!'),
                              ],
                            ),
                            backgroundColor: AppColors.success,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed:  ${e.toString()}'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('New Code'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing. sm,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ✅ NEW: Trainer-specific next workout card
Widget _buildTrainerNextWorkoutCard(BuildContext context, Workout?  nextWorkout, WorkoutProvider workoutProvider) {
  if (nextWorkout == null) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.trainerPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing. radiusMedium),
        border: Border.all(color: AppColors.trainerPrimary. withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: AppColors.trainerPrimary. withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing. sm),
          Text(
            'No upcoming workouts',
            style: AppTextStyles.body(color: AppColors.trainerPrimary),
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
        workoutProvider.deleteWorkout(nextWorkout. id, nextWorkout.date);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutScreen(workout: activeWorkout, autoStart: true),
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
        gradient: AppColors.trainerGradient, // ✅ Trainer gradient
        borderRadius: BorderRadius. circular(AppSpacing.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.trainerPrimary. withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
        ],
      ),
    ),
  );
}

  Widget _buildTrainerHeaderCard(dynamic user) {
    final userProvider = Provider.of<UserProvider>(context);
    final secondsRemaining = userProvider.codeSecondsRemaining;
    
    String formatTime(int seconds) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:  [
              AppColors.secondary,
              AppColors.secondary.withOpacity(0.7),
            ],
            begin:  Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Padding(
          padding:  const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white. withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.people,
                      size: 32,
                      color: Colors. white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing. md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: AppTextStyles.caption(color: Colors.white. withOpacity(0.9)),
                        ),
                        Text(
                          user.name,
                          style: AppTextStyles.h2(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height:  AppSpacing.lg),
              const Divider(color: Colors.white24),
              const SizedBox(height: AppSpacing.sm),
              
              Row(
                children: [
                  const Icon(Icons.qr_code, size: 20, color: Colors.white70),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Your Trainer Code',
                    style: AppTextStyles.bodySmall(color: Colors.white70),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: user.trainerCode ??  ''));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.copy, color: Colors.white),
                              SizedBox(width: 12),
                              Text('Trainer code copied!'),
                            ],
                          ),
                          duration: Duration(seconds: 2),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    child:  Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing. md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppSpacing. radiusSmall),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Row(
                        children: [
                          Text(
                            user.trainerCode ?? 'N/A',
                            style:  AppTextStyles.h4(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(Icons.copy, size: 16, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:  [
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: secondsRemaining <= 30 
                            ? Colors.red. shade300 
                            : Colors.white60,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Expires in ${formatTime(secondsRemaining)}',
                        style:  AppTextStyles.caption(
                          color: secondsRemaining <= 30 
                              ? Colors.red.shade300 
                              : Colors.white60,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        await userProvider. regenerateTrainerCode();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width:  12),
                                  Text('New code generated!'),
                                ],
                              ),
                              backgroundColor: AppColors.success,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed:  ${e.toString()}'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('New Code'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing. sm,
                        vertical: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainerStatCard({
  required IconData icon,
  required String label,
  required String value,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
    child: Card(
      child: Padding(
        padding:  const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: AppTextStyles.h2(color: AppColors.textPrimary), // ✅ BLACK
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.caption(color: AppColors.textSecondary), // ✅ GRAY
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildEmptyTraineesCard(dynamic user) {
    return Card(
      child:  Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing. lg),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 48,
                color: AppColors. secondary. withOpacity(0.5),
              ),
            ),
            const SizedBox(height:  AppSpacing.md),
            Text(
              'No Trainees Yet',
              style: AppTextStyles.h3(),
            ),
            const SizedBox(height: AppSpacing. sm),
            Text(
              'Share your trainer code with people who want to train with you',
              style: AppTextStyles. caption(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: () {
                _showAddTraineeDialog(context, user);
              },
              icon: const Icon(Icons.person_add, size: 20),
              label: const Text('Add Trainee'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraineesList(List<Map<String, dynamic>> trainees) {
    return Column(
      children: trainees.map((trainee) {
        final name = trainee['name'] ?? 'Unknown';
        final email = trainee['email'] ?? '';
        final connectedAt = trainee['connectedAt'] != null 
            ? DateTime.parse(trainee['connectedAt']) 
            : null;
        
        final daysConnected = connectedAt != null 
            ? DateTime.now().difference(connectedAt).inDays 
            :  0;

        return Card(
          margin:  const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary. withOpacity(0.2),
                  child: Text(
                    name. isNotEmpty ? name. substring(0, 1).toUpperCase() : 'U',
                    style: AppTextStyles.h4(color: AppColors.primary),
                  ),
                ),
                title: Text(name, style: AppTextStyles.h4()),
                subtitle: Column(
                  crossAxisAlignment:  CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          daysConnected == 0 
                              ? 'Connected today' 
                              : 'Connected $daysConnected days ago',
                          style: AppTextStyles. caption(),
                        ),
                      ],
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style:  AppTextStyles.caption(color: AppColors.textSecondaryLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showTraineeActions(context, trainee);
                },
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing. sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AssignWorkoutScreen(trainee: trainee),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Assign Workout'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    OutlinedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TraineeDetailScreen(trainee: trainee),
      ),
    ).then((_) {
      // Reload when returning
      setState(() {});
    });
  },
  child: const Text('Details'),
),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showTraineeActions(BuildContext context, Map<String, dynamic> trainee) {
  final traineeName = trainee['name']?.toString() ?? 'Unknown Trainee';
  final traineeId = trainee['id']?.toString() ?? '';
  
  showModalBottomSheet(
    context:  context,
    builder: (modalContext) => Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(traineeName, style: AppTextStyles.h3()),
          const SizedBox(height: AppSpacing.lg),
          
          ListTile(
            leading: const Icon(Icons.add_circle, color: AppColors.secondary),
            title: const Text('Assign Workout'),
            onTap: () {
              Navigator. pop(modalContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AssignWorkoutScreen(trainee: trainee),
                ),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.list_alt, color: AppColors. info),
            title: const Text('View Assigned Workouts'),
            onTap: () {
              Navigator.pop(modalContext);
              // ✅ UPDATED: Navigate to trainee detail screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TraineeDetailScreen(trainee: trainee),
                ),
              );
            },
          ),
          
          ListTile(
  leading: const Icon(Icons.bar_chart, color: AppColors.primary),
  title: const Text('View Progress'),
  onTap: () {
    Navigator.pop(modalContext);
    // ✅ Navigate to trainee detail screen with progress tab
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TraineeDetailScreen(
          trainee: trainee,
          initialTab: 1, // Progress tab
        ),
      ),
    );
  },
),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.person_remove, color: AppColors.error),
            title: const Text('Remove Trainee'),
            subtitle: const Text('Unlink this trainee'),
            onTap: () {
              Navigator.pop(modalContext);
              _showRemoveTraineeConfirmation(context, traineeId, traineeName);
            },
          ),
        ],
      ),
    ),
  );
}

void _showRemoveTraineeConfirmation(BuildContext context, String traineeId, String traineeName) {
  showDialog(
    context: context,
    builder:  (dialogContext) => AlertDialog(
      title: Text('Remove Trainee', style: AppTextStyles.h3()),
      content: Column(
        mainAxisSize:  MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment. start,
        children: [
          Text(
            'Are you sure you want to remove $traineeName? ',
            style: AppTextStyles.body(),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing. sm),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'This will unlink them from your account',
                    style: AppTextStyles.caption(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children:  [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Removing trainee... '),
                  ],
                ),
                duration: Duration(seconds:  30),
              ),
            );

            try {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              await userProvider.removeTrainee(traineeId, traineeName);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger. of(context).showSnackBar(
                  SnackBar(
                    content: Text('$traineeName removed successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to remove:  ${e.toString()}'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
}

  Widget _buildTrainerRecentActivityCard() {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding:  const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Icon(
                Icons.timeline,
                size: 48,
                color: AppColors.textSecondaryLight. withOpacity(0.5),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No Recent Activity',
                style: AppTextStyles.body(),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Trainee activity will appear here',
                style:  AppTextStyles.caption(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTraineeHeaderCard(dynamic user) {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors. primary,
              AppColors.primary.withOpacity(0.7),
            ],
            begin:  Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:  BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: AppTextStyles.caption(color: Colors.white.withOpacity(0.9)),
                        ),
                        Text(
                          user.name,
                          style: AppTextStyles. h2(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (user.hasTrainer) ...[
                const SizedBox(height: AppSpacing. lg),
                const Divider(color: Colors.white24),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.fitness_center, size: 20, color: Colors.white70),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Training with:  ',
                      style: AppTextStyles.bodySmall(color: Colors.white70),
                    ),
                    Text(
                      user.trainerName ??  'Unknown',
                      style: AppTextStyles.bodySmall(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

Widget _buildAssignedWorkoutsSection(AssignedWorkoutProvider assignedProvider) {
  final pendingWorkouts = assignedProvider. assignedWorkouts
      .where((w) => !w.isOverdue)
      .toList();
  final overdueWorkouts = assignedProvider. assignedWorkouts
      .where((w) => w.isOverdue)
      .toList();

  if (pendingWorkouts.isEmpty && overdueWorkouts.isEmpty) {
    return const SizedBox. shrink();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.assignment, color: AppColors.secondary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text('Assigned Workouts', style:  AppTextStyles.h3()),
          const Spacer(),
          if (pendingWorkouts.length + overdueWorkouts.length > 2)
            TextButton(
              onPressed: () {
                // Navigate to full list (you can create a dedicated screen later)
                Navigator.pushNamed(context, '/calendar');
              },
              child:  const Text('View All'),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),

      // OVERDUE WORKOUTS
      if (overdueWorkouts.isNotEmpty) ...[
        Row(
          children: [
            const Icon(Icons.warning, color: AppColors.error, size: 20),
            const SizedBox(width: AppSpacing. sm),
            Text('Overdue Workouts', style: AppTextStyles.h4(color: AppColors.error)),
            const Spacer(),
            Text(
              '${overdueWorkouts.length}',
              style: AppTextStyles.h4(color: AppColors.error),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...overdueWorkouts. take(2).map((workout) {
          final daysOverdue = DateTime.now()
              .difference(DateTime(
                workout.dueDate.year,
                workout.dueDate.month,
                workout. dueDate.day,
              ))
              .inDays;

          return SwipeToDelete(
            confirmationTitle: 'Remove Overdue Workout',
            confirmationMessage: 'Remove "${workout. workoutName}"?',
            onDelete: () async {
              await assignedProvider.deleteAssignedWorkout(workout.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Overdue workout removed'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child:  Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              color: AppColors.error.withOpacity(0.05),
              child: InkWell(
                // ✅ ADD onTap
                onTap: () => _showAssignedWorkoutDetails(workout),
                child: ListTile(
                  leading:  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning, color: AppColors.error),
                  ),
                  title: Text(workout.workoutName),
                  subtitle: Column(
                    crossAxisAlignment:  CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Was due:  ${DateFormat('MMM d, yyyy').format(workout.dueDate)}',
                        style:  const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$daysOverdue day${daysOverdue > 1 ? 's' : ''} overdue • Tap to view',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.error),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: AppSpacing.md),
      ],

      // PENDING WORKOUTS
      if (pendingWorkouts.isNotEmpty) ...[
        ...pendingWorkouts.take(2).map((workout) {
          final isToday = _isToday(workout.dueDate);
          final isLive = workout.isTrainerLed;

          return SwipeToDelete(
            confirmationTitle: 'Remove Workout',
            confirmationMessage: 'Remove "${workout.workoutName}"?',
            onDelete: () async {
              await assignedProvider.deleteAssignedWorkout(workout.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Workout removed'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              color: isLive
                  ? AppColors. secondary.withOpacity(0.05)
                  : AppColors.primary.withOpacity(0.05),
              child: InkWell(
                // ✅ ADD onTap
                onTap: () => _showAssignedWorkoutDetails(workout),
                child: ListTile(
                  leading:  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isLive
                          ? AppColors. secondary.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isLive ?  Icons.video_call : Icons. fitness_center,
                      color: isLive ? AppColors. secondary : AppColors.primary,
                    ),
                  ),
                  title: Text(workout. workoutName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday
                            ? 'Due today'
                            : 'Due:  ${DateFormat('MMM d').format(workout.dueDate)}',
                        style: TextStyle(
                          color: isToday ?  AppColors.success : Colors.grey,
                          fontWeight: isToday ? FontWeight. bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isLive
                                  ? AppColors.secondary.withOpacity(0.2)
                                  : AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isLive ? 'Live' : 'Solo',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isLive ?  AppColors.secondary : AppColors. primary,
                              ),
                            ),
                          ),
                          const SizedBox(width:  8),
                          Text(
                            '${workout.exercises.length} exercises • Tap to view',
                            style: const TextStyle(fontSize: 11, color: Colors. grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: isLive
                      ? const Icon(Icons.lock, color: AppColors.warning)
                      : (isToday
                          ? IconButton(
                              icon: const Icon(Icons.play_circle, color: AppColors.primary, size: 32),
                              onPressed: () => _startAssignedWorkout(workout),
                            )
                          : const Icon(Icons.chevron_right)),
                ),
              ),
            ),
          );
        }),
      ],
    ],
  );
}

// ✅ ADD THIS HELPER METHOD
bool _isToday(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final checkDate = DateTime(date.year, date.month, date.day);
  return checkDate.isAtSameMomentAs(today);
}

// ✅ ADD THIS METHOD (same as calendar screen)
void _showAssignedWorkoutDetails(AssignedWorkout assignedData) {
  final isToday = _isToday(assignedData.dueDate);
  final canStart = ! assignedData.isTrainerLed && (isToday || assignedData. dueDate.isBefore(DateTime.now()));
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child:  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(assignedData.workoutName, style: AppTextStyles. h2()),
                        const SizedBox(height: 4),
                        Text(
                          'Due: ${DateFormat('MMM d, yyyy').format(assignedData.dueDate)}',
                          style:  AppTextStyles.caption(),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              // Session type badge
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: assignedData.isTrainerLed
                      ? AppColors.secondary.withOpacity(0.1)
                      : AppColors. primary.withOpacity(0.1),
                  borderRadius:  BorderRadius.circular(20),
                ),
                child:  Text(
                  assignedData. isTrainerLed ? '🎥 Live Session' : '💪 Solo Workout',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:  FontWeight.bold,
                    color: assignedData.isTrainerLed ? AppColors.secondary :  AppColors.primary,
                  ),
                ),
              ),
              
              // Notes (if any)
              if (assignedData.notes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.note, size: 16, color: AppColors.info),
                          const SizedBox(width: 8),
                          Text('Trainer Notes', style: AppTextStyles.h4()),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(assignedData.notes, style: AppTextStyles.body()),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: AppSpacing.lg),
              Text('Exercises (${assignedData.exercises.length})', style: AppTextStyles. h3()),
              const Divider(),
              
              // Exercise list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: assignedData. exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = assignedData.exercises[index];
                    final sets = exercise['sets'] as List;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment:  CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ${exercise['name']}',
                              style: AppTextStyles.h4(),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              exercise['muscleGroup'] ?? 'Other',
                              style: AppTextStyles.caption(),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ... sets.asMap().entries.map((entry) {
                              final setIndex = entry.key;
                              final set = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        'Set ${setIndex + 1}',
                                        style: AppTextStyles.bodySmall(),
                                      ),
                                    ),
                                    Text(
                                      '${set['weight']} lbs × ${set['reps']} reps',
                                      style:  AppTextStyles.body(),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Start button
              if (canStart) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width:  double.infinity,
                  child: ElevatedButton. icon(
                    onPressed:  () {
                      Navigator.pop(context);
                      _startAssignedWorkout(assignedData);
                    },
                    icon: const Icon(Icons. play_arrow),
                    label: const Text('Start Workout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                  ),
                ),
              ] else if (assignedData.isTrainerLed) ...[
                const SizedBox(height:  AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warning. withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, color: AppColors.warning),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'This is a live session. Your trainer will start it when you meet.',
                          style: AppTextStyles.bodySmall(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}

// ✅ ADD THIS METHOD to start assigned workout
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
      id: '${assignedData.id}_${exerciseData['name']}',
      name: exerciseData['name'] ?? 'Unknown Exercise',
      muscleGroups: [exerciseData['muscleGroup'] ?? 'Other'],
      sets: sets,
    );
  }).toList();

  final workout = Workout(
    id: assignedData.id,
    name: assignedData.workoutName,
    date: DateTime.now(),
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

  Widget _buildAssignedWorkoutCard(AssignedWorkout workout, {bool isOverdue = false}) {
    final daysUntilDue = workout.dueDate.difference(DateTime.now()).inDays;
    
    return Card(
      margin:  const EdgeInsets.only(bottom: AppSpacing.sm),
      color: isOverdue ? AppColors. error. withOpacity(0.1) : null,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing. sm),
          decoration: BoxDecoration(
            color: (isOverdue ? AppColors.error : AppColors.secondary).withOpacity(0.2),
            shape: BoxShape. circle,
          ),
          child: Icon(
            isOverdue ? Icons.warning :  Icons.assignment,
            color: isOverdue ? AppColors.error : AppColors.secondary,
          ),
        ),
        title: Text(
          workout.workoutName,
          style: AppTextStyles.h4(),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              isOverdue
                  ? 'Overdue by ${-daysUntilDue} day(s)'
                  : daysUntilDue == 0
                      ? 'Due today'
                      : 'Due in $daysUntilDue day(s)',
              style: AppTextStyles.caption(
                color: isOverdue ? AppColors.error : AppColors.textSecondaryLight,
              ),
            ),
            if (workout.notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                workout.notes,
                style: AppTextStyles.caption(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout details coming soon! '),
              backgroundColor: AppColors.info,
            ),
          );
        },
      ),
    );
  }

  void _showAddTraineeDialog(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add Trainee', style: AppTextStyles.h3()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Trainees can connect to you by entering your trainer code in their app settings.',
              style: AppTextStyles.body(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing. md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Column(
                children: [
                  Text(
                    'Your Trainer Code',
                    style:  AppTextStyles.caption(),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    user.trainerCode ?? 'N/A',
                    style:  AppTextStyles.h2(color: AppThemeManager.secondaryColor,),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:  const Text('Close'),
          ),
          ElevatedButton. icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: user.trainerCode ?? ''));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Trainer code copied! '),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon:  const Icon(Icons.copy, size: 18),
            label:  const Text('Copy Code'),
            style: ElevatedButton.styleFrom(backgroundColor: AppThemeManager.secondaryColor,),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDashboard(BuildContext context, dynamic user) {
    return Consumer<WorkoutProvider>(
      builder: (context, workoutProvider, child) {
        final streak = workoutProvider.getCurrentStreak();
        final thisWeekCount = workoutProvider.getThisWeekCount();
        final totalPRs = workoutProvider.getTotalPRs();
        final thisMonthCount = _getThisMonthCount(workoutProvider);
        final nextWorkout = workoutProvider.getNextScheduledWorkout();
        final recentWorkouts = workoutProvider. getRecentWorkouts(limit: 3);

        final showWeeklySchedule = LocalStorageService.getSetting('showWeeklySchedule', defaultValue: true);
        final showExerciseAnalytics = LocalStorageService. getSetting('showExerciseAnalytics', defaultValue: true);
        final showMeasurements = LocalStorageService.getSetting('showMeasurements', defaultValue: false);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user != null && user.hasTrainer)
                _buildTraineeHeaderCard(user)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Let\'s Workout!  🔥', style: AppTextStyles. h2()),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Ready to crush your workout? ',
                      style: AppTextStyles.body(color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              
              if (user != null && user.hasTrainer) ...[
  const SizedBox(height: AppSpacing.lg),
  Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children:  [
      Text('Assigned by Trainer', style:  AppTextStyles. h3()),
    ],
  ),
  const SizedBox(height: AppSpacing.md),
  // ✅ FIX:  Get the provider and pass it
  Consumer<AssignedWorkoutProvider>(
    builder: (context, assignedProvider, child) {
      return _buildAssignedWorkoutsSection(assignedProvider);
    },
  ),
],
              
              const SizedBox(height: AppSpacing.lg),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton. icon(
                  onPressed:  () => _showStartWorkoutOptions(context),
                  icon: const Icon(Icons.fitness_center, size: 24),
                  label: const Text(
                    'Start Workout',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor:  Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    elevation: 4,
                  ),
                ),
              ),

              const SizedBox(height:  AppSpacing.lg),

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
                      value: '$thisWeekCount/7',
                    ),
                  ),
                ],
              ),
              const SizedBox(height:  AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PRHistoryScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      child: _buildStatCard(
                        icon: Icons.trending_up,
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

              _buildActionCardsRow(
                context,
                showWeeklySchedule,
                showExerciseAnalytics,
                showMeasurements,
              ),

              const SizedBox(height: AppSpacing. xl),

              Text('Next Workout', style: AppTextStyles.h3()),
              const SizedBox(height: AppSpacing.md),
              _buildNextWorkoutCard(context, nextWorkout, workoutProvider),

              const SizedBox(height: AppSpacing. xl),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:  [
                  Text('Recent Activity', style: AppTextStyles.h3()),
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
                ... recentWorkouts.map((workout) => _buildRecentActivityCard2(
                      context,
                      workout,
                      workoutProvider,
                    )),
            ],
          ),
        );
      },
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

  void _showStartWorkoutOptions(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
    
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
              leading: const Icon(Icons.add_circle, color: AppColors. secondary),
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
        child:  _buildActionCard(
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
    
    if (cards.length == 1) {
      cards.add(const SizedBox(width: AppSpacing.md));
      cards.add(const Expanded(child: SizedBox. shrink()));
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
              const SizedBox(height: AppSpacing. sm),
              Text(title, style: AppTextStyles.h4(), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
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
      builder:  (context) => _DashboardSettingsSheet(
        onSaved: () {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildStatCard({
  required IconData icon,
  required Color iconColor,
  required String label,
  required String value,
}) {
  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing. sm),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.h3(color: AppColors.textPrimary), // ✅ BLACK
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style:  AppTextStyles.caption(color: AppColors.textSecondary), // ✅ GRAY
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
        borderRadius:  BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.textSecondaryLight.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: AppColors.textSecondaryLight.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No upcoming workouts',
            style: AppTextStyles.body(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height:  AppSpacing.xs),
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
        workoutProvider.deleteWorkout(nextWorkout. id, nextWorkout.date);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutScreen(workout: activeWorkout, autoStart: true),
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
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
        ],
      ),
    ),
  );
}

void _startAssignedWorkoutFromDashboard(AssignedWorkout assignedData) {
  final exercises = assignedData. exercises.map((exerciseData) {
    final sets = (exerciseData['sets'] as List).asMap().entries.map((entry) {
      final setIndex = entry.key;
      final setData = entry.value;
      return ExerciseSet(
        // ✅ REMOVE id line
        setNumber: setIndex + 1,
        targetWeight:  (setData['weight'] ??  0).toDouble(),
        targetReps: setData['reps'] ?? 0,
        actualWeight: 0.0,
        actualReps: 0,
        // ✅ REMOVE status line
      );
    }).toList();

    return Exercise(
      id: '${assignedData.id}_${exerciseData['name']}',  // ✅ ADD THIS
      name: exerciseData['name'] ?? 'Unknown Exercise',
      muscleGroups: [exerciseData['muscleGroup'] ??  'Other'],
      sets:  sets,
    );
  }).toList();

  final workout = Workout(
    id: assignedData.id,
    name: assignedData.workoutName,
    date: DateTime.now(),
    muscleGroups: exercises
        .expand((e) => e.muscleGroups)
        .toSet()
        .toList(),
    status: WorkoutStatus.inProgress,
    exercises: exercises,
    isAssignedWorkout: true,
    assignedWorkoutData: assignedData,
  );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => WorkoutScreen(
        workout: workout,
        autoStart: true,
      ),
    ),
  );
}

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
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

  Widget _buildRecentActivityCard2(BuildContext context, Workout workout, WorkoutProvider workoutProvider) {
  final weightUnit = LocalStorageService.getSetting('weightUnit', defaultValue: 'lbs');
  final displayVolume = weightUnit == 'kg'
      ? (workout.totalVolume * 0.453592).toInt()
      : workout.totalVolume;

  final daysAgo = DateTime.now().difference(workout.date).inDays;
  final dateText = daysAgo == 0
      ? 'Today'
      : daysAgo == 1
          ? 'Yesterday'
          : DateFormat('MMM d').format(workout.date);

  return SwipeToDelete(
    confirmationTitle: 'Delete Workout',
    confirmationMessage:  'Are you sure you want to delete this workout?',
    onDelete: () async { // ✅ Make it async
      await workoutProvider.deleteWorkout(workout.id, workout.date);
      
      // ✅ Force UI refresh
      if (context.mounted) {
        setState(() {}); // ✅ ADD THIS
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout deleted'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
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
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: workout.muscleGroups.isNotEmpty
                      ? AppColors.getMuscleGroupColor(workout.muscleGroups. first)
                          .withOpacity(0.2)
                      : AppColors. primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing. radiusSmall),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: workout.muscleGroups.isNotEmpty
                      ? AppColors. getMuscleGroupColor(workout.muscleGroups.first)
                      : AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width:  AppSpacing.md),
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
                        style: AppTextStyles.caption(color: AppColors.warning),
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
      padding:  const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Customize Dashboard', style: AppTextStyles.h2()),
          const SizedBox(height: AppSpacing.sm),
          Text('Select up to 2 cards to display', style: AppTextStyles.caption()),
          const SizedBox(height: AppSpacing. lg),
          
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