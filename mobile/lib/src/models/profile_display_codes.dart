/// Stable, language-neutral identifiers for the user-facing profile summary.
///
/// Schema v2 stores these values under `display_codes`. The raw English fields
/// remain available for backwards compatibility, but should not be rendered
/// directly by the mobile UI.
class ProfileDisplayCodes {
  const ProfileDisplayCodes({
    this.healthProfiles = const [],
    this.recommendations = const [],
    this.foodsToIncrease = const [],
    this.foodsToLimit = const [],
    this.interpretationWarnings = const [],
  });

  final List<String> healthProfiles;
  final List<String> recommendations;
  final List<String> foodsToIncrease;
  final List<String> foodsToLimit;
  final List<String> interpretationWarnings;

  bool get isEmpty =>
      healthProfiles.isEmpty &&
      recommendations.isEmpty &&
      foodsToIncrease.isEmpty &&
      foodsToLimit.isEmpty &&
      interpretationWarnings.isEmpty;

  factory ProfileDisplayCodes.fromProfileJson(Map<String, dynamic> json) {
    final displayCodes = _stringKeyedMap(json['display_codes']);

    return ProfileDisplayCodes(
      healthProfiles: _firstNonEmptyList([
        displayCodes?['health_profiles'],
        json['profile_signal_codes'],
        json['health_profile_codes'],
      ]),
      recommendations: _firstNonEmptyList([
        displayCodes?['recommendations'],
        json['recommendation_codes'],
      ]),
      foodsToIncrease: _firstNonEmptyList([
        displayCodes?['foods_to_increase'],
        json['foods_to_increase_codes'],
      ]),
      foodsToLimit: _firstNonEmptyList([
        displayCodes?['foods_to_limit'],
        json['foods_to_limit_codes'],
      ]),
      interpretationWarnings: _firstNonEmptyList([
        displayCodes?['interpretation_warnings'],
        json['interpretation_warning_codes'],
      ]),
    );
  }

  Map<String, dynamic> toJson() => {
    'health_profiles': healthProfiles,
    'recommendations': recommendations,
    'foods_to_increase': foodsToIncrease,
    'foods_to_limit': foodsToLimit,
    'interpretation_warnings': interpretationWarnings,
  };

  static Map<String, dynamic>? _stringKeyedMap(dynamic value) {
    if (value is! Map) return null;
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static List<String> _firstNonEmptyList(List<dynamic> candidates) {
    for (final candidate in candidates) {
      final parsed = _stringList(candidate);
      if (parsed.isNotEmpty) return parsed;
    }
    return const [];
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return List.unmodifiable(
      value
          .whereType<Object>()
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty),
    );
  }
}
