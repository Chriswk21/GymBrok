import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:gymbrok/providers/workout_provider.dart';
import 'package:gymbrok/providers/exercise_provider.dart';
import 'package:gymbrok/screens/active_workout_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('gymbrok_multiselect_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget buildTestableWidget({
    required WorkoutProvider workoutProvider,
    required ExerciseProvider exerciseProvider,
    required Widget child,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WorkoutProvider>.value(value: workoutProvider),
        ChangeNotifierProvider<ExerciseProvider>.value(value: exerciseProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  testWidgets('Multi-select exercises on bottom sheet', (WidgetTester tester) async {
    late WorkoutProvider workoutProvider;
    late ExerciseProvider exerciseProvider;

    await tester.runAsync(() async {
      workoutProvider = WorkoutProvider();
      exerciseProvider = ExerciseProvider();

      // Wait for Hive initialization
      while (workoutProvider.isLoading || exerciseProvider.isLoading) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    });

    await tester.pumpWidget(buildTestableWidget(
      workoutProvider: workoutProvider,
      exerciseProvider: exerciseProvider,
      child: Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () {
              workoutProvider.startWorkout();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const ActiveWorkoutScreen(),
              );
            },
            child: const Text('Open Workout'),
          );
        },
      ),
    ));


    // Tap to open the workout screen modal sheet
    await tester.tap(find.text('Open Workout'));
    await tester.pumpAndSettle();

    // Verify ActiveWorkoutScreen is open
    expect(find.byType(ActiveWorkoutScreen), findsOneWidget);

    // Find and tap the "Add Exercise" button
    final addExerciseBtn = find.text('Add Exercise').first;
    expect(addExerciseBtn, findsOneWidget);
    await tester.tap(addExerciseBtn);
    await tester.pumpAndSettle();

    // Find target exercises
    final ex1Text = find.text('Ab Crunch Machine');
    final ex2Text = find.text('Ab Wheel Rollout');

    expect(ex1Text, findsOneWidget);
    expect(ex2Text, findsOneWidget);

    // Tap on first exercise (selects it)
    await tester.tap(ex1Text);
    await tester.pump();

    // Tap on second exercise (selects it)
    await tester.tap(ex2Text);
    await tester.pump();

    // The Apply button "Add 2 Exercises" should appear
    final applyBtn = find.text('Add 2 Exercises');
    expect(applyBtn, findsOneWidget);

    // Tap the Apply button
    await tester.tap(applyBtn);
    await tester.pumpAndSettle();

    // The sheet should close, and the exercises should be added to the active workout session
    expect(workoutProvider.activeSession!.exerciseLogs, hasLength(2));
    expect(workoutProvider.activeSession!.exerciseLogs[0].exerciseName, 'Ab Crunch Machine');
    expect(workoutProvider.activeSession!.exerciseLogs[1].exerciseName, 'Ab Wheel Rollout');
  });
}
