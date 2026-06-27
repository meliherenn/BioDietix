import 'dart:convert';
import 'dart:io';

import 'package:biodietix_mobile/src/models/personal_info.dart';
import 'package:biodietix_mobile/src/models/product.dart';
import 'package:biodietix_mobile/src/models/profile_memory.dart';
import 'package:biodietix_mobile/src/services/biodietix_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('allows only HTTPS or loopback development HTTP URLs', () {
    expect(BioDietixApi.isConfiguredUrl('https://api.example.com'), isTrue);
    expect(BioDietixApi.isConfiguredUrl('http://10.0.2.2:8000'), isTrue);
    expect(BioDietixApi.isConfiguredUrl('http://example.com'), isFalse);
  });

  test('product evaluation uses v1 and sends Firebase bearer token', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'decision': 'recommended',
          'reasons': [],
          'positives': [],
          'alternatives': [],
          'data_quality': {'level': 'high'},
          'medical_note': 'Educational use only.',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = BioDietixApi(
      'https://api.example.com/',
      client: client,
      accessTokenProvider: () async => 'firebase-token',
      appCheckTokenProvider: () async => 'app-check-token',
    );

    final result = await api.evaluateProduct(
      product: const Product(name: 'Oats'),
      profileMemory: ProfileMemory.fromJson(const {'allergies': []}),
    );

    expect(captured.url.path, '/v1/product/evaluate');
    expect(captured.headers['Authorization'], 'Bearer firebase-token');
    expect(captured.headers['X-Firebase-AppCheck'], 'app-check-token');
    expect(result.decision, 'recommended');
  });

  test('product lookup uses the versioned endpoint', () async {
    late http.Request captured;
    final api = BioDietixApi(
      'https://api.example.com',
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'product': {'barcode': '5449000000996', 'name': 'Test product'},
          }),
          200,
        );
      }),
      accessTokenProvider: () async => 'firebase-token',
      appCheckTokenProvider: () async => 'app-check-token',
    );

    final product = await api.lookupProduct('5449000000996');

    expect(captured.url.path, '/v1/product/lookup/5449000000996');
    expect(captured.headers['Authorization'], 'Bearer firebase-token');
    expect(captured.headers['X-Firebase-AppCheck'], 'app-check-token');
    expect(product.barcode, '5449000000996');
  });

  test(
    'disabled App Check never requests a token or sends its header',
    () async {
      late http.Request captured;
      var appCheckTokenCalls = 0;
      final api = BioDietixApi(
        'https://api.example.com',
        appCheckEnabled: false,
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'product': {'barcode': '5449000000996'},
            }),
            200,
          );
        }),
        accessTokenProvider: () async => 'firebase-token',
        appCheckTokenProvider: () async {
          appCheckTokenCalls += 1;
          throw Exception('Firebase App Check must not be called');
        },
      );

      await api.lookupProduct('5449000000996');

      expect(appCheckTokenCalls, 0);
      expect(captured.headers['Authorization'], 'Bearer firebase-token');
      expect(captured.headers.containsKey('X-Firebase-AppCheck'), isFalse);
    },
  );

  test('App Check failures are replaced with a safe client error', () async {
    const rawFirebaseError = '403 body: App attestation failed';
    final api = BioDietixApi(
      'https://api.example.com',
      appCheckEnabled: true,
      client: MockClient((_) async => http.Response('{}', 200)),
      accessTokenProvider: () async => 'firebase-token',
      appCheckTokenProvider: () async => throw Exception(rawFirebaseError),
    );

    await expectLater(
      api.lookupProduct('5449000000996'),
      throwsA(
        isA<BioDietixApiException>()
            .having((error) => error.statusCode, 'statusCode', 403)
            .having(
              (error) => error.message,
              'message',
              isNot(contains(rawFirebaseError)),
            ),
      ),
    );
  });

  test('blood and allergy uploads use versioned endpoints', () async {
    final requestedPaths = <String>[];
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'biodietix_api_test_',
    );
    final pdf = File('${temporaryDirectory.path}/report.pdf');
    await pdf.writeAsBytes(const [0x25, 0x50, 0x44, 0x46, 0x2d]);
    final api = BioDietixApi(
      'https://api.example.com',
      client: MockClient((request) async {
        requestedPaths.add(request.url.path);
        if (request.url.path.endsWith('blood-pdf')) {
          return http.Response(
            jsonEncode({
              'profile_memory': {'allergies': <String>[]},
              'extracted_values': <String, dynamic>{},
              'text_preview': '',
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({'allergies': <String>[], 'text_preview': ''}),
          200,
        );
      }),
      accessTokenProvider: () async => 'firebase-token',
      appCheckTokenProvider: () async => 'app-check-token',
    );

    try {
      await api.analyzeBloodPdf(
        file: pdf,
        personalInfo: const PersonalInfo(age: 30),
        allergies: const [],
      );
      await api.analyzeAllergyPdf(pdf);
    } finally {
      await temporaryDirectory.delete(recursive: true);
    }

    expect(requestedPaths, [
      '/v1/analyze/blood-pdf',
      '/v1/analyze/allergy-pdf',
    ]);
  });

  test(
    'protected request fails locally when auth session is missing',
    () async {
      final api = BioDietixApi(
        'https://api.example.com',
        client: MockClient((_) async => http.Response('{}', 200)),
        accessTokenProvider: () async => null,
        appCheckTokenProvider: () async => null,
      );

      expect(
        () => api.lookupProduct('12345678'),
        throwsA(isA<BioDietixApiException>()),
      );
    },
  );
}
