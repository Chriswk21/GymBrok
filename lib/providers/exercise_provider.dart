import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';

class ExerciseProvider extends ChangeNotifier {
  late Box _exercisesBox;
  List<Exercise> _exercises = [];
  bool _isLoading = true;

  List<Exercise> get exercises => _exercises;
  bool get isLoading => _isLoading;

  ExerciseProvider() {
    _init();
  }

  Future<void> _init() async {
    _exercisesBox = await Hive.openBox('exercises_box');
    
    // Seed if empty
    if (_exercisesBox.isEmpty) {
      await _seedInitialData();
    } else {
      _loadExercises();
      await _ensureInclineMachineChestPressExists();
      await _migrateCategoriesAndAddExercises();
    }
  }

  Future<void> _ensureInclineMachineChestPressExists() async {
    final exists = _exercises.any((e) => e.name == 'Incline Machine Chest Press');
    if (!exists) {
      final id = const Uuid().v4();
      final exercise = Exercise(
        id: id,
        name: 'Incline Machine Chest Press',
        category: 'Chest',
        isFavorite: false,
        isCustom: false,
        hasUnilateralWeights: true,
      );
      await _exercisesBox.put(id, exercise.toJson());
      _exercises.add(exercise);
      _sortExercises();
      notifyListeners();
    }
  }

