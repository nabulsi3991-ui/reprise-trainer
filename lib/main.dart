import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/theme/app_theme_manager.dart'; // ✅ NEW
import 'package:reprise/features/workout/providers/workout_provider.dart';
import 'package:reprise/features/user/providers/user_provider.dart';
import 'package:reprise/features/auth/screens/auth_gate.dart';
import 'package:reprise/shared/models/exercise_library.dart';
import 'package:reprise/services/workout_notification_service.dart';
import 'package:reprise/features/workout/providers/assigned_workout_provider.dart';
import 'package:reprise/firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  await Hive.initFlutter();
  await Hive.openBox('workouts');
  await Hive.openBox('settings');
  await WorkoutNotificationService. initialize();

  // Load custom exercises
  ExerciseLibrary. loadCustomExercises();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness. dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers:  [
        ChangeNotifierProvider(create: (context) => WorkoutProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AssignedWorkoutProvider()),
      ],
      child: const _AppWithLifecycle(),
    );
  }
}

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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    print('🔔 [GLOBAL] App state changed: $state');
    
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
    final hasActiveWorkout = workoutProvider.activeWorkout != null;
    
    if (state == AppLifecycleState.resumed) {
      print('🔔 [GLOBAL] App resumed - cancelling notification');
      WorkoutNotificationService.cancelWorkoutNotification();
    } else if (state == AppLifecycleState. paused) {
      print('🔔 [GLOBAL] App paused - checking for active workout');
      
      if (hasActiveWorkout) {
        final activeWorkout = workoutProvider. activeWorkout! ;
        final startTime = workoutProvider.activeWorkoutStartTime;
        
        if (startTime != null) {
          final completedSets = activeWorkout.exercises
              .expand((e) => e.sets)
              .where((s) => s.completed)
              .length;
          final totalSets = activeWorkout.exercises
              .expand((e) => e.sets)
              .length;
          
          print('🔔 [GLOBAL] Showing notification:  ${activeWorkout.name}');
          
          WorkoutNotificationService.showActiveWorkoutNotification(
            workoutName: activeWorkout.name,
            startTime: startTime,
            sets: '$completedSets/$totalSets sets',
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
    // ✅ Listen to user changes and update theme
    return Consumer<UserProvider>(
      builder:  (context, userProvider, child) {
        // ✅ Set theme mode based on user type
        final isTrainer = userProvider.currentUser?. isTrainer ?? false;
        AppThemeManager.setTrainerMode(isTrainer);
        
        return MaterialApp(
          title: 'RepRise',
          debugShowCheckedModeBanner: false,
          theme: _buildThemeData(), // ✅ Use dynamic theme
          home: const AuthGate(),
        );
      },
    );
  }

  // ✅ Dynamic theme builder
ThemeData _buildThemeData() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme. fromSeed(
      seedColor: AppThemeManager.primaryColor,
      secondary: AppThemeManager.secondaryColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.textPrimary),
      displayMedium: TextStyle(color: AppColors.textPrimary),
      displaySmall: TextStyle(color: AppColors.textPrimary),
      headlineLarge: TextStyle(color: AppColors.textPrimary),
      headlineMedium: TextStyle(color: AppColors.textPrimary),
      headlineSmall: TextStyle(color: AppColors.textPrimary),
      titleLarge: TextStyle(color: AppColors.textPrimary),
      titleMedium: TextStyle(color: AppColors.textPrimary),
      titleSmall: TextStyle(color: AppColors.textPrimary),
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color:  AppColors.textPrimary),
      bodySmall: TextStyle(color: AppColors.textPrimary),
      labelLarge: TextStyle(color: AppColors.textPrimary),
      labelMedium: TextStyle(color: AppColors.textPrimary),
      labelSmall: TextStyle(color: AppColors. textPrimary),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color:  AppColors.textPrimary),
      titleTextStyle: TextStyle(
        color: AppColors. textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppThemeManager. primaryColor,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme:  ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppThemeManager.primaryColor,
        foregroundColor: Colors. white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppThemeManager.primaryColor,
        side: BorderSide(color: AppThemeManager.primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical:  12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppThemeManager. primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide. none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide. none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:  BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppThemeManager.primaryColor,
          width: 2,
        ),
      ),
      errorBorder:  OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:  const BorderSide(color: AppColors.error, width: 1),
      ),
      labelStyle: const TextStyle(color: AppColors. textSecondary),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedColor: AppThemeManager.primaryColor,
      labelStyle: TextStyle(fontSize: 12, color: AppThemeManager.primaryColor),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    dividerColor: AppColors.textSecondaryLight. withOpacity(0.2),
    progressIndicatorTheme:  ProgressIndicatorThemeData(
      color: AppThemeManager.primaryColor,
    ),
    bottomNavigationBarTheme:  BottomNavigationBarThemeData(
      selectedItemColor: AppThemeManager. primaryColor,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle:  const TextStyle(color: AppColors.textPrimary),
      unselectedLabelStyle: const TextStyle(color: AppColors. textSecondary),
    ),
    listTileTheme:  const ListTileThemeData(
      textColor: AppColors. textPrimary,
      iconColor: AppColors.textPrimary,
    ),
  );
}
}