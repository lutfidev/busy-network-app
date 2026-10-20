import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../feedback/feedback_scope.dart';
import '../music/track.dart';
import '../theme/theme.dart';
import 'game_session.dart';
import 'router.dart';
import 'routes.dart';

class JaringanSibukApp extends StatefulWidget {
  const JaringanSibukApp({
    super.key,
    this.initialLocation = AppRoutes.home,
    this.session,
  });

  final String initialLocation;

  /// Sesi permainan; default sesi baru (test bisa mengisi hari sendiri).
  final GameSession? session;

  @override
  State<JaringanSibukApp> createState() => _JaringanSibukAppState();
}

class _JaringanSibukAppState extends State<JaringanSibukApp>
    with WidgetsBindingObserver {
  late final GameSession _session = widget.session ?? GameSession();
  late final GoRouter _router = createRouter(
    initialLocation: widget.initialLocation,
    session: _session,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router.routerDelegate.addListener(_onRouteChanged);
    _playMusicFor(widget.initialLocation);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.routerDelegate.removeListener(_onRouteChanged);
    _router.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _session.music.setForeground(state == AppLifecycleState.resumed);

  void _onRouteChanged() =>
      _playMusicFor(_router.routerDelegate.currentConfiguration.uri.path);

  /// Lagu santai di semua layar kecuali Fase Jalan (& Panel Antrean di
  /// atasnya), yang memilih lagunya sendiri dari jam hari.
  void _playMusicFor(String location) {
    if (Uri.parse(location).path.startsWith(AppRoutes.run)) return;
    _session.music.request(Track.calm);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Jaringan Sibuk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _router,
      builder: (context, child) =>
          FeedbackScope(feedback: _session.feedback, child: child!),
    );
  }
}
