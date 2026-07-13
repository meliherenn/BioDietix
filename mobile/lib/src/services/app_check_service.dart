import 'dart:async';
import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/diagnostics/safe_diagnostics.dart';

enum AppCheckProviderKind { disabled, debug, playIntegrity }

AppCheckProviderKind appCheckProviderFor({
  required AppFlavor flavor,
  required bool enabled,
}) {
  if (!enabled) return AppCheckProviderKind.disabled;
  return flavor == AppFlavor.prod
      ? AppCheckProviderKind.playIntegrity
      : AppCheckProviderKind.debug;
}

enum AppCheckFailureKind { configuration, network, attestation, unavailable }

class AppCheckFailure implements Exception {
  const AppCheckFailure(
    this.kind, {
    this.firebaseCode,
    this.sourceType = 'unknown',
  });

  final AppCheckFailureKind kind;
  final String? firebaseCode;
  final String sourceType;
}

class AppCheckService {
  AppCheckService({
    Future<void> Function(AppCheckProviderKind provider)? activate,
    Future<String?> Function(bool forceRefresh)? tokenProvider,
    this.tokenTimeout = const Duration(seconds: 20),
  }) : _activateOverride = activate,
       _tokenProviderOverride = tokenProvider;

  static final instance = AppCheckService();

  final Future<void> Function(AppCheckProviderKind provider)? _activateOverride;
  final Future<String?> Function(bool forceRefresh)? _tokenProviderOverride;
  final Duration tokenTimeout;

  var _enabled = false;
  var _firebaseReady = false;
  AppCheckFailure? _activationFailure;
  AppCheckProviderKind _provider = AppCheckProviderKind.disabled;

