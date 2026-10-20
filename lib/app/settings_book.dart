import 'package:flutter/foundation.dart';

import '../data/settings_store.dart';
import '../settings/settings.dart';

/// Setelan pemain selama aplikasi berjalan: dibaca layar Pengaturan,
/// `GameFeedback` & `BackgroundMusic`, diubah lewat [setSound] /
/// [setVibration] / [setMusic] lalu disimpan.
/// Belum ada yang tersimpan → [Settings.initial].
class SettingsBook extends ChangeNotifier {
  SettingsBook(this._store) : _settings = _store.load() ?? Settings.initial;

  /// Setelan di memori saja (default aplikasi di test).
  SettingsBook.memory([Settings? initial]) : this(MemorySettingsStore(initial));

  final SettingsStore _store;
  Settings _settings;

  Settings get settings => _settings;

  Future<void> setSound(bool on) => _update(_settings.copyWith(sound: on));

  Future<void> setVibration(bool on) =>
      _update(_settings.copyWith(vibration: on));

  Future<void> setMusic(bool on) => _update(_settings.copyWith(music: on));

  /// Gagal simpan tidak menghentikan permainan: setelan di memori tetap
  /// berlaku.
  Future<void> _update(Settings next) async {
    if (next == _settings) return;
    _settings = next;
    notifyListeners();
    try {
      await _store.save(next);
    } on Object catch (error) {
      debugPrint('Pengaturan gagal disimpan: $error');
    }
  }
}
