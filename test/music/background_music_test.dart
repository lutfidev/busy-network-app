import 'package:busy_network/app/settings_book.dart';
import 'package:busy_network/music/background_music.dart';
import 'package:busy_network/music/track.dart';
import 'package:busy_network/settings/settings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recording_music.dart';

const _zero = Duration.zero;

void main() {
  late SettingsBook settings;
  late RecordingMusic out;
  late BackgroundMusic music;

  setUp(() {
    settings = SettingsBook.memory();
    out = RecordingMusic();
    music = BackgroundMusic(settings: settings, out: out);
  });

  test('lagu diminta → crossfade; lagu sama tidak diulang', () {
    music.request(Track.calm);
    music.request(Track.calm);
    expect(out.calls, [
      (track: Track.calm, fade: MusicTiming.crossfade, delay: _zero),
    ]);
    music.request(Track.tense);
    expect(out.calls.last, (
      track: Track.tense,
      fade: MusicTiming.crossfade,
      delay: _zero,
    ));
    expect(music.audible, Track.tense);
  });

  test('hari selesai: redup, lalu lagu berikut menunggu bunyi hasil', () {
    music.request(Track.tense);
    music.endDay();
    expect(out.calls.last, (
      track: null,
      fade: MusicTiming.dayEndFade,
      delay: _zero,
    ));
    music.request(Track.calm);
    expect(out.calls.last, (
      track: Track.calm,
      fade: MusicTiming.crossfade,
      delay: MusicTiming.resultDelay,
    ));
    music.request(Track.tense);
    expect(out.calls.last, (
      track: Track.tense,
      fade: MusicTiming.crossfade,
      delay: _zero,
    ));
  });

  test('latar belakang: diam seketika, kembali → lagu yang diminta', () {
    music.request(Track.calm);
    music.setForeground(false);
    expect(out.calls.last, (track: null, fade: _zero, delay: _zero));
    music.request(Track.tense);
    expect(out.calls.length, 2, reason: 'di latar belakang tetap diam');
    music.setForeground(true);
    expect(out.calls.last, (track: Track.tense, fade: _zero, delay: _zero));
  });

  test('background cancels pending result calm', () {
    music.request(Track.tense);
    music.endDay();
    music.request(Track.calm);
    music.setForeground(false);
    expect(out.calls.last, (track: null, fade: _zero, delay: _zero));
    music.setForeground(true);
    expect(out.calls.last, (track: Track.calm, fade: _zero, delay: _zero));
  });

  test('sakelar musik: mati seketika, nyala → lagu yang diminta', () async {
    music.request(Track.calm);
    await settings.setMusic(false);
    expect(out.calls.last, (track: null, fade: _zero, delay: _zero));
    music.request(Track.tense);
    await settings.setMusic(true);
    expect(out.calls.last, (track: Track.tense, fade: _zero, delay: _zero));
    await settings.setSound(false);
    expect(out.current, Track.tense, reason: 'efek suara tidak mengatur musik');
  });

  test('musik mati sejak awal: tidak pernah memutar', () {
    music = BackgroundMusic(
      settings: SettingsBook.memory(const Settings(music: false)),
      out: out,
    );
    music.request(Track.calm);
    music.request(Track.tense);
    music.setForeground(false);
    music.setForeground(true);
    expect(out.calls, isEmpty);
  });
}
