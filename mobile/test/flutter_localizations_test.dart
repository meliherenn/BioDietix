import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _localizedMaterialApp(Locale locale) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('tr')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Builder(
      builder: (context) => Text(
        MaterialLocalizations.of(context).cancelButtonLabel,
        textDirection: TextDirection.ltr,
      ),
    ),
  );
}

void main() {
  testWidgets('Flutter Material strings follow Turkish and English locale', (
    tester,
  ) async {
    await tester.pumpWidget(_localizedMaterialApp(const Locale('tr')));
    await tester.pumpAndSettle();
    expect(find.text('İptal'), findsOneWidget);

    await tester.pumpWidget(_localizedMaterialApp(const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('Cancel'), findsOneWidget);
  });
}
