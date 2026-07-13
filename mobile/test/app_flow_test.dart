import 'package:biodietix_mobile/src/app.dart';
import 'package:biodietix_mobile/src/core/config/app_config.dart';
import 'package:biodietix_mobile/src/core/storage/hive_local_store.dart';
import 'package:biodietix_mobile/src/features/auth/data/auth_repository.dart';
import 'package:biodietix_mobile/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:biodietix_mobile/src/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:biodietix_mobile/src/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:biodietix_mobile/src/features/settings/presentation/screens/language_selection_screen.dart';
import 'package:biodietix_mobile/src/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:biodietix_mobile/src/i18n.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const _config = AppConfig(
  flavor: AppFlavor.dev,
  apiUrl: 'https://api.example.com',
);

class _FakeLocalStore extends HiveLocalStore {
  _FakeLocalStore({this.selectedLanguage, this.onboardingSeen = false});

  AppLanguage? selectedLanguage;
  bool onboardingSeen;

  @override
  Future<AppLanguage?> loadSelectedLanguage() async => selectedLanguage;

  @override
  Future<bool> hasSelectedLanguage() async => selectedLanguage != null;

  @override
  Future<void> saveLanguage(AppLanguage language) async {
    selectedLanguage = language;
  }

  @override
  Future<bool> hasSeenOnboarding() async => onboardingSeen;

  @override
  Future<void> saveOnboardingSeen() async {
    onboardingSeen = true;
  }
}

Future<void> _pumpFlow(WidgetTester tester, _FakeLocalStore store) async {
  const authRepository = AuthRepository(firebaseReady: false);
  final splashCubit = SplashCubit(
    localStore: store,
    authRepository: authRepository,
    connectivityChecker: () async => [ConnectivityResult.wifi],
  );
  await splashCubit.check();

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: splashCubit),
        BlocProvider(
          create: (_) => LocaleCubit(
            localStore: store,
            initialLanguage: store.selectedLanguage ?? AppLanguage.en,
          ),
        ),
        BlocProvider(create: (_) => AuthCubit(repository: authRepository)),
      ],
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, state) {
          return AppScope(
            language: state.language,
            strings: AppStrings(state.language),
            child: MaterialApp(
              locale: Locale(state.language.code),
              home: const AppFlow(config: _config, firebaseReady: false),
            ),
          );
        },
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('missing language shows selection before onboarding', (
    tester,
  ) async {
    final store = _FakeLocalStore();
    await _pumpFlow(tester, store);

    expect(find.byType(LanguageSelectionScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Türkçe'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('Turkish selection is persisted and opens Turkish onboarding', (
    tester,
  ) async {
    final store = _FakeLocalStore();
    await _pumpFlow(tester, store);

    await tester.tap(find.byKey(const Key('language-choice-tr')));
    await tester.pumpAndSettle();

    expect(store.selectedLanguage, AppLanguage.tr);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(
      find.text(const AppStrings(AppLanguage.tr).t('onboardLabsTitle')),
      findsOneWidget,
    );
  });

  testWidgets('English selection is persisted', (tester) async {
    final store = _FakeLocalStore();
    await _pumpFlow(tester, store);

    await tester.tap(find.byKey(const Key('language-choice-en')));
    await tester.pumpAndSettle();

    expect(store.selectedLanguage, AppLanguage.en);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('an existing language skips selection', (tester) async {
    final store = _FakeLocalStore(selectedLanguage: AppLanguage.tr);
    await _pumpFlow(tester, store);

    expect(find.byType(LanguageSelectionScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('missing language wins even when onboarding was completed', (
    tester,
  ) async {
    final store = _FakeLocalStore(onboardingSeen: true);
    await _pumpFlow(tester, store);

    expect(find.byType(LanguageSelectionScreen), findsOneWidget);
  });

  test('settings language changes still persist through LocaleCubit', () async {
    final store = _FakeLocalStore(selectedLanguage: AppLanguage.en);
    final cubit = LocaleCubit(
      localStore: store,
      initialLanguage: AppLanguage.en,
    );

    await cubit.setLanguage(AppLanguage.tr);

    expect(store.selectedLanguage, AppLanguage.tr);
    expect(cubit.state.language, AppLanguage.tr);
    await cubit.close();
  });
}
