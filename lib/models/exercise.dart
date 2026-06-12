class Exercise {
  final String id;
  final String name;
  final String category;
  final bool isFavorite;
  final bool isCustom;
  final bool hasUnilateralWeights;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    this.isFavorite = false,
    this.isCustom = false,
    this.hasUnilateralWeights = false,
  });

  Exercise copyWith({
    String? id,
    String? name,
    String? category,
    bool? isFavorite,
    bool? isCustom,
    bool? hasUnilateralWeights,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      isCustom: isCustom ?? this.isCustom,
      hasUnilateralWeights: hasUnilateralWeights ?? this.hasUnilateralWeights,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'isFavorite': isFavorite,
      'isCustom': isCustom,
      'hasUnilateralWeights': hasUnilateralWeights,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      isFavorite: (json['isFavorite'] ?? false) as bool,
      isCustom: (json['isCustom'] ?? false) as bool,
      hasUnilateralWeights: (json['hasUnilateralWeights'] ?? false) as bool,
    );
  }
}
