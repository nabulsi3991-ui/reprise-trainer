import 'package:reprise/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';

class ExerciseTemplate {
  final String id;
  final String name;
  final List<String> muscleGroups;
  final String equipment;
  final String description;
  final int defaultSets;
  final int defaultReps;
  final int defaultRestSeconds;

  ExerciseTemplate({
    required this.id,
    required this.name,
    required this.muscleGroups,
    required this.equipment,
    required this.description,
    this.defaultSets = 3,
    this.defaultReps = 10,
    this.defaultRestSeconds = 90,
  });
}

class ExerciseLibrary {
  static final List<ExerciseTemplate> exercises = [
    // ==================== CHEST EXERCISES ====================
    ExerciseTemplate(
      id: 'barbell_bench_press',
      name: 'Barbell Bench Press',
      muscleGroups: ['Chest'],
      equipment: 'Barbell',
      description: 'Classic compound chest exercise for overall mass',
      defaultSets: 4,
      defaultReps: 8,
      defaultRestSeconds:  120,
    ),
    ExerciseTemplate(
      id: 'incline_barbell_bench',
      name: 'Incline Barbell Bench Press',
      muscleGroups: ['Chest'],
      equipment: 'Barbell',
      description: 'Targets upper chest development',
      defaultSets: 4,
      defaultReps:  8,
      defaultRestSeconds: 120,
    ),
    ExerciseTemplate(
      id: 'decline_barbell_bench',
      name: 'Decline Barbell Bench Press',
      muscleGroups: ['Chest'],
      equipment: 'Barbell',
      description: 'Emphasizes lower chest',
      defaultSets: 3,
      defaultReps: 10,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id:  'dumbbell_bench_press',
      name: 'Dumbbell Bench Press',
      muscleGroups:  ['Chest'],
      equipment:  'Dumbbell',
      description: 'Greater range of motion than barbell',
      defaultSets: 4,
      defaultReps: 10,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'incline_dumbbell_bench',
      name: 'Incline Dumbbell Bench Press',
      muscleGroups:  ['Chest'],
      equipment:  'Dumbbell',
      description: 'Targets upper chest with dumbbells',
      defaultSets: 4,
      defaultReps: 10,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'decline_dumbbell_bench',
      name: 'Decline Dumbbell Bench Press',
      muscleGroups: ['Chest'],
      equipment: 'Dumbbell',
      description:  'Lower chest focus with dumbbells',
      defaultSets: 3,
      defaultReps: 12,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id:  'dumbbell_flyes',
      name: 'Dumbbell Flyes',
      muscleGroups: ['Chest'],
      equipment: 'Dumbbell',
      description: 'Isolation exercise for chest stretch',
      defaultSets: 3,
      defaultReps: 12,
      defaultRestSeconds:  60,
    ),
    ExerciseTemplate(
      id: 'incline_dumbbell_flyes',
      name: 'Incline Dumbbell Flyes',
      muscleGroups: ['Chest'],
      equipment: 'Dumbbell',
      description: 'Upper chest isolation',
      defaultSets: 3,
      defaultReps: 12,
      defaultRestSeconds:  60,
    ),
    ExerciseTemplate(
      id: 'cable_flyes',
      name: 'Cable Flyes',
      muscleGroups: ['Chest'],
      equipment: 'Cable',
      description: 'Constant tension chest isolation',
      defaultSets: 3,
      defaultReps:  15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id:  'chest_dips',
      name: 'Chest Dips',
      muscleGroups: ['Chest'],
      equipment: 'Bodyweight',
      description: 'Bodyweight compound chest exercise',
      defaultSets:  3,
      defaultReps: 12,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'push_ups',
      name: 'Push-Ups',
      muscleGroups: ['Chest'],
      equipment: 'Bodyweight',
      description: 'Classic bodyweight chest exercise',
      defaultSets: 3,
      defaultReps: 15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id:  'machine_chest_press',
      name: 'Machine Chest Press',
      muscleGroups: ['Chest'],
      equipment: 'Machine',
      description: 'Controlled chest press movement',
      defaultSets: 3,
      defaultReps:  12,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'pec_deck',
      name: 'Pec Deck Machine',
      muscleGroups:  ['Chest'],
      equipment:  'Machine',
      description:  'Chest isolation machine',
      defaultSets: 3,
      defaultReps: 15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id:  'cable_crossover',
      name: 'Cable Crossover',
      muscleGroups: ['Chest'],
      equipment: 'Cable',
      description: 'Standing chest cable exercise',
      defaultSets: 3,
      defaultReps:  15,
      defaultRestSeconds: 60,
    ),

    // ==================== BACK EXERCISES ====================
    ExerciseTemplate(
      id: 'deadlift',
      name:  'Deadlift',
      muscleGroups: ['Back'],
      equipment: 'Barbell',
      description: 'King of compound back exercises',
      defaultSets: 4,
      defaultReps:  6,
      defaultRestSeconds: 180,
    ),
    ExerciseTemplate(
      id: 'barbell_row',
      name: 'Barbell Row',
      muscleGroups: ['Back'],
      equipment: 'Barbell',
      description: 'Compound back thickness builder',
      defaultSets: 4,
      defaultReps:  8,
      defaultRestSeconds: 120,
    ),
    ExerciseTemplate(
      id: 'pendlay_row',
      name:  'Pendlay Row',
      muscleGroups: ['Back'],
      equipment: 'Barbell',
      description: 'Explosive rowing variation',
      defaultSets: 4,
      defaultReps:  8,
      defaultRestSeconds: 120,
    ),
    ExerciseTemplate(
      id:  'pull_ups',
      name: 'Pull-Ups',
      muscleGroups: ['Back'],
      equipment: 'Bodyweight',
      description: 'Classic back width builder',
      defaultSets:  4,
      defaultReps: 10,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id:  'chin_ups',
      name: 'Chin-Ups',
      muscleGroups: ['Back'],
      equipment: 'Bodyweight',
      description: 'Underhand grip pull-up variation',
      defaultSets: 4,
      defaultReps:  10,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'lat_pulldown',
      name:  'Lat Pulldown',
      muscleGroups: ['Back'],
      equipment: 'Cable',
      description: 'Cable back width exercise',
      defaultSets: 3,
      defaultReps: 12,
      defaultRestSeconds:  90,
    ),
    ExerciseTemplate(
      id: 'wide_grip_lat_pulldown',
      name: 'Wide Grip Lat Pulldown',
      muscleGroups: ['Back'],
      equipment: 'Cable',
      description: 'Emphasizes lat width',
      defaultSets: 3,
      defaultReps:  12,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'close_grip_lat_pulldown',
      name: 'Close Grip Lat Pulldown',
      muscleGroups: ['Back'],
      equipment: 'Cable',
      description: 'Targets lower lats',
      defaultSets:  3,
      defaultReps: 12,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'seated_cable_row',
      name: 'Seated Cable Row',
      muscleGroups: ['Back'],
      equipment: 'Cable',
      description: 'Mid-back cable exercise',
      defaultSets: 3,
      defaultReps: 12,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'one_arm_dumbbell_row',
      name: 'One Arm Dumbbell Row',
      muscleGroups: ['Back'],
      equipment: 'Dumbbell',
      description:  'Unilateral back thickness',
      defaultSets: 3,
      defaultReps: 12,
      defaultRestSeconds:  90,
    ),
    ExerciseTemplate(
      id: 'dumbbell_row',
      name: 'Dumbbell Row',
      muscleGroups: ['Back'],
      equipment: 'Dumbbell',
      description: 'Two-arm dumbbell rowing',
      defaultSets: 4,
      defaultReps: 10,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id:  't_bar_row',
      name: 'T-Bar Row',
      muscleGroups: ['Back'],
      equipment: 'Barbell',
      description:  'Thick back development',
      defaultSets: 4,
      defaultReps:  10,
      defaultRestSeconds: 120,
    ),
    ExerciseTemplate(
      id: 'face_pulls',
      name: 'Face Pulls',
      muscleGroups: ['Back'],
      equipment: 'Cable',
      description: 'Upper back and rear delt',
      defaultSets:  3,
      defaultReps: 15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id:  'hyperextension',
      name: 'Back Hyperextension',
      muscleGroups: ['Back'],
      equipment: 'Bodyweight',
      description: 'Lower back isolation',
      defaultSets: 3,
      defaultReps:  15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id: 'rack_pulls',
      name: 'Rack Pulls',
      muscleGroups: ['Back'],
      equipment:  'Barbell',
      description: 'Partial deadlift for upper back',
      defaultSets:  3,
      defaultReps: 8,
      defaultRestSeconds: 120,
    ),

    // ==================== SHOULDERS EXERCISES ====================
    ExerciseTemplate(
      id: 'overhead_press',
      name: 'Overhead Press',
      muscleGroups: ['Shoulders'],
      equipment: 'Barbell',
      description: 'Compound shoulder mass builder',
      defaultSets:  4,
      defaultReps: 8,
      defaultRestSeconds: 120,
    ),
    ExerciseTemplate(
      id: 'dumbbell_shoulder_press',
      name: 'Dumbbell Shoulder Press',
      muscleGroups:  ['Shoulders'],
      equipment:  'Dumbbell',
      description: 'Seated or standing shoulder press',
      defaultSets: 4,
      defaultReps: 10,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'arnold_press',
      name: 'Arnold Press',
      muscleGroups: ['Shoulders'],
      equipment: 'Dumbbell',
      description: 'Rotating dumbbell press',
      defaultSets: 3,
      defaultReps: 12,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id:  'lateral_raises',
      name: 'Lateral Raises',
      muscleGroups:  ['Shoulders'],
      equipment:  'Dumbbell',
      description: 'Side delt isolation',
      defaultSets:  3,
      defaultReps: 15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id:  'front_raises',
      name: 'Front Raises',
      muscleGroups: ['Shoulders'],
      equipment: 'Dumbbell',
      description: 'Front delt isolation',
      defaultSets: 3,
      defaultReps: 15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id: 'rear_delt_flyes',
      name: 'Rear Delt Flyes',
      muscleGroups:  ['Shoulders'],
      equipment:  'Dumbbell',
      description: 'Rear deltoid isolation',
      defaultSets: 3,
      defaultReps: 15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id: 'upright_rows',
      name:  'Upright Rows',
      muscleGroups: ['Shoulders'],
      equipment: 'Barbell',
      description: 'Compound shoulder exercise',
      defaultSets: 3,
      defaultReps: 12,
      defaultRestSeconds:  90,
    ),
    ExerciseTemplate(
      id: 'cable_lateral_raises',
      name: 'Cable Lateral Raises',
      muscleGroups: ['Shoulders'],
      equipment: 'Cable',
      description: 'Constant tension side delts',
      defaultSets:  3,
      defaultReps: 15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id: 'machine_shoulder_press',
      name: 'Machine Shoulder Press',
      muscleGroups: ['Shoulders'],
      equipment: 'Machine',
      description: 'Controlled shoulder press',
      defaultSets: 3,
      defaultReps: 12,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'reverse_pec_deck',
      name:  'Reverse Pec Deck',
      muscleGroups: ['Shoulders'],
      equipment: 'Machine',
      description: 'Machine rear delt isolation',
      defaultSets: 3,
      defaultReps:  15,
      defaultRestSeconds: 60,
    ),

    // ==================== LEGS EXERCISES ====================
    ExerciseTemplate(
      id: 'barbell_squat',
      name: 'Barbell Squat',
      muscleGroups: ['Legs'],
      equipment: 'Barbell',
      description: 'King of leg exercises',
      defaultSets:  4,
      defaultReps: 8,
      defaultRestSeconds: 180,
    ),
    ExerciseTemplate(
      id:  'front_squat',
      name:  'Front Squat',
      muscleGroups: ['Legs'],
      equipment: 'Barbell',
      description:  'Quad-focused squat variation',
      defaultSets: 4,
      defaultReps:  8,
      defaultRestSeconds: 150,
    ),
    ExerciseTemplate(
      id: 'leg_press',
      name: 'Leg Press',
      muscleGroups: ['Legs'],
      equipment: 'Machine',
      description: 'Machine quad and glute builder',
      defaultSets: 4,
      defaultReps:  12,
      defaultRestSeconds: 120,
    ),
    ExerciseTemplate(
      id: 'leg_extension',
      name: 'Leg Extension',
      muscleGroups: ['Legs'],
      equipment: 'Machine',
      description: 'Quad isolation',
      defaultSets:  3,
      defaultReps: 15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id: 'leg_curl',
      name: 'Leg Curl',
      muscleGroups: ['Legs'],
      equipment: 'Machine',
      description: 'Hamstring isolation',
      defaultSets: 3,
      defaultReps: 15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id: 'romanian_deadlift',
      name: 'Romanian Deadlift',
      muscleGroups:  ['Legs'],
      equipment:  'Barbell',
      description: 'Hamstring and glute focus',
      defaultSets: 4,
      defaultReps:  10,
      defaultRestSeconds: 120,
    ),
    ExerciseTemplate(
      id: 'walking_lunges',
      name:  'Walking Lunges',
      muscleGroups: ['Legs'],
      equipment: 'Dumbbell',
      description: 'Functional leg exercise',
      defaultSets: 3,
      defaultReps:  12,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'bulgarian_split_squat',
      name: 'Bulgarian Split Squat',
      muscleGroups: ['Legs'],
      equipment: 'Dumbbell',
      description:  'Unilateral leg strength',
      defaultSets: 3,
      defaultReps:  12,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'goblet_squat',
      name: 'Goblet Squat',
      muscleGroups: ['Legs'],
      equipment: 'Dumbbell',
      description: 'Front-loaded squat variation',
      defaultSets: 3,
      defaultReps:  15,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'hack_squat',
      name:  'Hack Squat',
      muscleGroups: ['Legs'],
      equipment: 'Machine',
      description: 'Machine quad builder',
      defaultSets: 3,
      defaultReps:  12,
      defaultRestSeconds: 120,
    ),
    ExerciseTemplate(
      id: 'calf_raises',
      name:  'Standing Calf Raises',
      muscleGroups: ['Legs'],
      equipment: 'Machine',
      description: 'Calf muscle development',
      defaultSets: 4,
      defaultReps: 20,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id:  'seated_calf_raises',
      name: 'Seated Calf Raises',
      muscleGroups: ['Legs'],
      equipment: 'Machine',
      description: 'Soleus focus',
      defaultSets: 3,
      defaultReps:  20,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id:  'lying_leg_curl',
      name: 'Lying Leg Curl',
      muscleGroups: ['Legs'],
      equipment: 'Machine',
      description: 'Hamstring isolation machine',
      defaultSets: 3,
      defaultReps:  15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id: 'sissy_squat',
      name: 'Sissy Squat',
      muscleGroups: ['Legs'],
      equipment: 'Bodyweight',
      description: 'Advanced quad isolation',
      defaultSets: 3,
      defaultReps:  12,
      defaultRestSeconds: 60,
    ),

    // ==================== BICEPS EXERCISES ====================
    ExerciseTemplate(
      id:  'barbell_curl',
      name: 'Barbell Curl',
      muscleGroups: ['Biceps'],
      equipment: 'Barbell',
      description: 'Classic bicep mass builder',
      defaultSets:  3,
      defaultReps: 10,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id:  'ez_bar_curl',
      name: 'EZ Bar Curl',
      muscleGroups:  ['Biceps'],
      equipment: 'Barbell',
      description: 'Angled bar for wrist comfort',
      defaultSets: 3,
      defaultReps:  12,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id:  'dumbbell_curl',
      name: 'Dumbbell Curl',
      muscleGroups: ['Biceps'],
      equipment: 'Dumbbell',
      description: 'Alternating or simultaneous curls',
      defaultSets: 3,
      defaultReps: 12,
      defaultRestSeconds:  60,
    ),
    ExerciseTemplate(
      id: 'hammer_curl',
      name: 'Hammer Curl',
      muscleGroups: ['Biceps'],
      equipment: 'Dumbbell',
      description: 'Neutral grip bicep curl',
      defaultSets: 3,
      defaultReps: 12,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id: 'preacher_curl',
      name:  'Preacher Curl',
      muscleGroups: ['Biceps'],
      equipment:  'Barbell',
      description: 'Isolated bicep curl',
      defaultSets: 3,
      defaultReps: 12,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'concentration_curl',
      name: 'Concentration Curl',
      muscleGroups: ['Biceps'],
      equipment:  'Dumbbell',
      description: 'Single arm isolated curl',
      defaultSets:  3,
      defaultReps: 12,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id: 'cable_curl',
      name: 'Cable Curl',
      muscleGroups: ['Biceps'],
      equipment: 'Cable',
      description: 'Constant tension bicep curl',
      defaultSets: 3,
      defaultReps: 15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id:  'incline_dumbbell_curl',
      name: 'Incline Dumbbell Curl',
      muscleGroups: ['Biceps'],
      equipment:  'Dumbbell',
      description: 'Stretched position bicep curl',
      defaultSets: 3,
      defaultReps: 12,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id: 'spider_curl',
      name: 'Spider Curl',
      muscleGroups: ['Biceps'],
      equipment: 'Barbell',
      description: 'Strict bicep isolation',
      defaultSets: 3,
      defaultReps:  12,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id: 'reverse_curl',
      name: 'Reverse Curl',
      muscleGroups: ['Biceps'],
      equipment: 'Barbell',
      description: 'Overhand grip bicep curl',
      defaultSets: 3,
      defaultReps: 12,
      defaultRestSeconds: 60,
    ),

    // ==================== TRICEPS EXERCISES ====================
    ExerciseTemplate(
      id: 'close_grip_bench',
      name: 'Close Grip Bench Press',
      muscleGroups:  ['Triceps'],
      equipment: 'Barbell',
      description: 'Compound tricep mass builder',
      defaultSets:  4,
      defaultReps: 8,
      defaultRestSeconds: 120,
    ),
    ExerciseTemplate(
      id: 'tricep_dips',
      name: 'Tricep Dips',
      muscleGroups: ['Triceps'],
      equipment: 'Bodyweight',
      description: 'Bodyweight tricep exercise',
      defaultSets: 3,
      defaultReps:  12,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'rope_pushdown',
      name: 'Rope Pushdown',
      muscleGroups: ['Triceps'],
      equipment: 'Cable',
      description: 'Cable tricep isolation',
      defaultSets: 3,
      defaultReps:  15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id:  'overhead_tricep_extension',
      name: 'Overhead Tricep Extension',
      muscleGroups: ['Triceps'],
      equipment: 'Dumbbell',
      description: 'Long head tricep focus',
      defaultSets: 3,
      defaultReps:  12,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'skull_crushers',
      name:  'Skull Crushers',
      muscleGroups: ['Triceps'],
      equipment:  'Barbell',
      description: 'Lying tricep extension',
      defaultSets: 3,
      defaultReps: 12,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'tricep_kickback',
      name: 'Tricep Kickback',
      muscleGroups: ['Triceps'],
      equipment: 'Dumbbell',
      description: 'Single arm tricep isolation',
      defaultSets: 3,
      defaultReps:  15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id:  'diamond_pushups',
      name: 'Diamond Push-Ups',
      muscleGroups: ['Triceps'],
      equipment: 'Bodyweight',
      description: 'Close grip push-up variation',
      defaultSets:  3,
      defaultReps: 15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id: 'bench_dips',
      name:  'Bench Dips',
      muscleGroups: ['Triceps'],
      equipment:  'Bodyweight',
      description: 'Tricep dips on bench',
      defaultSets:  3,
      defaultReps: 15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id:  'v_bar_pushdown',
      name: 'V-Bar Pushdown',
      muscleGroups: ['Triceps'],
      equipment: 'Cable',
      description: 'Cable tricep with V attachment',
      defaultSets: 3,
      defaultReps:  15,
      defaultRestSeconds: 60,
    ),

    // ==================== CORE/ABS EXERCISES ====================
    ExerciseTemplate(
      id:  'plank',
      name: 'Plank',
      muscleGroups: ['Core'],
      equipment: 'Bodyweight',
      description: 'Isometric core hold',
      defaultSets: 3,
      defaultReps:  60,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id: 'crunches',
      name: 'Crunches',
      muscleGroups: ['Core'],
      equipment: 'Bodyweight',
      description: 'Basic ab exercise',
      defaultSets:  3,
      defaultReps: 20,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id:  'russian_twists',
      name:  'Russian Twists',
      muscleGroups: ['Core'],
      equipment: 'Bodyweight',
      description: 'Oblique rotation exercise',
      defaultSets:  3,
      defaultReps: 20,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id:  'leg_raises',
      name: 'Leg Raises',
      muscleGroups: ['Core'],
      equipment: 'Bodyweight',
      description: 'Lower ab focus',
      defaultSets: 3,
      defaultReps:  15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id:  'hanging_leg_raises',
      name: 'Hanging Leg Raises',
      muscleGroups: ['Core'],
      equipment: 'Bodyweight',
      description: 'Advanced lower ab exercise',
      defaultSets: 3,
      defaultReps:  12,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'ab_wheel',
      name: 'Ab Wheel Rollout',
      muscleGroups:  ['Core'],
      equipment: 'Other',
      description: 'Full core engagement',
      defaultSets: 3,
      defaultReps:  12,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'bicycle_crunches',
      name: 'Bicycle Crunches',
      muscleGroups: ['Core'],
      equipment: 'Bodyweight',
      description: 'Dynamic ab and oblique work',
      defaultSets: 3,
      defaultReps: 20,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id: 'mountain_climbers',
      name:  'Mountain Climbers',
      muscleGroups: ['Core'],
      equipment: 'Bodyweight',
      description: 'Dynamic core and cardio',
      defaultSets:  3,
      defaultReps: 20,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id:  'cable_crunches',
      name: 'Cable Crunches',
      muscleGroups:  ['Core'],
      equipment: 'Cable',
      description: 'Weighted ab crunches',
      defaultSets: 3,
      defaultReps: 15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id:  'side_plank',
      name: 'Side Plank',
      muscleGroups: ['Core'],
      equipment: 'Bodyweight',
      description: 'Oblique isometric hold',
      defaultSets: 3,
      defaultReps:  45,
      defaultRestSeconds: 60,
    ),

    // ==================== CARDIO EXERCISES ====================
    ExerciseTemplate(
      id:  'treadmill_run',
      name: 'Treadmill Running',
      muscleGroups:  ['Cardio'],
      equipment: 'Machine',
      description: 'Cardiovascular running',
      defaultSets: 1,
      defaultReps: 20,
      defaultRestSeconds: 0,
    ),
    ExerciseTemplate(
      id: 'cycling',
      name: 'Stationary Bike',
      muscleGroups:  ['Cardio'],
      equipment: 'Machine',
      description: 'Low impact cardio',
      defaultSets: 1,
      defaultReps: 30,
      defaultRestSeconds: 0,
    ),
    ExerciseTemplate(
      id:  'rowing_machine',
      name: 'Rowing Machine',
      muscleGroups: ['Cardio'],
      equipment: 'Machine',
      description: 'Full body cardio',
      defaultSets: 1,
      defaultReps: 15,
      defaultRestSeconds: 0,
    ),
    ExerciseTemplate(
      id:  'elliptical',
      name: 'Elliptical Trainer',
      muscleGroups: ['Cardio'],
      equipment: 'Machine',
      description: 'Low impact cardio machine',
      defaultSets: 1,
      defaultReps:  20,
      defaultRestSeconds: 0,
    ),
    ExerciseTemplate(
      id:  'jump_rope',
      name: 'Jump Rope',
      muscleGroups: ['Cardio'],
      equipment: 'Other',
      description: 'High intensity jumping',
      defaultSets: 3,
      defaultReps: 100,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id: 'burpees',
      name: 'Burpees',
      muscleGroups: ['Cardio'],
      equipment: 'Bodyweight',
      description:  'Full body explosive cardio',
      defaultSets:  3,
      defaultReps: 15,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'battle_ropes',
      name:  'Battle Ropes',
      muscleGroups: ['Cardio'],
      equipment: 'Other',
      description: 'High intensity rope waves',
      defaultSets: 3,
      defaultReps:  30,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'box_jumps',
      name:  'Box Jumps',
      muscleGroups: ['Cardio'],
      equipment: 'Other',
      description: 'Explosive lower body power',
      defaultSets: 3,
      defaultReps:  12,
      defaultRestSeconds: 90,
    ),

    // ==================== GLUTES EXERCISES ====================
    ExerciseTemplate(
      id:  'hip_thrust',
      name: 'Barbell Hip Thrust',
      muscleGroups: ['Glutes'],
      equipment: 'Barbell',
      description: 'Primary glute builder',
      defaultSets: 4,
      defaultReps: 12,
      defaultRestSeconds: 120,
    ),
    ExerciseTemplate(
      id: 'glute_bridge',
      name: 'Glute Bridge',
      muscleGroups: ['Glutes'],
      equipment: 'Bodyweight',
      description: 'Bodyweight glute activation',
      defaultSets: 3,
      defaultReps:  15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id: 'cable_kickback',
      name: 'Cable Glute Kickback',
      muscleGroups: ['Glutes'],
      equipment: 'Cable',
      description: 'Isolated glute extension',
      defaultSets: 3,
      defaultReps:  15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id: 'sumo_deadlift',
      name: 'Sumo Deadlift',
      muscleGroups: ['Glutes'],
      equipment: 'Barbell',
      description: 'Wide stance deadlift for glutes',
      defaultSets: 4,
      defaultReps: 8,
      defaultRestSeconds: 150,
    ),
    ExerciseTemplate(
      id: 'step_ups',
      name: 'Step-Ups',
      muscleGroups: ['Glutes'],
      equipment: 'Dumbbell',
      description: 'Unilateral glute exercise',
      defaultSets: 3,
      defaultReps:  12,
      defaultRestSeconds: 90,
    ),

    // ==================== FOREARMS EXERCISES ====================
    ExerciseTemplate(
      id:  'wrist_curl',
      name: 'Wrist Curl',
      muscleGroups:  ['Forearms'],
      equipment: 'Dumbbell',
      description: 'Forearm flexor development',
      defaultSets: 3,
      defaultReps:  15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id:  'reverse_wrist_curl',
      name: 'Reverse Wrist Curl',
      muscleGroups: ['Forearms'],
      equipment: 'Dumbbell',
      description: 'Forearm extensor work',
      defaultSets: 3,
      defaultReps:  15,
      defaultRestSeconds: 60,
    ),
    ExerciseTemplate(
      id: 'farmers_walk',
      name: 'Farmer\'s Walk',
      muscleGroups: ['Forearms'],
      equipment: 'Dumbbell',
      description: 'Grip strength and endurance',
      defaultSets:  3,
      defaultReps: 60,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id:  'plate_pinch',
      name: 'Plate Pinch',
      muscleGroups: ['Forearms'],
      equipment: 'Other',
      description: 'Pinch grip strength',
      defaultSets: 3,
      defaultReps: 30,
      defaultRestSeconds: 60,
    ),

    // ==================== TRAPS EXERCISES ====================
    ExerciseTemplate(
      id:  'barbell_shrug',
      name: 'Barbell Shrug',
      muscleGroups: ['Traps'],
      equipment: 'Barbell',
      description: 'Upper trap development',
      defaultSets:  3,
      defaultReps: 12,
      defaultRestSeconds:  90,
    ),
    ExerciseTemplate(
      id: 'dumbbell_shrug',
      name: 'Dumbbell Shrug',
      muscleGroups: ['Traps'],
      equipment: 'Dumbbell',
      description: 'Dumbbell trap builder',
      defaultSets: 3,
      defaultReps:  15,
      defaultRestSeconds: 90,
    ),
    ExerciseTemplate(
      id: 'trap_bar_shrug',
      name: 'Trap Bar Shrug',
      muscleGroups: ['Traps'],
      equipment: 'Barbell',
      description: 'Heavy trap shrugs',
      defaultSets: 3,
      defaultReps:  10,
      defaultRestSeconds: 120,
    ),
  ];

