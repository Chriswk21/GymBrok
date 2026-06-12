class WorkoutSet {
  final double weight;
  final int reps;
  final bool isDone;
  final double? weightLeft;
  final double? weightRight;

  WorkoutSet({
    required this.weight,
    required this.reps,
    this.isDone = false,
    this.weightLeft,
    this.weightRight,
  });

  WorkoutSet copyWith({
    double? weight,
    int? reps,
    bool? isDone,
    double? weightLeft,
    double? weightRight,
  }) {
    // If updating left/right weights, update the main weight to be the sum
    double finalWeight = weight ?? this.weight;
    if (weightLeft != null || weightRight != null) {
      finalWeight = (weightLeft ?? this.weightLeft ?? 0.0) + 
                    (weightRight ?? this.weightRight ?? 0.0);
    }

    return WorkoutSet(
      weight: finalWeight,
      reps: reps ?? this.reps,
      isDone: isDone ?? this.isDone,
      weightLeft: weightLeft ?? this.weightLeft,
      weightRight: weightRight ?? this.weightRight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weight': weight,
      'reps': reps,
      'isDone': isDone,
      'weightLeft': weightLeft,
      'weightRight': weightRight,
    };
  }

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      weight: (json['weight'] as num).toDouble(),
      reps: json['reps'] as int,
      isDone: (json['isDone'] ?? false) as bool,
      weightLeft: json['weightLeft'] != null ? (json['weightLeft'] as num).toDouble() : null,
      weightRight: json['weightRight'] != null ? (json['weightRight'] as num).toDouble() : null,
    );
  }
}