  Future<void> _migrateCategoriesAndAddExercises() async {
    bool updated = false;

    // 1. Map old 'Arms' exercises to 'Bicep' or 'Tricep'
    final bicepExercises = [
      'EZ Bar Curl',
      'Hammer Curl',
      'Incline Dumbbell Curl',
      'Preacher Curl'
    ];
    final tricepExercises = [
      'Tricep Pushdown',
      'Skull Crusher',
      'Overhead Tricep Extension',
      'Close Grip Bench Press'
    ];

    for (int i = 0; i < _exercises.length; i++) {
      final exercise = _exercises[i];
      if (exercise.category == 'Arms') {
        String newCat = 'Bicep';
        if (tricepExercises.contains(exercise.name)) {
          newCat = 'Tricep';
        } else if (bicepExercises.contains(exercise.name)) {
          newCat = 'Bicep';
        }
        
        final updatedExercise = exercise.copyWith(category: newCat);
        await _exercisesBox.put(exercise.id, updatedExercise.toJson());
        _exercises[i] = updatedExercise;
        updated = true;
      }
    }

    // 2. Ensure new exercises exist (including the latest legs/back/core additions)
    final List<Map<String, dynamic>> newExercisesToSeed = [
      {
        'name': 'Single Arm Tricep Extension (Cable)',
        'category': 'Tricep',
        'hasUnilateralWeights': true,
      },
      {
        'name': 'Bayesian Curl',
        'category': 'Bicep',
        'hasUnilateralWeights': false,
      },
      {
        'name': 'Shoulder Press (Dumbbell)',
        'category': 'Shoulders',
        'hasUnilateralWeights': false,
      },
      {
        'name': 'Rear Delt Cable Fly (Single Arm)',
        'category': 'Shoulders',
        'hasUnilateralWeights': true,
      },
      {
        'name': 'Hamstring Curl',
        'category': 'Legs',
        'hasUnilateralWeights': false,
      },
      {
        'name': 'Leg Press Machine',
        'category': 'Legs',
        'hasUnilateralWeights': false,
      },
      {
        'name': 'Lat Pulldown Machine (Unilateral)',
        'category': 'Back',
        'hasUnilateralWeights': true,
      },
      {
        'name': 'Rotary Torso Machine',
        'category': 'Core',
        'hasUnilateralWeights': true,
      },
      {
        'name': 'Ab Crunch Machine',
        'category': 'Core',
        'hasUnilateralWeights': false,
      },
      {
        'name': 'Cable Woodchop',
        'category': 'Core',
        'hasUnilateralWeights': true,
      },
      {
        'name': 'Weighted Decline Crunch',
        'category': 'Core',
        'hasUnilateralWeights': false,
      },
      {
        'name': 'Russian Twist (Weighted)',
        'category': 'Core',
        'hasUnilateralWeights': false,
      },
      {
        'name': 'Hanging Knee Raise',
        'category': 'Core',
        'hasUnilateralWeights': false,
      },
      {
        'name': 'Toes to Bar',
        'category': 'Core',
        'hasUnilateralWeights': false,
      },
      {
        'name': 'Plank',
        'category': 'Core',
        'hasUnilateralWeights': false,
      },
      {
        'name': 'Side Plank',
        'category': 'Core',
        'hasUnilateralWeights': true,
      },
      {
        'name': 'Chest Supported Row (Upper Back)',
        'category': 'Back',
        'hasUnilateralWeights': false,
      },
      {
        'name': 'Chest Supported Row (Wide Grip)',
        'category': 'Back',
        'hasUnilateralWeights': false,
      },
      {
        'name': 'Cable Lateral Raise (Unilateral)',
        'category': 'Shoulders',
        'hasUnilateralWeights': true,
      },
      {
        'name': 'Chin Ups',
        'category': 'Calisthenics',
        'hasUnilateralWeights': false,
      },
      {
        'name': 'Push Ups (Bodyweight)',
        'category': 'Calisthenics',
        'hasUnilateralWeights': false,
      },
      {
        'name': 'Dips (Bodyweight)',
        'category': 'Calisthenics',
        'hasUnilateralWeights': false,
      },
      {
        'name': 'Muscle Ups',
        'category': 'Calisthenics',
        'hasUnilateralWeights': false,
      },
      {
        'name': 'Handstand Push Ups',
        'category': 'Calisthenics',
        'hasUnilateralWeights': false,
      },
      {
        'name': 'Pistol Squats',
        'category': 'Calisthenics',
        'hasUnilateralWeights': true,
      },
      {
        'name': 'L-Sit',
        'category': 'Calisthenics',
        'hasUnilateralWeights': false,
      },
    ];

    for (var raw in newExercisesToSeed) {
      final String name = raw['name'] as String;
      final exists = _exercises.any((e) => e.name == name);
      if (!exists) {
        final id = const Uuid().v4();
        final exercise = Exercise(
          id: id,
          name: name,
          category: raw['category'] as String,
          isFavorite: false,
          isCustom: false,
          hasUnilateralWeights: raw['hasUnilateralWeights'] as bool,
        );
        await _exercisesBox.put(id, exercise.toJson());
        _exercises.add(exercise);
        updated = true;
      }
    }

    // 3. Move existing calisthenics exercises to 'Calisthenics' category
    final calisthenicsToMigrate = [
      'Pull Ups',
      'Chest Dips',
      'Weighted Push Ups',
      'Plank',
      'Side Plank',
      'Hanging Leg Raise',
      'Hanging Knee Raise',
      'Toes to Bar'
    ];

    for (int i = 0; i < _exercises.length; i++) {
      final exercise = _exercises[i];
      if (calisthenicsToMigrate.contains(exercise.name) && exercise.category != 'Calisthenics') {
        final updatedExercise = exercise.copyWith(category: 'Calisthenics');
        await _exercisesBox.put(exercise.id, updatedExercise.toJson());
        _exercises[i] = updatedExercise;
        updated = true;
      }
    }

    if (updated) {
      _sortExercises();
      notifyListeners();
    }
  }

  void _loadExercises() {
    _exercises = _exercisesBox.values
        .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    
    // Sort: favorites first, then alphabetically by name
    _sortExercises();
    _isLoading = false;
    notifyListeners();
  }

  void reloadExercises() {
    _loadExercises();
  }

  void _sortExercises() {
    _exercises.sort((a, b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return a.name.compareTo(b.name);
    });
  }

