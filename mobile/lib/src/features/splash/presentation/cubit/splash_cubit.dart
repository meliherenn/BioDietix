import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/hive_local_store.dart';
import '../../../auth/data/auth_repository.dart';

sealed class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

final class SplashLoading extends SplashState {
  const SplashLoading();
}

final class SplashReady extends SplashState {
  const SplashReady({
    required this.hasSelectedLanguage,
    required this.hasSeenOnboarding,
    required this.isAuthenticated,
    required this.hasInternet,
    required this.firebaseReady,
  });

  final bool hasSelectedLanguage;
  final bool hasSeenOnboarding;
  final bool isAuthenticated;
  final bool hasInternet;
  final bool firebaseReady;

  SplashReady copyWith({
    bool? hasSelectedLanguage,
    bool? hasSeenOnboarding,
    bool? isAuthenticated,
    bool? hasInternet,
    bool? firebaseReady,
  }) {
    return SplashReady(
      hasSelectedLanguage: hasSelectedLanguage ?? this.hasSelectedLanguage,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      hasInternet: hasInternet ?? this.hasInternet,
      firebaseReady: firebaseReady ?? this.firebaseReady,
    );
  }

  @override
  List<Object?> get props => [
    hasSelectedLanguage,
    hasSeenOnboarding,
    isAuthenticated,
    hasInternet,
    firebaseReady,
  ];
}

final class SplashFailure extends SplashState {
  const SplashFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class SplashCubit extends Cubit<SplashState> {
  SplashCubit({
    required HiveLocalStore localStore,
    required AuthRepository authRepository,
    Future<List<ConnectivityResult>> Function()? connectivityChecker,
  }) : _localStore = localStore,
       _authRepository = authRepository,
       _connectivityChecker =
           connectivityChecker ?? Connectivity().checkConnectivity,
       super(const SplashLoading());

  final HiveLocalStore _localStore;
  final AuthRepository _authRepository;
  final Future<List<ConnectivityResult>> Function() _connectivityChecker;

  Future<void> check() async {
    emit(const SplashLoading());
    try {
      final hasSelectedLanguage = await _localStore.hasSelectedLanguage();
      final hasSeenOnboarding = await _localStore.hasSeenOnboarding();
      final connectivity = await _connectivityChecker();
      final hasInternet = connectivity.any(
        (result) => result != ConnectivityResult.none,
      );
      emit(
        SplashReady(
          hasSelectedLanguage: hasSelectedLanguage,
          hasSeenOnboarding: hasSeenOnboarding,
          isAuthenticated: _authRepository.currentUser != null,
          hasInternet: hasInternet,
          firebaseReady: _authRepository.firebaseReady,
        ),
      );
    } on Exception catch (error) {
      emit(SplashFailure(error.toString()));
    }
  }

  void completeLanguageSelection() {
    final current = state;
    if (current is SplashReady) {
      emit(current.copyWith(hasSelectedLanguage: true));
    }
  }

  Future<void> completeOnboarding() async {
    await _localStore.saveOnboardingSeen();
    final current = state;
    if (current is SplashReady) {
      emit(current.copyWith(hasSeenOnboarding: true));
    } else {
      await check();
    }
  }
}
