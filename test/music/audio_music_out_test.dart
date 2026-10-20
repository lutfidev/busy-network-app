import 'package:busy_network/app/settings_book.dart';
import 'package:busy_network/music/audio_music_out.dart';
import 'package:busy_network/music/background_music.dart';
import 'package:busy_network/music/track.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pemain palsu: mencatat volume & apakah sedang berbunyi.
class _FakeVoice implements MusicVoice {
  double volume = 0;
  bool playing = false;

  @override
  Future<void> setVolume(double volume) async => this.volume = volume;

  @override
  Future<void> resume() async => playing = true;

  @override
  Future<void> pause() async => playing = false;
}

const _second = Duration(seconds: 1);

void main() {
  late Map<Track, _FakeVoice> voices;
  late AudioMusicOut out;

  _FakeVoice calm() => voices[Track.calm]!;
  _FakeVoice tense() => voices[Track.tense]!;

  setUp(() {
    voices = {for (final t in Track.values) t: _FakeVoice()};
    out = AudioMusicOut.withVoices(Future.value(voices));
  });

  testWidgets('fade naik ke volume musik', (tester) async {
    await tester.pump();
    out.play(Track.calm, fade: _second);
    await tester.pump(const Duration(milliseconds: 500));
    expect(calm().playing, isTrue);
    expect(calm().volume, closeTo(AudioMusicOut.volume / 2, 0.03));
    await tester.pump(_second);
    expect(calm().volume, AudioMusicOut.volume);
    expect(tense().playing, isFalse);
  });

  testWidgets('crossfade: lagu lama turun lalu dijeda', (tester) async {
    await tester.pump();
    out.play(Track.calm);
    expect(calm().volume, AudioMusicOut.volume);
    out.play(Track.tense, fade: _second);
    await tester.pump(const Duration(milliseconds: 500));
    expect(calm().playing, isTrue);
    expect(tense().playing, isTrue);
    await tester.pump(_second);
    expect(calm().playing, isFalse);
    expect(calm().volume, 0);
    expect(tense().volume, AudioMusicOut.volume);
  });

  testWidgets('tunda: belum berbunyi sebelum waktunya', (tester) async {
    await tester.pump();
    out.play(Track.calm, delay: const Duration(milliseconds: 1500));
    await tester.pump(_second);
    expect(calm().playing, isFalse);
    await tester.pump(_second);
    expect(calm().playing, isTrue);
  });

  testWidgets('diam membatalkan lagu yang masih ditunda', (tester) async {
    await tester.pump();
    out.play(Track.calm, delay: const Duration(milliseconds: 1500));
    out.play(null);
    await tester.pump(const Duration(seconds: 3));
    expect(calm().playing, isFalse);
  });

  testWidgets('diminta sebelum selesai dimuat → diputar setelah dimuat', (
    tester,
  ) async {
    final loaded = <Track, _FakeVoice>{
      for (final t in Track.values) t: _FakeVoice(),
    };
    final slow = AudioMusicOut.withVoices(
      Future.delayed(_second, () => loaded),
    );
    slow.play(Track.tense);
    expect(loaded[Track.tense]!.playing, isFalse);
    await tester.pump(_second);
    expect(loaded[Track.tense]!.playing, isTrue);
    expect(loaded[Track.tense]!.volume, AudioMusicOut.volume);
  });

  testWidgets('gagal dimuat: diam tanpa galat', (tester) async {
    final broken = AudioMusicOut.withVoices(Future.error(StateError('rusak')));
    await tester.pump();
    broken.play(Track.calm, fade: _second);
    await tester.pump(_second);
  });

  for (final last in Track.values) {
    testWidgets('24:00 dari ${last.name}: redup dulu, lalu santai tertunda', (
      tester,
    ) async {
      final music = BackgroundMusic(settings: SettingsBook.memory(), out: out);
      await tester.pump();
      music.request(last);
      await tester.pump(_second);
      music
        ..endDay()
        ..request(Track.calm);
      await tester.pump(const Duration(milliseconds: 500));
      for (final voice in voices.values) {
        expect(voice.volume, 0);
        expect(voice.playing, isFalse);
      }
      await tester.pump(const Duration(milliseconds: 2100));
      expect(calm().playing, isTrue);
      expect(calm().volume, AudioMusicOut.volume);
      expect(tense().volume, 0);
    });
  }
}
