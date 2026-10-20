import 'package:busy_network/app/game_session.dart';
import 'package:busy_network/app/routes.dart';
import 'package:busy_network/music/background_music.dart';
import 'package:busy_network/music/track.dart';
import 'package:busy_network/screens/design_phase/design_phase_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../game/sim/sim_fixtures.dart';
import '../test_helpers.dart';
import 'recording_music.dart';

void main() {
  setUpFonts();

  testWidgets('Beranda memutar santai; pindah layar tidak mengulang', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    final out = RecordingMusic();
    await pumpApp(tester, session: musicSession(out));
    expect(out.current, Track.calm);
    await tester.tap(find.text('Main'));
    await tester.pumpAndSettle();
    expect(out.calls, hasLength(1));
  });

  /// Fase Jalan level 5 dari 18:58, dimainkan sampai masuk jam sibuk.
  Future<(RecordingMusic, GameSession)> runIntoRush(WidgetTester tester) async {
    setScreenSize(tester, const Size(390, 844));
    final out = RecordingMusic();
    final session = musicSession(out)
      ..begin(playUntil(designDay(designFiberCables), 18 * 60 + 58));
    await pumpApp(
      tester,
      location: AppRoutes.runOf(5),
      session: session,
      settle: false,
    );
    expect(out.current, Track.calm);
    await playFor(tester, 1);
    expect(out.current, Track.tense);
    return (out, session);
  }

  testWidgets('jam sibuk menegang lalu santai lagi', (tester) async {
    final (out, session) = await runIntoRush(tester);
    playUntil(session.last!, 21 * 60 + 58);
    await playFor(tester, 1);
    expect(out.current, Track.calm);
    expect(out.calls.map((c) => c.track), [
      Track.calm,
      Track.tense,
      Track.calm,
    ]);
    expect(out.calls.last.fade, MusicTiming.crossfade);
  });

  testWidgets('back saat jam sibuk → Rancang santai', (tester) async {
    final (out, _) = await runIntoRush(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(DesignPhaseScreen), findsOneWidget);
    expect(out.current, Track.calm);
  });

  testWidgets('deep link Panel Antrean = tegang', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final out = RecordingMusic();
    await pumpApp(
      tester,
      location: AppRoutes.queueOf(5),
      session: musicSession(out),
    );
    expect(out.current, Track.tense);
  });

  testWidgets('hari selesai → redup lalu santai tertunda', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final out = RecordingMusic();
    final session = musicSession(out)
      ..begin(playUntil(designDay(designFiberCables), 23 * 60 + 50));
    await pumpApp(
      tester,
      location: AppRoutes.runOf(5),
      session: session,
      settle: false,
    );
    await tester.pumpAndSettle();
    expect(session.result, isNotNull);
    expect(out.calls.skip(out.calls.length - 2), [
      (track: null, fade: MusicTiming.dayEndFade, delay: Duration.zero),
      (
        track: Track.calm,
        fade: MusicTiming.crossfade,
        delay: MusicTiming.resultDelay,
      ),
    ]);
  });

  testWidgets('latar belakang menjeda, kembali melanjutkan', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final out = RecordingMusic();
    await pumpApp(tester, session: musicSession(out));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(out.current, isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(out.current, Track.calm);
  });

  testWidgets('sakelar Musik: mati diam, nyala santai lagi', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final out = RecordingMusic();
    await pumpApp(
      tester,
      location: AppRoutes.settings,
      session: musicSession(out),
    );
    expect(out.current, Track.calm);
    await tester.tap(find.text('Musik'));
    await tester.pumpAndSettle();
    expect(out.current, isNull);
    await tester.tap(find.text('Musik'));
    await tester.pumpAndSettle();
    expect(out.current, Track.calm);
  });
}
