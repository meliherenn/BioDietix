import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_repository.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final User user;

  @override
  List<Object?> get props => [user.uid, user.email];
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthFailure extends AuthState {
  const AuthFailure(this.error);

  final Object error;

  @override
  List<Object?> get props => [error.toString()];
}

final class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required AuthRepository repository})
    : _repository = repository,
      super(const AuthLoading()) {
    _subscription = _repository.authStateChanges().listen((user) {
      if (user == null) {
        emit(const AuthUnauthenticated());
      } else {
        emit(AuthAuthenticated(user));
      }
    });
  }

  final AuthRepository _repository;
  late final StreamSubscription<User?> _subscription;

  Future<void> signIn({required String email, required String password}) async {
    emit(const AuthLoading());
    try {
      await _repository.signIn(email: email, password: password);
    } catch (error) {
      emit(AuthFailure(error));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    emit(const AuthLoading());
    try {
      await _repository.signUp(email: email, password: password);
    } catch (error) {
      emit(AuthFailure(error));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> sendPasswordReset(String email) async {
    emit(const AuthLoading());
    try {
      await _repository.sendPasswordReset(email);
      emit(const AuthPasswordResetSent());
      emit(const AuthUnauthenticated());
    } catch (error) {
      emit(AuthFailure(error));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    try {
      await _repository.signInWithGoogle();
    } catch (error) {
      emit(AuthFailure(error));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> signOut() async {
    emit(const AuthLoading());
    await _repository.signOut();
    emit(const AuthUnauthenticated());
  }

  Future<void> deleteAccount() async {
    await _repository.deleteAccount();
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
