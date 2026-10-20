import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import '../../app/game_session.dart';
import '../../app/routes.dart';
import '../../feedback/feedback_scope.dart';
import '../../feedback/game_feedback.dart';
import '../../game/map_scene.dart';
import '../../game/model/model.dart';
import '../../game/network_game_view.dart';
import '../../game/sim/sim.dart';
import '../../music/track.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'complaint_popup.dart';
import 'run_status_card.dart';

/// 5 · Fase Jalan: hari dari [session] berjalan 06:00 → 24:00.
///
/// Jam digerakkan `Ticker` dan hanya jalan selama rute ini paling atas:
/// berhenti begitu Panel Atur Antrean mulai meluncur masuk (bukan setelah
/// transisinya selesai), saat back, dan saat app di latar belakang.
/// Komplain menjeda hari sampai dijawab. Tombol back = hari dibatalkan,
/// kembali ke Fase Rancang. 24:00 → layar hasil.
///
/// Musik mengikuti jam hari: santai, tegang selama jam sibuk, lalu meredup
/// di 24:00.
class RunPhaseScreen extends StatefulWidget {
  const RunPhaseScreen({super.key, required this.session});

  final GameSession session;

  @override
  State<RunPhaseScreen> createState() => _RunPhaseScreenState();
}

class _RunPhaseScreenState extends State<RunPhaseScreen>
    with SingleTickerProviderStateMixin {
  late final GameState _game = widget.session.currentDay();
  late final Ticker _ticker = createTicker(_tick);
  Duration? _lastTick;
  bool _fastForward = false;
  bool _finished = false;

  /// Komplain yang sudah berbunyi (yang sudah tampil saat layar dibuka tidak
  /// berbunyi lagi).
  Complaint? _heardComplaint;

  /// Rute ini paling atas (tidak tertutup panel, tidak sedang di-back).
  bool _onTop = true;

  DaySim get _day => _game.day!;

  @override
  void initState() {
    super.initState();
    _heardComplaint = _day.complaint;
    _game.addListener(_onGameChanged);
    _requestMusic();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _onTop = ModalRoute.isCurrentOf(context) ?? true;
    _syncClock();
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) return;
    final seconds = math.min(
      (elapsed - last).inMicroseconds / Duration.microsecondsPerSecond,
      SimClock.maxFrameSeconds,
    );
    _game.advanceDay(seconds * (_fastForward ? SimClock.fastForward : 1));
  }

  void _onGameChanged() {
    final complaint = _day.complaint;
    if (complaint != null && complaint != _heardComplaint) {
      FeedbackScope.cue(context, Cue.complaint);
    }
    _heardComplaint = complaint;
    _syncClock();
    _requestMusic();
    if (_game.phase == GamePhase.result) _finish();
    setState(() {});
  }

  /// Jam jalan selama rute paling atas, hari berjalan, dan tidak ada
  /// komplain menunggu.
  void _syncClock() {
    final run =
        _onTop && _game.phase == GamePhase.run && _day.complaint == null;
    if (run == _ticker.isActive) return;
    if (run) {
      _lastTick = null;
      _ticker.start();
    } else {
      _ticker.stop();
    }
  }

  void _requestMusic() {
    if (_game.phase != GamePhase.run) return;
    widget.session.music.request(Track.forDay(_day));
  }

  /// Hari selesai: catat hasilnya, lalu layar berhasil bila lulus.
  void _finish() {
    if (_finished) return;
    _finished = true;
    final result = widget.session.finish();
    widget.session.music.endDay();
    FeedbackScope.cue(context, result.passed ? Cue.win : Cue.fail);
    context.go(result.passed ? AppRoutes.success : AppRoutes.fail);
  }

  /// Buka Panel Atur Antrean; jam berhenti sekarang juga supaya hari tidak
  /// maju selama panel meluncur masuk.
  void _openQueue() {
    _onTop = false;
    _syncClock();
    context.go(AppRoutes.queueOf(_game.level.number));
  }

  void _manageQueue() {
    _onTop = false;
    _game.dismissComplaint();
    _openQueue();
  }

  String _mapLabel() {
    final houses = _day.frame.houses.values;
    int count(HouseState s) => houses.where((h) => h.state == s).length;
    return 'Peta jaringan malam hari: ${count(HouseState.ok)} rumah lancar, '
        '${count(HouseState.slow)} mulai lambat, '
        '${count(HouseState.jam)} macet.';
  }

  @override
  Widget build(BuildContext context) {
    final complaint = _day.complaint;
    final complainer = complaint == null
        ? null
        : _game.level.house(complaint.houseId);
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        // Jam berhenti sekarang juga, bukan setelah transisi keluar: hari
        // yang dibatalkan tidak boleh maju (dan meminta musik) lagi.
        _onTop = false;
        _syncClock();
        widget.session.abandon(_game);
      },
      child: Scaffold(
        backgroundColor: AppColors.groundNight,
        body: NightScope(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenGutter),
                  child: RunStatusCard(
                    day: _day,
                    fastForward: _fastForward,
                    onFastForward: () =>
                        setState(() => _fastForward = !_fastForward),
                    onPause: _openQueue,
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: NetworkGameView(
                          state: _game,
                          alignment: Alignment.topCenter,
                          semanticLabel: _mapLabel(),
                        ),
                      ),
                      if (complaint != null && complainer != null)
                        Positioned(
                          left: AppSpacing.screenGutter,
                          right: AppSpacing.screenGutter,
                          bottom: AppSpacing.s18,
                          child: ComplaintPopup(
                            name: complainer.customer,
                            house: complainer.label,
                            clockMinutes: complaint.minute,
                            message: complainer.complaint,
                            onManageQueue: _manageQueue,
                            onIgnore: _game.dismissComplaint,
                          ),
                        ),
                    ],
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
