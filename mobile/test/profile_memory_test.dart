import 'package:biodietix_mobile/src/models/personal_info.dart';
import 'package:biodietix_mobile/src/models/profile_memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'profile updates propagate current BMI into product-evaluation memory',
    () {
      final memory = ProfileMemory.fromJson(const {
        'health_profile': 'Weight Management Risk',
        'allergies': [],
      });

      final updated = memory.copyWithPersonalInfo(
        const PersonalInfo(age: 30, weightKg: 70, heightCm: 175),
      );

      expect(updated.raw['bmi'], closeTo(22.857, 0.001));
      expect((updated.raw['personal_info'] as Map)['Age'], 30);
    },
  );
}
