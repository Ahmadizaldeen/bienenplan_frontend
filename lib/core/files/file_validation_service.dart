import 'dart:convert';
import 'dart:typed_data';

/// Validiert Dateien vor dem Upload und liefert bei Erfolg `null`.
///
/// Diese Prüfung verbessert das Feedback im Client. Das Backend muss dieselbe
/// Prüfung nochmals durchführen, weil Frontend-Code umgangen werden kann.
class FileValidationService {
  static const int defaultMaxFileSize = 10 * 1024 * 1024;

  /// Prüft Dateiendung und erkennbare Binärstruktur für unterstützte Dateien.
  ///
  /// PDF wird über `%PDF-` erkannt. TXT muss gültiges UTF-8 ohne Null-Bytes
  /// enthalten. Bilder werden über ihre Dateisignatur geprüft, Office-Dateien
  /// über die ZIP-Signatur (`PK`), die DOCX und XLSX verwenden.
  static String? validate(
    Uint8List bytes,
    String filename, {
    Set<String> allowedExtensions = const {'pdf', 'txt'},
    int maxFileSize = defaultMaxFileSize,
  }) {
    // Größenprüfung erfolgt vor der Inhaltsanalyse, damit große Dateien nicht
    // unnötig weiter verarbeitet werden.
    if (bytes.isEmpty) return 'Die Datei ist leer.';
    if (bytes.length > maxFileSize) {
      return 'Die Datei ist zu groß (max. 10 MB).';
    }

    // Die Endung ist nur ein Filter; die tatsächliche Datei wird anschließend
    // zusätzlich über ihre Signatur bzw. ihr Encoding geprüft.
    final extension = _extensionOf(filename);
    if (!allowedExtensions.contains(extension)) {
      return 'Diese Dateiendung ist nicht erlaubt.';
    }

    if (extension == 'pdf') {
      // Die PDF-Signatur verhindert, dass beliebige Bytes als .pdf umbenannt
      // und anschließend hochgeladen werden.
      final isPdf =
          bytes.length >= 5 && String.fromCharCodes(bytes.take(5)) == '%PDF-';
      return isPdf ? null : 'Die Datei ist kein gültiges PDF.';
    }

    if (extension == 'txt') {
      // Nullbytes und ungültiges UTF-8 sind ein Hinweis auf Binärdaten oder
      // beschädigten Text trotz der Endung .txt.
      if (bytes.contains(0)) return 'Die TXT-Datei enthält binäre Daten.';
      try {
        utf8.decode(bytes);
        return null;
      } on FormatException {
        return 'Die TXT-Datei enthält kein gültiges UTF-8.';
      }
    }

    // Magic Bytes erlauben den Abgleich zwischen Dateiendung und Inhalt.
    final isPng = _startsWith(bytes, const [0x89, 0x50, 0x4e, 0x47]);
    final isJpeg = _startsWith(bytes, const [0xff, 0xd8, 0xff]);
    final isGif = _startsWith(bytes, const [0x47, 0x49, 0x46, 0x38]);

    if (isPng && extension != 'png' ||
        isJpeg && extension != 'jpg' && extension != 'jpeg' ||
        isGif && extension != 'gif') {
      return 'Die Dateiendung stimmt nicht mit dem Dateiformat überein.';
    }
    if (extension == 'png' && !isPng) return 'Die Datei ist kein gültiges PNG.';
    if (extension == 'jpg' && !isJpeg)
      return 'Die Datei ist kein gültiges JPG.';
    if (extension == 'jpeg' && !isJpeg) {
      return 'Die Datei ist kein gültiges JPEG.';
    }
    if (extension == 'gif' && !isGif) return 'Die Datei ist kein gültiges GIF.';
    if ((extension == 'docx' || extension == 'xlsx') &&
        !_startsWith(bytes, const [0x50, 0x4b])) {
      return 'Die Office-Datei ist binär ungültig.';
    }

    return null;
  }

  static bool _startsWith(Uint8List bytes, List<int> signature) {
    // Der Vergleich arbeitet direkt auf Bytes und ist unabhängig vom
    // Dateinamen oder vom vom Client gemeldeten MIME-Typ.
    if (bytes.length < signature.length) return false;
    for (var index = 0; index < signature.length; index++) {
      if (bytes[index] != signature[index]) return false;
    }
    return true;
  }

  static String _extensionOf(String filename) {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == filename.length - 1) return '';
    return filename.substring(dotIndex + 1).toLowerCase();
  }
}
