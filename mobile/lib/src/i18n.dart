import 'package:flutter/widgets.dart';

enum AppLanguage {
  en('en'),
  tr('tr');

  const AppLanguage(this.code);

  final String code;

  static AppLanguage fromCode(String? code) {
    return code == AppLanguage.tr.code ? AppLanguage.tr : AppLanguage.en;
  }
}

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  bool get isTr => language == AppLanguage.tr;

  String t(String key) {
    return _values[language]?[key] ?? _values[AppLanguage.en]?[key] ?? key;
  }

  String allergy(String id) {
    return _allergies[language]?[id] ?? _allergies[AppLanguage.en]?[id] ?? id;
  }

  String decision(String value) {
    final key = switch (value) {
      'not_recommended' => 'decisionNotRecommended',
      'use_with_caution' => 'decisionCaution',
      _ => 'decisionRecommended',
    };
    return t(key);
  }

  String reason(Map<String, dynamic> reason) {
    final code = reason['code']?.toString() ?? '';
    final value = reason['value'] == null ? '' : ' (${reason['value']})';
    return switch (code) {
      'allergy_conflict' =>
        '${t('reasonAllergyConflict')}: ${(reason['allergens'] as List?)?.join(', ') ?? ''}',
      'high_sugar_blood_sugar' => '${t('reasonHighSugarBlood')}$value',
      'moderate_sugar_blood_sugar' => '${t('reasonModerateSugar')}$value',
      'very_high_saturated_fat_lipid' => '${t('reasonVeryHighSatFat')}$value',
      'high_saturated_fat_lipid' => '${t('reasonSatFat')}$value',
      'high_salt_bp_kidney' => t('reasonHighSalt'),
      'moderate_salt_bp_kidney' => t('reasonModerateSalt'),
      'high_energy_weight' => '${t('reasonHighEnergy')}$value',
      'ultra_processed_diet' => t('reasonUltraProcessed'),
      'low_fiber_diet' => '${t('reasonLowFiber')}$value',
      'high_protein_kidney' => '${t('reasonHighProtein')}$value',
      _ => code,
    };
  }

  String alternative(Map<String, dynamic> item) {
    return switch (item['code']?.toString()) {
      'allergy_safe_same_category' => t('altAllergySafe'),
      'low_sugar_snack' => t('altLowSugar'),
      'unsalted_option' => t('altUnsalted'),
      'unsaturated_fat_option' => t('altUnsaturatedFat'),
      'high_fiber_option' => t('altHighFiber'),
      'balanced_protein_option' => t('altBalancedProtein'),
      _ => t('altWholeFood'),
    };
  }

  String profileText(String value) {
    if (!isTr || value.trim().isEmpty) return value;
    var result = value;
    for (final entry in _profileReplacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  String foodText(String value) {
    if (!isTr || value.trim().isEmpty) return value;
    var result = value;
    for (final entry in _foodReplacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }
}

class AppScope extends InheritedWidget {
  const AppScope({
    required this.language,
    required this.strings,
    required super.child,
    super.key,
  });

  final AppLanguage language;
  final AppStrings strings;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing from the widget tree.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return language != oldWidget.language;
  }
}

const _values = {
  AppLanguage.en: {
    'appTitle': 'BioDietix',
    'home': 'Home',
    'profile': 'Profile',
    'tests': 'Tests',
    'scan': 'Scan',
    'settings': 'Settings',
    'biodietixMobile': 'BIODIETIX MOBILE',
    'personalNutritionEngine': 'PERSONAL NUTRITION ENGINE',
    'authHeroTitle': 'Personal nutrition decisions from your latest labs',
    'authHeroSubtitle':
        'Sign in securely, add your profile once, upload blood/allergy reports, then scan products in the market.',
    'firebaseMissingTitle': 'Firebase setup required',
    'firebaseMissingMessage':
        'This APK was built without Firebase configuration. Add the Firebase Android values and rebuild so users can sign in.',
    'email': 'Email',
    'password': 'Password',
    'signIn': 'Sign in',
    'createAccount': 'Create account',
    'createNewAccount': 'Create a new account',
    'alreadyHaveAccount': 'I already have an account',
    'authenticationFailed': 'Authentication failed.',
    'homeHeroTitle': 'Scan food against your own labs',
    'homeHeroSubtitle':
        'BioDietix keeps body measurements, allergies, and latest lab memory on the phone. Product checks use that profile until a newer PDF is uploaded.',
    'currentProfile': 'Current profile',
    'noBloodAnalyzed': 'No blood test has been analyzed yet.',
    'latestExtractedValues': 'Latest extracted values',
    'healthProfile': 'Health profile',
    'nutritionRecommendation': 'Nutrition recommendation',
    'foodsToIncrease': 'Foods to increase',
    'foodsToLimit': 'Foods to limit',
    'allergies': 'Allergies',
    'notAvailable': 'Not available',
    'profileSubtitle':
        'Saved on this phone after sign-in. Health files stay available until you replace or delete them.',
    'gender': 'Gender',
    'female': 'Female',
    'male': 'Male',
    'age': 'Age',
    'weightKg': 'Weight (kg)',
    'heightCm': 'Height (cm)',
    'knownAllergies': 'Known allergies',
    'saveProfile': 'Save profile to phone',
    'profileSaved': 'Profile saved on this phone.',
    'healthDataCleared': 'Health data deleted from this phone.',
    'deleteHealthData': 'Delete health data',
    'signOut': 'Sign out',
    'testsSubtitle':
        'Upload a blood test PDF to refresh the current profile. Upload allergy PDF if available.',
    'uploadBloodPdf': 'Upload blood test PDF',
    'uploadAllergyPdf': 'Upload allergy test PDF',
    'currentAllergies': 'Current allergies',
    'noAllergiesSaved': 'No allergies saved yet.',
    'pdfTextPreview': 'PDF text preview',
    'bloodAnalyzed': 'Blood test analyzed. Latest profile memory updated.',
    'bloodPdfFailed': 'Blood PDF failed',
    'allergyPdfFailed': 'Allergy PDF failed',
    'allergySignalsDetected': 'allergy signal(s) detected.',
    'serverNotConfigured':
        'BioDietix server is not configured. Build the APK with a public HTTPS API URL.',
    'productScanner': 'Product scanner',
    'productScannerSubtitle':
        'Scan a market product and evaluate it against the latest blood/allergy profile.',
    'bloodRequired':
        'Blood test profile required before personal product checks.',
    'openCameraScanner': 'Open camera scanner',
    'barcodeQrValue': 'Barcode / QR value',
    'lookUpProduct': 'Look up product',
    'productDetails': 'Product details',
    'name': 'Name',
    'category': 'Category',
    'ingredients': 'Ingredients',
    'declaredAllergens': 'Declared allergens',
    'sugar100': 'Sugar g/100g',
    'satFat100': 'Sat. fat g/100g',
    'salt100': 'Salt g/100g',
    'energy100': 'Energy kcal/100g',
    'protein100': 'Protein g/100g',
    'fiber100': 'Fiber g/100g',
    'sodium100': 'Sodium mg/100g',
    'evaluateProduct': 'Evaluate product',
    'scanBarcodeFirst': 'Scan or enter a barcode first.',
    'productFound': 'Product found.',
    'productLookupFailed': 'Product lookup failed',
    'uploadBloodFirst': 'Upload a blood test PDF first.',
    'productEvaluationFailed': 'Product evaluation failed',
    'closeScanner': 'Close scanner',
    'decision': 'Decision',
    'reasons': 'Reasons',
    'betterAlternatives': 'Better alternatives',
    'educationalOnly':
        'Educational guidance only. This is not medical diagnosis.',
    'decisionRecommended': 'Recommended',
    'decisionCaution': 'Use with caution',
    'decisionNotRecommended': 'Not recommended',
    'reasonAllergyConflict': 'Allergy conflict',
    'reasonHighSugarBlood': 'High sugar for blood sugar risk',
    'reasonModerateSugar': 'Sugar should be limited for this profile',
    'reasonVeryHighSatFat': 'Very high saturated fat for lipid risk',
    'reasonSatFat': 'Saturated fat should be limited',
    'reasonHighSalt':
        'High salt/sodium for blood pressure or kidney-related risk',
    'reasonModerateSalt': 'Salt/sodium should be limited',
    'reasonHighEnergy': 'High energy density for weight management',
    'reasonUltraProcessed':
        'Ingredient list suggests an ultra-processed product',
    'reasonLowFiber': 'Low fiber for diet-quality risk',
    'reasonHighProtein': 'High protein for kidney/creatinine-related findings',
    'altAllergySafe': 'Choose an allergen-free product in the same category.',
    'altLowSugar':
        'Prefer whole fruit, unsweetened yogurt, or a low-sugar whole-grain option.',
    'altUnsalted': 'Prefer an unsalted or low-sodium version.',
    'altUnsaturatedFat':
        'Prefer olive oil, avocado, fish, or allergy-safe nuts.',
    'altHighFiber': 'Choose legumes, vegetables, oats, whole grains, or fruit.',
    'altBalancedProtein': 'Prefer moderate protein portions.',
    'altWholeFood': 'Prefer a simpler whole-food alternative.',
    'settingsSubtitle':
        'Control language, appearance, account, and server status.',
    'language': 'Language',
    'english': 'English',
    'turkish': 'Turkish',
    'appearance': 'Appearance',
    'system': 'System',
    'light': 'Light',
    'dark': 'Dark',
    'server': 'Server',
    'serverSubtitle':
        'The phone app needs a public BioDietix API. Emulator/private computer addresses do not work for other users.',
    'productionApiUrl': 'Production API URL',
    'notConfigured': 'Not configured',
    'checkApiConnection': 'Check API connection',
    'apiConnected': 'API connected',
    'apiConnectionFailed': 'API connection failed',
    'account': 'Account',
    'signedInAs': 'Signed in as',
  },
  AppLanguage.tr: {
    'appTitle': 'BioDietix',
    'home': 'Ana Sayfa',
    'profile': 'Profil',
    'tests': 'Testler',
    'scan': 'Tara',
    'settings': 'Ayarlar',
    'biodietixMobile': 'BIODIETIX MOBIL',
    'personalNutritionEngine': 'KISISEL BESLENME MOTORU',
    'authHeroTitle': 'Son testlerine göre kişisel beslenme kararları',
    'authHeroSubtitle':
        'Güvenli giriş yap, profilini bir kez ekle, kan/alerji raporlarını yükle ve market ürünlerini tara.',
    'firebaseMissingTitle': 'Firebase kurulumu gerekli',
    'firebaseMissingMessage':
        'Bu APK Firebase yapılandırması olmadan derlenmiş. Kullanıcıların giriş yapabilmesi için Firebase Android değerlerini ekleyip yeniden build al.',
    'email': 'E-posta',
    'password': 'Şifre',
    'signIn': 'Giriş yap',
    'createAccount': 'Hesap oluştur',
    'createNewAccount': 'Yeni hesap oluştur',
    'alreadyHaveAccount': 'Zaten hesabım var',
    'authenticationFailed': 'Kimlik doğrulama başarısız.',
    'homeHeroTitle': 'Yiyecekleri kendi testlerine göre tara',
    'homeHeroSubtitle':
        'BioDietix boy, kilo, alerji ve son test hafızasını telefonda tutar. Yeni PDF yüklenene kadar ürün kontrolleri bu profile göre yapılır.',
    'currentProfile': 'Güncel profil',
    'noBloodAnalyzed': 'Henüz kan testi analiz edilmedi.',
    'latestExtractedValues': 'Son çıkarılan değerler',
    'healthProfile': 'Sağlık profili',
    'nutritionRecommendation': 'Beslenme önerisi',
    'foodsToIncrease': 'Artırılması önerilen besinler',
    'foodsToLimit': 'Sınırlandırılması önerilen besinler',
    'allergies': 'Alerjiler',
    'notAvailable': 'Mevcut değil',
    'profileSubtitle':
        'Girişten sonra bu telefonda saklanır. Sağlık dosyaları değiştirene veya silene kadar korunur.',
    'gender': 'Cinsiyet',
    'female': 'Kadın',
    'male': 'Erkek',
    'age': 'Yaş',
    'weightKg': 'Kilo (kg)',
    'heightCm': 'Boy (cm)',
    'knownAllergies': 'Bilinen alerjiler',
    'saveProfile': 'Profili telefona kaydet',
    'profileSaved': 'Profil bu telefona kaydedildi.',
    'healthDataCleared': 'Sağlık verileri bu telefondan silindi.',
    'deleteHealthData': 'Sağlık verilerini sil',
    'signOut': 'Çıkış yap',
    'testsSubtitle':
        'Güncel profili yenilemek için kan testi PDF’i yükle. Varsa alerji PDF’i de ekle.',
    'uploadBloodPdf': 'Kan testi PDF’i yükle',
    'uploadAllergyPdf': 'Alerji testi PDF’i yükle',
    'currentAllergies': 'Güncel alerjiler',
    'noAllergiesSaved': 'Henüz alerji kaydedilmedi.',
    'pdfTextPreview': 'PDF metin önizlemesi',
    'bloodAnalyzed':
        'Kan testi analiz edildi. Son profil hafızası güncellendi.',
    'bloodPdfFailed': 'Kan PDF’i başarısız',
    'allergyPdfFailed': 'Alerji PDF’i başarısız',
    'allergySignalsDetected': 'alerji sinyali bulundu.',
    'serverNotConfigured':
        'BioDietix sunucusu yapılandırılmamış. APK’yı herkese açık HTTPS API adresiyle build et.',
    'productScanner': 'Ürün tarayıcı',
    'productScannerSubtitle':
        'Market ürününü tara ve son kan/alerji profiline göre değerlendir.',
    'bloodRequired':
        'Kişisel ürün kontrolü için önce kan testi profili gerekir.',
    'openCameraScanner': 'Kamera tarayıcıyı aç',
    'barcodeQrValue': 'Barkod / QR değeri',
    'lookUpProduct': 'Ürünü bul',
    'productDetails': 'Ürün detayları',
    'name': 'Ad',
    'category': 'Kategori',
    'ingredients': 'İçindekiler',
    'declaredAllergens': 'Beyan edilen alerjenler',
    'sugar100': 'Şeker g/100g',
    'satFat100': 'Doymuş yağ g/100g',
    'salt100': 'Tuz g/100g',
    'energy100': 'Enerji kcal/100g',
    'protein100': 'Protein g/100g',
    'fiber100': 'Lif g/100g',
    'sodium100': 'Sodyum mg/100g',
    'evaluateProduct': 'Ürünü değerlendir',
    'scanBarcodeFirst': 'Önce barkod tara veya gir.',
    'productFound': 'Ürün bulundu.',
    'productLookupFailed': 'Ürün arama başarısız',
    'uploadBloodFirst': 'Önce kan testi PDF’i yükle.',
    'productEvaluationFailed': 'Ürün değerlendirme başarısız',
    'closeScanner': 'Tarayıcıyı kapat',
    'decision': 'Karar',
    'reasons': 'Nedenler',
    'betterAlternatives': 'Daha iyi alternatifler',
    'educationalOnly': 'Sadece eğitim amaçlıdır. Tıbbi teşhis değildir.',
    'decisionRecommended': 'Önerilir',
    'decisionCaution': 'Dikkatli tüket',
    'decisionNotRecommended': 'Önerilmez',
    'reasonAllergyConflict': 'Alerji uyumsuzluğu',
    'reasonHighSugarBlood': 'Kan şekeri riski için yüksek şeker',
    'reasonModerateSugar': 'Bu profil için şeker sınırlandırılmalı',
    'reasonVeryHighSatFat': 'Lipit riski için çok yüksek doymuş yağ',
    'reasonSatFat': 'Doymuş yağ sınırlandırılmalı',
    'reasonHighSalt':
        'Tansiyon veya böbrek ilişkili risk için yüksek tuz/sodyum',
    'reasonModerateSalt': 'Tuz/sodyum sınırlandırılmalı',
    'reasonHighEnergy': 'Kilo yönetimi için yüksek enerji yoğunluğu',
    'reasonUltraProcessed': 'İçerik listesi aşırı işlenmiş ürüne işaret ediyor',
    'reasonLowFiber': 'Beslenme kalitesi riski için düşük lif',
    'reasonHighProtein': 'Böbrek/kreatinin bulguları için yüksek protein',
    'altAllergySafe': 'Aynı kategoride alerjen içermeyen bir ürün seç.',
    'altLowSugar':
        'Tam meyve, şekersiz yoğurt veya düşük şekerli tam tahıllı seçenek tercih et.',
    'altUnsalted': 'Tuzsuz veya düşük sodyumlu seçenek tercih et.',
    'altUnsaturatedFat':
        'Zeytinyağı, avokado, balık veya alerjiye uygun kuruyemiş tercih et.',
    'altHighFiber': 'Baklagil, sebze, yulaf, tam tahıl veya meyve seç.',
    'altBalancedProtein': 'Orta porsiyon protein tercih et.',
    'altWholeFood': 'Daha sade, işlenmemiş bir alternatif tercih et.',
    'settingsSubtitle': 'Dil, görünüm, hesap ve sunucu durumunu yönet.',
    'language': 'Dil',
    'english': 'İngilizce',
    'turkish': 'Türkçe',
    'appearance': 'Görünüm',
    'system': 'Sistem',
    'light': 'Açık',
    'dark': 'Koyu',
    'server': 'Sunucu',
    'serverSubtitle':
        'Telefon uygulaması herkese açık BioDietix API gerektirir. Emülatör veya kişisel bilgisayar adresleri diğer kullanıcılarda çalışmaz.',
    'productionApiUrl': 'Production API adresi',
    'notConfigured': 'Yapılandırılmadı',
    'checkApiConnection': 'API bağlantısını kontrol et',
    'apiConnected': 'API bağlı',
    'apiConnectionFailed': 'API bağlantısı başarısız',
    'account': 'Hesap',
    'signedInAs': 'Giriş yapılan hesap',
  },
};

const _allergies = {
  AppLanguage.en: {
    'milk': 'Milk / dairy',
    'gluten': 'Gluten / wheat',
    'peanut': 'Peanut',
    'tree_nut': 'Tree nuts',
    'egg': 'Egg',
    'soy': 'Soy',
    'fish': 'Fish',
    'shellfish': 'Shellfish',
    'sesame': 'Sesame',
  },
  AppLanguage.tr: {
    'milk': 'Süt / süt ürünleri',
    'gluten': 'Gluten / buğday',
    'peanut': 'Yer fıstığı',
    'tree_nut': 'Kuruyemiş',
    'egg': 'Yumurta',
    'soy': 'Soya',
    'fish': 'Balık',
    'shellfish': 'Kabuklu deniz ürünü',
    'sesame': 'Susam',
  },
};

const _profileReplacements = {
  'Low Risk': 'Düşük Risk',
  'Cardiovascular Lipid Risk': 'Kardiyovasküler Lipit Riski',
  'Kidney / Muscle Marker': 'Böbrek / Kas Göstergesi',
  'Kidney / Muscle Indicator': 'Böbrek / Kas Göstergesi',
  'Thyroid / Metabolism Indicator': 'Tiroid / Metabolizma Göstergesi',
  'Blood Sugar / Insulin Resistance Risk': 'Kan Şekeri / İnsülin Direnci Riski',
  'Inflammation / Immune Indicator': 'Enflamasyon / Bağışıklık Göstergesi',
  'Weight Management Focus': 'Kilo Yönetimi Odağı',
  'Blood Pressure / Kidney Risk': 'Tansiyon / Böbrek Riski',
};

const _foodReplacements = {
  'For this age group, build long-term habits with regular meals, adequate protein, fiber, and physical activity.':
      'Bu yaş grubu için düzenli öğünler, yeterli protein, lif ve fiziksel aktiviteyle uzun vadeli alışkanlıklar oluştur.',
  'balanced meals': 'dengeli öğünler',
  'lean protein': 'yağsız protein',
  'whole grains': 'tam tahıllar',
  'vegetables': 'sebzeler',
  'fruits': 'meyveler',
  'frequent fast food': 'sık fast food tüketimi',
  'sugary drinks': 'şekerli içecekler',
  'meal skipping': 'öğün atlama',
  'olive oil': 'zeytinyağı',
  'nuts': 'kuruyemişler',
  'fish': 'balık',
  'avocado': 'avokado',
  'fiber-rich foods': 'lifli besinler',
  'fresh vegetables': 'taze sebzeler',
  'water': 'su',
  'processed meats': 'işlenmiş etler',
  'fried foods': 'kızartmalar',
  'trans fats': 'trans yağlar',
  'sugary foods': 'şekerli gıdalar',
  'high-sodium foods': 'yüksek sodyumlu gıdalar',
  'refined grains': 'rafine tahıllar',
  'margarine': 'margarin',
  'fatty red meat': 'yağlı kırmızı et',
};
