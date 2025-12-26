import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/features/workout/providers/workout_provider.dart';
import 'package:reprise/shared//widgets/main_navigation.dart';
import 'package:reprise/shared/models/exercise_library.dart';
import 'package:reprise/services/workout_notification_service.dart';

void main() async {
  WidgetsFlutterBinding. ensureInitialized();
  
  await Hive.initFlutter();
  await Hive.openBox('workouts');
  await Hive.openBox('settings');
  await WorkoutNotificationService.initialize();

  // Load custom exercises
  ExerciseLibrary.loadCustomExercises();
  
  SystemChrome. setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:  Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness. dark,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WorkoutProvider(),
      child: const _AppWithLifecycle(),  // ✅ CHANGED:  Wrap with lifecycle observer
    );
  }
}

// ✅ ADD THIS NEW CLASS
class _AppWithLifecycle extends StatefulWidget {
  const _AppWithLifecycle();

  @override
  State<_AppWithLifecycle> createState() => _AppWithLifecycleState();
}

class _AppWithLifecycleState extends State<_AppWithLifecycle> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding. instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    print('🔔 [GLOBAL] App state changed:  $state');
    
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen:  false);
    final hasActiveWorkout = workoutProvider.activeWorkout != null;
    
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground - cancel notification
      print('🔔 [GLOBAL] App resumed - cancelling notification');
      WorkoutNotificationService.cancelWorkoutNotification();
    } else if (state == AppLifecycleState.paused) {
      // App went to background - show notification if workout active
      print('🔔 [GLOBAL] App paused - checking for active workout');
      
      if (hasActiveWorkout) {
        final activeWorkout = workoutProvider.activeWorkout! ;
        final startTime = workoutProvider.activeWorkoutStartTime;
        
        if (startTime != null) {
          final completedSets = activeWorkout.exercises
              .expand((e) => e.sets)
              .where((s) => s.completed)
              .length;
          final totalSets = activeWorkout.exercises
              .expand((e) => e.sets)
              .length;
          
          print('🔔 [GLOBAL] Showing notification: ${activeWorkout.name}');
          
          WorkoutNotificationService. showActiveWorkoutNotification(
            workoutName: activeWorkout.name,
            startTime: startTime,
            sets:  '$completedSets/$totalSets sets',
          );
        } else {
          print('🔔 [GLOBAL] Active workout found but no start time');
        }
      } else {
        print('🔔 [GLOBAL] No active workout - skipping notification');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RepRise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:  ColorScheme.fromSeed(
          seedColor: AppColors. primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors. white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
          titleTextStyle:  TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme:  ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical:  12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton. styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical:  12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius. circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceLight,
          selectedColor: AppColors.primary,
          labelStyle: const TextStyle(fontSize: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        dividerColor: AppColors. textSecondaryLight.withOpacity(0.2),
      ),
      home: const MainNavigation(),
    );
  }
}