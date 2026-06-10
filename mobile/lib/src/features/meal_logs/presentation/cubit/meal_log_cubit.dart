import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/meal_log_repository.dart';
import '../../domain/meal_log.dart';

sealed class MealLogState extends Equatable {
  const MealLogState();

  @override
  List<Object?> get props => [];
}

final class MealLogInitial extends MealLogState {
  const MealLogInitial();
}

final class MealLogLoading extends MealLogState {
  const MealLogLoading({this.cached = const []});

  final List<MealLog> cached;

  @override
  List<Object?> get props => [cached];
}

final class MealLogLoaded extends MealLogState {
  const MealLogLoaded({
    required this.items,
    this.fromCache = false,
    this.busy = false,
    this.error,
  });

  final List<MealLog> items;
  final bool fromCache;
  final bool busy;
  final String? error;

  MealLogLoaded copyWith({
    List<MealLog>? items,
    bool? fromCache,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return MealLogLoaded(
      items: items ?? this.items,
      fromCache: fromCache ?? this.fromCache,
      busy: busy ?? this.busy,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [items, fromCache, busy, error];
}

final class MealLogFailure extends MealLogState {
  const MealLogFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class MealLogCubit extends Cubit<MealLogState> {
  MealLogCubit({required MealLogRepository repository})
    : _repository = repository,
      super(const MealLogInitial());

  final MealLogRepository _repository;
  String? _uid;

  Future<void> load(String uid) async {
    _uid = uid;
    emit(const MealLogLoading());
    try {
      final items = await _repository.load(uid);
      emit(MealLogLoaded(items: items));
    } catch (error) {
      emit(MealLogFailure(error.toString()));
    }
  }

  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null) return;
    final current = state;
    if (current is MealLogLoaded) {
      emit(MealLogLoading(cached: current.items));
    }
    await load(uid);
  }

  Future<void> create({
    required String title,
    required String note,
    required int calories,
  }) async {
    final uid = _uid;
    final current = state;
    if (uid == null || current is! MealLogLoaded) return;

    emit(current.copyWith(busy: true, clearError: true));
    try {
      final item = await _repository.create(
        uid: uid,
        title: title,
        note: note,
        calories: calories,
      );
      emit(
        current.copyWith(
          items: [item, ...current.items],
          busy: false,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(current.copyWith(busy: false, error: error.toString()));
    }
  }

  Future<void> update({
    required MealLog item,
    required String title,
    required String note,
    required int calories,
  }) async {
    final uid = _uid;
    final current = state;
    if (uid == null || current is! MealLogLoaded) return;

    emit(current.copyWith(busy: true, clearError: true));
    try {
      final updated = await _repository.update(
        uid: uid,
        item: item,
        title: title,
        note: note,
        calories: calories,
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

  Future<void> delete(MealLog item) async {
    final uid = _uid;
    final current = state;
    if (uid == null || current is! MealLogLoaded) return;

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
