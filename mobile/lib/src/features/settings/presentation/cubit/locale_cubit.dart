import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/hive_local_store.dart';
import '../../../../i18n.dart';

sealed class LocaleState extends Equatable {
  const LocaleState(this.language);

  final AppLanguage language;

  @override
  List<Object?> get props => [language];
}

final class LocaleReady extends LocaleState {
  const LocaleReady(super.language);
}

class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit({
    required HiveLocalStore localStore,
    required AppLanguage initialLanguage,
  }) : _localStore = localStore,
       super(LocaleReady(initialLanguage));

  final HiveLocalStore _localStore;

  Future<void> setLanguage(AppLanguage language) async {
    await _localStore.saveLanguage(language);
    emit(LocaleReady(language));
  }
}
