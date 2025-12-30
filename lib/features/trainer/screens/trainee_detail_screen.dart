import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'package:reprise/features/workout/providers/assigned_workout_provider.dart';
import 'package:reprise/features/user/providers/user_provider.dart';
import 'package:reprise/features/trainer/screens/assign_workout_screen.dart';
import 'package:reprise/shared/widgets/swipe_to_delete.dart';

class TraineeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> trainee;
  final int initialTab; // ✅ ADD THIS

  const TraineeDetailScreen({
    super.key,
    required this. trainee,
    this.initialTab = 0, // ✅ ADD THIS with default value
  });

  @override
  State<TraineeDetailScreen> createState() => _TraineeDetailScreenState();
}

class _TraineeDetailScreenState extends State<TraineeDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
void initState() {
  super.initState();
  _tabController = TabController(
    length:  2,
    vsync:  this,
    initialIndex: widget.initialTab,
  );
  
  // Load assigned workouts
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final provider = Provider.of<AssignedWorkoutProvider>(context, listen:  false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // ✅ Pass both trainee ID and trainer ID
    provider.loadAssignedWorkoutsForTrainer(
      widget.trainee['id'],
      userProvider. currentUser! .id, // Trainer's ID
    );
  });
}

  void _loadAssignedWorkouts() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final assignedWorkoutProvider = Provider.of<AssignedWorkoutProvider>(context, listen: false);
      
      assignedWorkoutProvider.loadAssignedWorkoutsByTrainer(
        userProvider.currentUser!.id,
        widget.trainee['id'],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final traineeName = widget.trainee['name']?. toString() ?? 'Unknown';
    final traineeEmail = widget.trainee['email']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(traineeName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAssignedWorkouts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trainee Info Card
            Card(
              child:  Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Text(
                        traineeName.substring(0, 1).toUpperCase(),
                        style: AppTextStyles.h1(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(traineeName, style: AppTextStyles.h2()),
                          const SizedBox(height: 4),
                          Text(traineeEmail, style: AppTextStyles.caption()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Assign Workout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssignWorkoutScreen(trainee: widget.trainee),
                    ),
                  ).then((_) => _loadAssignedWorkouts()); // ✅ Reload after assignment
                },
                icon: const Icon(Icons.add),
                label: const Text('Assign Workout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Assigned Workouts Section
            Text('Assigned Workouts', style:  AppTextStyles.h3()),
            const SizedBox(height: AppSpacing.md),

            Consumer<AssignedWorkoutProvider>(
              builder: (context, assignedProvider, child) {
                if (assignedProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final soloWorkouts = assignedProvider. getSoloWorkouts();
                final liveSessions = assignedProvider. getTrainerLedSessions();

                if (soloWorkouts.isEmpty && liveSessions.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size:  48,
                              color: AppColors.textSecondaryLight. withOpacity(0.5),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'No assigned workouts yet',
                              style: AppTextStyles.body(color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Solo Workouts
                    if (soloWorkouts.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.person, color: AppColors.primary, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Solo Workouts (${soloWorkouts.length})', style: AppTextStyles.h4()),
                        ],
                      ),
                      const SizedBox(height: AppSpacing. sm),
                      ...soloWorkouts.map((workout) => SwipeToDelete(
                            confirmationTitle: 'Remove Workout',
                            confirmationMessage: 'Remove "${workout. workoutName}" from ${traineeName}?',
                            onDelete: () async {
                              await assignedProvider.deleteAssignedWorkout(workout.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:  Text('Workout removed'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: ListTile(
                                leading: const Icon(Icons.person, color: AppColors.primary),
                                title: Text(workout.workoutName),
                                subtitle: Text('Due: ${DateFormat('MMM d, yyyy').format(workout.dueDate)}'),
                                trailing: const Icon(Icons. drag_handle),
                              ),
                            ),
                          )),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Live Sessions
                    if (liveSessions. isNotEmpty) ...[
                      Row(
                        children:  [
                          const Icon(Icons.people, color: AppColors. secondary, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Live Sessions (${liveSessions.length})', style: AppTextStyles.h4()),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...liveSessions. map((workout) => SwipeToDelete(
                            confirmationTitle: 'Remove Session',
                            confirmationMessage: 'Remove "${workout.workoutName}" session with ${traineeName}?',
                            onDelete: () async {
                              await assignedProvider. deleteAssignedWorkout(workout.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Session removed'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: ListTile(
                                leading: const Icon(Icons.people, color: AppColors.secondary),
                                title: Text(workout. workoutName),
                                subtitle: Text('Scheduled:  ${DateFormat('MMM d, yyyy').format(workout.dueDate)}'),
                                trailing:  Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Start live session - Coming soon!')),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.secondary,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      child: const Text('Start', style: TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.drag_handle),
                                  ],
                                ),
                              ),
                            ),
                          )),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}