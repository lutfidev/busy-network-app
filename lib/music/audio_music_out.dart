import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'music_out.dart';
import 'track.dart';

/// Satu lagu yang bisa dijeda & diatur volumenya.
abstract interface class MusicVoice {
  Future<void> setVolume(double volume);
  Future<void> resume();
  Future<void> pause();
}

/// Musik latar dari `assets/audio/` lewat `audioplayers` mode media player:
/// satu pemain per [Track], berulang ([ReleaseMode.loop]), campur dengan
/// musik aplikasi lain (tidak merebut fokus audio). Lagu yang turun ke
/// volume 0 dijeda, jadi lanjut dari posisinya saat diminta lagi.
///
/// Fade & tunda memakai `Timer`, bukan animasi Flutter. Lagu dimuat di
/// latar belakang; permintaan sebelum selesai dimuat dijalankan setelahnya,
/// dan lagu yang gagal dimuat diam saja.
class AudioMusicOut implements MusicOut {
  AudioMusicOut() : this.withVoices(_openVoices());

  /// [voices] = pemain siap pakai per lagu (test memakai pemain palsu).
  @visibleForTesting
  AudioMusicOut.withVoices(Future<Map<Track, MusicVoice>> voices) {
    voices.then(
      _ready,
      onError: (Object error) {
        debugPrint('Musik gagal dimuat: $error');
      },
    );
  }

  /// Volume musik: efek suara (volume penuh) tetap terdengar di atasnya.
  static const volume = 0.4;

  static const _step = Duration(milliseconds: 50);

  Map<Track, MusicVoice>? _voices;
  final _levels = {for (final t in Track.values) t: 0.0};
  Timer? _delay;
  Timer? _fade;
  ({Track? track, Duration fade, Duration delay})? _pending;

  static Future<Map<Track, MusicVoice>> _openVoices() async {
    final context = AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
    ).build();
    final entries = await Future.wait([
      for (final track in Track.values)
        _AudioVoice.open(
          track,
          context,
        ).then((voice) => MapEntry(track, voice)),
    ]);
    return Map.fromEntries(entries);
  }

  void _ready(Map<Track, MusicVoice> voices) {
    _voices = voices;
    final pending = _pending;
    _pending = null;
    if (pending != null) {
      play(pending.track, fade: pending.fade, delay: pending.delay);
    }
  }

  @override
  void play(
    Track? track, {
    Duration fade = Duration.zero,
    Duration delay = Duration.zero,
  }) {
    _delay?.cancel();
    _delay = null;
    if (_voices == null) {
      _pending = (track: track, fade: fade, delay: delay);
      return;
    }
    // Fade yang sedang jalan (mis. redup 24:00) dibiarkan selesai selama
    // menunggu; baru dibatalkan saat fade baru dimulai.
    if (delay > Duration.zero) {
      _delay = Timer(delay, () => _fadeTo(track, fade));
    } else {
      _fadeTo(track, fade);
    }
  }

  void _fadeTo(Track? track, Duration fade) {
    _fade?.cancel();
    _fade = null;
    final from = Map.of(_levels);
    final to = {for (final t in Track.values) t: t == track ? volume : 0.0};
    if (track != null && from[track] == 0) _call(track, (v) => v.resume());
    if (fade <= Duration.zero) {
      _setLevels(from, to, 1);
      return;
    }
    final steps = fade.inMicroseconds / _step.inMicroseconds;
    _fade = Timer.periodic(_step, (timer) {
      final t = (timer.tick / steps).clamp(0.0, 1.0);
      _setLevels(from, to, t);
      if (t >= 1) {
        timer.cancel();
        if (identical(_fade, timer)) _fade = null;
      }
    });
  }

  /// Volume tiap lagu = [from] → [to] pada [t]; lagu yang sampai 0 dijeda.
  void _setLevels(Map<Track, double> from, Map<Track, double> to, double t) {
    for (final track in Track.values) {
      final level = from[track]! + (to[track]! - from[track]!) * t;
      if (level == _levels[track]) continue;
      _levels[track] = level;
      _call(track, (v) => v.setVolume(level));
      if (level == 0) _call(track, (v) => v.pause());
    }
  }

  void _call(Track track, Future<void> Function(MusicVoice voice) action) {
    final voice = _voices?[track];
    if (voice == null) return;
    unawaited(
      action(voice).catchError(
        (Object error) => debugPrint('Musik ${track.file} gagal: $error'),
      ),
    );
  }
}

class _AudioVoice implements MusicVoice {
  _AudioVoice(this._player);

  final AudioPlayer _player;

  static Future<MusicVoice> open(Track track, AudioContext context) async {
    final player = AudioPlayer();
    await player.setAudioContext(context);
    await player.setPlayerMode(PlayerMode.mediaPlayer);
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(0);
    await player.setSource(AssetSource('audio/${track.file}.wav'));
    return _AudioVoice(player);
  }

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> pause() => _player.pause();
}
