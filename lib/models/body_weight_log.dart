class BodyWeightLog {
  final String id;
  final DateTime date;
  final double weight;

  BodyWeightLog({
    required this.id,
    required this.date,
    required this.weight,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weight': weight,
    };
  }

  factory BodyWeightLog.fromJson(Map<String, dynamic> json) {
    return BodyWeightLog(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      weight: (json['weight'] as num).toDouble(),
    );
  }
}
