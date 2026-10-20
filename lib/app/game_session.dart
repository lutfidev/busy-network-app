import 'dart:async';

import '../data/dummy_states.dart';
import '../game/model/model.dart';
import '../feedback/game_feedback.dart';
import '../game/result/level_result.dart';
import '../music/background_music.dart';
import '../music/music_out.dart';
import 'progress_book.dart';
import 'settings_book.dart';

/// Hari yang sedang dimainkan, dioper antarrute: Fase Rancang & tutorial
/// menaruhnya saat "Mulai Hari" ([begin]), Fase Jalan & Panel Atur Antrean
/// memakai hari yang sama ([currentDay]), Fase Jalan menutupnya di 24:00
/// ([finish]) dan layar hasil membaca [result]. Dibuat sekali oleh
/// aplikasi dan diteruskan router ke layar, bersama [progress],
/// [feedback] (suara & getar, beserta setelannya), dan [music].
///
/// Hari milik sesi (dibuat `GameState.planDay`) tidak di-`dispose`: layar
/// lain bisa masih mendengarkannya saat rutenya keluar; cukup dilepas.
class GameSession {
  GameSession({
    ProgressBook? progress,
    GameFeedback? feedback,
    MusicOut music = const SilentMusic(),
  }) : this._(
         progress ?? ProgressBook.memory(),
         feedback ?? GameFeedback(settings: SettingsBook.memory()),
         music,
       );

  GameSession._(this.progress, this.feedback, MusicOut music)
    : music = BackgroundMusic(settings: feedback.settings, out: music);

  /// Progres pemain (Beranda, Peta Babak, bintang hasil).
  final ProgressBook progress;

  /// Suara & getar; default diam (test).
  final GameFeedback feedback;

  /// Musik latar; default diam (test).
  final BackgroundMusic music;

  /// Setelan pemain (layar Pengaturan).
  SettingsBook get settings => feedback.settings;

  GameState? _day;

  /// Hari dimulai dari Fase Rancang (bukan potret desain): hasilnya
  /// dicatat ke [progress].
  bool _real = false;
  LevelResult? _result;

  /// Hari terakhir yang dimainkan layar Fase Jalan, termasuk yang sudah
  /// selesai.
  GameState? get last => _day;

  /// Hasil hari terakhir yang selesai ([finish]); `null` sampai ada.
  LevelResult? get result => _result;

  /// Mulai hari baru dari rancangan (state fase jalan).
  void begin(GameState day) {
    if (day.phase != GamePhase.run) {
      throw ArgumentError.value(day.phase, 'day.phase', 'harus fase jalan');
    }
    _day = day;
    _real = true;
    _result = null;
  }

  /// Hari untuk layar Fase Jalan & Panel Antrean: hari yang sedang
  /// berjalan, atau — bila tidak ada (deep link, hari sebelumnya sudah
  /// selesai) — bingkai Fase Jalan di desain, yang lalu menjadi hari
  /// sekarang. Hari potret tidak dicatat ke progres.
  GameState currentDay() {
    final day = _day;
    if (day != null && day.phase == GamePhase.run) return day;
    _real = false;
    _result = null;
    return _day = DummyStates.run();
  }

  /// Pemain meninggalkan [day] sebelum selesai (kembali ke Fase Rancang).
  void abandon(GameState day) {
    if (identical(day, _day)) _day = null;
  }

  /// Tutup hari yang sudah 24:00: hitung hasilnya sekali, dan bila hari
  /// asli & lulus, catat bintangnya ke [progress].
  LevelResult finish() {
    final day = _day;
    if (day == null || day.phase != GamePhase.result) {
      throw StateError('Belum ada hari yang selesai');
    }
    if (_result case final result?) return result;
    final result = _result = LevelResult.of(day);
    if (_real && result.passed) {
      unawaited(progress.record(result.level.number, result.stars));
    }
    return result;
  }
}
