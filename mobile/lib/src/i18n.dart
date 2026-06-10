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
      'nutrition_data_missing' => t('reasonNutritionMissing'),
      'very_high_sugar_product' => '${t('reasonVeryHighSugarProduct')}$value',
      'high_sugar_product' => '${t('reasonHighSugarProduct')}$value',
      'moderate_sugar_product' => '${t('reasonModerateSugarProduct')}$value',
      'very_high_saturated_fat_product' =>
        '${t('reasonVeryHighSatFatProduct')}$value',
      'high_saturated_fat_product' => '${t('reasonSatFatProduct')}$value',
      'high_salt_product' => t('reasonHighSaltProduct'),
      'moderate_salt_product' => t('reasonModerateSaltProduct'),
      'very_high_energy_product' => '${t('reasonVeryHighEnergyProduct')}$value',
      'high_energy_product' => '${t('reasonHighEnergyProduct')}$value',
      'ultra_processed_product' => '${t('reasonUltraProcessedProduct')}$value',
      'poor_nutrition_grade' => '${t('reasonPoorNutritionGrade')}$value',
      'low_fiber_product' => '${t('reasonLowFiberProduct')}$value',
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

  String positive(Map<String, dynamic> item) {
    final code = item['code']?.toString() ?? '';
    final value = item['value'] == null ? '' : ' (${item['value']})';
    return switch (code) {
      'good_fiber' => '${t('positiveGoodFiber')}$value',
      'good_protein' => '${t('positiveGoodProtein')}$value',
      'low_sugar' => '${t('positiveLowSugar')}$value',
      'low_salt' => '${t('positiveLowSalt')}$value',
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
    'splashSubtitle': 'Personal nutrition from labs, allergies, and food data.',
    'splashChecking': 'Checking internet, session, and local Hive data...',
    'onboardLabsTitle': 'Turn lab results into daily nutrition context',
    'onboardLabsBody':
        'Upload blood and allergy reports to build a profile that stays available on this phone.',
    'onboardScanTitle': 'Evaluate packaged food before you buy',
    'onboardScanBody':
        'Scan a barcode or enter product details to compare nutrition signals with your latest profile.',
    'onboardOfflineTitle': 'Works with local cache when connection drops',
    'onboardOfflineBody':
        'Theme, language, onboarding status, profile memory, and key dashboard data are stored with Hive.',
    'onboardingNext': 'Next',
    'onboardingStart': 'Start',
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
    'forgotPassword': 'Forgot password',
    'sendResetLink': 'Send reset link',
    'backToSignIn': 'Back to sign in',
    'passwordResetSent': 'Password reset email sent.',
    'emailRequired': 'Email is required.',
    'or': 'OR',
    'continueWithGoogle': 'Continue with Google',
    'authenticationFailed': 'Authentication failed.',
    'firebaseAuthConfigError':
        'Firebase Authentication is not fully configured. Enable Email/Password and Google providers in Firebase Console, add Android SHA-1/SHA-256 fingerprints, then download the updated google-services.json.',
    'googleSignInFailed': 'Google sign-in failed',
    'googleSignInCanceled': 'Google sign-in was canceled.',
    'googleSignInUnavailable':
        'Google sign-in is not available on this device.',
    'googleMissingIdToken':
        'Google did not return an ID token. Check Firebase Google provider and Android SHA fingerprints.',
    'googleConfigError':
        'Google sign-in is not configured correctly. Enable Google provider and add Android SHA-1/SHA-256 fingerprints in Firebase.',
    'emailAlreadyInUse': 'This email address is already registered.',
    'invalidEmail': 'Enter a valid email address.',
    'weakPassword': 'Password must be at least 6 characters.',
    'wrongPassword': 'Email or password is incorrect.',
    'userNotFound': 'No account was found for this email.',
    'networkRequestFailed': 'Network connection failed. Try again.',
    'homeHeroTitle': 'Scan food against your own labs',
    'homeHeroSubtitle':
        'BioDietix keeps body measurements, allergies, and latest lab memory on the phone. Product checks use that profile until a newer PDF is uploaded.',
    'currentProfile': 'Current profile',
    'noBloodAnalyzed': 'No blood test has been analyzed yet.',
    'latestExtractedValues': 'Latest extracted values',
    'mealLogs': 'Meal logs',
    'mealLogsSubtitle':
        'Create, read, update, and delete daily nutrition notes stored in Firestore and cached in Hive.',
    'offlineCacheNotice':
        'Showing cached data because the online source is currently unavailable.',
    'addMealLog': 'Add meal log',
    'editMealLog': 'Edit meal log',
    'noMealLogs': 'No meal logs yet.',
    'mealTitle': 'Meal title',
    'mealTitleRequired': 'Meal title is required.',
    'mealNote': 'Note',
    'mealCalories': 'Calories',
    'kcal': 'kcal',
    'edit': 'Edit',
    'delete': 'Delete',
    'save': 'Save',
    'healthProfile': 'Health profile',
    'nutritionRecommendation': 'Nutrition recommendation',
    'foodsToIncrease': 'Foods to increase',
    'foodsToLimit': 'Foods to limit',
    'allergies': 'Allergies',
    'notAvailable': 'Not available',
    'profileSubtitle':
        'Saved on this phone after sign-in. Health files stay available until you replace or delete them.',
    'personalDetails': 'Personal details',
    'gender': 'Gender',
    'female': 'Female',
    'male': 'Male',
    'age': 'Age',
    'weightKg': 'Weight (kg)',
    'heightCm': 'Height (cm)',
    'knownAllergies': 'Known allergies',
    'saveProfile': 'Save profile to phone',
    'profileSaved': 'Profile saved on this phone.',
    'profileSavedInline':
        'Profile saved. These values will be used for the next blood PDF and product checks.',
    'profileSaveFailed': 'Profile could not be saved.',
    'healthDataCleared': 'Health data deleted from this phone.',
    'deleteHealthData': 'Delete health data',
    'signOut': 'Sign out',
    'testsSubtitle':
        'Upload a blood test PDF to refresh the current profile. Upload allergy PDF if available.',
    'labReports': 'Lab reports',
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
    'barcodeLookup': 'Barcode lookup',
    'bloodRequired':
        'Blood test profile required before personal product checks.',
    'openCameraScanner': 'Open camera scanner',
    'barcodeQrValue': 'Barcode / QR value',
    'lookUpProduct': 'Look up product',
    'productDetails': 'Product details',
    'name': 'Name',
    'brand': 'Brand',
    'quantity': 'Quantity',
    'category': 'Category',
    'ingredients': 'Ingredients',
    'declaredAllergens': 'Declared allergens',
    'labels': 'Labels',
    'servingSize': 'Serving size',
    'nutritionGrade': 'Nutri-Score',
    'novaGroup': 'NOVA group',
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
    'productLookupNotFound':
        'This barcode was not found in the online food database. You can enter the product details manually and evaluate it.',
    'manualProductHint':
        'If barcode lookup does not find the product, fill the visible fields from the label and continue with evaluation.',
    'uploadBloodFirst': 'Upload a blood test PDF first.',
    'productEvaluationFailed': 'Product evaluation failed',
    'closeScanner': 'Close scanner',
    'decision': 'Decision',
    'reasons': 'Reasons',
    'positiveSignals': 'Positive signals',
    'betterAlternatives': 'Better alternatives',
    'educationalOnly':
        'Educational guidance only. This is not medical diagnosis.',
    'decisionRecommended': 'Recommended',
    'decisionCaution': 'Use with caution',
    'decisionNotRecommended': 'Not recommended',
    'reasonAllergyConflict': 'Allergy conflict',
    'reasonNutritionMissing':
        'Nutrition data is missing, so this product should be evaluated cautiously',
    'reasonVeryHighSugarProduct': 'Very high sugar for a packaged food',
    'reasonHighSugarProduct': 'High sugar for a packaged food',
    'reasonModerateSugarProduct': 'Moderate sugar level',
    'reasonVeryHighSatFatProduct': 'Very high saturated fat',
    'reasonSatFatProduct': 'High saturated fat',
    'reasonHighSaltProduct': 'High salt/sodium',
    'reasonModerateSaltProduct': 'Moderate salt/sodium',
    'reasonVeryHighEnergyProduct': 'Very high energy density',
    'reasonHighEnergyProduct': 'High energy density',
    'reasonUltraProcessedProduct': 'NOVA score suggests ultra-processing',
    'reasonPoorNutritionGrade': 'Weak Nutri-Score grade',
    'reasonLowFiberProduct': 'Low fiber relative to sugar or energy',
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
    'positiveGoodFiber': 'Good fiber content',
    'positiveGoodProtein': 'Useful protein content',
    'positiveLowSugar': 'Low sugar',
    'positiveLowSalt': 'Low salt',
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
    'accountProfile': 'Account profile',
    'uploadPhotoGallery': 'Upload photo from gallery',
    'uploadPhotoCamera': 'Take profile photo',
    'profilePhotoUpdated': 'Profile photo updated.',
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
    'flavor': 'Flavor',
    'notConfigured': 'Not configured',
    'checkApiConnection': 'Check API connection',
    'apiConnected': 'API connected',
    'apiConnectionFailed': 'API connection failed',
    'account': 'Account',
    'signedInAs': 'Signed in as',
  },
  AppLanguage.tr: {
    'appTitle': 'BioDietix',
    'splashSubtitle':
        'Testler, alerjiler ve gıda verilerinden kişisel beslenme.',
    'splashChecking':
        'Internet, oturum ve yerel Hive verileri kontrol ediliyor...',
    'onboardLabsTitle': 'Test sonuçlarını günlük beslenme bağlamına çevir',
    'onboardLabsBody':
        'Bu telefonda erişilebilir kalan bir profil oluşturmak için kan ve alerji raporlarını yükle.',
    'onboardScanTitle': 'Paketli gıdayı satın almadan önce değerlendir',
    'onboardScanBody':
        'Barkod tara veya ürün bilgilerini gir; besin sinyallerini son profilinle karşılaştır.',
    'onboardOfflineTitle': 'Bağlantı kesilince yerel önbellekle çalışır',
    'onboardOfflineBody':
        'Tema, dil, onboarding durumu, profil hafızası ve kritik dashboard verileri Hive ile saklanır.',
    'onboardingNext': 'Devam',
    'onboardingStart': 'Başla',
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
    'forgotPassword': 'Şifremi unuttum',
    'sendResetLink': 'Sıfırlama bağlantısı gönder',
    'backToSignIn': 'Girişe dön',
    'passwordResetSent': 'Şifre sıfırlama e-postası gönderildi.',
    'emailRequired': 'E-posta zorunlu.',
    'or': 'VEYA',
    'continueWithGoogle': 'Google ile devam et',
    'authenticationFailed': 'Kimlik doğrulama başarısız.',
    'firebaseAuthConfigError':
        'Firebase Authentication tam yapılandırılmamış. Firebase Console’da Email/Password ve Google sağlayıcılarını aç, Android SHA-1/SHA-256 parmak izlerini ekle, sonra güncel google-services.json dosyasını indir.',
    'googleSignInFailed': 'Google ile giriş başarısız',
    'googleSignInCanceled': 'Google ile giriş iptal edildi.',
    'googleSignInUnavailable': 'Bu cihazda Google ile giriş kullanılamıyor.',
    'googleMissingIdToken':
        'Google ID token döndürmedi. Firebase Google sağlayıcısını ve Android SHA parmak izlerini kontrol et.',
    'googleConfigError':
        'Google ile giriş doğru yapılandırılmamış. Firebase’de Google sağlayıcısını aç ve Android SHA-1/SHA-256 parmak izlerini ekle.',
    'emailAlreadyInUse': 'Bu e-posta adresi zaten kayıtlı.',
    'invalidEmail': 'Geçerli bir e-posta adresi gir.',
    'weakPassword': 'Şifre en az 6 karakter olmalı.',
    'wrongPassword': 'E-posta veya şifre hatalı.',
    'userNotFound': 'Bu e-posta için hesap bulunamadı.',
    'networkRequestFailed': 'Ağ bağlantısı başarısız. Tekrar dene.',
    'homeHeroTitle': 'Yiyecekleri kendi testlerine göre tara',
    'homeHeroSubtitle':
        'BioDietix boy, kilo, alerji ve son test hafızasını telefonda tutar. Yeni PDF yüklenene kadar ürün kontrolleri bu profile göre yapılır.',
    'currentProfile': 'Güncel profil',
    'noBloodAnalyzed': 'Henüz kan testi analiz edilmedi.',
    'latestExtractedValues': 'Son çıkarılan değerler',
    'mealLogs': 'Öğün kayıtları',
    'mealLogsSubtitle':
        'Firestore’da saklanan ve Hive’da önbelleğe alınan günlük beslenme notlarını ekle, oku, güncelle ve sil.',
    'offlineCacheNotice':
        'Çevrimiçi kaynak şu an kullanılamadığı için önbellekteki veri gösteriliyor.',
    'addMealLog': 'Öğün kaydı ekle',
    'editMealLog': 'Öğün kaydını düzenle',
    'noMealLogs': 'Henüz öğün kaydı yok.',
    'mealTitle': 'Öğün başlığı',
    'mealTitleRequired': 'Öğün başlığı zorunlu.',
    'mealNote': 'Not',
    'mealCalories': 'Kalori',
    'kcal': 'kcal',
    'edit': 'Düzenle',
    'delete': 'Sil',
    'save': 'Kaydet',
    'healthProfile': 'Sağlık profili',
    'nutritionRecommendation': 'Beslenme önerisi',
    'foodsToIncrease': 'Artırılması önerilen besinler',
    'foodsToLimit': 'Sınırlandırılması önerilen besinler',
    'allergies': 'Alerjiler',
    'notAvailable': 'Mevcut değil',
    'profileSubtitle':
        'Girişten sonra bu telefonda saklanır. Sağlık dosyaları değiştirene veya silene kadar korunur.',
    'personalDetails': 'Kişisel bilgiler',
    'gender': 'Cinsiyet',
    'female': 'Kadın',
    'male': 'Erkek',
    'age': 'Yaş',
    'weightKg': 'Kilo (kg)',
    'heightCm': 'Boy (cm)',
    'knownAllergies': 'Bilinen alerjiler',
    'saveProfile': 'Profili telefona kaydet',
    'profileSaved': 'Profil bu telefona kaydedildi.',
    'profileSavedInline':
        'Profil kaydedildi. Bu değerler sonraki kan PDF’i ve ürün kontrollerinde kullanılacak.',
    'profileSaveFailed': 'Profil kaydedilemedi.',
    'healthDataCleared': 'Sağlık verileri bu telefondan silindi.',
    'deleteHealthData': 'Sağlık verilerini sil',
    'signOut': 'Çıkış yap',
    'testsSubtitle':
        'Güncel profili yenilemek için kan testi PDF’i yükle. Varsa alerji PDF’i de ekle.',
    'labReports': 'Laboratuvar raporları',
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
    'barcodeLookup': 'Barkod arama',
    'bloodRequired':
        'Kişisel ürün kontrolü için önce kan testi profili gerekir.',
    'openCameraScanner': 'Kamera tarayıcıyı aç',
    'barcodeQrValue': 'Barkod / QR değeri',
    'lookUpProduct': 'Ürünü bul',
    'productDetails': 'Ürün detayları',
    'name': 'Ad',
    'brand': 'Marka',
    'quantity': 'Miktar',
    'category': 'Kategori',
    'ingredients': 'İçindekiler',
    'declaredAllergens': 'Beyan edilen alerjenler',
    'labels': 'Etiketler',
    'servingSize': 'Porsiyon',
    'nutritionGrade': 'Nutri-Score',
    'novaGroup': 'NOVA grubu',
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
    'productLookupNotFound':
        'Bu barkod çevrimiçi gıda veritabanında bulunamadı. Ürün bilgilerini elle girip değerlendirebilirsin.',
    'manualProductHint':
        'Barkod araması ürünü bulamazsa etiketteki bilgileri görünen alanlara girip değerlendirmeye devam et.',
    'uploadBloodFirst': 'Önce kan testi PDF’i yükle.',
    'productEvaluationFailed': 'Ürün değerlendirme başarısız',
    'closeScanner': 'Tarayıcıyı kapat',
    'decision': 'Karar',
    'reasons': 'Nedenler',
    'positiveSignals': 'Olumlu sinyaller',
    'betterAlternatives': 'Daha iyi alternatifler',
    'educationalOnly': 'Sadece eğitim amaçlıdır. Tıbbi teşhis değildir.',
    'decisionRecommended': 'Önerilir',
    'decisionCaution': 'Dikkatli tüket',
    'decisionNotRecommended': 'Önerilmez',
    'reasonAllergyConflict': 'Alerji uyumsuzluğu',
    'reasonNutritionMissing':
        'Besin değeri eksik olduğu için ürün dikkatli değerlendirilmeli',
    'reasonVeryHighSugarProduct': 'Paketli ürün için çok yüksek şeker',
    'reasonHighSugarProduct': 'Paketli ürün için yüksek şeker',
    'reasonModerateSugarProduct': 'Orta düzey şeker',
    'reasonVeryHighSatFatProduct': 'Çok yüksek doymuş yağ',
    'reasonSatFatProduct': 'Yüksek doymuş yağ',
    'reasonHighSaltProduct': 'Yüksek tuz/sodyum',
    'reasonModerateSaltProduct': 'Orta düzey tuz/sodyum',
    'reasonVeryHighEnergyProduct': 'Çok yüksek enerji yoğunluğu',
    'reasonHighEnergyProduct': 'Yüksek enerji yoğunluğu',
    'reasonUltraProcessedProduct':
        'NOVA skoru aşırı işlenmiş ürüne işaret ediyor',
    'reasonPoorNutritionGrade': 'Zayıf Nutri-Score derecesi',
    'reasonLowFiberProduct': 'Şeker veya enerjiye göre düşük lif',
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
    'positiveGoodFiber': 'İyi lif içeriği',
    'positiveGoodProtein': 'Yararlı protein içeriği',
    'positiveLowSugar': 'Düşük şeker',
    'positiveLowSalt': 'Düşük tuz',
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
    'accountProfile': 'Hesap profili',
    'uploadPhotoGallery': 'Galeriden fotoğraf yükle',
    'uploadPhotoCamera': 'Profil fotoğrafı çek',
    'profilePhotoUpdated': 'Profil fotoğrafı güncellendi.',
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
    'flavor': 'Flavor',
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
  'Thyroid-related lab changes should be reviewed with a healthcare professional; this is not a medical diagnosis.':
      'Tiroidle ilişkili laboratuvar değişiklikleri bir sağlık profesyoneliyle değerlendirilmelidir; bu tıbbi teşhis değildir.',
  'Support thyroid-related metabolism with':
      'Tiroidle ilişkili metabolizmayı desteklemek için',
  'regular meal patterns': 'düzenli öğün düzeni',
  'adequate protein': 'yeterli protein',
  'physical activity': 'fiziksel aktivite',
  'selenium-rich foods': 'selenyumdan zengin besinler',
  'very low-calorie diets': 'çok düşük kalorili diyetler',
  'ultra-processed foods': 'aşırı işlenmiş gıdalar',
  'excess sugar': 'fazla şeker',
  'balanced meals': 'dengeli öğünler',
  'lean protein': 'yağsız protein',
  'whole grains': 'tam tahıllar',
  'vegetables': 'sebzeler',
  'fruits': 'meyveler',
  'eggs': 'yumurta',
  'egg': 'yumurta',
  'yogurt': 'yoğurt',
  'dairy products': 'süt ürünleri',
  'selenium': 'selenyum',
  'zinc': 'çinko',
  'iodine': 'iyot',
  'protein': 'protein',
  'frequent fast food': 'sık fast food tüketimi',
  'sugary drinks': 'şekerli içecekler',
  'meal skipping': 'öğün atlama',
  'olive oil': 'zeytinyağı',
  'nuts': 'kuruyemişler',
  'fish': 'balık',
  'avocado': 'avokado',
  'fiber-rich foods': 'lifli besinler',
  'fiber': 'lif',
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
