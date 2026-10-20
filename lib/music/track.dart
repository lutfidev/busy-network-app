import '../game/sim/sim.dart';

/// Lagu latar, disintesis `tool/make_music.py`.
enum Track {
  /// Menu, Fase Rancang, tutorial, hasil, dan Fase Jalan di luar jam sibuk.
  calm('music_calm'),

  /// Fase Jalan selama jam sibuk.
  tense('music_tense');

  const Track(this.file);

  /// Nama berkas `assets/audio/<file>.wav`.
  final String file;

  /// Lagu Fase Jalan untuk [day] saat ini: tegang selama jam sibuk.
  static Track forDay(DaySim day) => day.inRush ? tense : calm;
}
