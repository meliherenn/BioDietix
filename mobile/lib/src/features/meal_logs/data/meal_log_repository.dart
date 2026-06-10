import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/app_config.dart';
import '../../../core/storage/hive_local_store.dart';
import '../domain/meal_log.dart';

class MealLogRepository {
  const MealLogRepository({
    required this.config,
    required this.localStore,
    required this.firebaseReady,
  });

  final AppConfig config;
  final HiveLocalStore localStore;
  final bool firebaseReady;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return FirebaseFirestore.instance
        .collection('environments')
        .doc(config.environmentCollection)
        .collection('users')
        .doc(uid)
        .collection('meal_logs');
  }

  Future<List<MealLog>> load(String uid) async {
    final cached = await localStore.loadMealLogs(uid);
    if (!firebaseReady) return cached;

    try {
      final result = await _collection(
        uid,
      ).orderBy('createdAt', descending: true).get();
      final items = result.docs.map(_fromDoc).toList();
      await localStore.saveMealLogs(uid, items);
      return items;
    } on Exception {
      return cached;
    }
  }

  Future<MealLog> create({
    required String uid,
    required String title,
    required String note,
    required int calories,
  }) async {
    final now = DateTime.now();
    final doc = firebaseReady ? _collection(uid).doc() : null;
    final item = MealLog(
      id: doc?.id ?? now.microsecondsSinceEpoch.toString(),
      title: title,
      note: note,
      calories: calories,
      createdAt: now,
      updatedAt: now,
    );

    if (doc != null) {
      await doc.set(_toFirestore(item));
    }
    await _upsertCache(uid, item);
    return item;
  }

  Future<MealLog> update({
    required String uid,
    required MealLog item,
    required String title,
    required String note,
    required int calories,
  }) async {
    final updated = item.copyWith(
      title: title,
      note: note,
      calories: calories,
      updatedAt: DateTime.now(),
    );
    if (firebaseReady) {
      await _collection(
        uid,
      ).doc(item.id).set(_toFirestore(updated), SetOptions(merge: true));
    }
    await _upsertCache(uid, updated);
    return updated;
  }

  Future<void> delete({required String uid, required MealLog item}) async {
    if (firebaseReady) {
      await _collection(uid).doc(item.id).delete();
    }
    final next = (await localStore.loadMealLogs(
      uid,
    )).where((cached) => cached.id != item.id).toList();
    await localStore.saveMealLogs(uid, next);
  }

  Future<void> _upsertCache(String uid, MealLog item) async {
    final cached = await localStore.loadMealLogs(uid);
    final next = [item, ...cached.where((cached) => cached.id != item.id)]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await localStore.saveMealLogs(uid, next);
  }

  MealLog _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return MealLog(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      note: data['note']?.toString() ?? '',
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  Map<String, dynamic> _toFirestore(MealLog item) {
    return {
      'title': item.title,
      'note': item.note,
      'calories': item.calories,
      'createdAt': Timestamp.fromDate(item.createdAt),
      'updatedAt': Timestamp.fromDate(item.updatedAt),
    };
  }

  DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