  Future<void> _seedInitialData() async {
    final seedData = {
      'Chest': [
        'Barbell Bench Press',
        'Incline Barbell Press',
        'Dumbbell Press (Flat/Incline)',
        'Machine Chest Press',
        'Incline Machine Chest Press',
        'Cable Fly',
        'Pec Deck'
      ],
      'Back': [
        'Deadlift',
        'Barbell Row',
        'Dumbbell Row',
        'Lat Pulldown',
        'Seated Cable Row',
        'T-Bar Row',
        'Face Pulls',
        'Hyperextensions',
        'Lat Pulldown Machine (Unilateral)',
        'Chest Supported Row (Upper Back)',
        'Chest Supported Row (Wide Grip)'
      ],
      'Legs': [
        'Barbell Squat',
        'Leg Press',
        'Hack Squat',
        'Bulgarian Split Squat',
        'Leg Extension',
        'Lying Leg Curl',
        'Romanian Deadlift',
        'Calf Raise',
        'Walking Lunges',
        'Hamstring Curl',
        'Leg Press Machine'
      ],
      'Shoulders': [
        'Overhead Press',
        'Arnold Press',
        'Lateral Raise (Dumbbell/Cable)',
        'Front Raise',
        'Reverse Fly',
        'Upright Row',
        'Shoulder Press (Dumbbell)',
        'Rear Delt Cable Fly (Single Arm)',
        'Cable Lateral Raise (Unilateral)'
      ],
      'Bicep': [
        'EZ Bar Curl',
        'Hammer Curl',
        'Incline Dumbbell Curl',
        'Preacher Curl',
        'Bayesian Curl'
      ],
      'Tricep': [
        'Tricep Pushdown',
        'Skull Crusher',
        'Overhead Tricep Extension',
        'Close Grip Bench Press',
        'Single Arm Tricep Extension (Cable)'
      ],
      'Core': [
        'Weighted Plank',
        'Cable Crunch',
        'Ab Wheel Rollout',
        'Rotary Torso Machine',
        'Ab Crunch Machine',
        'Cable Woodchop',
        'Weighted Decline Crunch',
        'Russian Twist (Weighted)'
      ],
      'Calisthenics': [
        'Pull Ups',
        'Chin Ups',
        'Push Ups (Bodyweight)',
        'Weighted Push Ups',
        'Dips (Bodyweight)',
        'Chest Dips',
        'Muscle Ups',
        'Handstand Push Ups',
        'Pistol Squats',
        'L-Sit',
        'Plank',
        'Side Plank',
        'Hanging Leg Raise',
        'Hanging Knee Raise',
        'Toes to Bar'
      ]
    };

    final uuid = const Uuid();
    for (var entry in seedData.entries) {
      final category = entry.key;
      for (var name in entry.value) {
        final id = uuid.v4();
        final isUnilateral = name == 'Incline Machine Chest Press' ||
            name == 'Single Arm Tricep Extension (Cable)' ||
            name == 'Rear Delt Cable Fly (Single Arm)' ||
            name == 'Lat Pulldown Machine (Unilateral)' ||
            name == 'Rotary Torso Machine' ||
            name == 'Cable Woodchop' ||
            name == 'Side Plank' ||
            name == 'Pistol Squats' ||
            name == 'Cable Lateral Raise (Unilateral)';
        
        final exercise = Exercise(
          id: id,
          name: name,
          category: category,
          isFavorite: false,
          isCustom: false,
          hasUnilateralWeights: isUnilateral,
        );
        await _exercisesBox.put(id, exercise.toJson());
      }
    }
    _loadExercises();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _exercises.indexWhere((e) => e.id == id);
    if (index != -1) {
      final updated = _exercises[index].copyWith(
        isFavorite: !_exercises[index].isFavorite,
      );
      await _exercisesBox.put(id, updated.toJson());
      _exercises[index] = updated;
      _sortExercises();
      notifyListeners();
    }
  }

  Future<Exercise?> addCustomExercise(String name, String category, {bool hasUnilateralWeights = false}) async {
    if (name.trim().isEmpty) return null;
    
    final id = const Uuid().v4();
    final exercise = Exercise(
      id: id,
      name: name.trim(),
      category: category,
      isFavorite: false,
      isCustom: true,
      hasUnilateralWeights: hasUnilateralWeights,
    );
    
    await _exercisesBox.put(id, exercise.toJson());
    _exercises.add(exercise);
    _sortExercises();
    notifyListeners();
    return exercise;
  }

  List<Exercise> getExercisesByCategory(String category) {
    if (category == 'All') return _exercises;
    return _exercises.where((e) => e.category == category).toList();
  }

  List<Exercise> searchExercises(String query, {String category = 'All'}) {
    final baseList = getExercisesByCategory(category);
    if (query.trim().isEmpty) return baseList;
    
    final lowercaseQuery = query.toLowerCase();
    return baseList
        .where((e) => e.name.toLowerCase().contains(lowercaseQuery))
        .toList();
  }
}
