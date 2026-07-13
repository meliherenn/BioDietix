import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/diagnostics/safe_diagnostics.dart';
import '../models/personal_info.dart';
import '../models/product.dart';
import '../models/product_evaluation.dart';
import '../models/profile_memory.dart';
import 'app_check_service.dart';
import 'pdf_upload_source.dart';

enum BioDietixApiErrorCode {
  authentication,
  network,
  timeout,
  appCheckConfiguration,
  appCheckNetwork,
  appCheckAttestation,
  appCheckUnavailable,
  appCheckRejected,
  pdfFileRead,
  backendValidation,
  serviceUnavailable,
  invalidResponse,
  requestFailed,
}

class BloodAnalysisResult {
  const BloodAnalysisResult({
    required this.profileMemory,
    required this.extractedValues,
    required this.textPreview,
  });

  final ProfileMemory profileMemory;
  final Map<String, dynamic> extractedValues;
  final String textPreview;
}

class AllergyAnalysisResult {
  const AllergyAnalysisResult({
    required this.allergies,
    required this.textPreview,
  });

  final List<String> allergies;
  final String textPreview;
}

class BioDietixApi {
  BioDietixApi(
    String apiUrl, {
    Future<String?> Function()? accessTokenProvider,
    Future<String?> Function()? appCheckTokenProvider,
    http.Client? client,
    this.appCheckEnabled = AppConfig.appCheckEnabled,
    this.requestTimeout = const Duration(seconds: 30),
    this.uploadTimeout = const Duration(seconds: 90),
  }) : baseUrl = apiUrl.replaceAll(RegExp(r'/+$'), ''),
       _accessTokenProvider = accessTokenProvider ?? _firebaseAccessToken,
       _appCheckTokenProvider = appCheckTokenProvider ?? _firebaseAppCheckToken,
       _usesDefaultAppCheckProvider = appCheckTokenProvider == null,
       _client = client ?? http.Client();

  final String baseUrl;
  final Duration requestTimeout;
  final Duration uploadTimeout;
  final bool appCheckEnabled;
  final Future<String?> Function() _accessTokenProvider;
  final Future<String?> Function() _appCheckTokenProvider;
  final bool _usesDefaultAppCheckProvider;
  final http.Client _client;

  static var _requestSequence = 0;

  static String newRequestId() {
    _requestSequence += 1;
    return 'mobile-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-$_requestSequence';
  }

  static bool isConfiguredUrl(String apiUrl) {
    final uri = Uri.tryParse(apiUrl.trim());
    if (uri == null || uri.host.isEmpty) return false;
    if (uri.scheme == 'https') return true;
    return uri.scheme == 'http' &&
        {'localhost', '127.0.0.1', '10.0.2.2'}.contains(uri.host);
  }

  Future<Map<String, dynamic>> health() {
    final requestId = newRequestId();
    return _guard('health', requestId, () async {
      _ensureConfigured();
      safeDebugLog(
        'api',
        'http_send',
        requestId: requestId,
        fields: {'operation': 'health', 'method': 'GET'},
      );
      final response = await _client
          .get(
            Uri.parse('$baseUrl/health'),
            headers: {'X-Request-ID': requestId},
          )
          .timeout(requestTimeout);
      return _decode(response, operation: 'health', requestId: requestId);
    });
  }

