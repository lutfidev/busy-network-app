import 'package:busy_network/app/routes.dart';
import 'package:busy_network/app/settings_book.dart';
import 'package:busy_network/feedback/game_feedback.dart';
import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/screens/result_fail/result_fail_screen.dart';
import 'package:busy_network/screens/result_success/result_success_screen.dart';
import 'package:busy_network/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../game/design_pull.dart';
import '../game/sim/sim_fixtures.dart';
import '../test_helpers.dart';
import 'recording_feedback.dart';

/// Router → Rumah 6, lurus ke bawah.
const _toHouse6 = [Offset(195, 240), Offset(195, 330), Offset(196, 418)];

/// Jaringan level 5 yang gagal (46%): jalur Blok B penuh.
final _failingCables = [
  ...Levels.level5.cables,
  designCables.firstWhere((c) => c.id == 'c-r5'),
];

void main() {
  setUpFonts();

  testWidgets('tombol berbunyi tap', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final out = RecordingFeedback();
    await pumpApp(tester, session: recordingSession(out));
    await tester.tap(find.text('Main'));
    await tester.pumpAndSettle();
    expect(out.sounds, [Cue.tap]);
    expect(out.buzzes, [Cue.tap]);
  });

  testWidgets('setelan mati: tanpa suara & getar', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final out = RecordingFeedback();
    final settings = SettingsBook.memory(
      const Settings(sound: false, vibration: false),
    );
    await pumpApp(tester, session: recordingSession(out, settings: settings));
    await tester.tap(find.text('Main'));
    await tester.pumpAndSettle();
    expect(out.sounds, isEmpty);
    expect(out.buzzes, isEmpty);
  });

  testWidgets('kabel terpasang, ditolak anggaran, dibongkar', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final out = RecordingFeedback();
    await pumpApp(
      tester,
      location: AppRoutes.design,
      session: recordingSession(out),
    );

    // Fiber: Rumah 6 & Rumah 5 terpasang, Rumah 7 tidak terbayar.
    await tester.tap(find.text('Fiber'));
    await tester.pumpAndSettle();
    out.sounds.clear();
    await dragOnMap(tester, _toHouse6);
    expect(out.sounds, [Cue.connect]);

    // Jari dilepas di luar rumah: diam.
    await dragOnMap(tester, const [Offset(195, 420), Offset(135, 420)]);
    expect(out.sounds, [Cue.connect]);

    await dragOnMap(tester, [...designPullPath, const Offset(312, 386)]);
    expect(out.sounds, [Cue.connect, Cue.connect]);
    await dragOnMap(tester, const [
      Offset(195, 420),
      Offset(75, 420),
      Offset(76, 334),
    ]);
    expect(find.textContaining('Anggaran kurang'), findsOneWidget);
    expect(out.sounds, [Cue.connect, Cue.connect, Cue.refuse]);

    out.sounds.clear();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    // Kabel Router → Rumah 4.
    await tester.tapAt(mapToScreen(tester, const Offset(257, 240)));
    await tester.pumpAndSettle();
    expect(out.sounds, [Cue.tap, Cue.remove]);
  });

  testWidgets('komplain yang sudah tampil saat dibuka diam', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final out = RecordingFeedback();
    await pumpApp(
      tester,
      location: AppRoutes.run,
      session: recordingSession(out),
    );
    expect(find.text('Abaikan'), findsOneWidget);
    expect(out.sounds, isEmpty);
  });

  testWidgets('komplain baru berbunyi sekali', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final out = RecordingFeedback();
    final day = playUntil(designDay(_failingCables), 17 * 60);
    final session = recordingSession(out)..begin(day);
    await pumpApp(
      tester,
      location: AppRoutes.runOf(5),
      session: session,
      settle: false,
    );
    for (var i = 0; i < 300 && day.day!.complaint == null; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(day.day!.complaint, isNotNull);
    await tester.pump(const Duration(seconds: 1));
    expect(out.sounds, [Cue.complaint]);
  });

  testWidgets('komplain di perubahan pertama setelah layar dibuka berbunyi', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    // Hari sama persis (deterministik): cari menit komplain pertama setelah
    // 17:00, lalu buka layar semenit sebelumnya.
    final probe = playUntil(designDay(_failingCables), 17 * 60);
    while (probe.day!.complaint == null) {
      probe.advanceDay(0.05);
    }
    final minute = probe.day!.complaint!.minute;
    final out = RecordingFeedback();
    final day = playUntil(designDay(_failingCables), minute - 1);
    expect(day.day!.complaint, isNull);
    final session = recordingSession(out)..begin(day);
    await pumpApp(
      tester,
      location: AppRoutes.runOf(5),
      session: session,
      settle: false,
    );
    for (var i = 0; i < 20 && day.day!.complaint == null; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(day.day!.complaint?.minute, minute);
    expect(out.sounds, [Cue.complaint]);
  });

  for (final (name, cables, cue, screen) in [
    ('lulus', designFiberCables, Cue.win, ResultSuccessScreen),
    (
      'gagal',
      [...Levels.level5.cables, designCables.firstWhere((c) => c.id == 'c-r5')],
      Cue.fail,
      ResultFailScreen,
    ),
  ]) {
    testWidgets('hari selesai $name → cue ${cue.name}', (tester) async {
      setScreenSize(tester, const Size(390, 844));
      final out = RecordingFeedback();
      final session = recordingSession(out)
        ..begin(playUntil(designDay(cables), 23 * 60 + 50));
      await pumpApp(
        tester,
        location: AppRoutes.runOf(5),
        session: session,
        settle: false,
      );
      await tester.pumpAndSettle();
      expect(session.result, isNotNull);
      expect(out.sounds, [cue]);
      expect(find.byType(screen), findsOneWidget);
    });
  }
}
