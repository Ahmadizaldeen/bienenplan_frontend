import 'dart:typed_data';

import '../../../core/files/file_validation_service.dart';

/// Prüft Profilbilder vor dem Upload und liefert Fehlermeldung oder `null` wenn die Datei gültig ist.
///
/// Diese Prüfung verbessert das Nutzerfeedback. Die verbindliche
/// Sicherheitsprüfung findet zusätzlich im Backend statt.
class ProfileImageValidator {
  // Das Limit bleibt hier als Teil der alten API sichtbar; die eigentliche
  // Prüfung und die Fehlermeldungen kommen aus dem zentralen Service.
  static const int maxFileSize = 5 * 1024 * 1024;

  /// Rückwärtskompatible Fassade für ältere Aufrufer.
  ///
  /// Neue Upload-Oberflächen sollen direkt `FileValidationService` verwenden.
  static String? validate(Uint8List bytes, String filename) {
    return FileValidationService.validate(
      bytes,
      filename,
      allowedExtensions: const {'jpg', 'jpeg', 'png'},
      maxFileSize: maxFileSize,
    );
  }
}
