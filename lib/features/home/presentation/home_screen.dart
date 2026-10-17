import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../projects/application/project_controller.dart';
import '../../projects/presentation/project_list_widget.dart';
import '../../sync/application/change_poller.dart';
import '../../sync/data/change_repository.dart';
import '../../tasks/application/task_controller.dart';
import '../../tasks/presentation/task_container_screen.dart';
import '../../user/application/user_controller.dart';
import 'widgets/home_top_bar.dart';
import 'widgets/user_profile_sidebar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onLogout,
    this.taskController,
    this.projectController,
    this.userController,
    this.changeRepository,
    this.pollInterval = const Duration(seconds: 5),
  });

  final VoidCallback onLogout;

  /// Quelle für GET /api/changes; Tests injizieren hier eine Fake-Variante.
  final ChangeRepositoryContract? changeRepository;
  final Duration pollInterval;

  /// Optional von außen injizierte Controller (z.B. für Tests). Wird keiner
  /// übergeben, verwaltet HomeScreen seine eigenen Controller.
  final TaskController? taskController;
  final ProjectController? projectController;
  final UserController? userController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>(); // Key für das Scaffold, um z.B. Snackbars anzuzeigen
  late int _groupsRevision;

  // HomeScreen besitzt beide Controller zentral, damit Pull-to-Refresh und
  // der Refresh-Button dieselben Daten neu laden können.
  late final TaskController _taskController =
      widget.taskController ?? TaskController();
  late final ProjectController _projectController =
      widget.projectController ?? ProjectController();
  late final UserController _userController =
      widget.userController ?? UserController();

  late final ChangePoller _changePoller = ChangePoller(
    repository: widget.changeRepository ?? ChangeRepository(),
    onRefreshRequired: _silentRefresh,
    interval: widget.pollInterval,
  );

  // Polling startet erst nach Baseline und Initial-Load.
  bool _pollingReady = false;
  bool _appResumed = true;

  @override
  void initState() {
    super.initState();
    _groupsRevision = _projectController.groupsRevision;
    _projectController.addListener(_handleProjectUpdate);
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _appResumed = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _initialize();
  }

  /// Erst die Baseline, dann der Full Load: Änderungen, die während des
  /// Initial-Loads passieren, liegen damit nach dem Cursor und werden beim
  /// ersten Poll gemeldet.
  Future<void> _initialize() async {
    await _changePoller.establishBaseline();
    if (!mounted) return;
    final loaded = await _loadAll();
    if (!mounted) return;
    if (!loaded) _changePoller.markRefreshRequired();
    _pollingReady = true;
    if (_appResumed) _changePoller.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    if (!_pollingReady) return;
    if (_appResumed) {
      _changePoller.resume();
    } else {
      _changePoller.pause();
    }
  }

  void _handleProjectUpdate() {
    if (!mounted || _groupsRevision == _projectController.groupsRevision) {
      return;
    }
    _groupsRevision = _projectController.groupsRevision;
    // Gruppenänderungen können Sichtbarkeit und Aufgabenzuweisungen ändern.
    // Die Revision verhindert, dass die Ladebenachrichtigungen neue Loads starten.
    _taskController.loadTasks();
    _projectController.loadProjects();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _changePoller.dispose();
    _projectController.removeListener(_handleProjectUpdate);
    // Nur aufräumen, wenn dieser Screen die Controller selbst erzeugt hat.
    // Von außen injizierte Controller gehören dem Owner und dürfen hier
    // nicht disposed werden.
    if (widget.taskController == null) _taskController.dispose();
    if (widget.projectController == null) _projectController.dispose();
    if (widget.userController == null) _userController.dispose();
    super.dispose();
  }

  // Manueller Refresh (Button und Pull-to-Refresh): sofort und mit sichtbarem
  // Ladezustand wie bisher.
  Future<void> _refreshAll() => _loadAll();

  Future<bool> _loadAll({bool silent = false}) async {
    final results = await Future.wait([
      _taskController.loadTasks(silent: silent),
      _projectController.loadProjects(silent: silent),
      _userController.loadCurrentUser(silent: silent),
    ]);
    return results.every((ok) => ok);
  }

  // Vom Poller ausgelöst: bestehende Daten bleiben sichtbar, kein Spinner.
  // Offene Dialoge halten eigene Formularzustände und werden nicht überschrieben.
  Future<bool> _silentRefresh() {
    if (!mounted) return Future.value(false);
    return _loadAll(silent: true);
  }

  void _handleLogout() {
    _changePoller.stop();
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                title: const Text(
                  'Profil & Einstellungen',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: IconButton(
                  key: const ValueKey('profile-sidebar-close'),
                  tooltip: 'Menü schließen',
                  onPressed: () => _scaffoldKey.currentState?.closeDrawer(),
                  icon: const Icon(Icons.close),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: UserProfileSidebar(
                    onLogout: _handleLogout,
                    projectController: _projectController,
                    userController: _userController,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                title: const Text(
                  'Projekte',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: IconButton(
                  key: const ValueKey('projects-sidebar-close'),
                  tooltip: 'Projektliste schließen',
                  onPressed: () => _scaffoldKey.currentState?.closeEndDrawer(),
                  icon: const Icon(Icons.close),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ProjectListWidget(controller: _projectController),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.surface, scheme.surfaceContainerLow],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                HomeTopBar(
                  userController: _userController,
                  projectController: _projectController,
                  onRefresh: _refreshAll,
                  onLogout: _handleLogout,
                  onOpenProfile: () => _scaffoldKey.currentState?.openDrawer(),
                  onOpenProjects: () =>
                      _scaffoldKey.currentState?.openEndDrawer(),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: _HomeContent(
                    taskController: _taskController,
                    projectController: _projectController,
                    userController: _userController,
                    changePoller: _changePoller,
                    onRefresh: _refreshAll,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.taskController,
    required this.projectController,
    required this.userController,
    required this.changePoller,
    required this.onRefresh,
  });

  final TaskController taskController;
  final ProjectController projectController;
  final UserController userController;
  final ChangePoller changePoller;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SyncStatusBanner(poller: changePoller),
            AnimatedBuilder(
              animation: projectController,
              builder: (context, _) {
                return TaskListScreen(
                  controller: taskController,
                  projectId: projectController.selectedProject?.id,
                  userController: userController,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Dezenter Hinweis bei Polling-Fehlern; die angezeigten Daten bleiben erhalten.
class _SyncStatusBanner extends StatelessWidget {
  const _SyncStatusBanner({required this.poller});

  final ChangePoller poller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: poller,
      builder: (context, _) {
        final message = poller.errorMessage;
        if (message == null) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        return Padding(
          key: const ValueKey('change-poll-error'),
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Material(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Icon(Icons.sync_problem, color: scheme.onErrorContainer),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      poller.isUnauthorized
                          ? message
                          : '$message Neuer Versuch folgt automatisch.',
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ),
                  if (!poller.isUnauthorized)
                    TextButton(
                      key: const ValueKey('change-poll-retry'),
                      onPressed: poller.isRequestInFlight
                          ? null
                          : poller.pollNow,
                      child: const Text('Jetzt versuchen'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
