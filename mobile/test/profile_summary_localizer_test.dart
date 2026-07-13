import 'package:biodietix_mobile/src/core/storage/hive_local_store.dart';
import 'package:biodietix_mobile/src/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:biodietix_mobile/src/i18n.dart';
import 'package:biodietix_mobile/src/i18n/profile_summary_catalog.dart';
import 'package:biodietix_mobile/src/i18n/profile_summary_localizer.dart';
import 'package:biodietix_mobile/src/models/profile_memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const _disclaimer =
    'These are general food-choice suggestions, not medical advice. BioDietix is not a medical device and does not diagnose, treat, cure, or prevent any condition; discuss abnormal results and major diet changes with a qualified healthcare professional.';

const _legacyProfile = <String, dynamic>{
  'schema_version': 1,
  'health_profile': 'Blood Sugar Risk, Immune / Inflammation Indicator',
  'nutrition_recommendation':
      'Reduce added sugar and refined carbohydrates, and prefer low-glycemic foods. $_disclaimer',
  'foods_to_increase': ['fresh vegetables', 'walnuts', 'high-fiber vegetables'],
  'foods_to_limit': ['sugary drinks'],
  'data_quality': {
    'interpretation_warnings': [
      'Reference intervals vary by laboratory, method, age, sex, pregnancy status, and clinical context.',
    ],
  },
  'allergies': <String>[],
};

LocalizedProfileSummary _summary(ProfileMemory memory, AppLanguage language) {
  return LocalizedProfileSummary(
    codes: memory.displayCodes,
    language: language,
    isComplete: memory.summaryLocalizationComplete,
  );
}

class _MemoryStore extends HiveLocalStore {
  AppLanguage language = AppLanguage.en;

  @override
  Future<void> saveLanguage(AppLanguage value) async {
    language = value;
  }
}

class _LanguageSwitchHarness extends StatelessWidget {
  const _LanguageSwitchHarness({required this.memory});

