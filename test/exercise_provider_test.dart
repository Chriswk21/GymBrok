import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:gymbrok/providers/exercise_provider.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('gymbrok_exercise_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('ExerciseProvider custom exercise creation test', () async {
    final provider = ExerciseProvider();

    // Wait for Hive initialization
    while (provider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 10));
    }

    // Default exercises loaded on seed
    final initialLength = provider.exercises.length;
    expect(initialLength, greaterThan(0));

    // Add bilateral custom exercise
    final ex1 = await provider.addCustomExercise(
      'Hammer Strength Incline Press',
      'Chest',
      hasUnilateralWeights: false,
    );

    expect(ex1, isNotNull);
    expect(ex1!.name, 'Hammer Strength Incline Press');
    expect(ex1.category, 'Chest');
    expect(ex1.isCustom, true);
    expect(ex1.hasUnilateralWeights, false);

    // Verify it is added to list
    expect(provider.exercises.length, initialLength + 1);
    expect(provider.exercises.any((e) => e.id == ex1.id), true);

    // Add unilateral custom exercise
    final ex2 = await provider.addCustomExercise(
      'Dumbbell Bicep Curl (Unilateral)',
      'Bicep',
      hasUnilateralWeights: true,
    );

    expect(ex2, isNotNull);
    expect(ex2!.name, 'Dumbbell Bicep Curl (Unilateral)');
    expect(ex2.category, 'Bicep');
    expect(ex2.isCustom, true);
    expect(ex2.hasUnilateralWeights, true);

    // Verify it is in list
    expect(provider.exercises.length, initialLength + 2);
    expect(provider.exercises.any((e) => e.id == ex2.id), true);

    // Verify Calisthenics exercises are seeded correctly
    final calisthenicsExercises = provider.exercises.where((e) => e.category == 'Calisthenics').toList();
    expect(calisthenicsExercises, isNotEmpty);

    final pullUps = calisthenicsExercises.firstWhere((e) => e.name == 'Pull Ups');
    expect(pullUps.category, 'Calisthenics');
    expect(pullUps.hasUnilateralWeights, false);

    final pistolSquats = calisthenicsExercises.firstWhere((e) => e.name == 'Pistol Squats');
    expect(pistolSquats.category, 'Calisthenics');
    expect(pistolSquats.hasUnilateralWeights, true);
  });
}
