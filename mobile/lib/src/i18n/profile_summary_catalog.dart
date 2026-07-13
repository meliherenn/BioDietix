class ProfileSummaryCatalogEntry {
  const ProfileSummaryCatalogEntry({
    required this.code,
    required this.legacyText,
    required this.en,
    required this.tr,
  });

  final String code;
  final String legacyText;
  final String en;
  final String tr;

  String localized(String languageCode) => languageCode == 'tr' ? tr : en;
}

/// Complete bilingual catalog for every summary value currently emitted by
/// the Python analysis pipeline.
class ProfileSummaryCatalog {
  const ProfileSummaryCatalog._();

  static final Map<String, ProfileSummaryCatalogEntry> healthByCode = _byCode(
    healthProfiles,
  );
  static final Map<String, ProfileSummaryCatalogEntry> recommendationByCode =
      _byCode(recommendations);
  static final Map<String, ProfileSummaryCatalogEntry> foodByCode = _byCode(
    foods,
  );
  static final Map<String, ProfileSummaryCatalogEntry> warningByCode = _byCode(
    interpretationWarnings,
  );

  static final Map<String, String> healthCodeByLegacy = _codeByLegacy(
    healthProfiles,
  );
  static final Map<String, String> recommendationCodeByLegacy = _codeByLegacy(
    recommendations,
  );
  static final Map<String, String> foodCodeByLegacy = _codeByLegacy(foods);
  static final Map<String, String> warningCodeByLegacy = _codeByLegacy(
    interpretationWarnings,
  );

  static Iterable<ProfileSummaryCatalogEntry> get allEntries sync* {
    yield* healthProfiles;
    yield* recommendations;
    yield* foods;
    yield* interpretationWarnings;
  }

  static Map<String, ProfileSummaryCatalogEntry> _byCode(
    List<ProfileSummaryCatalogEntry> entries,
  ) => Map.unmodifiable({for (final entry in entries) entry.code: entry});

  static Map<String, String> _codeByLegacy(
    List<ProfileSummaryCatalogEntry> entries,
  ) => Map.unmodifiable({
    for (final entry in entries) entry.legacyText: entry.code,
  });

  static const healthProfiles = <ProfileSummaryCatalogEntry>[
    ProfileSummaryCatalogEntry(
      code: 'health.blood_sugar_risk',
      legacyText: 'Blood Sugar Risk',
      en: 'Blood Sugar Risk',
      tr: 'Kan Şekeri Riski',
    ),
    ProfileSummaryCatalogEntry(
      code: 'health.weight_management_risk',
      legacyText: 'Weight Management Risk',
      en: 'Weight Management Risk',
      tr: 'Kilo Yönetimi Riski',
    ),
    ProfileSummaryCatalogEntry(
      code: 'health.blood_pressure_risk',
      legacyText: 'Blood Pressure Risk',
      en: 'Blood Pressure Risk',
      tr: 'Tansiyon Riski',
    ),
    ProfileSummaryCatalogEntry(
      code: 'health.cardiovascular_lipid_risk',
      legacyText: 'Cardiovascular Lipid Risk',
      en: 'Cardiovascular Lipid Risk',
      tr: 'Kardiyovasküler Lipit Riski',
    ),
    ProfileSummaryCatalogEntry(
      code: 'health.kidney_muscle_indicator',
      legacyText: 'Kidney / Muscle Indicator',
      en: 'Kidney / Muscle Indicator',
      tr: 'Böbrek / Kas Göstergesi',
    ),
    ProfileSummaryCatalogEntry(
      code: 'health.hemoglobin_indicator',
      legacyText: 'Hemoglobin Indicator',
      en: 'Hemoglobin Indicator',
      tr: 'Hemoglobin Göstergesi',
    ),
    ProfileSummaryCatalogEntry(
      code: 'health.immune_inflammation_indicator',
      legacyText: 'Immune / Inflammation Indicator',
      en: 'Immune / Inflammation Indicator',
      tr: 'Bağışıklık / Enflamasyon Göstergesi',
    ),
    ProfileSummaryCatalogEntry(
      code: 'health.blood_cell_anemia_support_indicator',
      legacyText: 'Blood Cell / Anemia Support Indicator',
      en: 'Blood Cell / Anemia Support Indicator',
      tr: 'Kan Hücreleri / Anemi Desteği Göstergesi',
    ),
    ProfileSummaryCatalogEntry(
      code: 'health.platelet_support_indicator',
      legacyText: 'Platelet Support Indicator',
      en: 'Platelet Support Indicator',
      tr: 'Trombositlerle İlgili Destek Göstergesi',
    ),
    ProfileSummaryCatalogEntry(
      code: 'health.liver_enzyme_indicator',
      legacyText: 'Liver Enzyme Indicator',
      en: 'Liver Enzyme Indicator',
      tr: 'Karaciğer Enzimi Göstergesi',
    ),
    ProfileSummaryCatalogEntry(
      code: 'health.fiber_intake_signal',
      legacyText: 'Fiber Intake Signal',
      en: 'Fiber Intake Signal',
      tr: 'Lif Alımı Sinyali',
    ),
    ProfileSummaryCatalogEntry(
      code: 'health.abdominal_obesity_risk',
      legacyText: 'Abdominal Obesity Risk',
      en: 'Abdominal Obesity Risk',
      tr: 'Karın Bölgesi Obezitesi Riski',
    ),
    ProfileSummaryCatalogEntry(
      code: 'health.thyroid_metabolism_indicator',
      legacyText: 'Thyroid / Metabolism Indicator',
      en: 'Thyroid / Metabolism Indicator',
      tr: 'Tiroid / Metabolizma Göstergesi',
    ),
    ProfileSummaryCatalogEntry(
      code: 'health.vitamin_d_bone_health_indicator',
      legacyText: 'Vitamin D / Bone Health Indicator',
      en: 'Vitamin D / Bone Health Indicator',
      tr: 'D Vitamini / Kemik Sağlığı Göstergesi',
    ),
    ProfileSummaryCatalogEntry(
      code: 'health.micronutrient_support_indicator',
      legacyText: 'Micronutrient Support Indicator',
      en: 'Micronutrient Support Indicator',
      tr: 'Mikro Besin Desteği Göstergesi',
    ),
    ProfileSummaryCatalogEntry(
      code: 'health.age_related_nutrition_focus',
      legacyText: 'Age-Related Nutrition Focus',
      en: 'Age-Related Nutrition Focus',
      tr: 'Yaşa Bağlı Beslenme Odağı',
    ),
    ProfileSummaryCatalogEntry(
      code: 'health.low_risk',
      legacyText: 'Low Risk',
      en: 'Low Risk',
      tr: 'Düşük Risk',
    ),
    ProfileSummaryCatalogEntry(
      code: 'health.no_flagged_risk_available_data',
      legacyText: 'No Flagged Risk in Available Data',
      en: 'No Flagged Risk in Available Data',
      tr: 'Mevcut Verilerde İşaretlenen Bir Risk Yok',
    ),
    ProfileSummaryCatalogEntry(
      code: 'health.insufficient_data',
      legacyText: 'Insufficient Data',
      en: 'Insufficient Data',
      tr: 'Yetersiz Veri',
    ),
  ];

