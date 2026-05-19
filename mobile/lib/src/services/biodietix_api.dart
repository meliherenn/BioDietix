import 'dart:convert';
import 'dart:io';

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
  BioDietixApi(String apiUrl) : baseUrl = apiUrl.replaceAll(RegExp(r'/+$'), '');

  final String baseUrl;

  static bool isConfiguredUrl(String apiUrl) {
    final uri = Uri.tryParse(apiUrl.trim());
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  Future<Map<String, dynamic>> health() async {
    _ensureConfigured();
    final response = await http.get(Uri.parse('$baseUrl/health'));
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
      Uri.parse('$baseUrl/analyze/blood-pdf'),
    );
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

    final response = await http.Response.fromStream(await request.send());
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
      Uri.parse('$baseUrl/analyze/allergy-pdf'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await http.Response.fromStream(await request.send());
    final payload = _decode(response);
    return AllergyAnalysisResult(
      allergies: _stringList(payload['allergies']),
      textPreview: payload['text_preview']?.toString() ?? '',
    );
  }

  Future<Product> lookupProduct(String barcode) async {
    _ensureConfigured();
    final response = await http.get(
      Uri.parse('$baseUrl/product/lookup/$barcode'),
    );
    final payload = _decode(response);
    return Product.fromJson(payload['product'] as Map<String, dynamic>);
  }

  Future<ProductEvaluation> evaluateProduct({
    required Product product,
    required ProfileMemory profileMemory,
  }) async {
    _ensureConfigured();
    final response = await http.post(
      Uri.parse('$baseUrl/product/evaluate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'product': product.toJson(),
        'profile_memory': profileMemory.toJson(),
      }),
    );
    return ProductEvaluation.fromJson(_decode(response));
  }

  void _ensureConfigured() {
    if (!isConfiguredUrl(baseUrl)) {
      throw Exception('A public HTTPS BioDietix API URL is required.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
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
