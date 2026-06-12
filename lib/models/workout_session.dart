import 'exercise_log.dart';

class WorkoutSession {
  final String id;
  final DateTime date;
  final List<ExerciseLog> exerciseLogs;

  WorkoutSession({
    required this.id,
    required this.date,
    required this.exerciseLogs,
  });

  WorkoutSession copyWith({
    String? id,
    DateTime? date,
    List<ExerciseLog>? exerciseLogs,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      date: date ?? this.date,
      exerciseLogs: exerciseLogs ?? this.exerciseLogs,
    );
  }

  // Calculate total volume for the session
  double get totalVolume {
    return exerciseLogs.fold(0.0, (sum, log) => sum + log.totalVolume);
  }

  // Total completed sets in the session
  int get totalCompletedSets {
    return exerciseLogs.fold(0, (sum, log) => sum + log.sets.where((s) => s.isDone).length);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'exerciseLogs': exerciseLogs.map((log) => log.toJson()).toList(),
    };
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      exerciseLogs: (json['exerciseLogs'] as List<dynamic>)
          .map((log) => ExerciseLog.fromJson(log as Map<String, dynamic>))
          .toList(),
    );
  }
}
