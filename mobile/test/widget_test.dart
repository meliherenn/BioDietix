import 'package:biodietix_mobile/src/app.dart';
import 'package:biodietix_mobile/src/i18n.dart';
import 'package:biodietix_mobile/src/models/personal_info.dart';
import 'package:biodietix_mobile/src/screens/auth_screen.dart';
import 'package:biodietix_mobile/src/screens/profile_screen.dart';
import 'package:biodietix_mobile/src/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('BioDietix app shows Firebase setup gate', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const BioDietixApp(firebaseReady: false));
    await tester.pumpAndSettle();

    expect(find.text('BIODIETIX MOBILE'), findsOneWidget);
    expect(find.text('Firebase setup required'), findsOneWidget);
    expect(find.text('Continue in local preview mode'), findsNothing);
  });

  testWidgets('Settings screen exposes language and theme controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      AppScope(
        language: AppLanguage.en,
        strings: const AppStrings(AppLanguage.en),
        child: MaterialApp(
          home: Scaffold(
            body: SettingsScreen(
              apiUrl: '',
              firebaseReady: true,
              userEmail: 'student@example.com',
              language: AppLanguage.en,
              themeMode: ThemeMode.system,
              onLanguageChanged: (_) async {},
              onThemeModeChanged: (_) async {},
              onClearHealthData: () async {},
              onSignOut: () async {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Turkish'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('Auth screen exposes Google sign-in action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      AppScope(
        language: AppLanguage.en,
        strings: const AppStrings(AppLanguage.en),
        child: const MaterialApp(home: AuthScreen(firebaseReady: true)),
      ),
    );

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Create a new account'), findsOneWidget);
  });

  testWidgets('Profile save shows visible confirmation', (
    WidgetTester tester,
  ) async {
    var saved = false;

    await tester.pumpWidget(
      AppScope(
        language: AppLanguage.en,
        strings: const AppStrings(AppLanguage.en),
        child: MaterialApp(
          home: Scaffold(
            body: ProfileScreen(
              personalInfo: const PersonalInfo(age: 28),
              allergies: const [],
              onPersonalInfoChanged: (_) {},
              onAllergiesChanged: (_) {},
              onSave: () async {
                saved = true;
              },
            ),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Save profile to phone'));
    await tester.tap(find.text('Save profile to phone'));
    await tester.pumpAndSettle();

    expect(saved, isTrue);
    expect(
      find.textContaining('Profile saved. These values will be used'),
      findsOneWidget,
    );
  });
}
