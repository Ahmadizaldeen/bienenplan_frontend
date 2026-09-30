const taskTitleMaxLength = 85;

typedef TaskText = ({String title, String? description});

/// Leitet aus einem freien Text Titel und Beschreibung ab.
/// Gibt `null` zurück, wenn der Text leer ist.
TaskText? parseTaskText(String input) {
  final text = input.replaceAll('\r\n', '\n').trim();
  if (text.isEmpty) return null;

  final newlineIndex = text.indexOf('\n');
  final firstLine = newlineIndex == -1 ? text : text.substring(0, newlineIndex);

  if (newlineIndex == -1 && firstLine.length <= taskTitleMaxLength) {
    return (title: firstLine, description: null);
  }

  return (
    title: _truncate(firstLine, taskTitleMaxLength).trimRight(),
    description: text,
  );
}

/// Baut aus gespeichertem Titel/Beschreibung wieder den Freitext für das Bearbeiten.
String composeTaskText(String title, String description) {
  final trimmedTitle = title.trim();
  final trimmedDescription = description.trim();
  if (trimmedDescription.isEmpty) return trimmedTitle;
  if (trimmedDescription.startsWith(trimmedTitle)) return trimmedDescription;
  return '$trimmedTitle\n$trimmedDescription';
}

/// Beschreibung für die Anzeige, ohne den am Anfang wiederholten Titel.
String taskDescriptionBody(String title, String description) {
  final trimmedTitle = title.trim();
  final trimmedDescription = description.replaceAll('\r\n', '\n').trim();
  if (trimmedTitle.isEmpty || !trimmedDescription.startsWith(trimmedTitle)) {
    return trimmedDescription;
  }
  return trimmedDescription.substring(trimmedTitle.length).trim();
}

String _truncate(String value, int maxLength) {
  if (value.length <= maxLength) return value;
  var end = maxLength;
  // Kein halbes Surrogat-Paar (z. B. Emoji) abschneiden.
  final lastUnit = value.codeUnitAt(end - 1);
  if (lastUnit >= 0xD800 && lastUnit <= 0xDBFF) end--;
  return value.substring(0, end);
}
