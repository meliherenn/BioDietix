import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:biodietix_mobile/src/models/personal_info.dart';
import 'package:biodietix_mobile/src/models/product.dart';
import 'package:biodietix_mobile/src/models/profile_memory.dart';
import 'package:biodietix_mobile/src/services/app_check_service.dart';
import 'package:biodietix_mobile/src/services/biodietix_api.dart';
import 'package:biodietix_mobile/src/services/pdf_upload_source.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      expect(captured.headers['X-Request-ID'], isNotEmpty);
    },
  );

  test('App Check provider exceptions produce a typed safe error', () async {
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
              (error) => error.code,
              'code',
              BioDietixApiErrorCode.appCheckUnavailable,
            )
            .having(
              (error) => error.message,
              'message',
              isNot(contains(rawFirebaseError)),
            ),
      ),
    );
  });

  test('typed App Check network failures remain distinguishable', () async {
    final api = BioDietixApi(
      'https://api.example.com',
      appCheckEnabled: true,
      client: MockClient((_) async => http.Response('{}', 200)),
      accessTokenProvider: () async => 'firebase-token',
      appCheckTokenProvider: () async =>
          throw const AppCheckFailure(AppCheckFailureKind.network),
    );

    await expectLater(
      api.lookupProduct('5449000000996'),
      throwsA(
        isA<BioDietixApiException>().having(
          (error) => error.code,
          'code',
          BioDietixApiErrorCode.appCheckNetwork,
        ),
      ),
    );
  });

  test(
    'backend invalid App Check response has a dedicated error code',
    () async {
      final api = BioDietixApi(
        'https://api.example.com',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'detail': 'Invalid app attestation token.'}),
            403,
          ),
        ),
        accessTokenProvider: () async => 'firebase-token',
        appCheckTokenProvider: () async => 'rejected-app-check-token',
      );

      await expectLater(
        api.lookupProduct('5449000000996'),
        throwsA(
          isA<BioDietixApiException>().having(
            (error) => error.code,
            'code',
            BioDietixApiErrorCode.appCheckRejected,
          ),
        ),
      );
    },
  );

  test('blood and allergy uploads use versioned endpoints', () async {
    final requests = <http.Request>[];
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'biodietix_api_test_',
    );
    final pdf = File('${temporaryDirectory.path}/report.pdf');
    await pdf.writeAsBytes(const [0x25, 0x50, 0x44, 0x46, 0x2d]);
    final api = BioDietixApi(
      'https://api.example.com',
      client: MockClient((request) async {
        requests.add(request);
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
        pdf: PdfUploadSource.fromPath(pdf.path, name: 'report.pdf'),
        personalInfo: const PersonalInfo(age: 30),
        allergies: const [],
      );
      await api.analyzeAllergyPdf(
        PdfUploadSource.fromPath(pdf.path, name: 'report.pdf'),
      );
    } finally {
      await temporaryDirectory.delete(recursive: true);
    }

    expect(requests.map((request) => request.url.path), [
      '/v1/analyze/blood-pdf',
      '/v1/analyze/allergy-pdf',
    ]);
    for (final request in requests) {
      expect(request.headers['Authorization'], 'Bearer firebase-token');
      expect(request.headers['X-Firebase-AppCheck'], 'app-check-token');
    }
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

  test('bytes-only PDF fallback uploads both report types', () async {
    final paths = <String>[];
    final api = BioDietixApi(
      'https://api.example.com',
      client: MockClient((request) async {
        paths.add(request.url.path);
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
    final source = PdfUploadSource(
      name: 'report.pdf',
      size: 9,
      bytes: Uint8List.fromList(const [
        0x25,
        0x50,
        0x44,
        0x46,
        0x2d,
        1,
        2,
        3,
        4,
      ]),
    );

    await api.analyzeBloodPdf(
      pdf: source,
      personalInfo: const PersonalInfo(age: 30),
      allergies: const [],
    );
    await api.analyzeAllergyPdf(source);

    expect(paths, ['/v1/analyze/blood-pdf', '/v1/analyze/allergy-pdf']);
  });

  test('picker cancellation returns no PDF source', () async {
    final picker = PdfPickerService(pickFiles: () async => null);

    expect(await picker.pickPdf(), isNull);
  });

  test('picker maps a bytes-only platform file', () async {
    final picker = PdfPickerService(
      pickFiles: () async => FilePickerResult([
        PlatformFile(
          name: 'report.pdf',
          size: 5,
          bytes: Uint8List.fromList(const [1, 2, 3, 4, 5]),
        ),
      ]),
    );

    final selected = await picker.pickPdf();

    expect(selected, isNotNull);
    expect(selected!.hasPath, isFalse);
    expect(selected.hasBytes, isTrue);
  });

  test('unavailable PDF source produces a file-read error', () async {
    final api = BioDietixApi(
      'https://api.example.com',
      client: MockClient((_) async => http.Response('{}', 200)),
      accessTokenProvider: () async => 'firebase-token',
      appCheckTokenProvider: () async => 'app-check-token',
    );

    await expectLater(
      api.analyzeAllergyPdf(const PdfUploadSource(name: 'report.pdf', size: 0)),
      throwsA(
        isA<BioDietixApiException>().having(
          (error) => error.code,
          'code',
          BioDietixApiErrorCode.pdfFileRead,
        ),
      ),
    );
  });

  test('Firebase Auth token errors preserve the network category', () async {
    final api = BioDietixApi(
      'https://api.example.com',
      client: MockClient((_) async => http.Response('{}', 200)),
      accessTokenProvider: () async =>
          throw FirebaseAuthException(code: 'network-request-failed'),
      appCheckTokenProvider: () async => 'app-check-token',
    );

    await expectLater(
      api.lookupProduct('5449000000996'),
      throwsA(
        isA<BioDietixApiException>().having(
          (error) => error.code,
          'code',
          BioDietixApiErrorCode.network,
        ),
      ),
    );
  });

  for (final scenario
      in <({int status, String detail, BioDietixApiErrorCode code})>[
        (
          status: 401,
          detail: 'Invalid or expired authentication token.',
          code: BioDietixApiErrorCode.authentication,
        ),
        (
          status: 403,
          detail: 'Invalid app attestation token.',
          code: BioDietixApiErrorCode.appCheckRejected,
        ),
        (
          status: 422,
          detail: 'Blood PDF could not be parsed.',
          code: BioDietixApiErrorCode.backendValidation,
        ),
        (
          status: 500,
          detail: 'Internal server error.',
          code: BioDietixApiErrorCode.serviceUnavailable,
        ),
      ]) {
    test('backend ${scenario.status} keeps its distinct category', () async {
      final api = BioDietixApi(
        'https://api.example.com',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'detail': scenario.detail}),
            scenario.status,
            headers: {'x-request-id': 'server-request'},
          ),
        ),
        accessTokenProvider: () async => 'firebase-token',
        appCheckTokenProvider: () async => 'app-check-token',
      );

      await expectLater(
        api.lookupProduct('5449000000996'),
        throwsA(
          isA<BioDietixApiException>()
              .having((error) => error.code, 'code', scenario.code)
              .having(
                (error) => error.requestId,
                'requestId',
                'server-request',
              ),
        ),
      );
    });
  }

  test('non-JSON backend 500 preserves status and service category', () async {
    final api = BioDietixApi(
      'https://api.example.com',
      client: MockClient(
        (_) async => http.Response(
          '<html>upstream failure</html>',
          500,
          headers: {'x-request-id': 'server-non-json'},
        ),
      ),
      accessTokenProvider: () async => 'firebase-token',
      appCheckTokenProvider: () async => 'app-check-token',
    );

    await expectLater(
      api.lookupProduct('5449000000996'),
      throwsA(
        isA<BioDietixApiException>()
            .having((error) => error.statusCode, 'statusCode', 500)
            .having(
              (error) => error.code,
              'code',
              BioDietixApiErrorCode.serviceUnavailable,
            )
            .having((error) => error.requestId, 'requestId', 'server-non-json'),
      ),
    );
  });

  test('request timeout produces a timeout category', () async {
    final api = BioDietixApi(
      'https://api.example.com',
      requestTimeout: const Duration(milliseconds: 10),
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response('{}', 200);
      }),
      accessTokenProvider: () async => 'firebase-token',
      appCheckTokenProvider: () async => 'app-check-token',
    );

    await expectLater(
      api.lookupProduct('5449000000996'),
      throwsA(
        isA<BioDietixApiException>().having(
          (error) => error.code,
          'code',
          BioDietixApiErrorCode.timeout,
        ),
      ),
    );
  });
}