  // NEW:  Custom exercises storage
  static final List<ExerciseTemplate> _customExercises = [];

  // NEW: Get all exercises (built-in + custom)
  static List<ExerciseTemplate> getAllExercises() {
    return [...exercises, ..._customExercises];
  }

  // NEW: Get only custom exercises
  static List<ExerciseTemplate> getCustomExercises() {
    return List.from(_customExercises);
  }

  // NEW: Check if exercise is custom
  static bool isCustomExercise(String exerciseId) {
    return exerciseId.startsWith('custom_');
  }

  // NEW: Add custom exercise
  static void addCustomExercise(ExerciseTemplate exercise) {
    _customExercises.removeWhere((e) => e.id == exercise.id);
    _customExercises.add(exercise);
    _saveCustomExercises();
  }

  // NEW: Delete custom exercise
  static void deleteCustomExercise(String exerciseId) {
    _customExercises.removeWhere((e) => e.id == exerciseId);
    _saveCustomExercises();
  }

  // NEW: Load custom exercises from storage
  static void loadCustomExercises() {
    final customData = LocalStorageService.getSetting('customExercises', defaultValue: []);
    
    if (customData is List) {
      _customExercises.clear();
      for (var data in customData) {
        if (data is Map) {
          try {
            _customExercises.add(ExerciseTemplate(
              id: data['id']?. toString() ?? '',
              name: data['name']?.toString() ?? '',
              muscleGroups: data['muscleGroups'] is List 
                  ? List<String>.from(data['muscleGroups'])
                  : [],
              equipment: data['equipment']?.toString() ?? 'Other',
              description: data['description']?.toString() ?? '',
              defaultSets: data['defaultSets'] as int? ?? 3,
              defaultReps: data['defaultReps'] as int? ?? 10,
              defaultRestSeconds: data['defaultRestSeconds'] as int?  ?? 90,
            ));
          } catch (e) {
            debugPrint('❌ Error loading custom exercise: $e');
          }
        }
      }
      debugPrint('✅ Loaded ${_customExercises. length} custom exercises');
    }
  }

