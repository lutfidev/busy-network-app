import 'package:busy_network/app/settings_book.dart';
import 'package:busy_network/data/settings_store.dart';
import 'package:busy_network/settings/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _BrokenStore implements SettingsStore {
  @override
  Settings? load() => null;

  @override
  Future<void> save(Settings settings) async => throw StateError('disk penuh');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings', () {
    test('awal: suara, getar & musik nyala', () {
      expect(Settings.initial.sound, isTrue);
      expect(Settings.initial.vibration, isTrue);
      expect(Settings.initial.music, isTrue);
    });

    test('encode → decode sama', () {
      for (final s in const [
        Settings(),
        Settings(sound: false),
        Settings(vibration: false),
        Settings(sound: false, vibration: false),
        Settings(music: false),
        Settings(sound: false, vibration: false, music: false),
      ]) {
        expect(Settings.decode(s.encode()), s);
      }
    });

    test('rusak, versi lain, atau tipe salah → null', () {
      for (final source in [
        null,
        '{rusak',
        '[]',
        '{"versi":3,"suara":true,"getar":true,"musik":true}',
        '{"versi":2,"suara":true,"getar":true}',
        '{"versi":2,"suara":true,"getar":true,"musik":"ya"}',
        '{"versi":1,"suara":"ya","getar":true}',
        '{"versi":1,"suara":true}',
      ]) {
        expect(Settings.decode(source), isNull, reason: '$source');
      }
    });

    test('versi 1 tetap terbaca, musik nyala', () {
      expect(
        Settings.decode('{"versi":1,"suara":false,"getar":true}'),
        const Settings(sound: false),
      );
    });
  });

  group('PrefsSettingsStore', () {
    void usePrefs(Map<String, Object> data) {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData(data);
    }

    test('kosong → null; simpan lalu buka ulang → sama', () async {
      usePrefs({});
      final store = await PrefsSettingsStore.open();
      expect(store.load(), isNull);
      const s = Settings(sound: false);
      await store.save(s);
      expect((await PrefsSettingsStore.open()).load(), s);
    });

    test('isi bertipe lain → null', () async {
      usePrefs({PrefsSettingsStore.key: 7});
      expect((await PrefsSettingsStore.open()).load(), isNull);
    });
  });

  group('SettingsBook', () {
    test('store kosong → setelan awal; tersimpan → dimuat', () {
      expect(SettingsBook.memory().settings, Settings.initial);
      const saved = Settings(vibration: false);
      expect(SettingsBook(MemorySettingsStore(saved)).settings, saved);
    });

    test('ubah: memberi tahu & menyimpan; nilai sama diabaikan', () async {
      final store = MemorySettingsStore();
      final book = SettingsBook(store);
      var notified = 0;
      book.addListener(() => notified++);
      await book.setSound(false);
      expect(book.settings.sound, isFalse);
      expect(store.load(), const Settings(sound: false));
      await book.setVibration(false);
      expect(store.load(), const Settings(sound: false, vibration: false));
      expect(notified, 2);
      await book.setVibration(false);
      expect(notified, 2);
      await book.setMusic(false);
      expect(book.settings.music, isFalse);
      expect(
        store.load(),
        const Settings(sound: false, vibration: false, music: false),
      );
      expect(notified, 3);
    });

    test('gagal simpan: setelan di memori tetap berlaku', () async {
      final book = SettingsBook(_BrokenStore());
      await book.setSound(false);
      expect(book.settings.sound, isFalse);
    });
  });
}
