class PersonalInfo {
  const PersonalInfo({
    this.gender = 'Female',
    this.age = 22,
    this.weightKg,
    this.heightCm,
  });

  final String gender;
  final int age;
  final double? weightKg;
  final double? heightCm;

  PersonalInfo copyWith({
    String? gender,
    int? age,
    double? weightKg,
    double? heightCm,
    bool clearWeight = false,
    bool clearHeight = false,
  }) {
    return PersonalInfo(
      gender: gender ?? this.gender,
      age: age ?? this.age,
      weightKg: clearWeight ? null : weightKg ?? this.weightKg,
      heightCm: clearHeight ? null : heightCm ?? this.heightCm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gender': gender,
      'age': age,
      'weightKg': weightKg,
      'heightCm': heightCm,
    };
  }

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      gender: json['gender']?.toString() ?? 'Female',
      age: (json['age'] as num?)?.toInt() ?? 22,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
    );
  }
}
