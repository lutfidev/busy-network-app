import 'dart:io';

import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:busy_network/game/sim/sim.dart';
import 'package:busy_network/music/track.dart';
import 'package:flutter_test/flutter_test.dart';

DaySim _dayAt(LevelDef level, int minute) => DaySim(
  level: level,
  network: Network(level: level, cables: const []),
  minute: minute,
);

void main() {
  test('jam sibuk 19–22: tegang tepat di 19:00 sampai sebelum 22:00', () {
    final level = Levels.level1;
    for (final (minute, track) in [
      (18 * 60 + 59, Track.calm),
      (19 * 60, Track.tense),
      (21 * 60 + 59, Track.tense),
      (22 * 60, Track.calm),
      (SimClock.dayEnd, Track.calm),
    ]) {
      final day = _dayAt(level, minute);
      expect(day.inRush, track == Track.tense, reason: '$minute');
      expect(Track.forDay(day), track, reason: '$minute');
    }
  });

  test('level dengan jam sibuk sendiri', () {
    final level = Levels.all.firstWhere((l) => l.rushHourFrom == 8);
    expect(Track.forDay(_dayAt(level, 7 * 60 + 59)), Track.calm);
    expect(Track.forDay(_dayAt(level, 8 * 60)), Track.tense);
    expect(Track.forDay(_dayAt(level, 17 * 60)), Track.calm);
  });

  test('tiap lagu punya WAV', () {
    for (final track in Track.values) {
      expect(
        File('assets/audio/${track.file}.wav').existsSync(),
        isTrue,
        reason: track.file,
      );
    }
  });
}
