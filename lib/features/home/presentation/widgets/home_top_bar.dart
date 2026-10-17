import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../projects/application/project_controller.dart';
import '../../../user/application/user_controller.dart';
import '../../../user/presentation/profile_avatar.dart';

class HomeTopBar extends StatefulWidget {
  const HomeTopBar({
    super.key,
    required this.userController,
    required this.projectController,
    required this.onRefresh,
    required this.onLogout,
    required this.onOpenProfile,
    required this.onOpenProjects,
    required this.onOpenAssistant,
  });

  final UserController userController;
  final ProjectController projectController;
  final Future<void> Function() onRefresh;
  final VoidCallback onLogout;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenProjects;
  final VoidCallback onOpenAssistant;

  @override
  State<HomeTopBar> createState() => _HomeTopBarState();
}

class _HomeTopBarState extends State<HomeTopBar> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;
  bool _isRefreshing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      // Die Suche ist noch nicht mit Filtern verbunden; Schließen verwirft den Text.
      if (!_isSearchVisible) _searchController.clear();
    });
  }

  Future<void> _refresh() async {
    // Während eines laufenden Refreshs weitere Klicks ignorieren.
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  ButtonStyle _identityButtonStyle(ColorScheme scheme) => TextButton.styleFrom(
    foregroundColor: scheme.onSurface,
    minimumSize: Size.zero,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
  );

  Widget _buildActions(ColorScheme scheme, {required bool compact}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const ValueKey('user-profile-assistant'),
          tooltip: widget.projectController.selectedProject == null
              ? 'Zuerst ein Projekt auswählen'
              : 'Projekt-Chat öffnen',
          onPressed: widget.projectController.selectedProject == null
              ? null
              : widget.onOpenAssistant,
          constraints: const BoxConstraints.tightFor(width: 40, height: 48),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.auto_awesome_outlined),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          // Auf schmalen Displays Platz für Projektname und Aktionsleiste lassen.
          width: _isSearchVisible ? (compact ? 150 : 260) : 40,
          height: 48,
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('user-profile-search-toggle'),
                tooltip: _isSearchVisible ? 'Suche schließen' : 'Suchen',
                onPressed: _toggleSearch,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 48,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
              ),
              if (_isSearchVisible)
                Expanded(
                  child: TextField(
                    key: const ValueKey('user-profile-search-field'),
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Suchen',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.sm,
                      ),
                      filled: true,
                      fillColor: scheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          key: const ValueKey('user-profile-refresh'),
          tooltip: 'Aktualisieren',
          onPressed: _isRefreshing ? null : _refresh,
          constraints: const BoxConstraints.tightFor(width: 40, height: 48),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          icon: _isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
        ),
        IconButton(
          key: const ValueKey('user-profile-logout'),
          tooltip: 'Abmelden',
          onPressed: widget.onLogout,
          constraints: const BoxConstraints.tightFor(width: 40, height: 48),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.logout, color: scheme.error),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 600;
            return Container(
              key: const ValueKey('home-top-bar'),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  widget.userController,
                  widget.projectController,
                ]),
                builder: (context, _) {
                  final user = widget.userController.currentUser;
                  final userName = user?.name ?? 'Benutzer';
                  final projectName =
                      widget.projectController.selectedProject?.name ??
                      (widget.projectController.isLoading
                          ? 'Projekte werden geladen'
                          : 'Kein Projekt');
                  final imageBytes =
                      widget.userController.currentProfilePictureBytes;

                  final identity = Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Tooltip(
                        message: 'Profil öffnen',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: const ValueKey('home-profile-avatar'),
                            customBorder: const CircleBorder(),
                            onTap: widget.onOpenProfile,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              child: ProfileAvatar(
                                user: user,
                                imageBytes: imageBytes,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Hallo ',
                                  style: TextStyle(color: scheme.onSurface),
                                ),
                                Flexible(
                                  child: TextButton(
                                    key: const ValueKey('home-user-name'),
                                    onPressed: widget.onOpenProfile,
                                    style: _identityButtonStyle(scheme),
                                    child: Text(
                                      userName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Aktuelles Projekt',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Icon(
                                  Icons.folder_outlined,
                                  size: 18,
                                  color: scheme.primary,
                                ),
                                Flexible(
                                  child: TextButton(
                                    key: const ValueKey('home-current-project'),
                                    onPressed: widget.onOpenProjects,
                                    style: _identityButtonStyle(scheme),
                                    child: Text(
                                      projectName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        identity,
                        Align(
                          alignment: Alignment.centerRight,
                          child: _buildActions(scheme, compact: compact),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: identity),
                      _buildActions(scheme, compact: compact),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
