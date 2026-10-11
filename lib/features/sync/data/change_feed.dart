/// Antwort von GET /api/changes.
///
/// [nextCursor] ist opak und benutzergebunden: Er wird nie lokal ausgewertet
/// oder verglichen, sondern nur beim nächsten Request zurückgegeben.
/// [changes] enthält lediglich Invalidierungs-Hinweise des Backends; für die
/// Entscheidung, ob neu geladen wird, zählt ausschließlich [refreshRequired].
class ChangeFeed {
  const ChangeFeed({
    required this.nextCursor,
    required this.refreshRequired,
    this.changes = const [],
  });

  final String nextCursor;
  final bool refreshRequired;
  final List<Map<String, dynamic>> changes;

  factory ChangeFeed.fromJson(Map<String, dynamic> json) {
    final cursor = json['next_cursor'];
    final refresh = json['refresh_required'];
    final changes = json['changes'];
    if (cursor is! String || cursor.isEmpty || refresh is! bool) {
      throw const FormatException('Ungültiges Änderungs-Datenformat.');
    }
    return ChangeFeed(
      nextCursor: cursor,
      refreshRequired: refresh,
      changes: changes is List
          ? List.unmodifiable(changes.whereType<Map<String, dynamic>>())
          : const [],
    );
  }
}
