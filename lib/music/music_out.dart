import 'track.dart';

/// Pemutar musik latar.
abstract interface class MusicOut {
  /// Tunggu [delay], lalu lagu yang terdengar turun dan [track] naik selama
  /// [fade] (nol = seketika); `null` = diam. Lagu yang dijeda lanjut dari
  /// posisinya. Tiap panggilan membatalkan tunggu panggilan sebelumnya;
  /// fade yang sedang jalan dibiarkan selesai selama [delay] dan baru
  /// diganti saat fade baru dimulai.
  void play(
    Track? track, {
    Duration fade = Duration.zero,
    Duration delay = Duration.zero,
  });
}

/// Tanpa musik (test, dan default sesi).
class SilentMusic implements MusicOut {
  const SilentMusic();

  @override
  void play(
    Track? track, {
    Duration fade = Duration.zero,
    Duration delay = Duration.zero,
  }) {}
}
