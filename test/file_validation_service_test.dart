import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:bienenplan_frontend/core/files/file_validation_service.dart';

void main() {
  group('FileValidationService', () {
    test('accepts a PDF with a valid PDF signature', () {
      final bytes = Uint8List.fromList('%PDF-1.7'.codeUnits);

      expect(FileValidationService.validate(bytes, 'vertrag.pdf'), isNull);
    });

    test('rejects a PDF with invalid binary content', () {
      final bytes = Uint8List.fromList('plain text'.codeUnits);

      expect(
        FileValidationService.validate(bytes, 'vertrag.pdf'),
        contains('kein gültiges PDF'),
      );
    });

    test('accepts UTF-8 text', () {
      final bytes = Uint8List.fromList(utf8.encode('Notiz ä'));

      expect(FileValidationService.validate(bytes, 'notiz.txt'), isNull);
    });

    test('rejects binary content with a txt extension', () {
      final bytes = Uint8List.fromList([0x48, 0x00, 0x49]);

      expect(
        FileValidationService.validate(bytes, 'notiz.txt'),
        contains('binäre Daten'),
      );
    });

    test('rejects an unsupported extension', () {
      final bytes = Uint8List.fromList('%PDF-1.7'.codeUnits);

      expect(
        FileValidationService.validate(bytes, 'vertrag.exe'),
        contains('Dateiendung'),
      );
    });

    test('accepts PNG bytes when the extension matches', () {
      final bytes = Uint8List.fromList([0x89, 0x50, 0x4e, 0x47]);

      expect(
        FileValidationService.validate(
          bytes,
          'bild.png',
          allowedExtensions: const {'png'},
        ),
        isNull,
      );
    });
  });
}
