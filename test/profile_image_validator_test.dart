import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:bienenplan_frontend/features/user/application/profile_image_validator.dart';

void main() {
  group('ProfileImageValidator', () {
    test('accepts JPEG bytes with jpg extension', () {
      final bytes = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]);

      expect(ProfileImageValidator.validate(bytes, 'profil.jpg'), isNull);
    });

    test('accepts PNG signature with png extension', () {
      final bytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
      ]);

      expect(ProfileImageValidator.validate(bytes, 'profil.png'), isNull);
    });

    test('rejects non-image bytes despite allowed extension', () {
      final bytes = Uint8List.fromList('not an image'.codeUnits);

      expect(
        ProfileImageValidator.validate(bytes, 'profil.jpg'),
        contains('kein gültiges'),
      );
    });

    test('rejects mismatching image extension', () {
      final bytes = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]);

      expect(
        ProfileImageValidator.validate(bytes, 'profil.png'),
        contains('Dateiendung'),
      );
    });
  });
}