  Future<BloodAnalysisResult> analyzeBloodPdf({
    required PdfUploadSource pdf,
    required PersonalInfo personalInfo,
    required List<String> allergies,
    String? requestId,
  }) {
    final effectiveRequestId = requestId ?? newRequestId();
    return _guard('blood_pdf', effectiveRequestId, () async {
      _ensureConfigured();
      safeDebugLog(
        'api',
        'upload_started',
        requestId: effectiveRequestId,
        fields: {'operation': 'blood_pdf'},
      );
      final readableBytes = await pdf.validateReadable();
      safeDebugLog(
        'api',
        'file_readable',
        requestId: effectiveRequestId,
        fields: {
          'source': pdf.hasPath ? 'path' : 'bytes',
          'size': readableBytes,
        },
      );
      final headers = await _authorizationHeaders(
        requestId: effectiveRequestId,
        operation: 'blood_pdf',
      );
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/v1/analyze/blood-pdf'),
      );
      request.headers.addAll(headers);
      request.fields['gender'] = personalInfo.gender;
      request.fields['age'] = personalInfo.age.toString();
      if (personalInfo.weightKg != null) {
        request.fields['weight_kg'] = personalInfo.weightKg.toString();
      }
      if (personalInfo.heightCm != null) {
        request.fields['height_cm'] = personalInfo.heightCm.toString();
      }
      request.fields['allergies_json'] = jsonEncode(allergies);
      request.files.add(await pdf.toMultipartFile('file'));
      safeDebugLog(
        'api',
        'multipart_created',
        requestId: effectiveRequestId,
        fields: {
          'operation': 'blood_pdf',
          'file_source': pdf.hasPath ? 'path' : 'bytes',
        },
      );

      final response = await _sendMultipart(
        request,
        operation: 'blood_pdf',
        requestId: effectiveRequestId,
      );
      final payload = _decode(
        response,
        operation: 'blood_pdf',
        requestId: effectiveRequestId,
      );
      return BloodAnalysisResult(
        profileMemory: ProfileMemory.fromJson(
          payload['profile_memory'] as Map<String, dynamic>,
        ),
        extractedValues: (payload['extracted_values'] as Map).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
        textPreview: payload['text_preview']?.toString() ?? '',
      );
    });
  }

  Future<AllergyAnalysisResult> analyzeAllergyPdf(
    PdfUploadSource pdf, {
    String? requestId,
  }) {
    final effectiveRequestId = requestId ?? newRequestId();
    return _guard('allergy_pdf', effectiveRequestId, () async {
      _ensureConfigured();
      safeDebugLog(
        'api',
        'upload_started',
        requestId: effectiveRequestId,
        fields: {'operation': 'allergy_pdf'},
      );
      final readableBytes = await pdf.validateReadable();
      safeDebugLog(
        'api',
        'file_readable',
        requestId: effectiveRequestId,
        fields: {
          'source': pdf.hasPath ? 'path' : 'bytes',
          'size': readableBytes,
        },
      );
      final headers = await _authorizationHeaders(
        requestId: effectiveRequestId,
        operation: 'allergy_pdf',
      );
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/v1/analyze/allergy-pdf'),
      );
      request.headers.addAll(headers);
      request.files.add(await pdf.toMultipartFile('file'));
      safeDebugLog(
        'api',
        'multipart_created',
        requestId: effectiveRequestId,
        fields: {
          'operation': 'allergy_pdf',
          'file_source': pdf.hasPath ? 'path' : 'bytes',
        },
      );

      final response = await _sendMultipart(
        request,
        operation: 'allergy_pdf',
        requestId: effectiveRequestId,
      );
      final payload = _decode(
        response,
        operation: 'allergy_pdf',
        requestId: effectiveRequestId,
      );
      return AllergyAnalysisResult(
        allergies: _stringList(payload['allergies']),
        textPreview: payload['text_preview']?.toString() ?? '',
      );
    });
  }

  Future<Product> lookupProduct(String barcode) {
    final requestId = newRequestId();
    return _guard('product_lookup', requestId, () async {
      _ensureConfigured();
      final response = await _client
          .get(
            Uri.parse('$baseUrl/v1/product/lookup/$barcode'),
            headers: await _authorizationHeaders(
              requestId: requestId,
              operation: 'product_lookup',
            ),
          )
          .timeout(requestTimeout);
      final payload = _decode(
        response,
        operation: 'product_lookup',
        requestId: requestId,
      );
      return Product.fromJson(payload['product'] as Map<String, dynamic>);
    });
  }

  Future<ProductEvaluation> evaluateProduct({
    required Product product,
    required ProfileMemory profileMemory,
  }) {
    final requestId = newRequestId();
    return _guard('product_evaluate', requestId, () async {
      _ensureConfigured();
      final response = await _client
          .post(
            Uri.parse('$baseUrl/v1/product/evaluate'),
            headers: {
              ...await _authorizationHeaders(
                requestId: requestId,
                operation: 'product_evaluate',
              ),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'product': product.toJson(),
              'profile_memory': profileMemory.toJson(),
            }),
          )
          .timeout(requestTimeout);
      return ProductEvaluation.fromJson(
        _decode(response, operation: 'product_evaluate', requestId: requestId),
      );
    });
  }

  void _ensureConfigured() {
    if (!isConfiguredUrl(baseUrl)) {
      throw const BioDietixApiException(
        statusCode: 0,
        code: BioDietixApiErrorCode.requestFailed,
        message: 'A public HTTPS or local development API URL is required.',
      );
    }
  }

  static Future<String?> _firebaseAccessToken() async {
    return FirebaseAuth.instance.currentUser?.getIdToken();
  }

  static Future<String?> _firebaseAppCheckToken() {
    return AppCheckService.instance.getToken(forceRefresh: kDebugMode);
  }

  Future<Map<String, String>> _authorizationHeaders({
    required String requestId,
    required String operation,
  }) async {
    String? token;
    try {
      safeDebugLog(
        'api',
        'auth_token_requested',
        requestId: requestId,
        fields: {'operation': operation},
      );
      token = await _accessTokenProvider().timeout(requestTimeout);
      safeDebugLog(
        'api',
        'auth_token_received',
        requestId: requestId,
        fields: {
          'operation': operation,
          'result': token?.isNotEmpty == true ? 'success' : 'empty',
        },
      );
    } on TimeoutException catch (error, stackTrace) {
      safeDebugError(
        'api',
        'auth_token_failed',
        error,
        stackTrace,
        requestId: requestId,
        errorCode: 'timeout',
      );
      rethrow;
    } on FirebaseAuthException catch (error, stackTrace) {
      safeDebugError(
        'api',
        'auth_token_failed',
        error,
        stackTrace,
        requestId: requestId,
        errorCode: error.code,
      );
      final isNetwork = error.code.toLowerCase().contains('network');
      throw BioDietixApiException(
        statusCode: isNetwork ? 0 : 401,
        code: isNetwork
            ? BioDietixApiErrorCode.network
            : BioDietixApiErrorCode.authentication,
        message: isNetwork
            ? 'Network connection failed.'
            : 'Authentication session is unavailable. Please sign in again.',
      );
    }
    if (token == null || token.isEmpty) {
      throw const BioDietixApiException(
        statusCode: 401,
        code: BioDietixApiErrorCode.authentication,
        message: 'Authentication session is unavailable. Please sign in again.',
      );
    }
    if (!appCheckEnabled) {
      return {'Authorization': 'Bearer $token', 'X-Request-ID': requestId};
    }

    String? appCheckToken;
    try {
      safeDebugLog(
        'api',
        'app_check_token_requested',
        requestId: requestId,
        fields: {'operation': operation, 'force_refresh': kDebugMode},
      );
      appCheckToken = _usesDefaultAppCheckProvider
          ? await AppCheckService.instance.getToken(
              forceRefresh: kDebugMode,
              requestId: requestId,
            )
          : await _appCheckTokenProvider().timeout(requestTimeout);
      safeDebugLog(
        'api',
        'app_check_token_received',
        requestId: requestId,
        fields: {
          'operation': operation,
          'result': appCheckToken?.isNotEmpty == true ? 'success' : 'empty',
        },
      );
    } on TimeoutException catch (error, stackTrace) {
      safeDebugError(
        'api',
        'app_check_token_failed',
        error,
        stackTrace,
        requestId: requestId,
        errorCode: 'timeout',
      );
      throw const BioDietixApiException(
        statusCode: 403,
        code: BioDietixApiErrorCode.appCheckNetwork,
        message: 'App verification timed out.',
      );
    } on AppCheckFailure catch (error, stackTrace) {
      safeDebugError(
        'api',
        'app_check_token_failed',
        error,
        stackTrace,
        requestId: requestId,
        errorCode: error.firebaseCode ?? error.kind.name,
      );
      throw BioDietixApiException(
        statusCode: 403,
        code: switch (error.kind) {
          AppCheckFailureKind.configuration =>
            BioDietixApiErrorCode.appCheckConfiguration,
          AppCheckFailureKind.network => BioDietixApiErrorCode.appCheckNetwork,
          AppCheckFailureKind.attestation =>
            BioDietixApiErrorCode.appCheckAttestation,
          AppCheckFailureKind.unavailable =>
            BioDietixApiErrorCode.appCheckUnavailable,
        },
        message: 'App verification could not be completed.',
      );
    } on Object catch (error, stackTrace) {
      safeDebugError(
        'api',
        'app_check_token_failed',
        error,
        stackTrace,
        requestId: requestId,
      );
      throw const BioDietixApiException(
        statusCode: 403,
        code: BioDietixApiErrorCode.appCheckUnavailable,
        message: 'App verification could not be completed.',
      );
    }
    if (appCheckToken == null || appCheckToken.isEmpty) {
      throw const BioDietixApiException(
        statusCode: 403,
        code: BioDietixApiErrorCode.appCheckUnavailable,
        message: 'App verification is unavailable. Please try again.',
      );
    }
    return {
      'Authorization': 'Bearer $token',
      'X-Firebase-AppCheck': appCheckToken,
      'X-Request-ID': requestId,
    };
  }

  Map<String, dynamic> _decode(
    http.Response response, {
    required String operation,
    required String requestId,
  }) {
    final serverRequestId = response.headers['x-request-id'];
    safeDebugLog(
      'api',
      'http_response',
      requestId: requestId,
      fields: {
        'operation': operation,
        'status': response.statusCode,
        'server_request_id': serverRequestId ?? 'missing',
        'content_type': response.headers['content-type'] ?? 'missing',
        'body_bytes': response.bodyBytes.length,
      },
    );

    dynamic decoded;
    try {
      decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } on FormatException {
      final isHttpError =
          response.statusCode < 200 || response.statusCode >= 300;
      throw BioDietixApiException(
        statusCode: response.statusCode,
        code: isHttpError
            ? _responseErrorCode(response.statusCode, '')
            : BioDietixApiErrorCode.invalidResponse,
        message: isHttpError
            ? 'BioDietix API request failed.'
            : 'BioDietix API returned an invalid response.',
        requestId: serverRequestId ?? requestId,
      );
    }
    final payload = decoded is Map
        ? decoded.map((key, value) => MapEntry(key.toString(), value))
        : <String, dynamic>{};
    final detail = payload['detail']?.toString();
    safeDebugLog(
      'api',
      'http_response_detail',
      requestId: requestId,
      fields: {
        'operation': operation,
        'status': response.statusCode,
        'server_request_id': serverRequestId ?? 'missing',
        'detail': _safeResponseDetail(detail),
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final responseDetail = detail ?? 'BioDietix API request failed.';
      throw BioDietixApiException(
        statusCode: response.statusCode,
        code: _responseErrorCode(response.statusCode, responseDetail),
        message: responseDetail,
        requestId: response.headers['x-request-id'] ?? requestId,
      );
    }
    return payload;
  }

  List<String> _stringList(dynamic value) {
    if (value is List) return value.map((item) => item.toString()).toList();
    return const [];
  }

  BioDietixApiErrorCode _responseErrorCode(int statusCode, String detail) {
    final normalized = detail.toLowerCase();
    if (normalized.contains('app attestation')) {
      return normalized.contains('invalid') || normalized.contains('required')
          ? BioDietixApiErrorCode.appCheckRejected
          : BioDietixApiErrorCode.appCheckUnavailable;
    }
    if (statusCode == 401) return BioDietixApiErrorCode.authentication;
    if (statusCode == 403) return BioDietixApiErrorCode.appCheckRejected;
    if (statusCode == 422 ||
        statusCode == 400 ||
        statusCode == 413 ||
        statusCode == 415) {
      return BioDietixApiErrorCode.backendValidation;
    }
    if (statusCode == 503) return BioDietixApiErrorCode.serviceUnavailable;
    if (statusCode >= 500) return BioDietixApiErrorCode.serviceUnavailable;
    return BioDietixApiErrorCode.requestFailed;
  }

  Future<http.Response> _sendMultipart(
    http.MultipartRequest request, {
    required String operation,
    required String requestId,
  }) async {
    safeDebugLog(
      'api',
      'http_send',
      requestId: requestId,
      fields: {'operation': operation, 'method': 'POST'},
    );
    final streamed = await _client.send(request).timeout(uploadTimeout);
    return http.Response.fromStream(streamed).timeout(uploadTimeout);
  }

  Future<T> _guard<T>(
    String operationName,
    String requestId,
    Future<T> Function() operation,
  ) async {
    try {
      return await operation();
    } on BioDietixApiException catch (error, stackTrace) {
      safeDebugError(
        'api',
        'operation_failed',
        error,
        stackTrace,
        requestId: error.requestId ?? requestId,
        errorCode: error.code.name,
      );
      rethrow;
    } on PdfSourceException catch (error, stackTrace) {
      safeDebugError(
        'api',
        'file_read_failed',
        error,
        stackTrace,
        requestId: requestId,
        errorCode: error.code.name,
      );
      throw BioDietixApiException(
        statusCode: 0,
        code: BioDietixApiErrorCode.pdfFileRead,
        message: 'The selected PDF could not be read.',
        requestId: requestId,
      );
    } on TimeoutException catch (error, stackTrace) {
      safeDebugError(
        'api',
        'operation_failed',
        error,
        stackTrace,
        requestId: requestId,
        errorCode: 'timeout',
      );
      throw const BioDietixApiException(
        statusCode: 0,
        code: BioDietixApiErrorCode.timeout,
        message: 'BioDietix API request timed out.',
      );
    } on SocketException catch (error, stackTrace) {
      safeDebugError(
        'api',
        'operation_failed',
        error,
        stackTrace,
        requestId: requestId,
        errorCode: 'socket',
      );
      throw const BioDietixApiException(
        statusCode: 0,
        code: BioDietixApiErrorCode.network,
        message: 'Network connection failed.',
      );
    } on http.ClientException catch (error, stackTrace) {
      safeDebugError(
        'api',
        'operation_failed',
        error,
        stackTrace,
        requestId: requestId,
        errorCode: 'http_client',
      );
      throw const BioDietixApiException(
        statusCode: 0,
        code: BioDietixApiErrorCode.network,
        message: 'Network connection failed.',
      );
    } on Object catch (error, stackTrace) {
      safeDebugError(
        'api',
        'operation_failed',
        error,
        stackTrace,
        requestId: requestId,
        errorCode: operationName,
      );
      rethrow;
    }
  }

  String _safeResponseDetail(String? detail) {
    const allowed = {
      'Authentication required.',
      'Invalid or expired authentication token.',
      'App attestation required.',
      'Invalid app attestation token.',
      'App attestation service unavailable.',
      'Request validation failed.',
      'Blood PDF analysis failed.',
      'Allergy PDF analysis failed.',
      'Blood PDF could not be parsed.',
      'Allergy PDF could not be parsed.',
      'Internal server error.',
      'Uploaded file is empty.',
      'Uploaded file is not a valid PDF.',
      'Only PDF uploads are supported.',
      'Uploaded file must use a PDF content type.',
    };
    if (detail == null) return 'none';
    return allowed.contains(detail)
        ? detail
        : '<redacted:length=${detail.length}>';
  }
}

