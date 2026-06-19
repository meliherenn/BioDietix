import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/product.dart';
import '../../../../models/product_evaluation.dart';
import '../../data/product_check_repository.dart';
import '../../domain/product_check.dart';

sealed class ProductCheckState extends Equatable {
  const ProductCheckState();

  @override
  List<Object?> get props => [];
}

final class ProductCheckInitial extends ProductCheckState {
  const ProductCheckInitial();
}

final class ProductCheckLoading extends ProductCheckState {
  const ProductCheckLoading({this.cached = const []});

  final List<ProductCheck> cached;

  @override
  List<Object?> get props => [cached];
}

final class ProductCheckLoaded extends ProductCheckState {
  const ProductCheckLoaded({
    required this.items,
    this.fromCache = false,
    this.busy = false,
    this.error,
  });

  final List<ProductCheck> items;
  final bool fromCache;
  final bool busy;
  final String? error;

  ProductCheckLoaded copyWith({
    List<ProductCheck>? items,
    bool? fromCache,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return ProductCheckLoaded(
      items: items ?? this.items,
      fromCache: fromCache ?? this.fromCache,
      busy: busy ?? this.busy,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [items, fromCache, busy, error];
}

final class ProductCheckFailure extends ProductCheckState {
  const ProductCheckFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ProductCheckCubit extends Cubit<ProductCheckState> {
  ProductCheckCubit({required ProductCheckRepository repository})
    : _repository = repository,
      super(const ProductCheckInitial());

  final ProductCheckRepository _repository;
  String? _uid;

  Future<void> load(String uid) async {
    _uid = uid;
    emit(const ProductCheckLoading());
    try {
      final items = await _repository.load(uid);
      emit(ProductCheckLoaded(items: items));
    } catch (error) {
      emit(ProductCheckFailure(error.toString()));
    }
  }

  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null) return;
    final current = state;
    if (current is ProductCheckLoaded) {
      emit(ProductCheckLoading(cached: current.items));
    }
    await load(uid);
  }

  Future<void> saveEvaluation({
    required Product product,
    required ProductEvaluation evaluation,
  }) async {
    final uid = _uid;
    final current = state;
    if (uid == null) return;
    final currentItems = switch (current) {
      ProductCheckLoaded(:final items) => items,
      ProductCheckLoading(:final cached) => cached,
      _ => <ProductCheck>[],
    };

    emit(ProductCheckLoaded(items: currentItems, busy: true));
    try {
      final item = await _repository.createFromEvaluation(
        uid: uid,
        product: product,
        evaluation: evaluation,
      );
      emit(ProductCheckLoaded(items: [item, ...currentItems], busy: false));
    } catch (error) {
      emit(
        ProductCheckLoaded(
          items: currentItems,
          busy: false,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> updateNote({
    required ProductCheck item,
    required String note,
  }) async {
    final uid = _uid;
    final current = state;
    if (uid == null || current is! ProductCheckLoaded) return;

    emit(current.copyWith(busy: true, clearError: true));
    try {
      final updated = await _repository.updateNote(
        uid: uid,
        item: item,
        note: note,
      );
      final next =
          current.items
              .map((candidate) => candidate.id == item.id ? updated : candidate)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(current.copyWith(items: next, busy: false, clearError: true));
    } catch (error) {
      emit(current.copyWith(busy: false, error: error.toString()));
    }
  }

  Future<void> delete(ProductCheck item) async {
    final uid = _uid;
    final current = state;
    if (uid == null || current is! ProductCheckLoaded) return;

    emit(current.copyWith(busy: true, clearError: true));
    try {
      await _repository.delete(uid: uid, item: item);
      emit(
        current.copyWith(
          items: current.items
              .where((candidate) => candidate.id != item.id)
              .toList(),
          busy: false,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(current.copyWith(busy: false, error: error.toString()));
    }
  }
}
