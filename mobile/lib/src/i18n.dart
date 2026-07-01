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

  String dataQuality(String value) {
    final key = switch (value) {
      'high' => 'dataQualityHigh',
      'medium' => 'dataQualityMedium',
      'low' => 'dataQualityLow',
      _ => 'dataQualityMissing',
    };
    return t(key);
  }

  String dataQualityNotice(String value) {
    final key = switch (value) {
      'low' => 'dataQualityLowNotice',
      'missing' => 'dataQualityMissingNotice',
      _ => 'dataQualityMediumNotice',
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
    'splashSubtitle':
        'A warm diet companion for meals, labels, allergies, and daily choices.',
    'splashChecking': 'Preparing your nutrition space...',
    'splashInternet': 'Internet',
    'splashSession': 'Session',
    'splashHive': 'Local Hive',
    'splashReady': 'Ready',
    'onboardLabsTitle': 'Build a balanced plate that fits you',
    'onboardLabsBody':
        'Add body details, allergies, and optional reports to shape a profile cached on this device and synced to your account.',
    'onboardScanTitle': 'Choose packaged food with confidence',
    'onboardScanBody':
        'Scan a barcode or enter label details to compare sugar, salt, fiber, and allergens with your profile.',
    'onboardOfflineTitle': 'Keep your nutrition routine close',
    'onboardOfflineBody':
        'Meal notes, preferences, theme, language, and key profile memory stay available with local cache.',
    'onboardingNext': 'Next',
    'onboardingStart': 'Start',
    'home': 'Home',
    'profile': 'Profile',
    'tests': 'Reports',
    'scan': 'Scan',
    'settings': 'Settings',
    'biodietixMobile': 'BIODIETIX NUTRITION',
    'personalNutritionEngine': 'YOUR DAILY NUTRITION GUIDE',
    'authHeroTitle': 'A warmer way to plan what you eat',
    'authHeroSubtitle':
        'Create your profile, keep allergy or lab context ready, and scan food labels with confidence.',
    'signInSubtitle': 'Welcome back. Your daily nutrition rhythm is waiting.',
    'createAccountSubtitle':
        'Start with a secure account and keep your BioDietix data synced.',
    'forgotPasswordSubtitle':
        'Enter your email and we will send a secure reset link.',
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
    'homeHeroTitle': 'A balanced plate, made personal',
    'homeHeroSubtitle':
        'BioDietix brings meals, allergies, body details, and label checks into one warm nutrition routine.',
    'currentProfile': 'Diet profile',
    'nutritionCompass': 'Nutrition compass',
    'reportMemoryActive': 'Report memory active',
    'todaysGuide': "Today's guide",
    'increaseShort': 'Increase',
    'limitShort': 'Limit',
    'homeProfileSubtitle':
        'A compact view of the signals guiding meals and food label checks.',
    'homeProfileEmptyHint':
        'Add a blood PDF in Reports or save profile details to make today more personal.',
    'decisionHomeTitle': 'Your food decisions',
    'decisionHomeSubtitle':
        'A focused view of products BioDietix checked against your blood profile, allergies, and label data.',
    'decisionOverview': 'Decision overview',
    'decisionOverviewSubtitle':
        'Track which products look suitable, need attention, or should be avoided.',
    'checkedProducts': 'Checked products',
    'productChecks': 'Product checks',
    'safeToEat': 'Suitable',
    'needsAttention': 'Attention',
    'avoidProducts': 'Avoid',
    'scanProduct': 'Scan product',
    'latestProductChecks': 'Latest product checks',
    'latestProductChecksSubtitle':
        'Saved results from barcode scans and manual label evaluations.',
    'noProductChecksTitle': 'No product checked yet',
    'noProductChecksBody':
        'Scan a barcode or enter label details to see whether the product fits your profile.',
    'editProductNote': 'Edit product note',
    'productNote': 'Product note',
    'unknownProduct': 'Unknown product',
    'noBloodAnalyzed': 'No report or diet memory has been added yet.',
    'latestExtractedValues': 'Latest extracted values',
    'labSignals': 'lab signals',
    'mealLogs': 'Product checks',
    'mealLogsSubtitle':
        'Save product decisions, adjust notes later, and keep personal food guidance available offline.',
    'dashboardTitle': 'Food decisions',
    'dashboardSubtitle':
        'A calm view of checked products, decision signals, and notes.',
    'dailyBalance': 'Decision balance',
    'todayCalories': 'Checked products',
    'mealCount': 'Needs attention',
    'profileSignals': 'Profile signals',
    'nutritionMemory': 'Nutrition memory',
    'noMealLogsTitle': 'Start with your first product',
    'noMealLogsBody':
        'Scan a label or barcode and BioDietix keeps the decision available offline.',
    'cachedMode': 'Offline cache',
    'quickAdd': 'Scan product',
    'mealTimeline': 'Product decision history',
    'offlineCacheNotice':
        'Showing cached data because the online source is currently unavailable.',
    'addMealLog': 'Add product check',
    'editMealLog': 'Edit product check',
    'noMealLogs': 'No product checks yet.',
    'mealTitle': 'Product name',
    'mealTitleRequired': 'Product name is required.',
    'mealNote': 'Product note',
    'mealCalories': 'Energy kcal/100g',
    'kcal': 'kcal',
    'edit': 'Edit',
    'delete': 'Delete',
    'save': 'Save',
    'healthProfile': 'Diet focus',
    'nutritionRecommendation': 'Nutrition recommendation',
    'foodsToIncrease': 'Foods to increase',
    'foodsToLimit': 'Foods to limit',
    'allergies': 'Allergies',
    'notAvailable': 'Not available',
    'profileSubtitle':
        'Profile data and derived report results are cached on this device and synced to your account until you replace or delete them.',
    'personalDetails': 'Personal details',
    'gender': 'Gender',
    'female': 'Female',
    'male': 'Male',
    'age': 'Age',
    'weightKg': 'Weight (kg)',
    'heightCm': 'Height (cm)',
    'knownAllergies': 'Known allergies',
    'saveProfile': 'Save profile to phone',
    'profileSaved': 'Profile saved to this device and your account.',
    'profileSavedInline':
        'Profile saved. These values will be used for the next blood PDF and product checks.',
    'profileSaveFailed': 'Profile could not be saved.',
    'invalidProfileValues':
        'Enter an age from 18 to 120, weight up to 350 kg, and height up to 250 cm.',
    'limitedLabDataWarning':
        'Only a limited set of lab values was found. The result does not mean that overall health risk is low.',
    'healthDataCleared': 'Health data deleted from this device and cloud.',
    'deleteHealthData': 'Delete health data',
    'exportData': 'Export my data',
    'exportDataPrivacy':
        'This export contains sensitive health data. Store and share it securely.',
    'copyExport': 'Copy JSON export',
    'healthUploadConsentTitle': 'Process health report',
    'healthUploadConsentBody':
        'The selected PDF will be sent securely to the BioDietix API for transient processing. Do not upload another person’s report. Continue?',
    'continueAction': 'Continue',
    'deleteHealthDataConfirm':
        'Delete saved profile, lab values, allergies, and profile photo from this device and cloud?',
    'deleteAccount': 'Delete account',
    'deleteAccountConfirm':
        'Permanently delete all BioDietix data and the Firebase account? This cannot be undone.',
    'deleteAccountRecentLogin':
        'For security, sign out, sign in again, and retry account deletion.',
    'deleteAccountFailed': 'Account deletion could not be completed.',
    'requestAccountDeletion': 'Request account deletion',
    'accountDeletionPageUnavailable':
        'The account deletion request page could not be opened.',
    'contactSupport': 'Contact support',
    'supportUnavailable': 'The support email is not configured.',
    'cancel': 'Cancel',
    'signOut': 'Sign out',
    'testsSubtitle':
        'Use optional blood or allergy reports to tune the diet profile behind your food recommendations.',
    'labReports': 'Nutrition profile reports',
    'labReportsSubtitle':
        'Upload a new PDF whenever you want to replace or improve the saved analysis.',
    'reportStatus': 'Report status',
    'reportStatusReadyBody':
        'Saved analysis is available, so this screen no longer starts from zero.',
    'reportStatusEmptyBody':
        'Your first report will turn into a reusable diet profile summary here.',
    'noReportYetTitle': 'No report added yet',
    'noReportYetBody':
        'Upload a blood or allergy PDF and BioDietix will keep the useful summary for later visits.',
    'bloodReportReady': 'Blood report analyzed',
    'bloodReportReadyBody':
        'Diet focus, nutrition notes, and extracted lab values are saved for future checks.',
    'allergyReportReady': 'Allergy signals saved',
    'allergyReportReadyBody':
        'Known allergy signals will be considered during product and meal recommendations.',
    'reportSavedOnDevice':
        'The useful analysis summary is saved. The raw PDF text is only shown right after upload.',
    'pdfPreviewSessionNotice':
        'PDF text preview is available for this upload session.',
    'pdfPreviewPrivacyNote':
        'This is the extracted text preview. The app keeps the useful nutrition summary instead of filling the screen with raw PDF text.',
    'viewPdfPreview': 'View PDF text',
    'analysisSummary': 'Analysis summary',
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
        'BioDietix cloud service is temporarily unavailable.',
    'productScanner': 'Product scan',
    'productScannerSubtitle':
        'Scan a barcode and BioDietix will look up the product automatically. Add details manually only when needed.',
    'barcodeLookup': 'Fast barcode lookup',
    'bloodRequired':
        'Blood test profile required before personal product checks.',
    'openCameraScanner': 'Open camera scanner',
    'barcodeQrValue': 'Barcode / QR value',
    'lookUpProduct': 'Search barcode',
    'productDetails': 'Product details',
    'productReady': 'Product found',
    'productReadySubtitle':
        'Review the matched label data, then evaluate it with your diet profile.',
    'editProductDetails': 'Edit details',
    'manualAddProduct': 'Manual add',
    'manualAddProductSubtitle':
        'Use this when the barcode is missing or the label needs extra detail.',
    'openManualDetails': 'Open manual product form',
    'manualProductDetails': 'Manual product details',
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
        'Open this only when barcode lookup cannot find enough label data.',
    'sugarShort': 'Sugar',
    'saltShort': 'Salt',
    'uploadBloodFirst': 'Upload a blood test PDF first.',
    'productEvaluationFailed': 'Product evaluation failed',
    'productCheckSaved': 'Product check saved to Home.',
    'closeScanner': 'Close scanner',
    'decision': 'Decision',
    'reasons': 'Reasons',
    'positiveSignals': 'Positive signals',
    'betterAlternatives': 'Better alternatives',
    'educationalOnly':
        'Supportive information only. BioDietix is not a medical device and does not diagnose, treat, cure, or prevent any condition. Consult a qualified healthcare professional.',
    'medicalDisclaimer':
        'BioDietix is not a medical device and does not diagnose, treat, cure, or prevent any medical condition. Results are supportive information only; consult a qualified healthcare professional.',
    'decisionRecommended': 'Appears suitable',
    'decisionCaution': 'Use with caution',
    'decisionNotRecommended': 'Not recommended',
    'dataQuality': 'Product data',
    'dataQualityHigh': 'Good label data',
    'dataQualityMedium': 'Partial label data',
    'dataQualityLow': 'Limited label data',
    'dataQualityMissing': 'No nutrition values',
    'dataQualityMediumNotice':
        'Some label values are missing, so the result should be read as guidance.',
    'dataQualityLowNotice':
        'Only limited product data is available. BioDietix avoids a hard not-recommended decision unless there is allergy conflict or strong measured risk.',
    'dataQualityMissingNotice':
        'Nutrition values are missing. Add label values for a more confident result.',
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
        'Keep your account, profile photo, language, and app feeling just right.',
    'accountProfile': 'Account profile',
    'changeProfilePhoto': 'Change profile photo',
    'photoSourceTitle': 'Choose photo source',
    'gallery': 'Gallery',
    'camera': 'Camera',
    'uploadPhotoGallery': 'Upload photo from gallery',
    'uploadPhotoCamera': 'Take profile photo',
    'profilePhotoUpdated': 'Profile photo updated.',
    'profilePhotoTooLarge': 'Profile photo must be smaller than 5 MB.',
    'language': 'Language',
    'english': 'English',
    'turkish': 'Turkish',
    'appearance': 'Appearance',
    'system': 'System',
    'light': 'Light',
    'dark': 'Dark',
    'cloudService': 'BioDietix cloud',
    'cloudServiceSubtitle':
        'The app connects automatically. You do not need to configure anything.',
    'serviceReady': 'Secure cloud connection is ready.',
    'serviceUnavailable': 'Cloud connection is not available right now.',
    'serviceEndpoint': 'Service endpoint',
    'server': 'Server',
    'serverSubtitle':
        'The phone app needs a public BioDietix API. Emulator/private computer addresses do not work for other users.',
    'productionApiUrl': 'Production API URL',
    'flavor': 'Flavor',
    'notConfigured': 'Not configured',
    'checkApiConnection': 'Check connection',
    'apiConnected': 'Connection ready',
    'apiConnectionFailed': 'Connection check failed',
    'account': 'Account',
    'privacyPolicy': 'Privacy policy',
    'privacyPolicyUnavailable': 'The privacy policy could not be opened.',
    'signedInAs': 'Signed in as',
  },
  AppLanguage.tr: {
    'appTitle': 'BioDietix',
    'splashSubtitle':
        'Öğünlerin, etiketler, alerjiler ve günlük seçimler için sıcak bir diyet eşlikçisi.',
    'splashChecking': 'Beslenme alanın hazırlanıyor...',
    'splashInternet': 'İnternet',
    'splashSession': 'Oturum',
    'splashHive': 'Yerel Hive',
    'splashReady': 'Hazır',
    'onboardLabsTitle': 'Sana uyan dengeli tabağı kur',
    'onboardLabsBody':
        'Vücut bilgilerini, alerjilerini ve istersen raporlarını ekle; cihazda önbelleğe alınan ve hesabınla eşitlenen profilini oluştur.',
    'onboardScanTitle': 'Paketli gıdayı daha bilinçli seç',
    'onboardScanBody':
        'Barkod tara veya etiket bilgilerini gir; şeker, tuz, lif ve alerjenleri profilinle karşılaştır.',
    'onboardOfflineTitle': 'Beslenme rutinin yanında kalsın',
    'onboardOfflineBody':
        'Öğün notların, tercihlerin, tema, dil ve temel profil hafızan yerel önbellekle erişilebilir kalır.',
    'onboardingNext': 'Devam',
    'onboardingStart': 'Başla',
    'home': 'Ana Sayfa',
    'profile': 'Profil',
    'tests': 'Raporlar',
    'scan': 'Tarama',
    'settings': 'Ayarlar',
    'biodietixMobile': 'BIODIETIX BESLENME',
    'personalNutritionEngine': 'GÜNLÜK BESLENME REHBERİN',
    'authHeroTitle': 'Ne yiyeceğini daha sıcak planla',
    'authHeroSubtitle':
        'Profilini oluştur, alerji ve test bağlamını hazır tut, gıda etiketlerini güvenle tara.',
    'signInSubtitle':
        'Tekrar hoş geldin. Günlük beslenme ritmin seni bekliyor.',
    'createAccountSubtitle':
        'Güvenli bir hesapla başla ve BioDietix verilerini senkron tut.',
    'forgotPasswordSubtitle':
        'E-postanı gir; güvenli sıfırlama bağlantısını gönderelim.',
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
    'homeHeroTitle': 'Dengeli tabak, sana göre',
    'homeHeroSubtitle':
        'BioDietix öğünlerini, alerjilerini, vücut bilgilerini ve etiket kontrollerini sıcak bir beslenme rutininde toplar.',
    'currentProfile': 'Diyet profili',
    'nutritionCompass': 'Diyet pusulası',
    'reportMemoryActive': 'Rapor hafızası aktif',
    'todaysGuide': 'Bugünün rehberi',
    'increaseShort': 'Artır',
    'limitShort': 'Sınırla',
    'homeProfileSubtitle':
        'Öğün ve ürün etiketi kontrollerini yönlendiren sinyallerin kompakt özeti.',
    'homeProfileEmptyHint':
        'Bugünü daha kişisel yapmak için Raporlar’dan kan PDF’i ekle veya profil bilgilerini kaydet.',
    'decisionHomeTitle': 'Gıda kararların',
    'decisionHomeSubtitle':
        'BioDietix’in kan profilin, alerjilerin ve etiket verilerine göre kontrol ettiği ürünlerin net özeti.',
    'decisionOverview': 'Karar özeti',
    'decisionOverviewSubtitle':
        'Hangi ürün uygun, hangisi dikkat ister, hangisinden kaçınmak gerekir hızlıca gör.',
    'checkedProducts': 'Kontrol edilen',
    'productChecks': 'Ürün kontrolü',
    'safeToEat': 'Uygun',
    'needsAttention': 'Dikkat',
    'avoidProducts': 'Kaçın',
    'scanProduct': 'Ürün tara',
    'latestProductChecks': 'Son ürün kontrolleri',
    'latestProductChecksSubtitle':
        'Barkod tarama ve manuel etiket değerlendirmelerinden kaydedilen sonuçlar.',
    'noProductChecksTitle': 'Henüz ürün kontrol edilmedi',
    'noProductChecksBody':
        'Barkod tara veya etiket bilgisi gir; ürünün profiline uygun olup olmadığını gör.',
    'editProductNote': 'Ürün notunu düzenle',
    'productNote': 'Ürün notu',
    'unknownProduct': 'Bilinmeyen ürün',
    'noBloodAnalyzed': 'Henüz rapor veya diyet hafızası eklenmedi.',
    'latestExtractedValues': 'Son çıkarılan değerler',
    'labSignals': 'laboratuvar sinyali',
    'mealLogs': 'Ürün kontrolleri',
    'mealLogsSubtitle':
        'Ürün kararlarını kaydet, notlarını sonra düzenle ve kişisel gıda rehberini çevrimdışıyken de yanında tut.',
    'dashboardTitle': 'Gıda kararları',
    'dashboardSubtitle':
        'Kontrol edilen ürünleri, karar sinyallerini ve notlarını sakin bir akışta gör.',
    'dailyBalance': 'Karar dengesi',
    'todayCalories': 'Kontrol edilen',
    'mealCount': 'Dikkat isteyen',
    'profileSignals': 'Profil sinyalleri',
    'nutritionMemory': 'Beslenme hafızası',
    'noMealLogsTitle': 'İlk ürün kontrolünle başla',
    'noMealLogsBody':
        'Etiket veya barkod tara; BioDietix kararı çevrimdışıyken de yanında tutsun.',
    'cachedMode': 'Çevrimdışı önbellek',
    'quickAdd': 'Ürün tara',
    'mealTimeline': 'Ürün karar geçmişi',
    'offlineCacheNotice':
        'Çevrimiçi kaynak şu an kullanılamadığı için önbellekteki veri gösteriliyor.',
    'addMealLog': 'Ürün kontrolü ekle',
    'editMealLog': 'Ürün kontrolünü düzenle',
    'noMealLogs': 'Henüz ürün kontrolü yok.',
    'mealTitle': 'Ürün adı',
    'mealTitleRequired': 'Ürün adı zorunlu.',
    'mealNote': 'Ürün notu',
    'mealCalories': 'Enerji kcal/100g',
    'kcal': 'kcal',
    'edit': 'Düzenle',
    'delete': 'Sil',
    'save': 'Kaydet',
    'healthProfile': 'Diyet odağı',
    'nutritionRecommendation': 'Beslenme önerisi',
    'foodsToIncrease': 'Artırılması önerilen besinler',
    'foodsToLimit': 'Sınırlandırılması önerilen besinler',
    'allergies': 'Alerjiler',
    'notAvailable': 'Mevcut değil',
    'profileSubtitle':
        'Profil verileri ve rapordan türetilen sonuçlar, değiştirene veya silene kadar cihazda önbelleğe alınır ve hesabınla eşitlenir.',
    'personalDetails': 'Kişisel bilgiler',
    'gender': 'Cinsiyet',
    'female': 'Kadın',
    'male': 'Erkek',
    'age': 'Yaş',
    'weightKg': 'Kilo (kg)',
    'heightCm': 'Boy (cm)',
    'knownAllergies': 'Bilinen alerjiler',
    'saveProfile': 'Profili telefona kaydet',
    'profileSaved': 'Profil bu cihaza ve hesabına kaydedildi.',
    'profileSavedInline':
        'Profil kaydedildi. Bu değerler sonraki kan PDF’i ve ürün kontrollerinde kullanılacak.',
    'profileSaveFailed': 'Profil kaydedilemedi.',
    'invalidProfileValues':
        '18-120 arası yaş, en fazla 350 kg kilo ve en fazla 250 cm boy girin.',
    'limitedLabDataWarning':
        'Yalnızca sınırlı sayıda laboratuvar değeri bulundu. Sonuç, genel sağlık riskinin düşük olduğu anlamına gelmez.',
    'healthDataCleared': 'Sağlık verileri bu cihazdan ve buluttan silindi.',
    'deleteHealthData': 'Sağlık verilerini sil',
    'exportData': 'Verilerimi dışa aktar',
    'exportDataPrivacy':
        'Bu dışa aktarım hassas sağlık verileri içerir. Güvenli biçimde saklayın ve paylaşın.',
    'copyExport': 'JSON dışa aktarımını kopyala',
    'healthUploadConsentTitle': 'Sağlık raporunu işle',
    'healthUploadConsentBody':
        'Seçilen PDF geçici işleme için güvenli biçimde BioDietix API’ye gönderilecektir. Başka bir kişiye ait raporu yüklemeyin. Devam edilsin mi?',
    'continueAction': 'Devam et',
    'deleteHealthDataConfirm':
        'Kayıtlı profil, laboratuvar değerleri, alerjiler ve profil fotoğrafı bu cihazdan ve buluttan silinsin mi?',
    'deleteAccount': 'Hesabı sil',
    'deleteAccountConfirm':
        'Tüm BioDietix verileri ve Firebase hesabı kalıcı olarak silinsin mi? Bu işlem geri alınamaz.',
    'deleteAccountRecentLogin':
        'Güvenlik için çıkış yapın, yeniden giriş yapın ve hesap silmeyi tekrar deneyin.',
    'deleteAccountFailed': 'Hesap silme tamamlanamadı.',
    'requestAccountDeletion': 'Hesap silme talebi oluştur',
    'accountDeletionPageUnavailable': 'Hesap silme talep sayfası açılamadı.',
    'contactSupport': 'Destek ile iletişime geç',
    'supportUnavailable': 'Destek e-posta adresi yapılandırılmadı.',
    'cancel': 'İptal',
    'signOut': 'Çıkış yap',
    'testsSubtitle':
        'Yemek önerilerinin arkasındaki diyet profilini hassaslaştırmak için isteğe bağlı kan ya da alerji raporu ekle.',
    'labReports': 'Beslenme profili raporları',
    'labReportsSubtitle':
        'Kayıtlı analizi yenilemek veya güçlendirmek istediğinde yeni PDF yükleyebilirsin.',
    'reportStatus': 'Rapor durumu',
    'reportStatusReadyBody':
        'Kayıtlı analiz var; bu ekran artık her girişte sıfırdan başlamıyor.',
    'reportStatusEmptyBody':
        'İlk raporun burada tekrar kullanılabilir bir diyet profili özetine dönüşür.',
    'noReportYetTitle': 'Henüz rapor eklenmedi',
    'noReportYetBody':
        'Kan veya alerji PDF’i yükle; BioDietix işe yarayan özeti sonraki ziyaretler için saklasın.',
    'bloodReportReady': 'Kan raporu analiz edildi',
    'bloodReportReadyBody':
        'Diyet odağı, beslenme notları ve çıkarılan laboratuvar değerleri sonraki kontroller için kayıtlı.',
    'allergyReportReady': 'Alerji sinyalleri kaydedildi',
    'allergyReportReadyBody':
        'Bilinen alerji sinyalleri ürün ve öğün önerilerinde dikkate alınır.',
    'reportSavedOnDevice':
        'Kullanışlı analiz özeti kayıtlı. Ham PDF metni yalnızca yükleme sonrasında gösterilir.',
    'pdfPreviewSessionNotice':
        'PDF metin önizlemesi bu yükleme oturumu için hazır.',
    'pdfPreviewPrivacyNote':
        'Bu çıkarılan metin önizlemesidir. Uygulama ekranı ham PDF metniyle doldurmak yerine işe yarayan beslenme özetini saklar.',
    'viewPdfPreview': 'PDF metnini görüntüle',
    'analysisSummary': 'Analiz özeti',
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
    'serverNotConfigured': 'BioDietix bulut servisine şu anda ulaşılamıyor.',
    'productScanner': 'Ürün tarama',
    'productScannerSubtitle':
        'Barkodu okut; BioDietix ürünü otomatik arasın. Gerekirse manuel ürün bilgisi ekle.',
    'barcodeLookup': 'Barkodla hızlı ara',
    'bloodRequired':
        'Kişisel ürün kontrolü için önce kan testi profili gerekir.',
    'openCameraScanner': 'Kamera tarayıcıyı aç',
    'barcodeQrValue': 'Barkod / QR değeri',
    'lookUpProduct': 'Barkodu ara',
    'productDetails': 'Ürün detayları',
    'productReady': 'Ürün bulundu',
    'productReadySubtitle':
        'Eşleşen etiket verisini kontrol et, sonra diyet profiline göre değerlendir.',
    'editProductDetails': 'Detayları düzenle',
    'manualAddProduct': 'Manuel ekle',
    'manualAddProductSubtitle':
        'Barkod yoksa veya etiket için ek bilgi gerekiyorsa bu alanı kullan.',
    'openManualDetails': 'Manuel ürün formunu aç',
    'manualProductDetails': 'Manuel ürün detayları',
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
        'Barkod araması yeterli etiket verisi bulamazsa bu alanı açıp doldur.',
    'sugarShort': 'Şeker',
    'saltShort': 'Tuz',
    'uploadBloodFirst': 'Önce kan testi PDF’i yükle.',
    'productEvaluationFailed': 'Ürün değerlendirme başarısız',
    'productCheckSaved': 'Ürün kontrolü Ana Sayfa’ya kaydedildi.',
    'closeScanner': 'Tarayıcıyı kapat',
    'decision': 'Karar',
    'reasons': 'Nedenler',
    'positiveSignals': 'Olumlu sinyaller',
    'betterAlternatives': 'Daha iyi alternatifler',
    'educationalOnly':
        'Yalnızca destekleyici bilgidir. BioDietix tıbbi cihaz değildir; herhangi bir durumu teşhis, tedavi veya önleme amacı taşımaz. Yetkili bir sağlık profesyoneline danışın.',
    'medicalDisclaimer':
        'BioDietix tıbbi cihaz değildir; herhangi bir sağlık durumunu teşhis, tedavi veya önleme amacı taşımaz. Sonuçlar yalnızca destekleyici bilgidir. Yetkili bir sağlık profesyoneline danışın.',
    'decisionRecommended': 'Mevcut veriye göre uygun görünüyor',
    'decisionCaution': 'Dikkatli tüket',
    'decisionNotRecommended': 'Önerilmez',
    'dataQuality': 'Ürün verisi',
    'dataQualityHigh': 'İyi etiket verisi',
    'dataQualityMedium': 'Kısmi etiket verisi',
    'dataQualityLow': 'Sınırlı etiket verisi',
    'dataQualityMissing': 'Besin değeri yok',
    'dataQualityMediumNotice':
        'Bazı etiket değerleri eksik; sonucu rehber niteliğinde oku.',
    'dataQualityLowNotice':
        'Ürün verisi sınırlı. BioDietix alerji çakışması veya güçlü ölçülmüş risk yoksa doğrudan önerilmez demez.',
    'dataQualityMissingNotice':
        'Besin değerleri eksik. Daha güvenli sonuç için etiket değerlerini ekle.',
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
    'settingsSubtitle':
        'Hesabını, profil fotoğrafını, dilini ve uygulama hissini kendine uydur.',
    'accountProfile': 'Hesap profili',
    'changeProfilePhoto': 'Profil fotoğrafını değiştir',
    'photoSourceTitle': 'Fotoğraf kaynağı seç',
    'gallery': 'Galeri',
    'camera': 'Kamera',
    'uploadPhotoGallery': 'Galeriden fotoğraf yükle',
    'uploadPhotoCamera': 'Profil fotoğrafı çek',
    'profilePhotoUpdated': 'Profil fotoğrafı güncellendi.',
    'profilePhotoTooLarge': 'Profil fotoğrafı 5 MB’den küçük olmalıdır.',
    'language': 'Dil',
    'english': 'İngilizce',
    'turkish': 'Türkçe',
    'appearance': 'Görünüm',
    'system': 'Sistem',
    'light': 'Açık',
    'dark': 'Koyu',
    'cloudService': 'BioDietix bulut',
    'cloudServiceSubtitle':
        'Uygulama otomatik bağlanır. Herhangi bir ayar yapman gerekmez.',
    'serviceReady': 'Güvenli bulut bağlantısı hazır.',
    'serviceUnavailable': 'Bulut bağlantısı şu anda kullanılamıyor.',
    'serviceEndpoint': 'Servis adresi',
    'server': 'Sunucu',
    'serverSubtitle':
        'Telefon uygulaması herkese açık BioDietix API gerektirir. Emülatör veya kişisel bilgisayar adresleri diğer kullanıcılarda çalışmaz.',
    'productionApiUrl': 'Production API adresi',
    'flavor': 'Flavor',
    'notConfigured': 'Yapılandırılmadı',
    'checkApiConnection': 'Bağlantıyı kontrol et',
    'apiConnected': 'Bağlantı hazır',
    'apiConnectionFailed': 'Bağlantı kontrolü başarısız',
    'account': 'Hesap',
    'privacyPolicy': 'Gizlilik politikası',
    'privacyPolicyUnavailable': 'Gizlilik politikası açılamadı.',
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
  'Insufficient Data': 'Yetersiz Veri',
  'No Flagged Risk in Available Data': 'Mevcut Veride İşaretlenen Risk Yok',
  'Cardiovascular Lipid Risk': 'Kardiyovasküler Lipit Riski',
  'Kidney / Muscle Marker': 'Böbrek / Kas Göstergesi',
  'Kidney / Muscle Indicator': 'Böbrek / Kas Göstergesi',
  'Thyroid / Metabolism Indicator': 'Tiroid / Metabolizma Göstergesi',
  'Blood Sugar / Insulin Resistance Risk': 'Kan Şekeri / İnsülin Direnci Riski',
  'Inflammation / Immune Indicator': 'Enflamasyon / Bağışıklık Göstergesi',
  'Weight Management Focus': 'Kilo Yönetimi Odağı',
  'Blood Pressure / Kidney Risk': 'Tansiyon / Böbrek Riski',
  'Fiber Intake Signal': 'Lif Alımı Sinyali',
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
