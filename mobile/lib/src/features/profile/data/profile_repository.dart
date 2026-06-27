import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/config/app_config.dart';
import '../../../core/storage/hive_local_store.dart';
import '../../../models/personal_info.dart';
import '../../../models/profile_memory.dart';

class ProfileSnapshot {
  const ProfileSnapshot({
    required this.personalInfo,
    required this.allergies,
    required this.profileMemory,
    required this.extractedValues,
    required this.photoUrl,
  });

  final PersonalInfo personalInfo;
  final List<String> allergies;
  final ProfileMemory? profileMemory;
  final Map<String, dynamic>? extractedValues;
  final String? photoUrl;
}

class ProfileRepository {
  const ProfileRepository({
    required this.config,
    required this.localStore,
    required this.firebaseReady,
  });

  final AppConfig config;
  final HiveLocalStore localStore;
  final bool firebaseReady;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return FirebaseFirestore.instance
        .collection('environments')
        .doc(config.environmentCollection)
        .collection('users')
        .doc(uid);
  }

  Future<ProfileSnapshot> load(String uid) async {
    final localPersonal = await localStore.loadPersonalInfo(uid);
    final localMemory = await localStore.loadProfileMemory(uid);
    final localExtractedValues = await localStore.loadExtractedValues(uid);
    final localPhotoUrl = await localStore.loadProfilePhotoUrl(uid);

    var snapshot = ProfileSnapshot(
      personalInfo: localPersonal ?? const PersonalInfo(),
      allergies: localMemory?.allergies ?? const [],
      profileMemory: localMemory,
      extractedValues: localExtractedValues,
      photoUrl: localPhotoUrl,
    );

    if (!firebaseReady) return snapshot;

    try {
      final remote = await _userDoc(uid).get();
      final data = remote.data();
      if (data == null) return snapshot;

      final personalInfo = data['personalInfo'] is Map
          ? PersonalInfo.fromJson(
              (data['personalInfo'] as Map).map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            )
          : snapshot.personalInfo;
      final profileMemory = data['profileMemory'] is Map
          ? ProfileMemory.fromJson(
              (data['profileMemory'] as Map).map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            )
          : snapshot.profileMemory;
      final extractedValues = data['extractedValues'] is Map
          ? (data['extractedValues'] as Map).map(
              (key, value) => MapEntry(key.toString(), value),
            )
          : snapshot.extractedValues;
      final allergies = _stringList(data['allergies']).isNotEmpty
          ? _stringList(data['allergies'])
          : profileMemory?.allergies ?? snapshot.allergies;
      final photoUrl = data['photoUrl']?.toString() ?? snapshot.photoUrl;

      snapshot = ProfileSnapshot(
        personalInfo: personalInfo,
        allergies: allergies,
        profileMemory: profileMemory,
        extractedValues: extractedValues,
        photoUrl: photoUrl,
      );
      await _cache(uid, snapshot);
    } on Exception {
      return snapshot;
    }

    return snapshot;
  }

  Future<void> saveProfile({
    required String uid,
    required PersonalInfo personalInfo,
    required List<String> allergies,
    ProfileMemory? profileMemory,
  }) async {
    final memory = profileMemory
        ?.copyWithAllergies(allergies)
        .copyWithPersonalInfo(personalInfo);
    await localStore.savePersonalInfo(uid, personalInfo);
    if (memory != null) await localStore.saveProfileMemory(uid, memory);

    if (!firebaseReady) return;
    await _userDoc(uid).set({
      'personalInfo': personalInfo.toJson(),
      'allergies': allergies,
      if (memory != null) 'profileMemory': memory.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveProfileMemory({
    required String uid,
    required ProfileMemory profileMemory,
    required Map<String, dynamic>? extractedValues,
  }) async {
    await localStore.saveProfileMemory(uid, profileMemory);
    if (extractedValues != null) {
      await localStore.saveExtractedValues(uid, extractedValues);
    }

    if (!firebaseReady) return;
    await _userDoc(uid).set({
      'profileMemory': profileMemory.toJson(),
      'allergies': profileMemory.allergies,
      ...?extractedValues == null ? null : {'extractedValues': extractedValues},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveAllergies({
    required String uid,
    required List<String> allergies,
    ProfileMemory? profileMemory,
  }) async {
    final memory = profileMemory?.copyWithAllergies(allergies);
    if (memory != null) await localStore.saveProfileMemory(uid, memory);

    if (!firebaseReady) return;
    await _userDoc(uid).set({
      'allergies': allergies,
      if (memory != null) 'profileMemory': memory.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> uploadProfilePhoto({
    required String uid,
    required File file,
  }) async {
    if (!firebaseReady) {
      throw StateError('Firebase Storage is not configured.');
    }

    final ref = _profilePhotoRef(uid);

    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    await localStore.saveProfilePhotoUrl(uid, url);
    await _userDoc(uid).set({
      'photoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return url;
  }

  Reference _profilePhotoRef(String uid) {
    return FirebaseStorage.instance
        .ref()
        .child(config.environmentCollection)
        .child('users')
        .child(uid)
        .child('profile')
        .child('photo.jpg');
  }

  Future<void> clearHealthData(String uid) async {
    await localStore.clearHealthData(uid);
    if (!firebaseReady) return;
    try {
      await _profilePhotoRef(uid).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
    await _userDoc(uid).set({
      'personalInfo': FieldValue.delete(),
      'profileMemory': FieldValue.delete(),
      'extractedValues': FieldValue.delete(),
      'allergies': <String>[],
      'photoUrl': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteAllUserData(String uid) async {
    await localStore.clearAllUserData(uid);
    if (!firebaseReady) return;

    await _deleteCollection(_userDoc(uid).collection('product_checks'));
    await _deleteCollection(_userDoc(uid).collection('meal_logs'));
    try {
      await _profilePhotoRef(uid).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
    await _userDoc(uid).delete();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection.limit(400).get();
      if (snapshot.docs.isEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _cache(String uid, ProfileSnapshot snapshot) async {
    await localStore.savePersonalInfo(uid, snapshot.personalInfo);
    if (snapshot.profileMemory != null) {
      await localStore.saveProfileMemory(uid, snapshot.profileMemory!);
    }
    if (snapshot.extractedValues != null) {
      await localStore.saveExtractedValues(uid, snapshot.extractedValues!);
    }
    await localStore.saveProfilePhotoUrl(uid, snapshot.photoUrl);
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }
}
