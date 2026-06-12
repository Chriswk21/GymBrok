class TemplateExercise {
  final String exerciseId;
  final String name;
  final String category;

  TemplateExercise({
    required this.exerciseId,
    required this.name,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'name': name,
      'category': category,
    };
  }

  factory TemplateExercise.fromJson(Map<String, dynamic> json) {
    return TemplateExercise(
      exerciseId: json['exerciseId'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
    );
  }
}

class WorkoutTemplate {
  final String id;
  final String name;
  final List<TemplateExercise> exercises;

  WorkoutTemplate({
    required this.id,
    required this.name,
    required this.exercises,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => TemplateExercise.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