  static const recommendations = <ProfileSummaryCatalogEntry>[
    ProfileSummaryCatalogEntry(
      code: 'recommendation.age_young_adult',
      legacyText:
          'For this age group, build long-term habits with regular meals, adequate protein, fiber, and physical activity.',
      en: 'For this age group, build long-term habits with regular meals, adequate protein, fiber, and physical activity.',
      tr: 'Bu yaş grubu için düzenli öğünler, yeterli protein ve lif tüketimi ile fiziksel aktiviteyi içeren, uzun vadede sürdürülebilir alışkanlıklar geliştirin.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.age_adult',
      legacyText:
          'For adult metabolic maintenance, prioritize portion control, fiber, lean protein, and consistent activity.',
      en: 'For adult metabolic maintenance, prioritize portion control, fiber, lean protein, and consistent activity.',
      tr: 'Yetişkinlik döneminde metabolik sağlığı korumak için porsiyon kontrolüne, liften zengin besinlere, yağsız proteine ve düzenli fiziksel aktiviteye öncelik verin.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.age_midlife',
      legacyText:
          'For midlife prevention, focus on cardiovascular health, muscle maintenance, fiber, vitamin D, calcium, and regular checkups.',
      en: 'For midlife prevention, focus on cardiovascular health, muscle maintenance, fiber, vitamin D, calcium, and regular checkups.',
      tr: 'Orta yaş döneminde korunma için kalp-damar sağlığına, kas kütlesinin korunmasına, lif, D vitamini ve kalsiyum alımına ve düzenli kontrollere odaklanın.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.age_older_adult',
      legacyText:
          'For older adults, protect muscle and bone health with adequate protein, vitamin D, calcium, hydration, and clinically guided follow-up.',
      en: 'For older adults, protect muscle and bone health with adequate protein, vitamin D, calcium, hydration, and clinically guided follow-up.',
      tr: 'İleri yaşlarda yeterli protein, D vitamini, kalsiyum ve sıvı alımı ile kas ve kemik sağlığını koruyun; kontrollerinizi sağlık profesyonelinin yönlendirmesiyle sürdürün.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.reduce_added_sugar_refined_carbs',
      legacyText:
          'Reduce added sugar and refined carbohydrates, and prefer low-glycemic foods.',
      en: 'Reduce added sugar and refined carbohydrates, and prefer low-glycemic foods.',
      tr: 'Eklenmiş şekeri ve rafine karbonhidratları azaltın; glisemik indeksi düşük besinleri tercih edin.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.portion_control_nutrient_dense_meals',
      legacyText:
          'Control portion sizes and choose nutrient-dense, lower-calorie meals.',
      en: 'Control portion sizes and choose nutrient-dense, lower-calorie meals.',
      tr: 'Porsiyonları kontrol edin; besin değeri yüksek ve kalorisi daha düşük öğünleri tercih edin.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.underweight_nutrient_dense_support',
      legacyText:
          'BMI indicates an underweight range. Increase nutrient-dense calories with protein-rich meals and healthy fats, and review unintentional weight loss with a healthcare professional.',
      en: 'BMI indicates an underweight range. Increase nutrient-dense calories with protein-rich meals and healthy fats, and review unintentional weight loss with a healthcare professional.',
      tr: 'BKİ değeri düşük kilo aralığında. Protein açısından zengin öğünler ve sağlıklı yağlarla besin değeri yüksek kalori alımını artırın; istemsiz kilo kaybını bir sağlık profesyoneliyle değerlendirin.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.severely_elevated_blood_pressure',
      legacyText:
          'This blood-pressure value is severely elevated. Recheck it correctly and seek prompt clinical advice; if there are symptoms such as chest pain, shortness of breath, weakness, vision change, or difficulty speaking, use local emergency services.',
      en: 'This blood-pressure value is severely elevated. Recheck it correctly and seek prompt clinical advice; if there are symptoms such as chest pain, shortness of breath, weakness, vision change, or difficulty speaking, use local emergency services.',
      tr: 'Bu tansiyon değeri ciddi derecede yüksek. Doğru teknikle yeniden ölçün ve gecikmeden tıbbi değerlendirme için başvurun. Göğüs ağrısı, nefes darlığı, güçsüzlük, görmede değişiklik veya konuşma güçlüğü varsa bulunduğunuz yerdeki acil sağlık hizmetlerine başvurun.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.reduce_sodium_dash_pattern',
      legacyText:
          'Reduce sodium intake and follow a DASH-style eating pattern.',
      en: 'Reduce sodium intake and follow a DASH-style eating pattern.',
      tr: 'Sodyum alımını azaltın ve DASH tipi bir beslenme düzeni uygulayın.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.heart_healthy_fats',
      legacyText:
          'Reduce saturated fat and refined carbohydrates; prefer heart-healthy fats.',
      en: 'Reduce saturated fat and refined carbohydrates; prefer heart-healthy fats.',
      tr: 'Doymuş yağı ve rafine karbonhidratları azaltın; kalp sağlığını destekleyen yağları tercih edin.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.creatinine_clinical_review',
      legacyText:
          'A creatinine result should be interpreted with eGFR, hydration, muscle mass, medicines, and the laboratory range. Do not change protein or fluid intake based on this result alone; discuss it with a healthcare professional.',
      en: 'A creatinine result should be interpreted with eGFR, hydration, muscle mass, medicines, and the laboratory range. Do not change protein or fluid intake based on this result alone; discuss it with a healthcare professional.',
      tr: 'Kreatinin sonucu; eGFR, sıvı durumu, kas kütlesi, kullanılan ilaçlar ve laboratuvarın referans aralığıyla birlikte değerlendirilmelidir. Yalnızca bu sonuca dayanarak protein veya sıvı alımınızı değiştirmeyin; bir sağlık profesyoneline danışın.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.low_creatinine_muscle_support',
      legacyText:
          'Support muscle mass with adequate calories, high-quality protein, and regular resistance exercise.',
      en: 'Support muscle mass with adequate calories, high-quality protein, and regular resistance exercise.',
      tr: 'Yeterli kalori, kaliteli protein ve düzenli direnç egzersiziyle kas kütlesini destekleyin.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.low_hemoglobin_clinical_review',
      legacyText:
          'A low hemoglobin indicator has several possible causes and should be discussed with a healthcare professional. Iron-containing foods may be reasonable, but do not start iron supplements without clinical advice.',
      en: 'A low hemoglobin indicator has several possible causes and should be discussed with a healthcare professional. Iron-containing foods may be reasonable, but do not start iron supplements without clinical advice.',
      tr: 'Düşük hemoglobin göstergesinin birden fazla olası nedeni vardır ve bir sağlık profesyoneliyle değerlendirilmelidir. Demir içeren besinleri tüketmek uygun olabilir; ancak klinik öneri olmadan demir takviyesine başlamayın.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.inflammation_varied_diet',
      legacyText:
          'Inflammation or blood-cell indicators are nonspecific and should be interpreted with symptoms and other tests. A varied eating pattern with vegetables, fruit, adequate protein, and hydration is a general option.',
      en: 'Inflammation or blood-cell indicators are nonspecific and should be interpreted with symptoms and other tests. A varied eating pattern with vegetables, fruit, adequate protein, and hydration is a general option.',
      tr: 'Enflamasyon veya kan hücresi göstergeleri özgül değildir; belirtiler ve diğer testlerle birlikte değerlendirilmelidir. Sebze, meyve, yeterli protein ve sıvı içeren çeşitli bir beslenme düzeni genel bir yaklaşım olabilir.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.blood_cell_nutrient_support',
      legacyText:
          'Support blood cell health with iron, folate, vitamin B12, vitamin C, and adequate protein intake.',
      en: 'Support blood cell health with iron, folate, vitamin B12, vitamin C, and adequate protein intake.',
      tr: 'Kan hücresi sağlığını demir, folat, B12 vitamini, C vitamini ve yeterli protein alımıyla destekleyin.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.platelet_balanced_nutrition',
      legacyText:
          'Maintain balanced nutrition and hydration; platelet-related abnormalities should be interpreted with clinical context.',
      en: 'Maintain balanced nutrition and hydration; platelet-related abnormalities should be interpreted with clinical context.',
      tr: 'Dengeli beslenmeyi ve yeterli sıvı alımını sürdürün; trombositle ilgili değişiklikler klinik bağlamla birlikte değerlendirilmelidir.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.liver_health_support',
      legacyText:
          'Liver enzyme changes should be reviewed with a healthcare professional. Reduce alcohol, fried foods, and excess sugar to support liver health.',
      en: 'Liver enzyme changes should be reviewed with a healthcare professional. Reduce alcohol, fried foods, and excess sugar to support liver health.',
      tr: 'Karaciğer enzimlerindeki değişiklikler bir sağlık profesyoneliyle değerlendirilmelidir. Karaciğer sağlığını desteklemek için alkolü, kızartmaları ve fazla şekeri azaltın.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.thyroid_clinical_review',
      legacyText:
          "Thyroid-related lab changes should be reviewed with a healthcare professional and the reporting laboratory's reference range. Do not start iodine, selenium, or thyroid supplements based on this result.",
      en: "Thyroid-related lab changes should be reviewed with a healthcare professional and the reporting laboratory's reference range. Do not start iodine, selenium, or thyroid supplements based on this result.",
      tr: 'Tiroidle ilişkili laboratuvar değişiklikleri, sonucu veren laboratuvarın referans aralığı dikkate alınarak bir sağlık profesyoneliyle birlikte değerlendirilmelidir. Yalnızca bu sonuca dayanarak iyot, selenyum veya tiroid destek ürünü kullanmaya başlamayın.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.low_fiber_gradual_increase',
      legacyText:
          'Recorded fiber intake appears below the general adult reference used by this app. If the entry reflects your usual intake, consider gradually adding varied fiber sources and discuss individual needs with a dietitian or healthcare professional.',
      en: 'Recorded fiber intake appears below the general adult reference used by this app. If the entry reflects your usual intake, consider gradually adding varied fiber sources and discuss individual needs with a dietitian or healthcare professional.',
      tr: 'Kaydedilen lif alımı, uygulamanın yetişkinler için kullandığı genel referansın altında görünüyor. Bu kayıt olağan tüketiminizi yansıtıyorsa çeşitli lif kaynaklarını beslenmenize kademeli olarak eklemeyi değerlendirin ve kişisel gereksinimlerinizi bir diyetisyen veya sağlık profesyoneliyle görüşün.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.weight_management_focus',
      legacyText:
          'Focus on weight management, fiber-rich meals, and regular physical activity.',
      en: 'Focus on weight management, fiber-rich meals, and regular physical activity.',
      tr: 'Kilo yönetimine, liften zengin öğünlere ve düzenli fiziksel aktiviteye odaklanın.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.vitamin_d_clinical_review',
      legacyText:
          'A vitamin D indicator should be reviewed with a healthcare professional because thresholds and treatment decisions vary. Food sources of vitamin D, calcium, and protein can be part of a balanced diet; do not start high-dose supplements from this result alone.',
      en: 'A vitamin D indicator should be reviewed with a healthcare professional because thresholds and treatment decisions vary. Food sources of vitamin D, calcium, and protein can be part of a balanced diet; do not start high-dose supplements from this result alone.',
      tr: 'D vitamini göstergesi bir sağlık profesyoneliyle değerlendirilmelidir; eşik değerler ve tedavi kararları değişebilir. D vitamini, kalsiyum ve protein kaynakları dengeli beslenmenin parçası olabilir; yalnızca bu sonuca dayanarak yüksek dozda takviye kullanmaya başlamayın.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.micronutrient_clinical_review',
      legacyText:
          'Micronutrient indicators require the laboratory range and clinical context. Discuss abnormal results before starting or stopping any supplement.',
      en: 'Micronutrient indicators require the laboratory range and clinical context. Discuss abnormal results before starting or stopping any supplement.',
      tr: 'Mikro besin göstergeleri, laboratuvarın referans aralığı ve klinik bağlamla birlikte değerlendirilmelidir. Herhangi bir takviyeye başlamadan veya takviyeyi bırakmadan önce anormal sonuçları bir sağlık profesyoneliyle görüşün.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.high_ferritin_clinical_review',
      legacyText:
          'High ferritin can occur for several reasons, including inflammation; do not increase iron intake or use iron supplements unless a clinician advises it.',
      en: 'High ferritin can occur for several reasons, including inflammation; do not increase iron intake or use iron supplements unless a clinician advises it.',
      tr: 'Yüksek ferritin, enflamasyon da dahil olmak üzere çeşitli nedenlerle görülebilir; bir klinisyen önermedikçe demir alımını artırmayın veya demir takviyesi kullanmayın.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.balanced_diet_general',
      legacyText:
          'Maintain a balanced diet with regular meals, adequate fiber, lean protein, and healthy fats.',
      en: 'Maintain a balanced diet with regular meals, adequate fiber, lean protein, and healthy fats.',
      tr: 'Düzenli öğünler, yeterli lif, yağsız protein ve sağlıklı yağlar içeren dengeli bir beslenme düzeni sürdürün.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.guide_higher_fiber_carbohydrates',
      legacyText:
          'Consider higher-fiber carbohydrate sources and smaller portions as general lower-glycemic food choices.',
      en: 'Consider higher-fiber carbohydrate sources and smaller portions as general lower-glycemic food choices.',
      tr: 'Genel olarak daha düşük glisemik etki için liften zengin karbonhidrat kaynaklarını ve daha küçük porsiyonları tercih etmeyi değerlendirin.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.guide_limit_added_sugar',
      legacyText:
          'Consider limiting added sugar and choosing whole fruit instead of sweet snacks when appropriate.',
      en: 'Consider limiting added sugar and choosing whole fruit instead of sweet snacks when appropriate.',
      tr: 'Uygun olduğunda eklenmiş şekeri sınırlamayı ve tatlı atıştırmalıklar yerine meyvenin kendisini tercih etmeyi değerlendirin.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.guide_varied_fiber_sources',
      legacyText:
          'Consider varied fiber sources such as vegetables, legumes, seeds, and whole grains, increasing gradually if needed.',
      en: 'Consider varied fiber sources such as vegetables, legumes, seeds, and whole grains, increasing gradually if needed.',
      tr: 'Sebze, baklagil, tohum ve tam tahıl gibi çeşitli lif kaynaklarını değerlendirin; gerekirse miktarı kademeli artırın.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.guide_balanced_protein',
      legacyText:
          'Include moderate portions of lean or plant protein as part of balanced meals.',
      en: 'Include moderate portions of lean or plant protein as part of balanced meals.',
      tr: 'Dengeli öğünlerin bir parçası olarak ölçülü miktarda yağsız veya bitkisel protein tüketin.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.guide_unsaturated_fats',
      legacyText:
          'Replace saturated and fried fats with unsaturated fat sources in modest portions.',
      en: 'Replace saturated and fried fats with unsaturated fat sources in modest portions.',
      tr: 'Doymuş yağları ve kızartma yağlarını ölçülü miktarda doymamış yağ kaynaklarıyla değiştirin.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.guide_lower_fat_dairy_fish',
      legacyText:
          'Prefer lower-fat dairy and fish while reducing fatty red meat and high-fat dairy.',
      en: 'Prefer lower-fat dairy and fish while reducing fatty red meat and high-fat dairy.',
      tr: 'Yağlı kırmızı eti ve tam yağlı süt ürünlerini azaltırken az yağlı süt ürünlerini ve balığı tercih edin.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.guide_liver_health',
      legacyText:
          'Support liver health by avoiding alcohol, fried foods, and sugary foods.',
      en: 'Support liver health by avoiding alcohol, fried foods, and sugary foods.',
      tr: 'Alkol, kızartma ve şekerli gıdalardan kaçınarak karaciğer sağlığını destekleyin.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.guide_lower_sodium',
      legacyText:
          'Use herbs or lemon instead of extra salt and consider fewer salty processed foods; ask a clinician before changing potassium intake if kidney function is reduced.',
      en: 'Use herbs or lemon instead of extra salt and consider fewer salty processed foods; ask a clinician before changing potassium intake if kidney function is reduced.',
      tr: 'İlave tuz yerine taze otlar veya limon kullanın ve tuzlu işlenmiş gıdaları azaltmayı değerlendirin; böbrek işlevi azalmışsa potasyum alımını değiştirmeden önce bir klinisyene danışın.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.guide_weight_control',
      legacyText:
          'Prioritize vegetables and lean protein while reducing high-calorie fast food.',
      en: 'Prioritize vegetables and lean protein while reducing high-calorie fast food.',
      tr: 'Yüksek kalorili ayaküstü hazır yiyecekleri azaltırken sebzelere ve yağsız proteine öncelik verin.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.guide_mediterranean_pattern',
      legacyText:
          'Use a Mediterranean-style pattern to support overall metabolic health.',
      en: 'Use a Mediterranean-style pattern to support overall metabolic health.',
      tr: 'Genel metabolik sağlığı desteklemek için Akdeniz tipi bir beslenme düzeni uygulayın.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'recommendation.medical_disclaimer',
      legacyText:
          'These are general food-choice suggestions, not medical advice. BioDietix is not a medical device and does not diagnose, treat, cure, or prevent any condition; discuss abnormal results and major diet changes with a qualified healthcare professional.',
      en: 'These are general food-choice suggestions, not medical advice. BioDietix is not a medical device and does not diagnose, treat, cure, or prevent any condition; discuss abnormal results and major diet changes with a qualified healthcare professional.',
      tr: 'Bunlar genel besin seçimi önerileridir; tıbbi tavsiye değildir. BioDietix tıbbi cihaz değildir ve herhangi bir durumu teşhis etmez, tedavi etmez, iyileştirmez veya önlemez. Anormal sonuçları ve önemli beslenme değişikliklerini yetkin bir sağlık profesyoneliyle görüşün.',
    ),
  ];

