import 'dart:convert';

/// Setelan pemain (layar Pengaturan). Murni, tanpa Flutter.
class Settings {
  const Settings({this.sound = true, this.vibration = true, this.music = true});

  /// Awal permainan: suara, getar & musik nyala.
  static const initial = Settings();

  /// Versi format [encode]. Versi 1 (sebelum ada musik) masih dibaca
  /// [decode] dengan musik nyala; versi lain diabaikan.
  static const version = 2;

  /// Efek suara.
  final bool sound;

  /// Getar (haptic).
  final bool vibration;

  /// Musik latar.
  final bool music;

  Settings copyWith({bool? sound, bool? vibration, bool? music}) => Settings(
    sound: sound ?? this.sound,
    vibration: vibration ?? this.vibration,
    music: music ?? this.music,
  );

  String encode() => jsonEncode({
    'versi': version,
    'suara': sound,
    'getar': vibration,
    'musik': music,
  });

  /// Kebalikan [encode]; `null` bila kosong, rusak, atau versi lain.
  static Settings? decode(String? source) {
    if (source == null) return null;
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      return null;
    }
    if (json is! Map) return null;
    final sound = json['suara'];
    final vibration = json['getar'];
    final music = switch (json['versi']) {
      1 => true,
      version => json['musik'],
      _ => null,
    };
    if (sound is! bool || vibration is! bool || music is! bool) return null;
    return Settings(sound: sound, vibration: vibration, music: music);
  }

  @override
  bool operator ==(Object other) =>
      other is Settings &&
      other.sound == sound &&
      other.vibration == vibration &&
      other.music == music;

  @override
  int get hashCode => Object.hash(sound, vibration, music);

  @override
  String toString() =>
      'Settings(sound: $sound, vibration: $vibration, music: $music)';
}
