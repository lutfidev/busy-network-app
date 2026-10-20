import '../app/settings_book.dart';
import 'music_out.dart';
import 'track.dart';

/// Lama pergantian musik.
abstract final class MusicTiming {
  /// Ganti lagu (santai ↔ tegang, layar ke layar).
  static const crossfade = Duration(seconds: 1);

  /// Redup di 24:00 supaya bunyi menang/kalah terdengar jelas.
  static const dayEndFade = Duration(milliseconds: 400);

  /// Lagu layar hasil menunggu bunyi menang/kalah selesai.
  static const resultDelay = Duration(milliseconds: 1500);
}

/// Musik latar selama aplikasi berjalan: layar meminta lagu ([request]),
/// yang terdengar = lagu itu bila setelan `music` nyala dan aplikasi di
/// latar depan ([setForeground]); selain itu diam. Keluaran [out] disuntik;
/// default diam (test).
class BackgroundMusic {
  BackgroundMusic({required this.settings, this.out = const SilentMusic()}) {
    settings.addListener(_sync);
  }

  final SettingsBook settings;
  final MusicOut out;

  Track? _wanted;
  Track? _audible;
  bool _foreground = true;

  /// Hari baru saja selesai: lagu berikut menunggu [MusicTiming.resultDelay].
  bool _afterDayEnd = false;

  /// Lagu yang sedang terdengar; `null` = diam.
  Track? get audible => _audible;

  /// Layar ingin [track] terdengar.
  void request(Track track) {
    if (track == _wanted && !_afterDayEnd) return;
    _wanted = track;
    final delay = _afterDayEnd ? MusicTiming.resultDelay : Duration.zero;
    _afterDayEnd = false;
    _sync(fade: MusicTiming.crossfade, delay: delay);
  }

  /// Hari selesai (24:00): musik meredup sebelum bunyi hasil.
  void endDay() {
    _wanted = null;
    _afterDayEnd = true;
    _sync(fade: MusicTiming.dayEndFade);
  }

  /// Aplikasi di latar depan (`resumed`) atau tidak; berlaku seketika.
  void setForeground(bool foreground) {
    _foreground = foreground;
    _sync();
  }

  void _sync({Duration fade = Duration.zero, Duration delay = Duration.zero}) {
    final target = settings.settings.music && _foreground ? _wanted : null;
    if (target == _audible) return;
    _audible = target;
    out.play(target, fade: fade, delay: delay);
  }
}
