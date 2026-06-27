import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../i18n.dart';
import '../../models/personal_info.dart';
import '../../models/profile_memory.dart';
import '../../features/product_checks/domain/product_check.dart';

class HiveLocalStore {
  static const _boxName = 'biodietix_local';
  static const _encryptionKeyName = 'biodietix_hive_key_v1';
  static const _secureStorage = FlutterSecureStorage();

  Future<void> init() async {
    await Hive.initFlutter();
    if (Hive.isBoxOpen(_boxName)) return;

    var encodedKey = await _secureStorage.read(key: _encryptionKeyName);
    Map<dynamic, dynamic> legacyValues = const {};
    if (encodedKey == null) {
      if (await Hive.boxExists(_boxName)) {
        final legacyBox = await Hive.openBox<dynamic>(_boxName);
        legacyValues = legacyBox.toMap();
        await legacyBox.close();
        await Hive.deleteBoxFromDisk(_boxName);
      }
      final random = Random.secure();
      final key = List<int>.generate(32, (_) => random.nextInt(256));
      encodedKey = base64UrlEncode(key);
      await _secureStorage.write(key: _encryptionKeyName, value: encodedKey);
    }

    final encryptionKey = base64Url.decode(encodedKey);
    final box = await Hive.openBox<dynamic>(
      _boxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    if (legacyValues.isNotEmpty) await box.putAll(legacyValues);
  }

  Box<dynamic> get _box => Hive.box<dynamic>(_boxName);

  String _key(String uid, String name) => 'biodietix:$uid:$name';
  String _globalKey(String name) => 'biodietix:app:$name';

  Future<bool> hasSeenOnboarding() async {
    return _box.get(_globalKey('onboardingSeen')) == true;
  }

  Future<void> saveOnboardingSeen() async {
    await _box.put(_globalKey('onboardingSeen'), true);
  }

  Future<AppLanguage> loadLanguage() async {
    return AppLanguage.fromCode(_box.get(_globalKey('language'))?.toString());
  }

  Future<void> saveLanguage(AppLanguage language) async {
    await _box.put(_globalKey('language'), language.code);
  }

  Future<ThemeMode> loadThemeMode() async {
    return _themeModeFromString(_box.get(_globalKey('themeMode'))?.toString());
  }

  Future<void> saveThemeMode(ThemeMode value) async {
    await _box.put(_globalKey('themeMode'), _themeModeToString(value));
  }

  Future<PersonalInfo?> loadPersonalInfo(String uid) async {
    final value = _jsonMap(_box.get(_key(uid, 'personalInfo')));
    if (value == null) return null;
    return PersonalInfo.fromJson(value);
  }

  Future<void> savePersonalInfo(String uid, PersonalInfo personalInfo) async {
    await _box.put(
      _key(uid, 'personalInfo'),
      jsonEncode(personalInfo.toJson()),
    );
  }

  Future<ProfileMemory?> loadProfileMemory(String uid) async {
    final value = _jsonMap(_box.get(_key(uid, 'profileMemory')));
    if (value == null) return null;
    return ProfileMemory.fromJson(value);
  }

  Future<void> saveProfileMemory(
    String uid,
    ProfileMemory profileMemory,
  ) async {
    await _box.put(
      _key(uid, 'profileMemory'),
      jsonEncode(profileMemory.toJson()),
    );
  }

  Future<Map<String, dynamic>?> loadExtractedValues(String uid) async {
    return _jsonMap(_box.get(_key(uid, 'extractedValues')));
  }

  Future<void> saveExtractedValues(
    String uid,
    Map<String, dynamic> values,
  ) async {
    await _box.put(_key(uid, 'extractedValues'), jsonEncode(values));
  }

  Future<String?> loadProfilePhotoUrl(String uid) async {
    return _box.get(_key(uid, 'profilePhotoUrl'))?.toString();
  }

  Future<void> saveProfilePhotoUrl(String uid, String? url) async {
    if (url == null || url.trim().isEmpty) {
      await _box.delete(_key(uid, 'profilePhotoUrl'));
      return;
    }
    await _box.put(_key(uid, 'profilePhotoUrl'), url);
  }

  Future<List<ProductCheck>> loadProductChecks(String uid) async {
    final raw = _box.get(_key(uid, 'productChecks'));
    if (raw is! String || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded.whereType<Map>().map((item) {
      return ProductCheck.fromJson(
        item.map((key, value) => MapEntry(key.toString(), value)),
      );
    }).toList();
  }

  Future<void> saveProductChecks(String uid, List<ProductCheck> items) async {
    await _box.put(
      _key(uid, 'productChecks'),
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> clearHealthData(String uid) async {
    await _box.delete(_key(uid, 'profileMemory'));
    await _box.delete(_key(uid, 'personalInfo'));
    await _box.delete(_key(uid, 'extractedValues'));
    await _box.delete(_key(uid, 'profilePhotoUrl'));
  }

  Future<void> clearAllUserData(String uid) async {
    await clearHealthData(uid);
    await _box.delete(_key(uid, 'mealLogs'));
    await _box.delete(_key(uid, 'productChecks'));
  }

  Map<String, dynamic>? _jsonMap(dynamic value) {
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    if (value is! String || value.isEmpty) return null;
    final decoded = jsonDecode(value);
    if (decoded is! Map) return null;
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
}

ThemeMode _themeModeFromString(String? value) {
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