class BioDietixApiException implements Exception {
  const BioDietixApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.requestId,
  });

  final int statusCode;
  final BioDietixApiErrorCode code;
  final String message;
  final String? requestId;

  String get localizationKey => switch (code) {
    BioDietixApiErrorCode.authentication => 'apiAuthenticationError',
    BioDietixApiErrorCode.network => 'apiNetworkError',
    BioDietixApiErrorCode.timeout => 'apiTimeoutError',
    BioDietixApiErrorCode.appCheckConfiguration => 'appCheckConfigurationError',
    BioDietixApiErrorCode.appCheckNetwork => 'appCheckNetworkError',
    BioDietixApiErrorCode.appCheckAttestation => 'appCheckAttestationError',
    BioDietixApiErrorCode.appCheckUnavailable => 'appCheckUnavailableError',
    BioDietixApiErrorCode.appCheckRejected => 'appCheckRejectedError',
    BioDietixApiErrorCode.pdfFileRead => 'pdfFileReadError',
    BioDietixApiErrorCode.backendValidation => 'pdfValidationError',
    BioDietixApiErrorCode.serviceUnavailable => 'apiServiceUnavailableError',
    BioDietixApiErrorCode.invalidResponse => 'apiInvalidResponseError',
    BioDietixApiErrorCode.requestFailed => 'apiRequestFailedError',
  };

  bool get isNotFound {
    final normalized = message.toLowerCase();
    return statusCode == 404 || normalized.contains('404');
  }

  @override
  String toString() => message;
}
