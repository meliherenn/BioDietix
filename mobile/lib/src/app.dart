import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/app_config.dart';
import 'core/storage/hive_local_store.dart';
import 'core/widgets/ui.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/main/presentation/screens/main_shell.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/product_checks/data/product_check_repository.dart';
import 'features/profile/data/profile_repository.dart';
import 'features/settings/presentation/cubit/locale_cubit.dart';
import 'features/settings/presentation/cubit/theme_cubit.dart';
import 'features/splash/presentation/cubit/splash_cubit.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'i18n.dart';

class BioDietixApp extends StatelessWidget {
  const BioDietixApp({
    required this.config,
    required this.firebaseReady,
    required this.localStore,
    required this.initialLanguage,
    required this.initialThemeMode,
    super.key,
  });

  final AppConfig config;
  final bool firebaseReady;
  final HiveLocalStore localStore;
  final AppLanguage initialLanguage;
  final ThemeMode initialThemeMode;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: config),
        RepositoryProvider.value(value: localStore),
        RepositoryProvider(
          create: (_) => AuthRepository(firebaseReady: firebaseReady),
        ),
        RepositoryProvider(
          create: (_) => ProfileRepository(
            config: config,
            localStore: localStore,
            firebaseReady: firebaseReady,
          ),
        ),
        RepositoryProvider(
          create: (_) => ProductCheckRepository(
            config: config,
            localStore: localStore,
            firebaseReady: firebaseReady,
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ThemeCubit(
              localStore: localStore,
              initialMode: initialThemeMode,
            ),
          ),
          BlocProvider(
            create: (_) => LocaleCubit(
              localStore: localStore,
              initialLanguage: initialLanguage,
            ),
          ),
          BlocProvider(
            create: (context) =>
                AuthCubit(repository: context.read<AuthRepository>()),
          ),
          BlocProvider(
            create: (context) => SplashCubit(
              localStore: localStore,
              authRepository: context.read<AuthRepository>(),
            )..check(),
          ),
        ],
        child: BlocBuilder<LocaleCubit, LocaleState>(
          builder: (context, localeState) {
            final strings = AppStrings(localeState.language);
            return AppScope(
              language: localeState.language,
              strings: strings,
              child: BlocBuilder<ThemeCubit, ThemeState>(
                builder: (context, themeState) {
                  return MaterialApp(
                    title: strings.t('appTitle'),
                    debugShowCheckedModeBanner: false,
                    locale: Locale(localeState.language.code),
                    themeMode: themeState.mode,
                    theme: _theme(Brightness.light),
                    darkTheme: _theme(Brightness.dark),
                    home: _AppFlow(
                      config: config,
                      firebaseReady: firebaseReady,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: green,
      brightness: brightness,
      primary: green,
      secondary: gold,
      surface: isDark ? const Color(0xFF10231B) : porcelain,
      error: danger,
    );
    final textColor = isDark ? const Color(0xFFF7F0E2) : ink;
    final labelColor = isDark ? const Color(0xFFC1B8A8) : muted;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? const Color(0xFF07120E) : background,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 86,
        elevation: 0,
        backgroundColor: isDark
            ? const Color(0xFF0B1712)
            : const Color(0xFFFFFBF4),
        indicatorColor: isDark
            ? const Color(0xFF1F4C3B)
            : const Color(0xFFE6F2DA),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? green : labelColor,
            size: selected ? 27 : 25,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF07120E) : background,
        modalBackgroundColor: isDark ? const Color(0xFF07120E) : background,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          color: textColor,
          fontSize: 30,
          height: 1.08,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: textColor,
          fontSize: 21,
          height: 1.15,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: textColor,
          fontSize: 16,
          height: 1.22,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        labelSmall: TextStyle(
          color: labelColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(
          color: textColor,
          height: 1.45,
          fontWeight: FontWeight.w600,
        ),
        bodySmall: TextStyle(
          color: labelColor,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF0C1A14) : const Color(0xFFFFF8EA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2D4439) : const Color(0xFFE7D8C2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2D4439) : const Color(0xFFE7D8C2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: aqua, width: 1.7),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: danger, width: 1.7),
        ),
        prefixIconColor: labelColor,
        hintStyle: TextStyle(color: labelColor),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? const Color(0xFF1B3026)
            : const Color(0xFFF5ECD9),
        selectedColor: isDark
            ? const Color(0xFF1F4C3B)
            : const Color(0xFFE6F2DA),
        side: BorderSide(color: isDark ? const Color(0xFF2D4439) : line),
        labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.w700),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFFF7F0E2) : deepGreen,
        contentTextStyle: TextStyle(
          color: isDark ? deepGreen : Colors.white,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class _AppFlow extends StatelessWidget {
  const _AppFlow({required this.config, required this.firebaseReady});

  final AppConfig config;
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SplashCubit, SplashState>(
      builder: (context, splashState) {
        if (splashState is SplashLoading) {
          return const SplashScreen();
        }

        if (splashState is SplashFailure) {
          return Scaffold(body: Center(child: Text(splashState.message)));
        }

        if (splashState is SplashReady && !splashState.hasSeenOnboarding) {
          return OnboardingScreen(
            onFinished: context.read<SplashCubit>().completeOnboarding,
          );
        }

        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            if (authState is AuthLoading) {
              return const SplashScreen();
            }
            if (authState is AuthAuthenticated) {
              return MainShell(
                user: authState.user,
                config: config,
                firebaseReady: firebaseReady,
              );
            }
            return AuthScreen(firebaseReady: firebaseReady);
          },
        );
      },
    );
  }
}
