import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/api/api_endpoints.dart';
import '../data/user_model.dart';

/// Zeigt das Profilbild oder Initialen, wenn kein Bild vorhanden bzw. das
/// Laden der Bild-URL fehlgeschlagen ist.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.user,
    this.imageBytes,
    this.size = 52,
  });

  final AppUser? user;
  final Uint8List? imageBytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final picture = user?.picture;
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary),
      alignment: Alignment.center,
      child: Text(
        _initialsFromName(user?.name ?? ''),
        style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700),
      ),
    );

    // Direkt nach dem Upload vermeiden lokale Bytes einen veralteten
    // Browser-Cache. Nach einem Neustart wird stattdessen die Server-URL genutzt.
    if (imageBytes != null) {
      return ClipOval(
        child: Image.memory(
          imageBytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        ),
      );
    }

    if (picture == null || picture.isEmpty) return fallback;

    return ClipOval(
      child: Image.network(
        ApiEndpoints.attachmentUrl(picture),
        key: ValueKey(picture),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }

  static String _initialsFromName(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
