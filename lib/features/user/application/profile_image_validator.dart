import 'dart:typed_data';

/// Prüft Profilbilder bereits vor dem Upload und liefert eine deutsche
/// Fehlermeldung oder `null` bei einer gültigen Datei.
///
/// Diese Prüfung verbessert das Nutzerfeedback. Die verbindliche
/// Sicherheitsprüfung findet zusätzlich im Backend statt.
class ProfileImageValidator {
  static const int maxFileSize = 5 * 1024 * 1024;

  /// Erlaubt ausschließlich JPEG- und PNG-Dateien, deren Dateiendung mit der
  /// binären Dateisignatur übereinstimmt.
  static String? validate(Uint8List bytes, String filename) {
    if (bytes.length > maxFileSize) {
      return 'Das Bild darf maximal 5 MB groß sein.';
    }

    final extension = filename.split('.').last.toLowerCase();
    if (!const {'jpg', 'jpeg', 'png'}.contains(extension)) {
      return 'Nur JPG- und PNG-Bilder sind erlaubt.';
    }

    // Magic Bytes verhindern, dass nur die Dateiendung als Bild getarnt wird.
    final isJpeg =
        bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff;
    final isPng =
        bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a;

    if (!isJpeg && !isPng) {
      return 'Die Datei enthält kein gültiges JPG- oder PNG-Bild.';
    }
    if (isJpeg && extension != 'jpg' && extension != 'jpeg') {
      return 'Die Dateiendung stimmt nicht mit dem Bildformat überein.';
    }
    if (isPng && extension != 'png') {
      return 'Die Dateiendung stimmt nicht mit dem Bildformat überein.';
    }

    return null;
  }
}
