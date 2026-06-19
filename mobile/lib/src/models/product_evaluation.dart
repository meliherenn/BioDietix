class ProductEvaluation {
  const ProductEvaluation({
    required this.decision,
    required this.reasons,
    required this.positives,
    required this.alternatives,
    required this.dataQuality,
    required this.medicalNote,
  });

  final String decision;
  final List<Map<String, dynamic>> reasons;
  final List<Map<String, dynamic>> positives;
  final List<Map<String, dynamic>> alternatives;
  final Map<String, dynamic> dataQuality;
  final String medicalNote;

  bool get hasDataQuality => dataQuality.isNotEmpty;

  String get dataQualityLevel {
    return dataQuality['level']?.toString() ?? 'medium';
  }

  factory ProductEvaluation.fromJson(Map<String, dynamic> json) {
    return ProductEvaluation(
      decision: json['decision']?.toString() ?? 'recommended',
      reasons: _mapList(json['reasons']),
      positives: _mapList(json['positives']),
      alternatives: _mapList(json['alternatives']),
      dataQuality:
          (json['data_quality'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value),
          ) ??
          const <String, dynamic>{},
      medicalNote: json['medical_note']?.toString() ?? '',
    );
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList();
  }
}
