import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

enum PdfSourceFailureCode { unavailable, unreadable, empty }

class PdfSourceException implements Exception {
  const PdfSourceException(this.code);

  final PdfSourceFailureCode code;
}

class PdfUploadSource {
  const PdfUploadSource({
    required this.name,
    required this.size,
    this.path,
    this.bytes,
  });

  factory PdfUploadSource.fromPath(String path, {String? name}) {
    final normalizedName = name ?? path.split(Platform.pathSeparator).last;
    return PdfUploadSource(name: normalizedName, size: 0, path: path);
  }

  final String name;
  final int size;
  final String? path;
  final Uint8List? bytes;

  bool get hasPath => path != null && path!.trim().isNotEmpty;
  bool get hasBytes => bytes != null && bytes!.isNotEmpty;
  String get safeNameForLog {
    final extension = name.toLowerCase().endsWith('.pdf') ? '.pdf' : 'other';
    return '<redacted:$extension,length=${name.length}>';
  }

  Future<int> validateReadable() async {
    if (hasPath) {
      try {
        final file = File(path!);
        if (!await file.exists()) {
          throw const PdfSourceException(PdfSourceFailureCode.unreadable);
        }
        final length = await file.length();
        if (length <= 0) {
          throw const PdfSourceException(PdfSourceFailureCode.empty);
        }
        await file.openRead(0, 1).first;
        return length;
      } on PdfSourceException {
        rethrow;
      } on Object catch (_, stackTrace) {
        Error.throwWithStackTrace(
          const PdfSourceException(PdfSourceFailureCode.unreadable),
          stackTrace,
        );
      }
    }
    if (hasBytes) return bytes!.length;
    throw const PdfSourceException(PdfSourceFailureCode.unavailable);
  }

  Future<http.MultipartFile> toMultipartFile(String field) async {
    await validateReadable();
    if (hasPath) {
      return http.MultipartFile.fromPath(field, path!, filename: name);
    }
    return http.MultipartFile.fromBytes(field, bytes!, filename: name);
  }
}

typedef PickFilesCallback = Future<FilePickerResult?> Function();

class PdfPickerService {
  PdfPickerService({PickFilesCallback? pickFiles})
    : _pickFiles = pickFiles ?? _defaultPickFiles;

  final PickFilesCallback _pickFiles;

  Future<PdfUploadSource?> pickPdf() async {
    final result = await _pickFiles();
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    return PdfUploadSource(
      name: file.name,
      size: file.size,
      path: file.path,
      bytes: file.bytes,
    );
  }

  static Future<FilePickerResult?> _defaultPickFiles() {
    return FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
  }
}