  static const foods = <ProfileSummaryCatalogEntry>[
    ProfileSummaryCatalogEntry(
      code: 'food.mediterranean_diet_foods',
      legacyText: 'Mediterranean diet foods',
      en: 'Mediterranean diet foods',
      tr: 'Akdeniz tipi beslenmeye uygun besinler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.adequate_protein',
      legacyText: 'adequate protein',
      en: 'adequate protein',
      tr: 'yeterli protein',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.alcohol',
      legacyText: 'alcohol',
      en: 'alcohol',
      tr: 'alkol',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.avocado',
      legacyText: 'avocado',
      en: 'avocado',
      tr: 'avokado',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.balanced_meals',
      legacyText: 'balanced meals',
      en: 'balanced meals',
      tr: 'dengeli öğünler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.beans',
      legacyText: 'beans',
      en: 'beans',
      tr: 'fasulye',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.berries',
      legacyText: 'berries',
      en: 'berries',
      tr: 'orman meyveleri',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.brown_rice',
      legacyText: 'brown rice',
      en: 'brown rice',
      tr: 'esmer pirinç',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.bulgur',
      legacyText: 'bulgur',
      en: 'bulgur',
      tr: 'bulgur',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.butter',
      legacyText: 'butter',
      en: 'butter',
      tr: 'tereyağı',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.calcium_rich_foods',
      legacyText: 'calcium-rich foods',
      en: 'calcium-rich foods',
      tr: 'kalsiyumdan zengin besinler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.chia_seeds',
      legacyText: 'chia seeds',
      en: 'chia seeds',
      tr: 'chia tohumu',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.chicken_breast',
      legacyText: 'chicken breast',
      en: 'chicken breast',
      tr: 'tavuk göğsü',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.cinnamon',
      legacyText: 'cinnamon',
      en: 'cinnamon',
      tr: 'tarçın',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.citrus_fruits',
      legacyText: 'citrus fruits',
      en: 'citrus fruits',
      tr: 'turunçgiller',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.coffee_without_sugar',
      legacyText: 'coffee without sugar',
      en: 'coffee without sugar',
      tr: 'şekersiz kahve',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.dairy_or_fortified_alternatives',
      legacyText: 'dairy or fortified alternatives',
      en: 'dairy or fortified alternatives',
      tr: 'süt ürünleri veya zenginleştirilmiş alternatifler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.dairy_products',
      legacyText: 'dairy products',
      en: 'dairy products',
      tr: 'süt ürünleri',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.dehydration',
      legacyText: 'dehydration',
      en: 'dehydration',
      tr: 'susuz kalma',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.desserts',
      legacyText: 'desserts',
      en: 'desserts',
      tr: 'tatlılar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.eggs',
      legacyText: 'eggs',
      en: 'eggs',
      tr: 'yumurta',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.excess_alcohol',
      legacyText: 'excess alcohol',
      en: 'excess alcohol',
      tr: 'aşırı alkol',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.excess_sodium',
      legacyText: 'excess sodium',
      en: 'excess sodium',
      tr: 'fazla sodyum',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.excess_sugar',
      legacyText: 'excess sugar',
      en: 'excess sugar',
      tr: 'fazla şeker',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.excessive_red_meat',
      legacyText: 'excessive red meat',
      en: 'excessive red meat',
      tr: 'aşırı kırmızı et tüketimi',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.fast_food',
      legacyText: 'fast food',
      en: 'fast food',
      tr: 'ayaküstü hazır yiyecekler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.fatty_fish',
      legacyText: 'fatty fish',
      en: 'fatty fish',
      tr: 'yağlı balıklar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.fatty_red_meat',
      legacyText: 'fatty red meat',
      en: 'fatty red meat',
      tr: 'yağlı kırmızı et',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.fiber_rich_foods',
      legacyText: 'fiber-rich foods',
      en: 'fiber-rich foods',
      tr: 'liften zengin besinler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.fish',
      legacyText: 'fish',
      en: 'fish',
      tr: 'balık',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.flaxseed',
      legacyText: 'flaxseed',
      en: 'flaxseed',
      tr: 'keten tohumu',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.fortified_dairy',
      legacyText: 'fortified dairy',
      en: 'fortified dairy',
      tr: 'zenginleştirilmiş süt ürünleri',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.frequent_fast_food',
      legacyText: 'frequent fast food',
      en: 'frequent fast food',
      tr: 'sık ayaküstü hazır yiyecek tüketimi',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.fresh_fruits',
      legacyText: 'fresh fruits',
      en: 'fresh fruits',
      tr: 'taze meyveler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.fresh_vegetables',
      legacyText: 'fresh vegetables',
      en: 'fresh vegetables',
      tr: 'taze sebzeler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.fried_foods',
      legacyText: 'fried foods',
      en: 'fried foods',
      tr: 'kızartmalar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.fruits',
      legacyText: 'fruits',
      en: 'fruits',
      tr: 'meyveler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.healthy_fats',
      legacyText: 'healthy fats',
      en: 'healthy fats',
      tr: 'sağlıklı yağlar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.herbs',
      legacyText: 'herbs',
      en: 'herbs',
      tr: 'taze otlar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.high_calorie_fast_food',
      legacyText: 'high-calorie fast food',
      en: 'high-calorie fast food',
      tr: 'yüksek kalorili ayaküstü hazır yiyecekler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.high_calorie_snacks',
      legacyText: 'high-calorie snacks',
      en: 'high-calorie snacks',
      tr: 'yüksek kalorili atıştırmalıklar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.high_dose_protein_supplements_without_clinical_advice',
      legacyText: 'high-dose protein supplements without clinical advice',
      en: 'high-dose protein supplements without clinical advice',
      tr: 'klinik öneri olmadan yüksek doz protein takviyeleri',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.high_fat_dairy',
      legacyText: 'high-fat dairy',
      en: 'high-fat dairy',
      tr: 'tam yağlı süt ürünleri',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.high_fiber_foods',
      legacyText: 'high-fiber foods',
      en: 'high-fiber foods',
      tr: 'yüksek lifli besinler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.high_fiber_vegetables',
      legacyText: 'high-fiber vegetables',
      en: 'high-fiber vegetables',
      tr: 'yüksek lifli sebzeler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.high_sodium_foods',
      legacyText: 'high-sodium foods',
      en: 'high-sodium foods',
      tr: 'yüksek sodyumlu gıdalar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.high_sodium_packaged_foods',
      legacyText: 'high-sodium packaged foods',
      en: 'high-sodium packaged foods',
      tr: 'yüksek sodyumlu paketli gıdalar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.instant_soups',
      legacyText: 'instant soups',
      en: 'instant soups',
      tr: 'hazır çorbalar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.large_portions',
      legacyText: 'large portions',
      en: 'large portions',
      tr: 'büyük porsiyonlar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.leafy_greens',
      legacyText: 'leafy greens',
      en: 'leafy greens',
      tr: 'koyu yeşil yapraklı sebzeler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.lean_meat',
      legacyText: 'lean meat',
      en: 'lean meat',
      tr: 'yağsız et',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.lean_meats',
      legacyText: 'lean meats',
      en: 'lean meats',
      tr: 'yağsız etler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.lean_protein',
      legacyText: 'lean protein',
      en: 'lean protein',
      tr: 'yağsız protein',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.lean_red_meat',
      legacyText: 'lean red meat',
      en: 'lean red meat',
      tr: 'yağsız kırmızı et',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.legumes',
      legacyText: 'legumes',
      en: 'legumes',
      tr: 'baklagiller',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.lemon',
      legacyText: 'lemon',
      en: 'lemon',
      tr: 'limon',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.lentils',
      legacyText: 'lentils',
      en: 'lentils',
      tr: 'mercimek',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.low_fat_dairy',
      legacyText: 'low-fat dairy',
      en: 'low-fat dairy',
      tr: 'az yağlı süt ürünleri',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.low_fat_yogurt',
      legacyText: 'low-fat yogurt',
      en: 'low-fat yogurt',
      tr: 'az yağlı yoğurt',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.low_fiber_processed_snacks',
      legacyText: 'low-fiber processed snacks',
      en: 'low-fiber processed snacks',
      tr: 'düşük lifli işlenmiş atıştırmalıklar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.low_fiber_refined_grains',
      legacyText: 'low-fiber refined grains',
      en: 'low-fiber refined grains',
      tr: 'düşük lifli rafine tahıllar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.margarine',
      legacyText: 'margarine',
      en: 'margarine',
      tr: 'margarin',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.meal_skipping',
      legacyText: 'meal skipping',
      en: 'meal skipping',
      tr: 'öğün atlama',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.nutrient_poor_processed_foods',
      legacyText: 'nutrient-poor processed foods',
      en: 'nutrient-poor processed foods',
      tr: 'besin değeri düşük işlenmiş gıdalar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.nuts',
      legacyText: 'nuts',
      en: 'nuts',
      tr: 'kuruyemişler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.oats',
      legacyText: 'oats',
      en: 'oats',
      tr: 'yulaf',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.olive_oil',
      legacyText: 'olive oil',
      en: 'olive oil',
      tr: 'zeytinyağı',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.omega_3_rich_foods',
      legacyText: 'omega-3 rich foods',
      en: 'omega-3 rich foods',
      tr: 'omega-3 açısından zengin besinler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.packaged_snacks',
      legacyText: 'packaged snacks',
      en: 'packaged snacks',
      tr: 'paketli atıştırmalıklar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.pastries',
      legacyText: 'pastries',
      en: 'pastries',
      tr: 'hamur işleri',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.pickles',
      legacyText: 'pickles',
      en: 'pickles',
      tr: 'turşu',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.processed_foods',
      legacyText: 'processed foods',
      en: 'processed foods',
      tr: 'işlenmiş gıdalar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.processed_meat',
      legacyText: 'processed meat',
      en: 'processed meat',
      tr: 'işlenmiş et',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.processed_meats',
      legacyText: 'processed meats',
      en: 'processed meats',
      tr: 'işlenmiş etler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.protein_rich_foods',
      legacyText: 'protein-rich foods',
      en: 'protein-rich foods',
      tr: 'proteinden zengin besinler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.quinoa',
      legacyText: 'quinoa',
      en: 'quinoa',
      tr: 'kinoa',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.refined_carbohydrates',
      legacyText: 'refined carbohydrates',
      en: 'refined carbohydrates',
      tr: 'rafine karbonhidratlar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.refined_carbs',
      legacyText: 'refined carbs',
      en: 'refined carbs',
      tr: 'rafine karbonhidratlar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.refined_grains',
      legacyText: 'refined grains',
      en: 'refined grains',
      tr: 'rafine tahıllar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.salty_snacks',
      legacyText: 'salty snacks',
      en: 'salty snacks',
      tr: 'tuzlu atıştırmalıklar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.saturated_fat',
      legacyText: 'saturated fat',
      en: 'saturated fat',
      tr: 'doymuş yağ',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.soft_drinks',
      legacyText: 'soft drinks',
      en: 'soft drinks',
      tr: 'gazlı içecekler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.spinach',
      legacyText: 'spinach',
      en: 'spinach',
      tr: 'ıspanak',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.sugary_cereals',
      legacyText: 'sugary cereals',
      en: 'sugary cereals',
      tr: 'şekerli kahvaltılık gevrekler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.sugary_drinks',
      legacyText: 'sugary drinks',
      en: 'sugary drinks',
      tr: 'şekerli içecekler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.sugary_foods',
      legacyText: 'sugary foods',
      en: 'sugary foods',
      tr: 'şekerli gıdalar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.tea_or_coffee_immediately_with_iron_containing_meals',
      legacyText: 'tea or coffee immediately with iron-containing meals',
      en: 'tea or coffee immediately with iron-containing meals',
      tr: 'demir içeren öğünlerle birlikte veya hemen sonrasında çay ya da kahve',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.tea_or_coffee_immediately_with_iron_rich_meals',
      legacyText: 'tea or coffee immediately with iron-rich meals',
      en: 'tea or coffee immediately with iron-rich meals',
      tr: 'demirden zengin öğünlerle birlikte veya hemen sonrasında çay ya da kahve',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.trans_fats',
      legacyText: 'trans fats',
      en: 'trans fats',
      tr: 'trans yağlar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.ultra_processed_foods',
      legacyText: 'ultra-processed foods',
      en: 'ultra-processed foods',
      tr: 'ultra işlenmiş gıdalar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.vegetables',
      legacyText: 'vegetables',
      en: 'vegetables',
      tr: 'sebzeler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.very_low_calorie_diets',
      legacyText: 'very low-calorie diets',
      en: 'very low-calorie diets',
      tr: 'çok düşük kalorili diyetler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.very_restrictive_diets',
      legacyText: 'very restrictive diets',
      en: 'very restrictive diets',
      tr: 'çok kısıtlayıcı diyetler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.vitamin_c_foods',
      legacyText: 'vitamin C foods',
      en: 'vitamin C foods',
      tr: 'C vitamini içeren besinler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.vitamin_d_foods',
      legacyText: 'vitamin D foods',
      en: 'vitamin D foods',
      tr: 'D vitamini içeren besinler',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.walnuts',
      legacyText: 'walnuts',
      en: 'walnuts',
      tr: 'ceviz',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.water',
      legacyText: 'water',
      en: 'water',
      tr: 'su',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.white_bread',
      legacyText: 'white bread',
      en: 'white bread',
      tr: 'beyaz ekmek',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.white_rice',
      legacyText: 'white rice',
      en: 'white rice',
      tr: 'beyaz pirinç',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.whole_grains',
      legacyText: 'whole grains',
      en: 'whole grains',
      tr: 'tam tahıllar',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.whole_wheat_bread',
      legacyText: 'whole wheat bread',
      en: 'whole wheat bread',
      tr: 'tam buğday ekmeği',
    ),
    ProfileSummaryCatalogEntry(
      code: 'food.yogurt',
      legacyText: 'yogurt',
      en: 'yogurt',
      tr: 'yoğurt',
    ),
  ];

