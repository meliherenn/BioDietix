import 'dart:convert';

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
