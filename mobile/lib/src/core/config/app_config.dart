enum AppFlavor {
  dev('dev'),
  prod('prod');

  const AppFlavor(this.value);

  final String value;

  static AppFlavor fromValue(String value) {
    return value.toLowerCase() == prod.value ? prod : dev;
  }
}

class AppConfig {
  static const defaultApiUrl = 'https://biodietix-ml.onrender.com';
  static const defaultPrivacyPolicyUrl =
      'https://github.com/meliherenn/BioDietix/blob/main/PRIVACY.md';
  static const appCheckEnabled = bool.fromEnvironment(
    'BIODIETIX_APP_CHECK_ENABLED',
    defaultValue: true,
  );

  const AppConfig({
    required this.flavor,
    required this.apiUrl,
    this.privacyPolicyUrl = defaultPrivacyPolicyUrl,
  });

  factory AppConfig.fromEnvironment() {
    final flavor = AppFlavor.fromValue(
      const String.fromEnvironment('FLAVOR', defaultValue: 'dev'),
    );
    const apiUrl = String.fromEnvironment(
      'BIODIETIX_API_URL',
      defaultValue: defaultApiUrl,
    );
    const privacyPolicyUrl = String.fromEnvironment(
      'BIODIETIX_PRIVACY_POLICY_URL',
      defaultValue: defaultPrivacyPolicyUrl,
    );
    if (flavor == AppFlavor.prod) {
      if (!appCheckEnabled) {
        throw StateError(
          'App Check cannot be disabled for a production build.',
        );
      }
      if (Uri.tryParse(apiUrl)?.scheme != 'https') {
        throw StateError('Production API URL must use HTTPS.');
      }
      if (Uri.tryParse(privacyPolicyUrl)?.scheme != 'https') {
        throw StateError('Production privacy policy URL must use HTTPS.');
      }
    }
    return AppConfig(
      flavor: flavor,
      apiUrl: apiUrl,
      privacyPolicyUrl: privacyPolicyUrl,
    );
  }

  final AppFlavor flavor;
  final String apiUrl;
  final String privacyPolicyUrl;

  String get environmentCollection => flavor.value;

  String get appName {
    return flavor == AppFlavor.prod ? 'BioDietix' : 'BioDietix Dev';
  }
}
