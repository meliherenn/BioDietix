import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/personal_info.dart';
import '../../../../models/profile_memory.dart';
import '../../data/profile_repository.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileLoaded extends ProfileState {
  const ProfileLoaded({
    required this.personalInfo,
    required this.allergies,
    required this.profileMemory,
    required this.extractedValues,
    required this.photoUrl,
    this.saving = false,
    this.notice,
    this.error,
  });

  final PersonalInfo personalInfo;
  final List<String> allergies;
  final ProfileMemory? profileMemory;
  final Map<String, dynamic>? extractedValues;
  final String? photoUrl;
  final bool saving;
  final String? notice;
  final String? error;

  ProfileLoaded copyWith({
    PersonalInfo? personalInfo,
    List<String>? allergies,
    ProfileMemory? profileMemory,
    Map<String, dynamic>? extractedValues,
    String? photoUrl,
    bool? saving,
    String? notice,
    String? error,
    bool clearProfileMemory = false,
    bool clearExtractedValues = false,
    bool clearNotice = false,
    bool clearError = false,
  }) {
    return ProfileLoaded(
      personalInfo: personalInfo ?? this.personalInfo,
      allergies: allergies ?? this.allergies,
      profileMemory: clearProfileMemory
          ? null
          : profileMemory ?? this.profileMemory,
      extractedValues: clearExtractedValues
          ? null
          : extractedValues ?? this.extractedValues,
      photoUrl: photoUrl ?? this.photoUrl,
      saving: saving ?? this.saving,
      notice: clearNotice ? null : notice ?? this.notice,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    personalInfo.gender,
    personalInfo.age,
    personalInfo.weightKg,
    personalInfo.heightCm,
    allergies,
    profileMemory?.toJson(),
    extractedValues,
    photoUrl,
    saving,
    notice,
    error,
  ];
}

final class ProfileFailure extends ProfileState {
  const ProfileFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required ProfileRepository repository})
    : _repository = repository,
      super(const ProfileInitial());

  final ProfileRepository _repository;
  String? _uid;

  Future<void> load(String uid) async {
    _uid = uid;
    emit(const ProfileLoading());
    try {
      final snapshot = await _repository.load(uid);
      emit(
        ProfileLoaded(
          personalInfo: snapshot.personalInfo,
          allergies: snapshot.allergies,
          profileMemory: snapshot.profileMemory,
          extractedValues: snapshot.extractedValues,
          photoUrl: snapshot.photoUrl,
        ),
      );
    } catch (error) {
      emit(ProfileFailure(error.toString()));
    }
  }

  void updatePersonalInfo(PersonalInfo personalInfo) {
    final current = state;
    if (current is! ProfileLoaded) return;
    emit(current.copyWith(personalInfo: personalInfo, clearNotice: true));
  }

  void updateAllergies(List<String> allergies) {
    final current = state;
    if (current is! ProfileLoaded) return;
    emit(current.copyWith(allergies: allergies, clearNotice: true));
  }

  Future<void> saveProfile() async {
    final uid = _uid;
    final current = state;
    if (uid == null || current is! ProfileLoaded) return;

    emit(current.copyWith(saving: true, clearError: true, clearNotice: true));
    try {
      await _repository.saveProfile(
        uid: uid,
        personalInfo: current.personalInfo,
        allergies: current.allergies,
        profileMemory: current.profileMemory,
      );
      emit(current.copyWith(saving: false, notice: 'profileSavedInline'));
    } catch (error) {
      emit(
        current.copyWith(
          saving: false,
          error: error.toString(),
          clearNotice: true,
        ),
      );
    }
  }

  Future<void> saveProfileMemory({
    required ProfileMemory profileMemory,
    required Map<String, dynamic>? extractedValues,
  }) async {
    final uid = _uid;
    final current = state;
    if (uid == null || current is! ProfileLoaded) return;

    final updated = current.copyWith(
      profileMemory: profileMemory,
      allergies: profileMemory.allergies,
      extractedValues: extractedValues,
      saving: true,
      clearError: true,
      clearNotice: true,
    );
    emit(updated);
    try {
      await _repository.saveProfileMemory(
        uid: uid,
        profileMemory: profileMemory,
        extractedValues: extractedValues,
      );
      emit(updated.copyWith(saving: false, notice: 'bloodAnalyzed'));
    } catch (error) {
      emit(updated.copyWith(saving: false, error: error.toString()));
    }
  }

  Future<void> saveAllergies(List<String> allergies) async {
    final uid = _uid;
    final current = state;
    if (uid == null || current is! ProfileLoaded) return;
    final memory = current.profileMemory?.copyWithAllergies(allergies);
    final updated = current.copyWith(
      allergies: allergies,
      profileMemory: memory,
      saving: true,
      clearError: true,
      clearNotice: true,
    );
    emit(updated);
    try {
      await _repository.saveAllergies(
        uid: uid,
        allergies: allergies,
        profileMemory: current.profileMemory,
      );
      emit(updated.copyWith(saving: false));
    } catch (error) {
      emit(updated.copyWith(saving: false, error: error.toString()));
    }
  }

  Future<void> uploadProfilePhoto(File file) async {
    final uid = _uid;
    final current = state;
    if (uid == null || current is! ProfileLoaded) return;

    emit(current.copyWith(saving: true, clearError: true, clearNotice: true));
    try {
      final url = await _repository.uploadProfilePhoto(uid: uid, file: file);
      emit(
        current.copyWith(
          photoUrl: url,
          saving: false,
          notice: 'profilePhotoUpdated',
        ),
      );
    } catch (error) {
      emit(current.copyWith(saving: false, error: error.toString()));
    }
  }

  Future<void> clearHealthData() async {
    final uid = _uid;
    final current = state;
    if (uid == null || current is! ProfileLoaded) return;

    emit(current.copyWith(saving: true, clearError: true, clearNotice: true));
    try {
      await _repository.clearHealthData(uid);
      emit(
        current.copyWith(
          personalInfo: const PersonalInfo(),
          allergies: const [],
          saving: false,
          notice: 'healthDataCleared',
          clearProfileMemory: true,
          clearExtractedValues: true,
        ),
      );
    } catch (error) {
      emit(current.copyWith(saving: false, error: error.toString()));
    }
  }

  Future<void> deleteAllUserData() async {
    final uid = _uid;
    final current = state;
    if (uid == null || current is! ProfileLoaded) return;
    await _repository.deleteAllUserData(uid);
  }
}
