import 'package:biodietix_mobile/src/i18n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lab labels and enum values switch without changing measurements', () {
    const en = AppStrings(AppLanguage.en);
    const tr = AppStrings(AppLanguage.tr);

    expect(en.labLabel('Glucose_mgdL'), 'Glucose (mg/dL)');
    expect(tr.labLabel('Glucose_mgdL'), 'Glukoz (mg/dL)');
    expect(en.labValue('Gender', 'Female'), 'Female');
    expect(tr.labValue('Gender', 'Female'), 'Kadın');
    expect(tr.labValue('Glucose_mgdL', 91.4), '91.4');
    expect(
      tr.labValue('Observed_Lab_Domains', 'glycemic, thyroid'),
      'Kan şekeri, Tiroid',
    );
  });

  test(
    'possible allergy conflict has a safe translation in both languages',
    () {
      const reason = {
        'code': 'possible_allergy_conflict',
        'allergens': ['milk'],
      };

      expect(
        const AppStrings(AppLanguage.en).reason(reason),
        'Possible allergy conflict: Milk / dairy',
      );
      expect(
        const AppStrings(AppLanguage.tr).reason(reason),
        'Olası alerji uyumsuzluğu: Süt / süt ürünleri',
      );
    },
  );
}
