import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/workout_session.dart';
import '../models/exercise_log.dart';
import '../models/workout_set.dart';
import '../models/exercise.dart';
import '../models/workout_template.dart';
import '../models/body_weight_log.dart';
import 'exercise_provider.dart';

class WorkoutProvider extends ChangeNotifier {
  late Box _workoutsBox;
  late Box _templatesBox;
  late Box _weightBox;
  late Box _caloriesBox;
  late Box _activeSessionBox;
  
  List<WorkoutSession> _history = [];
  List<WorkoutTemplate> _templates = [];
  List<BodyWeightLog> _weightHistory = [];
  Map<String, double> _calorieLogs = {};
  double _calorieTarget = 2000.0;
  bool _isLoading = true;

  // Active workout state
  WorkoutSession? _activeSession;
  bool get hasActiveSession => _activeSession != null;
  WorkoutSession? get activeSession => _activeSession;

  // Rest Timer State
  Timer? _restTimer;
  int _timerDuration = 90; // Default 90 seconds rest
  int _timerSecondsLeft = 0;
  bool _isTimerActive = false;
  String _timerExerciseName = '';

  List<WorkoutSession> get history => _history;
  List<WorkoutTemplate> get templates => _templates;
  bool get isLoading => _isLoading;

  int get timerDuration => _timerDuration;
  int get timerSecondsLeft => _timerSecondsLeft;
  bool get isTimerActive => _isTimerActive;
  String get timerExerciseName => _timerExerciseName;

  WorkoutProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      _workoutsBox = await Hive.openBox('workouts_box');
      _loadHistory();
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error loading workouts history: $e\n$stack');
      }
    }

    try {
      _templatesBox = await Hive.openBox('templates_box');
      _loadTemplates();
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error loading templates: $e\n$stack');
      }
    }

    try {
      _weightBox = await Hive.openBox('weight_box');
      _loadWeightHistory();
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error loading weight history: $e\n$stack');
      }
    }

    try {
      _caloriesBox = await Hive.openBox('calories_box');
      _loadCalorieData();
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error loading calorie data: $e\n$stack');
      }
    }

    try {
      _activeSessionBox = await Hive.openBox('active_session_box');
      _loadActiveSession();
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error loading active session: $e\n$stack');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void _loadHistory() {
    _history = _workoutsBox.values
        .map((w) => WorkoutSession.fromJson(Map<String, dynamic>.from(w as Map)))
        .toList();
    // Sort history by date descending
    _history.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void _loadTemplates() {
    _templates = _templatesBox.values
        .map((t) => WorkoutTemplate.fromJson(Map<String, dynamic>.from(t as Map)))
        .toList();
    notifyListeners();
  }

  void _loadWeightHistory() {
    _weightHistory = _weightBox.values
        .map((w) => BodyWeightLog.fromJson(Map<String, dynamic>.from(w as Map)))
        .toList();
    // Sort by date descending (newest first)
    _weightHistory.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void _loadCalorieData() {
    _calorieTarget = (_caloriesBox.get('target_calories', defaultValue: 2000.0) as num).toDouble();
    _calorieLogs = {};
    for (var key in _caloriesBox.keys) {
      if (key != 'target_calories') {
        _calorieLogs[key.toString()] = (_caloriesBox.get(key) as num).toDouble();
      }
    }
    notifyListeners();
  }

  void _loadActiveSession() {
    final raw = _activeSessionBox.get('active_session');
    if (raw != null) {
      try {
        _activeSession = WorkoutSession.fromJson(Map<String, dynamic>.from(raw as Map));
      } catch (e, stack) {
        if (kDebugMode) {
          print('Error loading active session details: $e\n$stack');
        }
      }
    }
  }

  Future<void> _saveActiveSessionToDisk() async {
    if (_activeSession != null) {
      await _activeSessionBox.put('active_session', _activeSession!.toJson());
    } else {
      await _activeSessionBox.delete('active_session');
    }
  }

  // Weight Log Management
  List<BodyWeightLog> get weightHistory => _weightHistory;

  Future<void> addWeightLog(double weight) async {
    final id = const Uuid().v4();
    final log = BodyWeightLog(
      id: id,
      date: DateTime.now(),
      weight: weight,
    );
    await _weightBox.put(id, log.toJson());
    _weightHistory.insert(0, log);
    notifyListeners();
  }

  Future<void> deleteWeightLog(String id) async {
    await _weightBox.delete(id);
    _weightHistory.removeWhere((log) => log.id == id);
    notifyListeners();
  }

  // Calorie Tracker Management
  Map<String, double> get calorieLogs => _calorieLogs;
  double get calorieTarget => _calorieTarget;
  double get todayCalories => _calorieLogs[_formatDateKey(DateTime.now())] ?? 0.0;

  Future<void> updateTodayCalories(double amount) async {
    final dateKey = _formatDateKey(DateTime.now());
    await _caloriesBox.put(dateKey, amount);
    _calorieLogs[dateKey] = amount;
    notifyListeners();
  }

  Future<void> addTodayCalories(double amount) async {
    final dateKey = _formatDateKey(DateTime.now());
    final current = _calorieLogs[dateKey] ?? 0.0;
    final updated = current + amount;
    await _caloriesBox.put(dateKey, updated);
    _calorieLogs[dateKey] = updated;
    notifyListeners();
  }

  Future<void> setCalorieTarget(double target) async {
    _calorieTarget = target;
    await _caloriesBox.put('target_calories', target);
    notifyListeners();
  }

  // Backup & Restore JSON
  Future<String> exportBackupJson(List<Exercise> exercises) async {
    final Map<String, dynamic> backup = {
      'workouts': _history.map((w) => w.toJson()).toList(),
      'templates': _templates.map((t) => t.toJson()).toList(),
      'weight_history': _weightHistory.map((w) => w.toJson()).toList(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'calories': _calorieLogs,
      'calorie_target': _calorieTarget,
      'rest_timer_duration': _timerDuration,
    };
    return jsonEncode(backup);
  }

  Future<bool> importBackupJson(String jsonStr, ExerciseProvider exerciseProvider) async {
    try {
      final Map<String, dynamic> backup = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (!backup.containsKey('workouts') && !backup.containsKey('templates') && !backup.containsKey('exercises')) {
        return false;
      }

      await _workoutsBox.clear();
      await _templatesBox.clear();
      await _weightBox.clear();
      await _caloriesBox.clear();
      await _activeSessionBox.clear();
      _activeSession = null;
      
      final exercisesBox = Hive.box('exercises_box');
      await exercisesBox.clear();

      if (backup.containsKey('exercises')) {
        final List<dynamic> exList = backup['exercises'] as List<dynamic>;
        for (var item in exList) {
          final exerciseMap = Map<String, dynamic>.from(item as Map);
          final exercise = Exercise.fromJson(exerciseMap);
          await exercisesBox.put(exercise.id, exercise.toJson());
        }
      }

      if (backup.containsKey('workouts')) {
        final List<dynamic> wList = backup['workouts'] as List<dynamic>;
        for (var item in wList) {
          final wMap = Map<String, dynamic>.from(item as Map);
          final workout = WorkoutSession.fromJson(wMap);
          await _workoutsBox.put(workout.id, workout.toJson());
        }
      }

      if (backup.containsKey('templates')) {
        final List<dynamic> tList = backup['templates'] as List<dynamic>;
        for (var item in tList) {
          final tMap = Map<String, dynamic>.from(item as Map);
          final template = WorkoutTemplate.fromJson(tMap);
          await _templatesBox.put(template.id, template.toJson());
        }
      }

      if (backup.containsKey('weight_history')) {
        final List<dynamic> whList = backup['weight_history'] as List<dynamic>;
        for (var item in whList) {
          final whMap = Map<String, dynamic>.from(item as Map);
          final weightLog = BodyWeightLog.fromJson(whMap);
          await _weightBox.put(weightLog.id, weightLog.toJson());
        }
      }

      if (backup.containsKey('calories')) {
        final Map<String, dynamic> cMap = backup['calories'] as Map<String, dynamic>;
        cMap.forEach((key, val) {
          _caloriesBox.put(key, (val as num).toDouble());
        });
      }
      if (backup.containsKey('calorie_target')) {
        _calorieTarget = (backup['calorie_target'] as num).toDouble();
        await _caloriesBox.put('target_calories', _calorieTarget);
      }

      if (backup.containsKey('rest_timer_duration')) {
        _timerDuration = backup['rest_timer_duration'] as int;
      }

      _loadHistory();
      _loadTemplates();
      _loadWeightHistory();
      _loadCalorieData();
      
      exerciseProvider.reloadExercises();

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error during restore: $e');
      }
      return false;
    }
  }

  // Set default rest duration
  void setRestDuration(int seconds) {
    _timerDuration = seconds;
    notifyListeners();
  }

  // Start a new empty workout
  void startWorkout() {
    if (_activeSession != null) return; // Workout already in progress

    _activeSession = WorkoutSession(
      id: const Uuid().v4(),
      date: DateTime.now(),
      exerciseLogs: [],
    );
    _saveActiveSessionToDisk();
    notifyListeners();
  }

  // Helper to get the last log of a specific exercise
  ExerciseLog? getLastLogForExercise(String exerciseId) {
    for (var session in _history) {
      for (var log in session.exerciseLogs) {
        if (log.exerciseId == exerciseId) {
          return log;
        }
      }
    }
    return null;
  }

  // Start a workout pre-populated with exercises from a template
  void startWorkoutFromTemplate(WorkoutTemplate template) {
    if (_activeSession != null) return; // Workout already in progress

    final List<ExerciseLog> logs = template.exercises.map((te) {
      final lastLog = getLastLogForExercise(te.exerciseId);
      final List<WorkoutSet> sets;
      
      if (lastLog != null && lastLog.sets.isNotEmpty) {
        sets = lastLog.sets.map((set) => WorkoutSet(
          weight: set.weight,
          reps: set.reps,
          isDone: false,
          weightLeft: set.weightLeft,
          weightRight: set.weightRight,
        )).toList();
      } else {
        sets = [
          WorkoutSet(weight: 0.0, reps: 0, isDone: false),
        ];
      }

      return ExerciseLog(
        exerciseId: te.exerciseId,
        exerciseName: te.name,
        category: te.category,
        sets: sets,
      );
    }).toList();

    _activeSession = WorkoutSession(
      id: const Uuid().v4(),
      date: DateTime.now(),
      exerciseLogs: logs,
    );
    _saveActiveSessionToDisk();
    notifyListeners();
  }

  // Save active workout exercises as a template
  Future<void> saveActiveWorkoutAsTemplate(String templateName) async {
    if (_activeSession == null || _activeSession!.exerciseLogs.isEmpty) return;

    final id = const Uuid().v4();
    final List<TemplateExercise> exercises = _activeSession!.exerciseLogs.map((log) {
      return TemplateExercise(
        exerciseId: log.exerciseId,
        name: log.exerciseName,
        category: log.category,
      );
    }).toList();

    final template = WorkoutTemplate(
      id: id,
      name: templateName.trim(),
      exercises: exercises,
    );

    await _templatesBox.put(id, template.toJson());
    _templates.add(template);
    notifyListeners();
  }

  // Create template manually
  Future<void> createTemplate(String name, List<Exercise> selectedExercises) async {
    if (name.trim().isEmpty || selectedExercises.isEmpty) return;

    final id = const Uuid().v4();
    final List<TemplateExercise> exercises = selectedExercises.map((e) {
      return TemplateExercise(
        exerciseId: e.id,
        name: e.name,
        category: e.category,
      );
    }).toList();

    final template = WorkoutTemplate(
      id: id,
      name: name.trim(),
      exercises: exercises,
    );

    await _templatesBox.put(id, template.toJson());
    _templates.add(template);
    notifyListeners();
  }

  // Delete a template
  Future<void> deleteTemplate(String templateId) async {
    await _templatesBox.delete(templateId);
    _templates.removeWhere((t) => t.id == templateId);
    notifyListeners();
  }

  // Add exercise to active workout
  void addExerciseToActiveWorkout(Exercise exercise) {
    if (_activeSession == null) return;

    // Avoid adding the same exercise twice
    final exists = _activeSession!.exerciseLogs.any((log) => log.exerciseId == exercise.id);
    if (exists) return;

    final lastLog = getLastLogForExercise(exercise.id);
    final List<WorkoutSet> defaultSets;
    
    if (lastLog != null && lastLog.sets.isNotEmpty) {
      defaultSets = lastLog.sets.map((set) => WorkoutSet(
        weight: set.weight,
        reps: set.reps,
        isDone: false,
        weightLeft: set.weightLeft,
        weightRight: set.weightRight,
      )).toList();
    } else {
      defaultSets = [
        WorkoutSet(weight: 0.0, reps: 0, isDone: false),
      ];
    }

    final newLog = ExerciseLog(
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      category: exercise.category,
      sets: defaultSets,
    );

    final updatedLogs = List<ExerciseLog>.from(_activeSession!.exerciseLogs)..add(newLog);
    _activeSession = _activeSession!.copyWith(exerciseLogs: updatedLogs);
    _saveActiveSessionToDisk();
    notifyListeners();
  }

  // Remove exercise from active workout
  void removeExerciseFromActiveWorkout(String exerciseId) {
    if (_activeSession == null) return;

    final updatedLogs = _activeSession!.exerciseLogs.where((log) => log.exerciseId != exerciseId).toList();
    _activeSession = _activeSession!.copyWith(exerciseLogs: updatedLogs);
    _saveActiveSessionToDisk();
    notifyListeners();
  }

  // Add set to exercise in active workout
  void addSetToExercise(String exerciseId) {
    if (_activeSession == null) return;

    final logIndex = _activeSession!.exerciseLogs.indexWhere((log) => log.exerciseId == exerciseId);
    if (logIndex == -1) return;

    final exerciseLog = _activeSession!.exerciseLogs[logIndex];
    
    // Autofill with last set values if they exist, otherwise 0
    double defaultWeight = 0.0;
    int defaultReps = 0;
    double? defaultLeft;
    double? defaultRight;
    if (exerciseLog.sets.isNotEmpty) {
      final lastSet = exerciseLog.sets.last;
      defaultWeight = lastSet.weight;
      defaultReps = lastSet.reps;
      defaultLeft = lastSet.weightLeft;
      defaultRight = lastSet.weightRight;
    }

    final newSet = WorkoutSet(
      weight: defaultWeight,
      reps: defaultReps,
      isDone: false,
      weightLeft: defaultLeft,
      weightRight: defaultRight,
    );
    final updatedSets = List<WorkoutSet>.from(exerciseLog.sets)..add(newSet);
    
    final updatedLogs = List<ExerciseLog>.from(_activeSession!.exerciseLogs);
    updatedLogs[logIndex] = exerciseLog.copyWith(sets: updatedSets);
    
    _activeSession = _activeSession!.copyWith(exerciseLogs: updatedLogs);
    _saveActiveSessionToDisk();
    notifyListeners();
  }

  // Remove set from exercise in active workout
  void removeSetFromExercise(String exerciseId, int setIndex) {
    if (_activeSession == null) return;

    final logIndex = _activeSession!.exerciseLogs.indexWhere((log) => log.exerciseId == exerciseId);
    if (logIndex == -1) return;

    final exerciseLog = _activeSession!.exerciseLogs[logIndex];
    if (exerciseLog.sets.length <= setIndex) return;

    final updatedSets = List<WorkoutSet>.from(exerciseLog.sets)..removeAt(setIndex);
    
    final updatedLogs = List<ExerciseLog>.from(_activeSession!.exerciseLogs);
    updatedLogs[logIndex] = exerciseLog.copyWith(sets: updatedSets);
    
    _activeSession = _activeSession!.copyWith(exerciseLogs: updatedLogs);
    _saveActiveSessionToDisk();
    notifyListeners();
  }

  // Update set details
  void updateSet(
    String exerciseId,
    int setIndex, {
    double? weight,
    int? reps,
    bool? isDone,
    double? weightLeft,
    double? weightRight,
  }) {
    if (_activeSession == null) return;

    final logIndex = _activeSession!.exerciseLogs.indexWhere((log) => log.exerciseId == exerciseId);
    if (logIndex == -1) return;

    final exerciseLog = _activeSession!.exerciseLogs[logIndex];
    if (exerciseLog.sets.length <= setIndex) return;

    final currentSet = exerciseLog.sets[setIndex];
    final wasDone = currentSet.isDone;

    final updatedSet = currentSet.copyWith(
      weight: weight,
      reps: reps,
      isDone: isDone,
      weightLeft: weightLeft,
      weightRight: weightRight,
    );

    final updatedSets = List<WorkoutSet>.from(exerciseLog.sets);
    updatedSets[setIndex] = updatedSet;

    final updatedLogs = List<ExerciseLog>.from(_activeSession!.exerciseLogs);
    updatedLogs[logIndex] = exerciseLog.copyWith(sets: updatedSets);

    _activeSession = _activeSession!.copyWith(exerciseLogs: updatedLogs);

    // If set is marked done and wasn't before, trigger rest timer
    if (isDone == true && !wasDone) {
      _startRestTimer(exerciseLog.exerciseName);
    }

    _saveActiveSessionToDisk();
    notifyListeners();
  }

  // Save active workout session to history
  Future<void> finishActiveWorkout() async {
    if (_activeSession == null) return;

    // Filter out exercises with no completed sets
    final savedLogs = _activeSession!.exerciseLogs.map((log) {
      final doneSets = log.sets.where((s) => s.isDone).toList();
      return log.copyWith(sets: doneSets);
    }).where((log) => log.sets.isNotEmpty).toList();

    if (savedLogs.isNotEmpty) {
      final savedSession = _activeSession!.copyWith(
        exerciseLogs: savedLogs,
        date: DateTime.now(), // update date to exact save time
      );

      await _workoutsBox.put(savedSession.id, savedSession.toJson());
      _history.insert(0, savedSession);
    }

    _activeSession = null;
    await _saveActiveSessionToDisk();
    _stopRestTimer();
    notifyListeners();
  }

  // Cancel and discard active workout session
  void cancelActiveWorkout() async {
    _activeSession = null;
    await _saveActiveSessionToDisk();
    _stopRestTimer();
    notifyListeners();
  }

  // Delete a completed workout session from history
  Future<void> deleteWorkoutFromHistory(String sessionId) async {
    await _workoutsBox.delete(sessionId);
    _history.removeWhere((session) => session.id == sessionId);
    notifyListeners();
  }

  // Update an existing completed workout session in history
  Future<void> updateWorkoutInHistory(WorkoutSession updatedSession) async {
    await _workoutsBox.put(updatedSession.id, updatedSession.toJson());
    final index = _history.indexWhere((s) => s.id == updatedSession.id);
    if (index != -1) {
      _history[index] = updatedSession;
      notifyListeners();
    }
  }

  // Timer Management
  void _startRestTimer(String exerciseName) {
    _restTimer?.cancel();
    _timerExerciseName = exerciseName;
    _timerSecondsLeft = _timerDuration;
    _isTimerActive = true;
    notifyListeners();

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSecondsLeft > 1) {
        _timerSecondsLeft--;
        notifyListeners();
      } else {
        _stopRestTimer();
      }
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    _isTimerActive = false;
    _timerSecondsLeft = 0;
    _timerExerciseName = '';
    notifyListeners();
  }

  void addTimeToTimer(int seconds) {
    if (!_isTimerActive) return;
    _timerSecondsLeft += seconds;
    notifyListeners();
  }

  void skipTimer() {
    _stopRestTimer();
  }

  // Analytics Helpers

  // Get set logs of a specific exercise sorted by date ascending
  List<MapEntry<DateTime, ExerciseLog>> getExerciseHistory(String exerciseId) {
    final List<MapEntry<DateTime, ExerciseLog>> result = [];
    for (var session in _history) {
      for (var log in session.exerciseLogs) {
        if (log.exerciseId == exerciseId) {
          result.add(MapEntry(session.date, log));
        }
      }
    }
    // Sort ascending by date for charts
    result.sort((a, b) => a.key.compareTo(b.key));
    return result;
  }

  // Map of date strings (yyyy-MM-dd) to list of workouts completed on that day (for calendar)
  Map<String, List<WorkoutSession>> get workoutsByDate {
    final Map<String, List<WorkoutSession>> map = {};
    for (var session in _history) {
      final dateKey = _formatDateKey(session.date);
      if (!map.containsKey(dateKey)) {
        map[dateKey] = [];
      }
      map[dateKey]!.add(session);
    }
    return map;
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }
}