  static const interpretationWarnings = <ProfileSummaryCatalogEntry>[
    ProfileSummaryCatalogEntry(
      code: 'warning.reference_intervals_vary',
      legacyText:
          'Reference intervals vary by laboratory, method, age, sex, pregnancy status, and clinical context.',
      en: 'Reference intervals vary by laboratory, method, age, sex, pregnancy status, and clinical context.',
      tr: 'Referans aralıkları laboratuvara, yönteme, yaşa, biyolojik cinsiyete, gebelik durumuna ve klinik bağlama göre değişir.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'warning.glucose_fasting_status_unknown',
      legacyText:
          'The glucose threshold assumes a fasting sample; fasting status cannot be reliably inferred from every PDF.',
      en: 'The glucose threshold assumes a fasting sample; fasting status cannot be reliably inferred from every PDF.',
      tr: 'Glukoz için kullanılan eşik, kan örneğinin açlık durumunda alındığı varsayımına dayanır; açlık durumu her PDF raporundan güvenilir biçimde belirlenemez.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'warning.hba1c_clinical_factors',
      legacyText:
          'HbA1c can be affected by anemia, kidney or liver disease, blood disorders, pregnancy, blood loss, or transfusion.',
      en: 'HbA1c can be affected by anemia, kidney or liver disease, blood disorders, pregnancy, blood loss, or transfusion.',
      tr: 'HbA1c; anemi, böbrek veya karaciğer hastalığı, kan hastalıkları, gebelik, kan kaybı ya da kan transfüzyonundan etkilenebilir.',
    ),
    ProfileSummaryCatalogEntry(
      code: 'warning.egfr_single_result_not_diagnostic',
      legacyText:
          'A single eGFR below 60 does not establish chronic kidney disease; persistence and urine markers matter.',
      en: 'A single eGFR below 60 does not establish chronic kidney disease; persistence and urine markers matter.',
      tr: 'Tek bir eGFR değerinin 60’ın altında olması, tek başına kronik böbrek hastalığı tanısı koydurmaz; düşük değerin kalıcı olup olmadığı ve idrar belirteçleri önemlidir.',
    ),
  ];
}
