class MealLog {
  const MealLog({
    required this.id,
    required this.title,
    required this.note,
    required this.calories,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String note;
  final int calories;
  final DateTime createdAt;
  final DateTime updatedAt;

  MealLog copyWith({
    String? id,
    String? title,
    String? note,
    int? calories,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealLog(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      calories: calories ?? this.calories,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'calories': calories,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MealLog.fromJson(Map<String, dynamic> json) {
    return MealLog(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
    );
  }

  static DateTime _date(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
