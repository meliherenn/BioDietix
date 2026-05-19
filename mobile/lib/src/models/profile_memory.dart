class ProfileMemory {
  const ProfileMemory({
    required this.raw,
    required this.healthProfile,
    required this.nutritionRecommendation,
    required this.foodsToIncrease,
    required this.foodsToLimit,
    required this.allergies,
  });

  final Map<String, dynamic> raw;
  final String healthProfile;
  final String nutritionRecommendation;
  final List<String> foodsToIncrease;
  final List<String> foodsToLimit;
  final List<String> allergies;

  Map<String, dynamic> toJson() => raw;

  ProfileMemory copyWithAllergies(List<String> nextAllergies) {
    final updated = Map<String, dynamic>.from(raw);
    updated['allergies'] = nextAllergies;
    return ProfileMemory.fromJson(updated);
  }

  factory ProfileMemory.fromJson(Map<String, dynamic> json) {
    return ProfileMemory(
      raw: Map<String, dynamic>.from(json),
      healthProfile: json['health_profile']?.toString() ?? '',
      nutritionRecommendation:
          json['nutrition_recommendation']?.toString() ?? '',
      foodsToIncrease: _stringList(json['foods_to_increase']),
      foodsToLimit: _stringList(json['foods_to_limit']),
      allergies: _stringList(json['allergies']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String && value.isNotEmpty) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }
}
