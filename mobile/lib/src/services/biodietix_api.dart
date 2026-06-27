import 'dart:convert';
import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/personal_info.dart';
import '../models/product.dart';
import '../models/product_evaluation.dart';
import '../models/profile_memory.dart';

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
    this.requestTimeout = const Duration(seconds: 30),
    this.uploadTimeout = const Duration(seconds: 90),
  }) : baseUrl = apiUrl.replaceAll(RegExp(r'/+$'), ''),
       _accessTokenProvider = accessTokenProvider ?? _firebaseAccessToken,
       _appCheckTokenProvider = appCheckTokenProvider ?? _firebaseAppCheckToken,
       _client = client ?? http.Client();

  final String baseUrl;
  final Duration requestTimeout;
  final Duration uploadTimeout;
  final Future<String?> Function() _accessTokenProvider;
  final Future<String?> Function() _appCheckTokenProvider;
  final http.Client _client;

  static bool isConfiguredUrl(String apiUrl) {
    final uri = Uri.tryParse(apiUrl.trim());
    if (uri == null || uri.host.isEmpty) return false;
    if (uri.scheme == 'https') return true;
    return uri.scheme == 'http' &&
        {'localhost', '127.0.0.1', '10.0.2.2'}.contains(uri.host);
  }

  Future<Map<String, dynamic>> health() async {
    _ensureConfigured();
    final response = await _client
        .get(Uri.parse('$baseUrl/health'))
        .timeout(requestTimeout);
    return _decode(response);
  }

  Future<BloodAnalysisResult> analyzeBloodPdf({
    required File file,
    required PersonalInfo personalInfo,
    required List<String> allergies,
  }) async {
    _ensureConfigured();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/v1/analyze/blood-pdf'),
    );
    request.headers.addAll(await _authorizationHeaders());
    request.fields['gender'] = personalInfo.gender;
    request.fields['age'] = personalInfo.age.toString();
    if (personalInfo.weightKg != null) {
      request.fields['weight_kg'] = personalInfo.weightKg.toString();
    }
    if (personalInfo.heightCm != null) {
      request.fields['height_cm'] = personalInfo.heightCm.toString();
    }
    request.fields['allergies_json'] = jsonEncode(allergies);
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await http.Response.fromStream(
      await _client.send(request).timeout(uploadTimeout),
    );
    final payload = _decode(response);
    return BloodAnalysisResult(
      profileMemory: ProfileMemory.fromJson(
        payload['profile_memory'] as Map<String, dynamic>,
      ),
      extractedValues: (payload['extracted_values'] as Map).map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      textPreview: payload['text_preview']?.toString() ?? '',
    );
  }

  Future<AllergyAnalysisResult> analyzeAllergyPdf(File file) async {
    _ensureConfigured();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/v1/analyze/allergy-pdf'),
    );
    request.headers.addAll(await _authorizationHeaders());
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await http.Response.fromStream(
      await _client.send(request).timeout(uploadTimeout),
    );
    final payload = _decode(response);
    return AllergyAnalysisResult(
      allergies: _stringList(payload['allergies']),
      textPreview: payload['text_preview']?.toString() ?? '',
    );
  }

  Future<Product> lookupProduct(String barcode) async {
    _ensureConfigured();
    final response = await _client
        .get(
          Uri.parse('$baseUrl/v1/product/lookup/$barcode'),
          headers: await _authorizationHeaders(),
        )
        .timeout(requestTimeout);
    final payload = _decode(response);
    return Product.fromJson(payload['product'] as Map<String, dynamic>);
  }

  Future<ProductEvaluation> evaluateProduct({
    required Product product,
    required ProfileMemory profileMemory,
  }) async {
    _ensureConfigured();
    final response = await _client
        .post(
          Uri.parse('$baseUrl/v1/product/evaluate'),
          headers: {
            ...await _authorizationHeaders(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'product': product.toJson(),
            'profile_memory': profileMemory.toJson(),
          }),
        )
        .timeout(requestTimeout);
    return ProductEvaluation.fromJson(_decode(response));
  }

  void _ensureConfigured() {
    if (!isConfiguredUrl(baseUrl)) {
      throw Exception(
        'A public HTTPS or local development API URL is required.',
      );
    }
  }

  static Future<String?> _firebaseAccessToken() async {
    return FirebaseAuth.instance.currentUser?.getIdToken();
  }

  static Future<String?> _firebaseAppCheckToken() async {
    return FirebaseAppCheck.instance.getToken();
  }

  Future<Map<String, String>> _authorizationHeaders() async {
    final token = await _accessTokenProvider();
    if (token == null || token.isEmpty) {
      throw const BioDietixApiException(
        statusCode: 401,
        message: 'Authentication session is unavailable. Please sign in again.',
      );
    }
    final appCheckToken = await _appCheckTokenProvider();
    return {
      'Authorization': 'Bearer $token',
      if (appCheckToken != null && appCheckToken.isNotEmpty)
        'X-Firebase-AppCheck': appCheckToken,
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic decoded;
    try {
      decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } on FormatException {
      throw BioDietixApiException(
        statusCode: response.statusCode,
        message: 'BioDietix API returned an invalid response.',
      );
    }
    final payload = decoded is Map
        ? decoded.map((key, value) => MapEntry(key.toString(), value))
        : <String, dynamic>{};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BioDietixApiException(
        statusCode: response.statusCode,
        message:
            payload['detail']?.toString() ?? 'BioDietix API request failed.',
      );
    }
    return payload;
  }

  List<String> _stringList(dynamic value) {
    if (value is List) return value.map((item) => item.toString()).toList();
    return const [];
  }
}

class BioDietixApiException implements Exception {
  const BioDietixApiException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  bool get isNotFound {
    final normalized = message.toLowerCase();
    return statusCode == 404 || normalized.contains('404');
  }

  @override
  String toString() => message;
}
