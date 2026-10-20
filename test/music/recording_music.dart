import 'package:busy_network/app/game_session.dart';
import 'package:busy_network/app/progress_book.dart';
import 'package:busy_network/app/settings_book.dart';
import 'package:busy_network/feedback/game_feedback.dart';
import 'package:busy_network/music/music_out.dart';
import 'package:busy_network/music/track.dart';

/// Satu permintaan ke [MusicOut.play].
typedef MusicCall = ({Track? track, Duration fade, Duration delay});

/// Mencatat lagu yang diminta, alih-alih memutarnya.
class RecordingMusic implements MusicOut {
  final calls = <MusicCall>[];

  /// Lagu yang terdengar terakhir diminta; `null` = diam.
  Track? get current => calls.isEmpty ? null : calls.last.track;

  @override
  void play(
    Track? track, {
    Duration fade = Duration.zero,
    Duration delay = Duration.zero,
  }) => calls.add((track: track, fade: fade, delay: delay));
}

/// Sesi yang musiknya direkam ke [out].
GameSession musicSession(
  RecordingMusic out, {
  SettingsBook? settings,
  ProgressBook? progress,
}) => GameSession(
  progress: progress,
  feedback: GameFeedback(settings: settings ?? SettingsBook.memory()),
  music: out,
);