  Future<void> initialize({
    required AppFlavor flavor,
    required bool enabled,
    required bool firebaseReady,
  }) async {
    _enabled = enabled;
    _firebaseReady = firebaseReady;
    _activationFailure = null;

    final provider = appCheckProviderFor(flavor: flavor, enabled: enabled);
    _provider = provider;
    if (provider == AppCheckProviderKind.disabled) {
      safeDebugLog('app_check', 'activation', fields: {'provider': 'disabled'});
      return;
    }
    if (!firebaseReady) {
      _activationFailure = const AppCheckFailure(
        AppCheckFailureKind.configuration,
      );
      safeDebugLog(
        'app_check',
        'activation',
        fields: {'result': 'failure', 'error_code': 'firebase_not_ready'},
      );
      return;
    }

    try {
      final override = _activateOverride;
      if (override != null) {
        await override(provider);
      } else {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: provider == AppCheckProviderKind.playIntegrity
              ? const AndroidPlayIntegrityProvider()
              : const AndroidDebugProvider(),
          providerApple: provider == AppCheckProviderKind.playIntegrity
              ? const AppleAppAttestWithDeviceCheckFallbackProvider()
              : const AppleDebugProvider(),
        );
        await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
      }
      safeDebugLog(
        'app_check',
        'activation',
        fields: {'result': 'success', 'provider': provider.name},
      );
    } on Object catch (error, stackTrace) {
      _activationFailure = _classify(error);
      _debugFailure('activation', error, stackTrace, _activationFailure!);
    }
  }

  Future<String?> getToken({
    bool forceRefresh = false,
    String? requestId,
  }) async {
    if (!_enabled || !_firebaseReady) {
      throw const AppCheckFailure(AppCheckFailureKind.configuration);
    }
    final activationFailure = _activationFailure;
    if (activationFailure != null) throw activationFailure;

    AppCheckFailure? lastFailure;
    StackTrace? lastStackTrace;
    final attempts = forceRefresh ? const [true] : const [false, true];
    for (final refresh in attempts) {
      final stopwatch = Stopwatch()..start();
      try {
        safeDebugLog(
          'app_check',
          'token_requested',
          requestId: requestId,
          fields: {'provider': _provider.name, 'force_refresh': refresh},
        );
        final provider = _tokenProviderOverride;
        final token =
            await (provider != null
                    ? provider(refresh)
                    : FirebaseAppCheck.instance.getToken(refresh))
                .timeout(tokenTimeout);
        stopwatch.stop();
        if (token != null && token.isNotEmpty) {
          safeDebugLog(
            'app_check',
            'token_received',
            requestId: requestId,
            fields: {
              'result': 'success',
              'provider': _provider.name,
              'force_refresh': refresh,
              'duration_ms': stopwatch.elapsedMilliseconds,
            },
          );
          return token;
        }
        lastFailure = const AppCheckFailure(AppCheckFailureKind.unavailable);
        lastStackTrace = StackTrace.current;
        safeDebugLog(
          'app_check',
          'token_received',
          requestId: requestId,
          fields: {
            'result': 'failure',
            'error_code': 'empty_token',
            'force_refresh': refresh,
            'duration_ms': stopwatch.elapsedMilliseconds,
          },
        );
      } on Object catch (error, stackTrace) {
        stopwatch.stop();
        lastFailure = _classify(error);
        lastStackTrace = stackTrace;
        _debugFailure(
          'token_failed',
          error,
          stackTrace,
          lastFailure,
          requestId: requestId,
          durationMs: stopwatch.elapsedMilliseconds,
        );
        if (lastFailure.kind == AppCheckFailureKind.configuration) break;
      }
    }
    final failure =
        lastFailure ?? const AppCheckFailure(AppCheckFailureKind.unavailable);
    Error.throwWithStackTrace(failure, lastStackTrace ?? StackTrace.current);
  }

  Future<void> runDebugDiagnostic({required bool authUserPresent}) async {
    if (!kDebugMode || !_enabled) return;
    safeDebugLog(
      'app_check',
      'diagnostic_started',
      fields: {
        'provider': _provider.name,
        'auth_user_present': authUserPresent,
      },
    );
    try {
      await getToken(forceRefresh: true, requestId: 'startup-diagnostic');
      safeDebugLog(
        'app_check',
        'diagnostic_completed',
        fields: {'result': 'success', 'provider': _provider.name},
      );
    } on Object catch (error, stackTrace) {
      final failure = _classify(error);
      _debugFailure('diagnostic_completed', error, stackTrace, failure);
    }
  }

  AppCheckFailure _classify(Object error) {
    if (error is AppCheckFailure) return error;
    final firebaseCode = error is FirebaseException ? error.code : null;
    final sourceType = error.runtimeType.toString();
    if (error is TimeoutException || error is SocketException) {
      return AppCheckFailure(
        AppCheckFailureKind.network,
        firebaseCode: firebaseCode,
        sourceType: sourceType,
      );
    }

    final code = error is FirebaseException ? error.code.toLowerCase() : '';
    final text = error.toString().toLowerCase();
    if (code.contains('network') ||
        text.contains('network') ||
        text.contains('timeout') ||
        text.contains('connection')) {
      return AppCheckFailure(
        AppCheckFailureKind.network,
        firebaseCode: firebaseCode,
        sourceType: sourceType,
      );
    }
    if (text.contains('not registered') ||
        text.contains('api key') ||
        text.contains('project') ||
        text.contains('configuration') ||
        text.contains('400')) {
      return AppCheckFailure(
        AppCheckFailureKind.configuration,
        firebaseCode: firebaseCode,
        sourceType: sourceType,
      );
    }
    if (text.contains('play integrity') ||
        text.contains('attest') ||
        text.contains('integrity') ||
        text.contains('403') ||
        text.contains('401')) {
      return AppCheckFailure(
        AppCheckFailureKind.attestation,
        firebaseCode: firebaseCode,
        sourceType: sourceType,
      );
    }
    return AppCheckFailure(
      AppCheckFailureKind.unavailable,
      firebaseCode: firebaseCode,
      sourceType: sourceType,
    );
  }

  void _debugFailure(
    String stage,
    Object error,
    StackTrace stackTrace,
    AppCheckFailure failure, {
    String? requestId,
    int? durationMs,
  }) {
    safeDebugLog(
      'app_check',
      stage,
      requestId: requestId,
      fields: {
        'result': 'failure',
        'provider': _provider.name,
        'failure_kind': failure.kind.name,
        'source_type': failure.sourceType,
        'firebase_code': failure.firebaseCode ?? 'n/a',
        'duration_ms': durationMs ?? 'n/a',
      },
    );
    safeDebugError(
      'app_check',
      stage,
      error,
      stackTrace,
      requestId: requestId,
      errorCode: failure.firebaseCode ?? failure.kind.name,
    );
  }
}
