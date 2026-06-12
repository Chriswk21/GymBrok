import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:gymbrok/providers/workout_provider.dart';
import 'package:gymbrok/providers/exercise_provider.dart';
import 'package:gymbrok/models/exercise.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('gymbrok_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('WorkoutProvider history prefilling test', () async {
    final provider = WorkoutProvider();
    
    // Wait for Hive to initialize and provider to load
    while (provider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 10));
    }

    // 1. Start empty workout
    provider.startWorkout();
    expect(provider.hasActiveSession, true);
    expect(provider.activeSession!.exerciseLogs, isEmpty);

    // Create a dummy exercise
    final benchPress = Exercise(
      id: 'bench_press_id',
      name: 'Barbell Bench Press',
      category: 'Chest',
    );

    // 2. Add Bench Press to active workout
    provider.addExerciseToActiveWorkout(benchPress);
    expect(provider.activeSession!.exerciseLogs, hasLength(1));
    
    final log = provider.activeSession!.exerciseLogs.first;
    expect(log.exerciseId, 'bench_press_id');
    expect(log.sets, hasLength(1));
    expect(log.sets.first.weight, 0.0);
    expect(log.sets.first.reps, 0);

    // 3. Update the set to 90 kg and 8 reps, and mark as done
    provider.updateSet(
      'bench_press_id',
      0,
      weight: 90.0,
      reps: 8,
      isDone: true,
    );

    // Verify update
    expect(provider.activeSession!.exerciseLogs.first.sets.first.weight, 90.0);
    expect(provider.activeSession!.exerciseLogs.first.sets.first.reps, 8);
    expect(provider.activeSession!.exerciseLogs.first.sets.first.isDone, true);

    // 4. Finish the active workout (saves to history)
    await provider.finishActiveWorkout();
    expect(provider.hasActiveSession, false);
    expect(provider.history, hasLength(1));
    expect(provider.history.first.exerciseLogs.first.sets.first.weight, 90.0);

    // 5. Start a new empty workout
    provider.startWorkout();
    expect(provider.hasActiveSession, true);

    // 6. Add Bench Press again
    provider.addExerciseToActiveWorkout(benchPress);
    expect(provider.activeSession!.exerciseLogs, hasLength(1));
    
    final newLog = provider.activeSession!.exerciseLogs.first;
    expect(newLog.exerciseId, 'bench_press_id');
    // It should have prefilled the sets based on the last history!
    expect(newLog.sets, hasLength(1));
    expect(newLog.sets.first.weight, 90.0);
    expect(newLog.sets.first.reps, 8);
    expect(newLog.sets.first.isDone, false); // Should be false so the user can log it
  });

  test('WorkoutProvider body weight logs test', () async {
    final provider = WorkoutProvider();
    
    // Wait for Hive to initialize and provider to load
    while (provider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 10));
    }

    expect(provider.weightHistory, isEmpty);

    // Add weight logs
    await provider.addWeightLog(80.5);
    expect(provider.weightHistory, hasLength(1));
    expect(provider.weightHistory.first.weight, 80.5);

    await provider.addWeightLog(79.8);
    expect(provider.weightHistory, hasLength(2));
    expect(provider.weightHistory.first.weight, 79.8); // Newest first

    final secondLogId = provider.weightHistory[1].id;

    // Delete a log
    await provider.deleteWeightLog(secondLogId);
    expect(provider.weightHistory, hasLength(1));
    expect(provider.weightHistory.first.weight, 79.8);
  });

  test('WorkoutProvider calories and JSON backup/restore test', () async {
    final provider = WorkoutProvider();
    
    // Wait for Hive to initialize and provider to load
    while (provider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 10));
    }

    // 1. Check calorie defaults
    expect(provider.calorieTarget, 2000.0);
    expect(provider.todayCalories, 0.0);

    // 2. Set target and add today's calories
    await provider.setCalorieTarget(2500.0);
    expect(provider.calorieTarget, 2500.0);

    await provider.updateTodayCalories(1500.0);
    expect(provider.todayCalories, 1500.0);

    await provider.addTodayCalories(500.0);
    expect(provider.todayCalories, 2000.0);

    // 3. Export backup JSON
    final jsonBackup = await provider.exportBackupJson([]);
    expect(jsonBackup, isNotEmpty);
    expect(jsonBackup.contains('"calorie_target":2500'), true);
    expect(jsonBackup.contains('"rest_timer_duration":90'), true);

    // 4. Change states to test restore
    await provider.setCalorieTarget(1800.0);
    await provider.updateTodayCalories(0.0);
    expect(provider.calorieTarget, 1800.0);
    expect(provider.todayCalories, 0.0);

    // 5. Restore JSON backup
    final mockExerciseProvider = ExerciseProvider();
    while (mockExerciseProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    
    final success = await provider.importBackupJson(jsonBackup, mockExerciseProvider);
    expect(success, true);

    // 6. Check if state restored correctly
    expect(provider.calorieTarget, 2500.0);
    expect(provider.todayCalories, 2000.0);
  });
}
