import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/hive_local_store.dart';

sealed class ThemeState extends Equatable {
  const ThemeState(this.mode);

  final ThemeMode mode;

  @override
  List<Object?> get props => [mode];
}

final class ThemeReady extends ThemeState {
  const ThemeReady(super.mode);
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({
    required HiveLocalStore localStore,
    required ThemeMode initialMode,
  }) : _localStore = localStore,
       super(ThemeReady(initialMode));

  final HiveLocalStore _localStore;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _localStore.saveThemeMode(mode);
    emit(ThemeReady(mode));
  }
}
