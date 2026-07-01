import 'package:biodietix_mobile/src/core/config/app_config.dart';
import 'package:biodietix_mobile/src/core/storage/hive_local_store.dart';
import 'package:biodietix_mobile/src/features/auth/data/auth_repository.dart';
import 'package:biodietix_mobile/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:biodietix_mobile/src/features/auth/presentation/screens/auth_screen.dart';
import 'package:biodietix_mobile/src/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:biodietix_mobile/src/features/profile/data/profile_repository.dart';
import 'package:biodietix_mobile/src/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:biodietix_mobile/src/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:biodietix_mobile/src/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:biodietix_mobile/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:biodietix_mobile/src/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppConfig validates release links and support email', () {
    expect(
      AppConfig.httpsUri('https://example.com/privacy')?.host,
      'example.com',
    );
    expect(AppConfig.httpsUri('http://example.com/privacy'), isNull);
    expect(AppConfig.httpsUri('not-a-url'), isNull);
    expect(AppConfig.supportEmailUri('support@example.com')?.scheme, 'mailto');
    expect(AppConfig.supportEmailUri('not-an-email'), isNull);
  });

  testWidgets('Onboarding shows first page and primary action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      AppScope(
        language: AppLanguage.en,
        strings: const AppStrings(AppLanguage.en),
        child: MaterialApp(home: OnboardingScreen(onFinished: () async {})),
      ),
    );

    expect(find.text('Build a balanced plate that fits you'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('Auth screen exposes email, Google, and reset flows', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      AppScope(
        language: AppLanguage.en,
        strings: const AppStrings(AppLanguage.en),
        child: BlocProvider(
          create: (_) =>
              AuthCubit(repository: const AuthRepository(firebaseReady: false)),
          child: const MaterialApp(home: AuthScreen(firebaseReady: true)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Forgot password'), findsOneWidget);
  });

  testWidgets('Settings screen exposes language and theme controls', (
    WidgetTester tester,
  ) async {
    final store = HiveLocalStore();
    const config = AppConfig(
      flavor: AppFlavor.dev,
      apiUrl: '',
      privacyPolicyUrl: 'https://example.com/privacy',
      accountDeletionUrl: 'https://example.com/delete-account',
      supportEmail: 'support@example.com',
    );

    await tester.pumpWidget(
      AppScope(
        language: AppLanguage.en,
        strings: const AppStrings(AppLanguage.en),
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => LocaleCubit(
                localStore: store,
                initialLanguage: AppLanguage.en,
              ),
            ),
            BlocProvider(
              create: (_) =>
                  ThemeCubit(localStore: store, initialMode: ThemeMode.system),
            ),
            BlocProvider(
              create: (_) => AuthCubit(
                repository: const AuthRepository(firebaseReady: false),
              ),
            ),
            BlocProvider(
              create: (_) => ProfileCubit(
                repository: ProfileRepository(
                  config: config,
                  localStore: store,
                  firebaseReady: false,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SettingsScreen(
                config: config,
                firebaseReady: false,
                userEmail: 'student@example.com',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('English'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
    expect(find.text('Turkish'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Request account deletion'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('Request account deletion'), findsOneWidget);
    expect(find.text('Contact support'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);
  });
}
