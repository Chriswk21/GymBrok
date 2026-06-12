import 'workout_set.dart';

class ExerciseLog {
  final String exerciseId;
  final String exerciseName;
  final String category;
  final List<WorkoutSet> sets;

  ExerciseLog({
    required this.exerciseId,
    required this.exerciseName,
    required this.category,
    required this.sets,
  });

  ExerciseLog copyWith({
    String? exerciseId,
    String? exerciseName,
    String? category,
    List<WorkoutSet>? sets,
  }) {
    return ExerciseLog(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      category: category ?? this.category,
      sets: sets ?? this.sets,
    );
  }

  // Calculate total volume for this exercise log (only count completed sets)
  double get totalVolume {
    return sets
        .where((set) => set.isDone)
        .fold(0.0, (sum, set) => sum + (set.weight * set.reps));
  }

  // Find the maximum weight lifted in completed sets
  double get maxWeight {
    final completedSets = sets.where((set) => set.isDone);
    if (completedSets.isEmpty) return 0.0;
    return completedSets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
  }

  // Find the maximum estimated 1RM from completed sets using Epley formula: 1RM = Weight * (1 + (Reps / 30))
  double get estimatedOneRepMax {
    final completedSets = sets.where((set) => set.isDone && set.reps > 0);
    if (completedSets.isEmpty) return 0.0;
    return completedSets
        .map((s) => s.weight * (1 + (s.reps / 30.0)))
        .reduce((a, b) => a > b ? a : b);
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'category': category,
      'sets': sets.map((s) => s.toJson()).toList(),
    };
  }

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      category: json['category'] as String,
      sets: (json['sets'] as List<dynamic>)
          .map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
