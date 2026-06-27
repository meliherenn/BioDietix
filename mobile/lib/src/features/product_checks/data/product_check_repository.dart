import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/app_config.dart';
import '../../../core/storage/hive_local_store.dart';
import '../../../models/product.dart';
import '../../../models/product_evaluation.dart';
import '../domain/product_check.dart';

class ProductCheckRepository {
  const ProductCheckRepository({
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
        .collection('product_checks');
  }

  Future<List<ProductCheck>> load(String uid) async {
    final cached = await localStore.loadProductChecks(uid);
    if (!firebaseReady) return cached;

    try {
      final result = await _collection(
        uid,
      ).orderBy('createdAt', descending: true).get();
      final items = result.docs.map(_fromDoc).toList();
      await localStore.saveProductChecks(uid, items);
      return items;
    } on Exception {
      return cached;
    }
  }

  Future<ProductCheck> createFromEvaluation({
    required String uid,
    required Product product,
    required ProductEvaluation evaluation,
  }) async {
    final now = DateTime.now();
    final doc = firebaseReady ? _collection(uid).doc() : null;
    final item = ProductCheck.fromEvaluation(
      id: doc?.id ?? now.microsecondsSinceEpoch.toString(),
      product: product,
      evaluation: evaluation,
      now: now,
    );

    await _upsertCache(uid, item);
    if (doc != null) {
      await doc.set(_toFirestore(item));
    }
    return item;
  }

  Future<ProductCheck> updateNote({
    required String uid,
    required ProductCheck item,
    required String note,
  }) async {
    final updated = item.copyWith(note: note, updatedAt: DateTime.now());
    await _upsertCache(uid, updated);
    if (firebaseReady) {
      await _collection(
        uid,
      ).doc(item.id).set(_toFirestore(updated), SetOptions(merge: true));
    }
    return updated;
  }

  Future<void> delete({required String uid, required ProductCheck item}) async {
    final next = (await localStore.loadProductChecks(
      uid,
    )).where((cached) => cached.id != item.id).toList();
    await localStore.saveProductChecks(uid, next);
    if (firebaseReady) {
      await _collection(uid).doc(item.id).delete();
    }
  }

  Future<void> _upsertCache(String uid, ProductCheck item) async {
    final cached = await localStore.loadProductChecks(uid);
    final next = [item, ...cached.where((cached) => cached.id != item.id)]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await localStore.saveProductChecks(uid, next);
  }

  ProductCheck _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return ProductCheck(
      id: doc.id,
      productName: data['productName']?.toString() ?? '',
      brand: data['brand']?.toString() ?? '',
      barcode: data['barcode']?.toString() ?? '',
      decision: data['decision']?.toString() ?? 'recommended',
      dataQualityLevel: data['dataQualityLevel']?.toString() ?? 'medium',
      note: data['note']?.toString() ?? '',
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  Map<String, dynamic> _toFirestore(ProductCheck item) {
    return {
      'productName': item.productName,
      'brand': item.brand,
      'barcode': item.barcode,
      'decision': item.decision,
      'dataQualityLevel': item.dataQualityLevel,
      'note': item.note,
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
