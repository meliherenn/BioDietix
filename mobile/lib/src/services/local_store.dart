import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../i18n.dart';
import '../models/personal_info.dart';
import '../models/profile_memory.dart';

class LocalStore {
  const LocalStore();

  String _key(String uid, String name) => 'biodietix:$uid:$name';
  String _globalKey(String name) => 'biodietix:app:$name';

  Future<AppLanguage> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return AppLanguage.fromCode(prefs.getString(_globalKey('language')));
  }

  Future<void> saveLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_globalKey('language'), language.code);
  }

  Future<String> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_globalKey('themeMode')) ?? 'system';
  }

  Future<void> saveThemeMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_globalKey('themeMode'), value);
  }

  Future<PersonalInfo?> loadPersonalInfo(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key(uid, 'personalInfo'));
    if (value == null) return null;
    return PersonalInfo.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  Future<void> savePersonalInfo(String uid, PersonalInfo personalInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(uid, 'personalInfo'),
      jsonEncode(personalInfo.toJson()),
    );
  }

  Future<ProfileMemory?> loadProfileMemory(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key(uid, 'profileMemory'));
    if (value == null) return null;
    return ProfileMemory.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  Future<void> saveProfileMemory(
    String uid,
    ProfileMemory profileMemory,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(uid, 'profileMemory'),
      jsonEncode(profileMemory.toJson()),
    );
  }

  Future<void> clearHealthData(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(uid, 'profileMemory'));
    await prefs.remove(_key(uid, 'personalInfo'));
  }
}
