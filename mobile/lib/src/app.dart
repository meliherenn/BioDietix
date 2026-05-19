import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'i18n.dart';
import 'models/personal_info.dart';
import 'models/profile_memory.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tests_screen.dart';
import 'services/google_sign_in_service.dart';
import 'services/local_store.dart';
import 'widgets/ui.dart';

class BioDietixApp extends StatefulWidget {
  const BioDietixApp({required this.firebaseReady, super.key});

  final bool firebaseReady;

  @override
  State<BioDietixApp> createState() => _BioDietixAppState();
}

class _BioDietixAppState extends State<BioDietixApp> {
  static const _configuredApiUrl = String.fromEnvironment('BIODIETIX_API_URL');

  final _store = const LocalStore();

  User? _user;
  var _booting = true;
  var _tab = 0;
  final _apiUrl = _configuredApiUrl;
  var _language = AppLanguage.en;
  var _themeMode = ThemeMode.system;
  var _personalInfo = const PersonalInfo();
  var _allergies = <String>[];
  ProfileMemory? _profileMemory;
  Map<String, dynamic>? _lastExtractedValues;

  String? get _uid => _user?.uid;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final language = await _store.loadLanguage();
    final themeMode = _themeModeFromString(await _store.loadThemeMode());

    if (mounted) {
      setState(() {
        _language = language;
        _themeMode = themeMode;
      });
    }

    if (!widget.firebaseReady) {
      if (mounted) setState(() => _booting = false);
      return;
    }

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      _user = user;
      if (user != null) {
        await _loadStoredState(user.uid);
      } else {
        _personalInfo = const PersonalInfo();
        _allergies = <String>[];
        _profileMemory = null;
        _lastExtractedValues = null;
      }
      _booting = false;
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadStoredState(String uid) async {
    final personalInfo = await _store.loadPersonalInfo(uid);
    final profileMemory = await _store.loadProfileMemory(uid);

    if (personalInfo != null) _personalInfo = personalInfo;
    if (profileMemory != null) {
      _profileMemory = profileMemory;
      _allergies = profileMemory.allergies;
    }
  }

  Future<void> _saveProfile() async {
    final uid = _uid;
    if (uid == null) return;
    await _store.savePersonalInfo(uid, _personalInfo);
    if (_profileMemory != null) {
      _profileMemory = _profileMemory!.copyWithAllergies(_allergies);
      await _store.saveProfileMemory(uid, _profileMemory!);
    }
    if (mounted) {
      setState(() {});
      showAppSnack(context, AppStrings(_language).t('profileSaved'));
    }
  }

  Future<void> _saveProfileMemory(ProfileMemory memory) async {
    final uid = _uid;
    _profileMemory = memory;
    _allergies = memory.allergies;
    if (uid != null) await _store.saveProfileMemory(uid, memory);
    if (mounted) setState(() {});
  }

  Future<void> _clearHealthData() async {
    final uid = _uid;
    if (uid == null) return;
    await _store.clearHealthData(uid);
    _profileMemory = null;
    _lastExtractedValues = null;
    if (mounted) {
      setState(() {});
      showAppSnack(context, AppStrings(_language).t('healthDataCleared'));
    }
  }

  Future<void> _signOut() async {
    try {
      await GoogleSignInService.signOut();
    } on Exception {
      // Firebase sign-out below is the source of truth for app state.
    }
    if (FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.signOut();
    }
    _user = null;
    _tab = 0;
    if (mounted) setState(() {});
  }

  Future<void> _setLanguage(AppLanguage language) async {
    await _store.saveLanguage(language);
    if (mounted) setState(() => _language = language);
  }

  Future<void> _setThemeMode(ThemeMode themeMode) async {
    await _store.saveThemeMode(_themeModeToString(themeMode));
    if (mounted) setState(() => _themeMode = themeMode);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(_language);
    return AppScope(
      language: _language,
      strings: strings,
      child: MaterialApp(
        title: strings.t('appTitle'),
        debugShowCheckedModeBanner: false,
        locale: Locale(_language.code),
        themeMode: _themeMode,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: _buildHome(),
      ),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: green,
      brightness: brightness,
    );
    final textColor = isDark ? const Color(0xFFE9F2EE) : ink;
    final labelColor = isDark ? const Color(0xFF9CB0A8) : muted;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? const Color(0xFF071310) : background,
      colorScheme: scheme,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF0C1A17) : Colors.white,
        indicatorColor: isDark
            ? const Color(0xFF1E4C43)
            : const Color(0xFFCDEDE7),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(color: textColor, fontWeight: FontWeight.w700),
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
        labelSmall: TextStyle(
          color: labelColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
        bodyMedium: TextStyle(color: textColor, height: 1.4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF0A1815) : const Color(0xFFF9FBF7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF26423A) : const Color(0xFFCFDAD3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF26423A) : const Color(0xFFCFDAD3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: green, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildHome() {
    if (_booting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_uid == null) {
      return AuthScreen(firebaseReady: widget.firebaseReady);
    }

    final pages = [
      HomeScreen(
        profileMemory: _profileMemory,
        extractedValues: _lastExtractedValues,
      ),
      ProfileScreen(
        personalInfo: _personalInfo,
        allergies: _allergies,
        onPersonalInfoChanged: (value) => setState(() => _personalInfo = value),
        onAllergiesChanged: (value) => setState(() => _allergies = value),
        onSave: _saveProfile,
      ),
      TestsScreen(
        apiUrl: _apiUrl,
        personalInfo: _personalInfo,
        allergies: _allergies,
        onAllergiesChanged: (value) => setState(() => _allergies = value),
        onProfileMemory: _saveProfileMemory,
        onExtractedValues: (value) =>
            setState(() => _lastExtractedValues = value),
      ),
      ScanScreen(apiUrl: _apiUrl, profileMemory: _profileMemory),
      SettingsScreen(
        apiUrl: _apiUrl,
        firebaseReady: widget.firebaseReady,
        userEmail: _user?.email,
        language: _language,
        themeMode: _themeMode,
        onLanguageChanged: _setLanguage,
        onThemeModeChanged: _setThemeMode,
        onClearHealthData: _clearHealthData,
        onSignOut: _signOut,
      ),
    ];

    final strings = AppStrings(_language);
    return Scaffold(
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: strings.t('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: strings.t('profile'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.science_outlined),
            selectedIcon: const Icon(Icons.science),
            label: strings.t('tests'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.qr_code_scanner),
            selectedIcon: const Icon(Icons.qr_code_2),
            label: strings.t('scan'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: strings.t('settings'),
          ),
        ],
      ),
    );
  }
}

ThemeMode _themeModeFromString(String value) {
  return switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

String _themeModeToString(ThemeMode value) {
  return switch (value) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
}
