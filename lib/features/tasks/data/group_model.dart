class Group {
  // Gleiches Muster wie Group::parsePersonalUserId im Backend (ohne führende Nullen).
  static final _personalGroupPattern = RegExp(
    r'^Personal user ([1-9]\d*)$',
    caseSensitive: false,
  );

  final int id;
  final String name;
  final int? personalUserId;
  final int? projectId;
  final bool isGlobal;
  final int? memberCount;
  final bool isCurrentUserMember;

  /// Anzeigename: Benutzername einer persönlichen Gruppe
  /// (Backend-Feld `personal_user_name`), sonst null.
  final String? displayName;

  const Group({
    required this.id,
    required this.name,
    this.personalUserId,
    this.projectId,
    this.isGlobal = false,
    this.memberCount,
    this.isCurrentUserMember = false,
    this.displayName,
  });

  /// Persönliche Gruppe = `personal_user_id` gesetzt (bzw. Name
  /// "Personal user {id}" bei Altdaten); Team-Gruppen haben keines davon.
  bool get isPersonal => personalUserId != null;

  String get label {
    final display = displayName?.trim();
    return display != null && display.isNotEmpty ? display : name;
  }

  /// Liest die User-ID aus "Personal user {id}"; null bei Team-Gruppen.
  static int? parsePersonalUserId(String name) {
    final match = _personalGroupPattern.firstMatch(name.trim());
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  // Wie im Backend (Group::resolvePersonalUserId): die FK-Spalte
  // personal_user_id hat Vorrang, der Name ist nur Fallback.
  factory Group.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? '').toString();
    final rawPersonalUserId = json['personal_user_id'];
    return Group(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      name: name,
      personalUserId: rawPersonalUserId != null
          ? int.tryParse(rawPersonalUserId.toString())
          : parsePersonalUserId(name),
      displayName: json['personal_user_name']?.toString(),
      projectId: int.tryParse('${json['project_id']}'),
      memberCount: int.tryParse('${json['member_count']}'),
      isCurrentUserMember:
          json['is_current_user_member'] == true ||
          json['is_current_user_member'] == 1 ||
          json['is_current_user_member'] == '1',
      isGlobal:
          json['is_global'] == true ||
          json['is_global'] == 1 ||
          json['is_global'] == '1',
    );
  }
}
