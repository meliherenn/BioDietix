import '../i18n.dart';
import '../models/profile_display_codes.dart';
import 'profile_summary_catalog.dart';

class ProfileSummaryResolution {
  const ProfileSummaryResolution({
    required this.codes,
    required this.isComplete,
  });

  final ProfileDisplayCodes codes;
  final bool isComplete;
}

/// Resolves both schema-v2 display codes and legacy schema-v1 English fields.
///
/// Legacy values are matched as complete generated phrases. User-facing prose
/// is never translated with substring replacement.
class ProfileSummaryCodeResolver {
  const ProfileSummaryCodeResolver._();

  static ProfileSummaryResolution resolve(Map<String, dynamic> json) {
    if (_hasExplicitCodes(json)) {
      final codes = ProfileDisplayCodes.fromProfileJson(json);
      return ProfileSummaryResolution(
        codes: codes,
        isComplete: _explicitCodesAreComplete(json, codes),
      );
    }
    return _resolveLegacy(json);
  }

  static bool _hasExplicitCodes(Map<String, dynamic> json) {
    return json.containsKey('display_codes') ||
        json.containsKey('profile_signal_codes') ||
        json.containsKey('health_profile_codes') ||
        json.containsKey('recommendation_codes') ||
        json.containsKey('foods_to_increase_codes') ||
        json.containsKey('foods_to_limit_codes') ||
        json.containsKey('interpretation_warning_codes');
  }

  static bool _explicitCodesAreComplete(
    Map<String, dynamic> json,
    ProfileDisplayCodes codes,
  ) {
    final allKnown =
        codes.healthProfiles.every(
          ProfileSummaryCatalog.healthByCode.containsKey,
        ) &&
        codes.recommendations.every(
          ProfileSummaryCatalog.recommendationByCode.containsKey,
        ) &&
        codes.foodsToIncrease.every(
          ProfileSummaryCatalog.foodByCode.containsKey,
        ) &&
        codes.foodsToLimit.every(
          ProfileSummaryCatalog.foodByCode.containsKey,
        ) &&
        codes.interpretationWarnings.every(
          ProfileSummaryCatalog.warningByCode.containsKey,
        );
    if (!allKnown) return false;

    return (!_hasText(json['health_profile']) ||
            codes.healthProfiles.isNotEmpty) &&
        (!_hasText(json['nutrition_recommendation']) ||
            codes.recommendations.isNotEmpty) &&
        (_stringList(json['foods_to_increase']).isEmpty ||
            codes.foodsToIncrease.isNotEmpty) &&
        (_stringList(json['foods_to_limit']).isEmpty ||
            codes.foodsToLimit.isNotEmpty) &&
        (_warningTexts(json).isEmpty ||
            codes.interpretationWarnings.isNotEmpty);
  }

  static ProfileSummaryResolution _resolveLegacy(Map<String, dynamic> json) {
    var complete = true;

    final healthCodes = <String>[];
    for (final value in _commaSeparated(json['health_profile'])) {
      final code = ProfileSummaryCatalog.healthCodeByLegacy[value];
      if (code == null) {
        complete = false;
      } else {
        healthCodes.add(code);
      }
    }

    final recommendationResult = _legacyRecommendationCodes(
      json['nutrition_recommendation']?.toString() ?? '',
    );
    complete = complete && recommendationResult.isComplete;

    final increaseResult = _legacyItemCodes(
      _stringList(json['foods_to_increase']),
      ProfileSummaryCatalog.foodCodeByLegacy,
    );
    complete = complete && increaseResult.isComplete;

    final limitResult = _legacyItemCodes(
      _stringList(json['foods_to_limit']),
      ProfileSummaryCatalog.foodCodeByLegacy,
    );
    complete = complete && limitResult.isComplete;

    final warningResult = _legacyItemCodes(
      _warningTexts(json),
      ProfileSummaryCatalog.warningCodeByLegacy,
    );
    complete = complete && warningResult.isComplete;

    return ProfileSummaryResolution(
      codes: ProfileDisplayCodes(
        healthProfiles: List.unmodifiable(healthCodes),
        recommendations: recommendationResult.codes,
        foodsToIncrease: increaseResult.codes,
        foodsToLimit: limitResult.codes,
        interpretationWarnings: warningResult.codes,
      ),
      isComplete: complete,
    );
  }