  final ProfileMemory memory;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, state) {
        final summary = _summary(memory, state.language);
        return MaterialApp(
          locale: Locale(state.language.code),
          home: Scaffold(
            body: Column(
              children: [
                Text(summary.healthProfile, key: const Key('health-summary')),
                Text(summary.recommendation, key: const Key('recommendation')),
                Text(
                  summary.foodsToIncrease.join(', '),
                  key: const Key('foods'),
                ),
                TextButton(
                  key: const Key('switch-language'),
                  onPressed: () {
                    final next = state.language == AppLanguage.en
                        ? AppLanguage.tr
                        : AppLanguage.en;
                    context.read<LocaleCubit>().setLanguage(next);
                  },
                  child: const Text('switch'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

void main() {
  test('catalog covers every canonical backend category in both languages', () {
    expect(ProfileSummaryCatalog.healthProfiles, hasLength(19));
    expect(ProfileSummaryCatalog.recommendations, hasLength(35));
    expect(ProfileSummaryCatalog.foods, hasLength(102));
    expect(ProfileSummaryCatalog.interpretationWarnings, hasLength(4));

    final entries = ProfileSummaryCatalog.allEntries.toList();
    expect(entries, hasLength(160));
    expect(entries.map((entry) => entry.code).toSet(), hasLength(160));
    expect(entries.map((entry) => entry.legacyText).toSet(), hasLength(160));
    expect(entries.every((entry) => entry.en.trim().isNotEmpty), isTrue);
    expect(entries.every((entry) => entry.tr.trim().isNotEmpty), isTrue);
  });

  test('schema-v1 summary migrates by exact phrases and localizes fully', () {
    final memory = ProfileMemory.fromJson(_legacyProfile);
    final en = _summary(memory, AppLanguage.en);
    final tr = _summary(memory, AppLanguage.tr);

    expect(memory.summaryLocalizationComplete, isTrue);
    expect(memory.displayCodes.healthProfiles, [
      'health.blood_sugar_risk',
      'health.immune_inflammation_indicator',
    ]);
    expect(en.healthProfile, _legacyProfile['health_profile']);
    expect(en.recommendation, _legacyProfile['nutrition_recommendation']);
    expect(en.foodsToIncrease, [
      'fresh vegetables',
      'walnuts',
      'high-fiber vegetables',
    ]);
    expect(
      tr.healthProfile,
      'Kan Şekeri Riski, Bağışıklık / Enflamasyon Göstergesi',
    );
    expect(tr.foodsToIncrease, [
      'taze sebzeler',
      'ceviz',
      'yüksek lifli sebzeler',
    ]);
    expect(tr.recommendation, isNot(contains('Reduce added sugar')));
    expect(tr.recommendation, isNot(contains('medical advice')));
    expect(tr.recommendation, contains('Eklenmiş şekeri'));
    expect(tr.recommendation, contains('tıbbi tavsiye değildir'));
  });

  test('legacy resolution does not mutate the stored/product API payload', () {
    final memory = ProfileMemory.fromJson(_legacyProfile);

    expect(memory.toJson()['schema_version'], 1);
    expect(memory.toJson().containsKey('display_codes'), isFalse);
    expect(memory.toJson()['health_profile'], _legacyProfile['health_profile']);
  });

  test('schema-v2 nested display codes round-trip without prose parsing', () {
    final memory = ProfileMemory.fromJson(const {
      'schema_version': 2,
      'health_profile': 'future legacy prose',
      'display_codes': {
        'health_profiles': ['health.blood_pressure_risk'],
        'recommendations': ['recommendation.reduce_sodium_dash_pattern'],
        'foods_to_increase': ['food.vegetables'],
        'foods_to_limit': ['food.salty_snacks'],
        'interpretation_warnings': ['warning.reference_intervals_vary'],
      },
      'allergies': <String>[],
    });

    expect(memory.summaryLocalizationComplete, isTrue);
    expect(_summary(memory, AppLanguage.tr).healthProfile, 'Tansiyon Riski');
    expect((memory.toJson()['display_codes'] as Map)['health_profiles'], [
      'health.blood_pressure_risk',
    ]);
  });

  test('unknown legacy prose never leaks as a mixed translation', () {
    final memory = ProfileMemory.fromJson(const {
      'health_profile': 'Unknown future signal',
      'nutrition_recommendation': 'Unknown future recommendation.',
      'allergies': <String>[],
    });
    final tr = _summary(memory, AppLanguage.tr);

    expect(memory.summaryLocalizationComplete, isFalse);
    expect(tr.healthProfile, contains('PDF raporunu yeniden yükleyin'));
    expect(tr.healthProfile, isNot(contains('Unknown future signal')));
    expect(tr.recommendation, isNot(contains('Unknown future recommendation')));
    expect(tr.foodsToIncrease, isEmpty);
  });

  testWidgets('the same stored summary switches EN to TR to EN locally', (
    tester,
  ) async {
    final store = _MemoryStore();
    final cubit = LocaleCubit(
      localStore: store,
      initialLanguage: AppLanguage.en,
    );
    final memory = ProfileMemory.fromJson(_legacyProfile);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: _LanguageSwitchHarness(memory: memory),
      ),
    );
    final originalEnglish = tester
        .widget<Text>(find.byKey(const Key('recommendation')))
        .data;
    expect(
      find.text('fresh vegetables, walnuts, high-fiber vegetables'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('switch-language')));
    await tester.pumpAndSettle();
    expect(
      find.text('taze sebzeler, ceviz, yüksek lifli sebzeler'),
      findsOneWidget,
    );
    expect(find.textContaining('Eklenmiş şekeri'), findsOneWidget);

    await tester.tap(find.byKey(const Key('switch-language')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('recommendation'))).data,
      originalEnglish,
    );
    expect(store.language, AppLanguage.en);
    await cubit.close();
  });
}
