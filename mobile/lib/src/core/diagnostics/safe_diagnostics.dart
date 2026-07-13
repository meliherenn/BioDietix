import 'package:flutter/foundation.dart';

void safeDebugLog(
  String component,
  String stage, {
  String? requestId,
  Map<String, Object?> fields = const {},
}) {
  if (!kDebugMode) return;
  final context = <String>[
    'component=$component',
    'stage=$stage',
    if (requestId != null) 'request_id=$requestId',
    ...fields.entries.map((entry) => '${entry.key}=${_safeValue(entry.value)}'),
  ].join(' ');
  debugPrint('BioDietixDiag $context');
}

void safeDebugError(
  String component,
  String stage,
  Object error,
  StackTrace stackTrace, {
  String? requestId,
  String? errorCode,
}) {
  if (!kDebugMode) return;
  safeDebugLog(
    component,
    stage,
    requestId: requestId,
    fields: {
      'result': 'failure',
      'exception_type': error.runtimeType,
      'error_code': errorCode ?? 'n/a',
    },
  );
  debugPrintStack(
    label: 'BioDietixDiag stack component=$component stage=$stage',
    stackTrace: stackTrace,
    maxFrames: 16,
  );
}

String _safeValue(Object? value) {
  final text = value?.toString() ?? 'null';
  final normalized = text.replaceAll(RegExp(r'[\r\n\s]+'), '_');
  return normalized.length <= 160 ? normalized : normalized.substring(0, 160);
}
