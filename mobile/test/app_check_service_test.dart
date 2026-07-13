import 'package:biodietix_mobile/src/core/config/app_config.dart';
import 'package:biodietix_mobile/src/services/app_check_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('provider selection is explicit for disabled, dev, and prod', () {
    expect(
      appCheckProviderFor(flavor: AppFlavor.dev, enabled: false),
      AppCheckProviderKind.disabled,
    );
    expect(
      appCheckProviderFor(flavor: AppFlavor.dev, enabled: true),
      AppCheckProviderKind.debug,
    );
    expect(
      appCheckProviderFor(flavor: AppFlavor.prod, enabled: true),
      AppCheckProviderKind.playIntegrity,
    );
  });

  test('token acquisition retries once with force refresh', () async {
    final refreshValues = <bool>[];
    final service = AppCheckService(
      activate: (_) async {},
      tokenProvider: (forceRefresh) async {
        refreshValues.add(forceRefresh);
        if (!forceRefresh) throw Exception('temporary token failure');
        return 'fresh-token';
      },
    );
    await service.initialize(
      flavor: AppFlavor.dev,
      enabled: true,
      firebaseReady: true,
    );

    expect(await service.getToken(), 'fresh-token');
    expect(refreshValues, [false, true]);
  });

  test('activation failure is surfaced as a typed failure', () async {
    final service = AppCheckService(
      activate: (_) async => throw Exception('Play Integrity 403'),
      tokenProvider: (_) async => 'must-not-be-used',
    );
    await service.initialize(
      flavor: AppFlavor.prod,
      enabled: true,
      firebaseReady: true,
    );

    await expectLater(
      service.getToken(),
      throwsA(
        isA<AppCheckFailure>().having(
          (failure) => failure.kind,
          'kind',
          AppCheckFailureKind.attestation,
        ),
      ),
    );
  });

  test('explicit force refresh never accepts a cached token first', () async {
    final refreshValues = <bool>[];
    final service = AppCheckService(
      activate: (_) async {},
      tokenProvider: (forceRefresh) async {
        refreshValues.add(forceRefresh);
        return 'token';
      },
    );
    await service.initialize(
      flavor: AppFlavor.dev,
      enabled: true,
      firebaseReady: true,
    );

    expect(await service.getToken(forceRefresh: true), 'token');
    expect(refreshValues, [true]);
  });
}