  // NEW:  Save custom exercises to storage
  static void _saveCustomExercises() {
    final customData = _customExercises.map((e) => {
      'id': e.id,
      'name': e.name,
      'muscleGroups': e.muscleGroups,
      'equipment': e.equipment,
      'description': e.description,
      'defaultSets': e.defaultSets,
      'defaultReps': e.defaultReps,
      'defaultRestSeconds': e.defaultRestSeconds,
    }).toList();
    
    LocalStorageService.saveSetting('customExercises', customData);
    debugPrint('💾 Saved ${_customExercises.length} custom exercises');
  }

  // Get all unique muscle groups
  static List<String> getAllMuscleGroups() {
    final groups = <String>{};
    for (var exercise in getAllExercises()) {
      groups.addAll(exercise.muscleGroups);
    }
    return groups.toList()..sort();
  }

  // Get exercises by muscle group
  static List<ExerciseTemplate> getExercisesByMuscleGroup(String muscleGroup) {
    return getAllExercises()
        .where((ex) => ex.muscleGroups.contains(muscleGroup))
        .toList();
  }

  // Get exercises by equipment
  static List<ExerciseTemplate> getExercisesByEquipment(String equipment) {
    return getAllExercises().where((ex) => ex.equipment == equipment).toList();
  }

  // Search exercises
  static List<ExerciseTemplate> searchExercises(String query) {
    final lowerQuery = query.toLowerCase();
    return getAllExercises()
        .where((ex) =>
            ex.name.toLowerCase().contains(lowerQuery) ||
            ex.muscleGroups.any((mg) => mg.toLowerCase().contains(lowerQuery)) ||
            ex.description.toLowerCase().contains(lowerQuery))
        .toList();
  }

  // Get all equipment types
  static List<String> getAllEquipmentTypes() {
    final equipment = <String>{};
    for (var exercise in getAllExercises()) {
      equipment.add(exercise.equipment);
    }
    return equipment.toList()..sort();
  }
}