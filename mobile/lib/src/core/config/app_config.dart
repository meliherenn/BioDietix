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
  static const appCheckEnabled = bool.fromEnvironment(
    'BIODIETIX_APP_CHECK_ENABLED',
    defaultValue: true,
  );

  const AppConfig({
    required this.flavor,
    required this.apiUrl,
    this.privacyPolicyUrl = '',
    this.accountDeletionUrl = '',
    this.supportEmail = '',
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
    );
    const accountDeletionUrl = String.fromEnvironment(
      'BIODIETIX_ACCOUNT_DELETION_URL',
    );
    const supportEmail = String.fromEnvironment('BIODIETIX_SUPPORT_EMAIL');
    if (flavor == AppFlavor.prod) {
      if (!appCheckEnabled) {
        throw StateError(
          'App Check cannot be disabled for a production build.',
        );
      }
      if (Uri.tryParse(apiUrl)?.scheme != 'https') {
        throw StateError('Production API URL must use HTTPS.');
      }
      if (httpsUri(privacyPolicyUrl) == null) {
        throw StateError('Production privacy policy URL must use HTTPS.');
      }
      if (httpsUri(accountDeletionUrl) == null) {
        throw StateError('Production account deletion URL must use HTTPS.');
      }
      if (supportEmailUri(supportEmail) == null) {
        throw StateError('Production support email must be configured.');
      }
    }
    return AppConfig(
      flavor: flavor,
      apiUrl: apiUrl,
      privacyPolicyUrl: privacyPolicyUrl,
      accountDeletionUrl: accountDeletionUrl,
      supportEmail: supportEmail,
    );
  }

  final AppFlavor flavor;
  final String apiUrl;
  final String privacyPolicyUrl;
  final String accountDeletionUrl;
  final String supportEmail;

  static Uri? httpsUri(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }

  static Uri? supportEmailUri(String value) {
    final email = value.trim();
    final parts = email.split('@');
    if (email.isEmpty ||
        email.contains(RegExp(r'\s')) ||
        parts.length != 2 ||
        parts.first.isEmpty ||
        parts.last.isEmpty) {
      return null;
    }
    return Uri(scheme: 'mailto', path: email);
  }

  String get environmentCollection => flavor.value;

  String get appName {
    return flavor == AppFlavor.prod ? 'BioDietix' : 'BioDietix Dev';
  }
}
