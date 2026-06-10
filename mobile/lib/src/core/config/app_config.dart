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

  const AppConfig({required this.flavor, required this.apiUrl});

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      flavor: AppFlavor.fromValue(
        const String.fromEnvironment('FLAVOR', defaultValue: 'dev'),
      ),
      apiUrl: const String.fromEnvironment(
        'BIODIETIX_API_URL',
        defaultValue: defaultApiUrl,
      ),
    );
  }

  final AppFlavor flavor;
  final String apiUrl;

  String get environmentCollection => flavor.value;

  String get appName {
    return flavor == AppFlavor.prod ? 'BioDietix' : 'BioDietix Dev';
  }
}
