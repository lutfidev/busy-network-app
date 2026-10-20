import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/app.dart';
import 'app/game_session.dart';
import 'app/progress_book.dart';
import 'app/settings_book.dart';
import 'data/progress_store.dart';
import 'data/settings_store.dart';
import 'feedback/audio_sound_out.dart';
import 'feedback/game_feedback.dart';
import 'music/audio_music_out.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Font dibundel di assets/google_fonts → tidak perlu unduh saat runtime.
  GoogleFonts.config.allowRuntimeFetching = false;
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final (progress, settings) = await (_openProgress(), _openSettings()).wait;
  runApp(
    JaringanSibukApp(
      session: GameSession(
        progress: progress,
        feedback: GameFeedback(
          settings: settings,
          sound: AudioSoundOut(),
          haptics: const SystemHaptics(),
        ),
        music: AudioMusicOut(),
      ),
    ),
  );
}

/// Progres tersimpan di perangkat; bila penyimpanannya tidak bisa dibuka,
/// permainan tetap jalan dengan progres di memori.
Future<ProgressBook> _openProgress() async {
  try {
    return ProgressBook(await PrefsProgressStore.open());
  } on Object catch (error) {
    debugPrint('Progres tidak bisa dibuka: $error');
    return ProgressBook.memory();
  }
}

/// Seperti [_openProgress], untuk setelan.
Future<SettingsBook> _openSettings() async {
  try {
    return SettingsBook(await PrefsSettingsStore.open());
  } on Object catch (error) {
    debugPrint('Pengaturan tidak bisa dibuka: $error');
    return SettingsBook.memory();
  }
}
