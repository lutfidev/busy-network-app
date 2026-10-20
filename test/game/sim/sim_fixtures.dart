import 'package:busy_network/data/dummy_states.dart';
import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/model/model.dart';

/// Jaringan Fase Jalan di desain (Rumah 5 lewat Rumah 4, Rumah 6 & 7 lewat
/// j2).
final designCables = DummyStates.run().cables;

/// Jaringan desain dengan kabel Router → Rumah 4 diganti fiber.
final designFiberCables = [
  for (final c in designCables)
    c.id == 'c-r4'
        ? Cable(
            id: c.id,
            from: c.from,
            to: c.to,
            kind: CableKind.fiber,
            points: c.points,
          )
        : c,
];

/// Pemakaian puncak (jam sibuk) tiap rumah level 5.
final peakDemand = {for (final h in Levels.level5.houses) h.id: h.peakMbps};

/// Hari level 5 di jaringan [cables] (junction desain), mulai 06:00,
/// batas antrean [limits].
GameState designDay(List<Cable> cables, {Map<String, int> limits = const {}}) {
  final game = GameState(
    Levels.level5,
    junctions: DummyStates.run().junctions,
    cables: cables,
  )..startDay();
  if (limits.isNotEmpty) game.setQueue(limits: limits, priority: const {});
  return game;
}

/// Mainkan [game] sampai 24:00; komplain langsung dijawab.
GameState playDay(GameState game) {
  while (game.phase == GamePhase.run) {
    game.dismissComplaint();
    game.advanceDay(1);
  }
  return game;
}

/// Majukan [game] sampai [minute], komplain langsung dijawab.
GameState playUntil(GameState game, int minute) {
  while (game.day!.minute < minute) {
    game.dismissComplaint();
    game.advanceDay(0.05);
  }
  game.dismissComplaint();
  return game;
}
