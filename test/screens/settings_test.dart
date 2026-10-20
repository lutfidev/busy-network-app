import 'package:busy_network/app/game_session.dart';
import 'package:busy_network/app/progress_book.dart';
import 'package:busy_network/app/routes.dart';
import 'package:busy_network/app/settings_book.dart';
import 'package:busy_network/data/dummy_data.dart';
import 'package:busy_network/data/progress_store.dart';
import 'package:busy_network/data/settings_store.dart';
import 'package:busy_network/feedback/game_feedback.dart';
import 'package:busy_network/game/progress/progress.dart';
import 'package:busy_network/gallery/widget_gallery_screen.dart';
import 'package:busy_network/screens/home/home_screen.dart';
import 'package:busy_network/screens/settings/settings_screen.dart';
import 'package:busy_network/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../feedback/recording_feedback.dart';
import '../test_helpers.dart';

void main() {
  setUpFonts();

  GameSession designSession({ProgressStore? store}) => GameSession(
    progress: ProgressBook(
      store ?? MemoryProgressStore(),
      initial: DummyData.designProgress,
    ),
  );

  testWidgets('Beranda → Pengaturan → kembali', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Pengaturan'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Efek suara'), findsOneWidget);
    expect(find.text('Getar'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Musik')).dy,
      lessThan(tester.getTopLeft(find.text('Efek suara')).dy),
    );

    await tester.tap(find.bySemanticsLabel('Kembali ke Beranda'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('sakelar mengubah & menyimpan setelan', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final store = MemorySettingsStore();
    final out = RecordingFeedback();
    final session = recordingSession(out, settings: SettingsBook(store));
    await pumpApp(tester, location: AppRoutes.settings, session: session);

    await tester.tap(find.text('Efek suara'));
    await tester.pumpAndSettle();
    expect(session.settings.settings.sound, isFalse);
    expect(store.load(), const Settings(sound: false));
    // Mematikan suara: diam, tapi masih bergetar.
    expect(out.sounds, isEmpty);
    expect(out.buzzes, [Cue.tap]);

    await tester.tap(find.text('Getar'));
    await tester.pumpAndSettle();
    expect(store.load(), const Settings(sound: false, vibration: false));
    expect(out.buzzes, [Cue.tap]);

    // Menyalakan suara langsung terdengar.
    await tester.tap(find.text('Efek suara'));
    await tester.pumpAndSettle();
    expect(session.settings.settings.sound, isTrue);
    expect(out.sounds, [Cue.tap]);
  });

  testWidgets('sakelar Musik mengubah & menyimpan setelan', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final store = MemorySettingsStore();
    final session = GameSession(
      feedback: GameFeedback(settings: SettingsBook(store)),
    );
    await pumpApp(tester, location: AppRoutes.settings, session: session);
    await tester.tap(find.text('Musik'));
    await tester.pumpAndSettle();
    expect(session.settings.settings.music, isFalse);
    expect(store.load(), const Settings(music: false));
  });

  testWidgets('sakelar terbaca pembaca layar', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final handle = tester.ensureSemantics();
    final session = GameSession(
      feedback: GameFeedback(
        settings: SettingsBook.memory(const Settings(vibration: false)),
      ),
    );
    await pumpApp(tester, location: AppRoutes.settings, session: session);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Efek suara')),
      matchesSemantics(
        label: 'Efek suara',
        hint: 'Bunyi saat kabel tersambung, ada komplain, dan hari selesai.',
        isButton: true,
        isToggled: true,
        hasToggledState: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Getar')),
      matchesSemantics(
        label: 'Getar',
        hint: 'Getar halus saat kabel dipasang, ditolak, atau ada komplain.',
        isButton: true,
        hasToggledState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  group('reset progres', () {
    testWidgets('Batal / ketuk di luar: progres tetap', (tester) async {
      setScreenSize(tester, const Size(390, 844));
      final session = designSession();
      await pumpApp(tester, location: AppRoutes.settings, session: session);
      expect(find.text('4 / 12 level selesai'), findsOneWidget);

      await tester.tap(find.text('Reset progres'));
      await tester.pumpAndSettle();
      expect(find.text('Reset progres?'), findsOneWidget);
      expect(
        find.text(
          '9 bintang hilang dan permainan mulai lagi dari tutorial level 1. '
          'Ini nggak bisa dibatalkan.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Reset progres?'), findsNothing);
      expect(session.progress.progress, DummyData.designProgress);

      await tester.tap(find.text('Reset progres'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Reset progres?'), findsNothing);
      expect(session.progress.progress, DummyData.designProgress);
    });

    testWidgets('Reset: progres kosong & tersimpan; Beranda 0 bintang', (
      tester,
    ) async {
      setScreenSize(tester, const Size(390, 844));
      final store = MemoryProgressStore();
      final session = designSession(store: store);
      await pumpApp(tester, location: AppRoutes.settings, session: session);

      await tester.tap(find.text('Reset progres'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(session.progress.progress, Progress.empty);
      expect(store.load(), Progress.empty);
      expect(find.text('0 / 12 level selesai'), findsOneWidget);
      expect(
        find.text('Belum ada progres. Semua mulai dari tutorial level 1.'),
        findsOneWidget,
      );

      // Tombol mati: tidak membuka dialog lagi.
      await tester.tap(find.text('Reset progres'));
      await tester.pumpAndSettle();
      expect(find.text('Reset progres?'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Kembali ke Beranda'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Bintang terkumpul 0 dari 36'), findsOne);
    });
  });

  testWidgets('galeri komponen dari Pengaturan, kembali ke Pengaturan', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester, location: AppRoutes.settings);
    await tester.tap(find.text('Galeri komponen'));
    await tester.pumpAndSettle();
    expect(find.byType(WidgetGalleryScreen), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Kembali'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