  static _CodeListResult _legacyRecommendationCodes(String source) {
    var remaining = source.trim();
    if (remaining.isEmpty) return const _CodeListResult([], true);

    final entries = [...ProfileSummaryCatalog.recommendations]
      ..sort((a, b) => b.legacyText.length.compareTo(a.legacyText.length));
    final codes = <String>[];
    while (remaining.isNotEmpty) {
      ProfileSummaryCatalogEntry? match;
      for (final entry in entries) {
        if (remaining.startsWith(entry.legacyText)) {
          match = entry;
          break;
        }
      }
      if (match == null) return _CodeListResult(codes, false);
      codes.add(match.code);
      remaining = remaining.substring(match.legacyText.length).trimLeft();
    }
    return _CodeListResult(List.unmodifiable(codes), true);
  }

  static _CodeListResult _legacyItemCodes(
    List<String> values,
    Map<String, String> codeByLegacy,
  ) {
    final codes = <String>[];
    var complete = true;
    for (final value in values) {
      final code = codeByLegacy[value];
      if (code == null) {
        complete = false;
      } else {
        codes.add(code);
      }
    }
    return _CodeListResult(List.unmodifiable(codes), complete);
  }

  static bool _hasText(dynamic value) =>
      value?.toString().trim().isNotEmpty ?? false;

  static List<String> _commaSeparated(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return const [];
    return text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Object>()
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return _commaSeparated(value);
  }

  static List<String> _warningTexts(Map<String, dynamic> json) {
    final quality = json['data_quality'];
    if (quality is! Map) return const [];
    return _stringList(quality['interpretation_warnings']);
  }
}

class LocalizedProfileSummary {
  const LocalizedProfileSummary({
    required this.codes,
    required this.language,
    required this.isComplete,
  });

  final ProfileDisplayCodes codes;
  final AppLanguage language;
  final bool isComplete;

  String get refreshMessage => language == AppLanguage.tr
      ? 'Bu özet eski bir uygulama sürümünden kaldı. Eksiksiz çeviri için PDF raporunu yeniden yükleyin.'
      : 'This summary is from an older app version. Upload the PDF report again for a complete translation.';

  String get healthProfile => _localizedText(
    codes.healthProfiles,
    ProfileSummaryCatalog.healthByCode,
    separator: ', ',
  );

  String get recommendation => _localizedText(
    codes.recommendations,
    ProfileSummaryCatalog.recommendationByCode,
    separator: ' ',
  );

  List<String> get foodsToIncrease =>
      _localizedItems(codes.foodsToIncrease, ProfileSummaryCatalog.foodByCode);

  List<String> get foodsToLimit =>
      _localizedItems(codes.foodsToLimit, ProfileSummaryCatalog.foodByCode);

  List<String> get interpretationWarnings => _localizedItems(
    codes.interpretationWarnings,
    ProfileSummaryCatalog.warningByCode,
  );

  String _localizedText(
    List<String> values,
    Map<String, ProfileSummaryCatalogEntry> catalog, {
    required String separator,
  }) {
    if (!isComplete) return refreshMessage;
    return _localizedItems(values, catalog).join(separator);
  }

  List<String> _localizedItems(
    List<String> values,
    Map<String, ProfileSummaryCatalogEntry> catalog,
  ) {
    if (!isComplete) return const [];
    final result = <String>[];
    for (final code in values) {
      final entry = catalog[code];
      if (entry == null) return const [];
      result.add(entry.localized(language.code));
    }
    return List.unmodifiable(result);
  }
}

class _CodeListResult {
  const _CodeListResult(this.codes, this.isComplete);

  final List<String> codes;
  final bool isComplete;
}
