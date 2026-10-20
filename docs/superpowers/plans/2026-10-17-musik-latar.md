# Musik Latar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (CLAUDE.md: main session, not subagent-driven) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Two synthesized looping background tracks (calm / tense), with tense playing during the level's rush hours in Fase Jalan, a saved "Musik" toggle, and pause/resume with the app lifecycle.

**Architecture:** Pure rule (`Track.forDay`) + one controller `BackgroundMusic` (in `GameSession`) that decides what is audible from the requested track, `Settings.music`, and foreground state, and talks to an injected `MusicOut` (silent by default, recorder in tests, `AudioMusicOut` = audioplayers in `main()`). Routes outside Fase Jalan request calm via a router listener in the app; Fase Jalan requests from its day clock. Fades/delays live only inside `AudioMusicOut` (timers), never in Flutter animations.

**Tech Stack:** Flutter, audioplayers 6.8 (already a dependency), go_router 18.1, Python 3 stdlib for synthesis.

**Spec:** `docs/superpowers/specs/2026-10-17-musik-latar-design.md`

## Global Constraints

- Tense exactly while `rushFrom*60 ≤ minute < rushTo*60` (`DaySim.rushFrom/rushTo`); otherwise calm.
- Crossfade between tracks 1 s; day-end fade ≤ 0.5 s (use 400 ms); calm on the result screen starts ~1.5 s after day end.
- Music volume 0.4; audio context `mixWithOthers` (does not stop other apps' music).
- Settings JSON version 2 with key `musik`; version-1 data still decodes with `music = true`.
- New row title copy: `Musik`, placed above `Efek suara`. Subtitle: `Lagu santai di menu, lebih tegang saat jam sibuk.`
- No sound in tests; `pumpAndSettle` unaffected (no Flutter tickers for music).
- WAV 16-bit mono 22.05 kHz, seamless loop, ≤ ~2 MB each, deterministic synthesis, stdlib only.
- Commit messages English, `feat(scope): ...` / `test: ...` / `docs: ...`.

## Review Focus

- App backgrounded during the 1.5 s wait before result calm → nothing plays until resumed, then calm (Task 2 test `background cancels pending result calm`).
- Every day tick calls `request`; the same track must not re-trigger `MusicOut.play` (Task 2 dedup test, Task 3 count assertion).
- Back from Fase Jalan during rush → Rancang plays calm (Task 3 test).
- App opened with music already off → `MusicOut` never asked to play a track (Task 2 test).
- Cold deep link to Panel Antrean (design snapshot inside rush) → tense, from the run screen beneath (Task 3 test).

---

### Task 1: `Settings.music` (v2) + `SettingsBook.setMusic`

**Files:**
- Modify: `lib/settings/settings.dart`, `lib/app/settings_book.dart`
- Test: `test/settings/settings_test.dart`, `test/app/` (wherever `SettingsBook` is tested; grep `setVibration` in `test/`)

**Interfaces:**
- Produces: `Settings({bool sound = true, bool vibration = true, bool music = true})`, `Settings.music`, `copyWith({..., bool? music})`, `Settings.version == 2`; `SettingsBook.setMusic(bool on) → Future<void>`.

- [ ] **Step 1: Failing tests** — in `settings_test.dart`:
  - round trip includes `Settings(music: false)` and `Settings(sound: false, vibration: false, music: false)`;
  - `test('versi 1 tetap terbaca, musik nyala')`: `Settings.decode('{"versi":1,"suara":false,"getar":true}')` == `Settings(sound: false)` (music true);
  - the "rusak" list: replace `'{"versi":2,"suara":true,"getar":true}'` with `'{"versi":3,"suara":true,"getar":true,"musik":true}'` and add `'{"versi":2,"suara":true,"getar":true}'` (v2 without musik) and `'{"versi":2,"suara":true,"getar":true,"musik":"ya"}'`.
  - SettingsBook test: `setMusic(false)` → `settings.music == false`, notifies, saved to store.
- [ ] **Step 2: Run** `flutter test test/settings test/app` → FAIL (no `music`).
- [ ] **Step 3: Implement** — `music` field everywhere (`==`, `hashCode`, `toString`); `encode` writes `versi: 2, suara, getar, musik`; `decode` accepts versi 1 (no `musik` key, music = true) and versi 2 (`musik` must be bool). `setMusic` mirrors `setSound`. Update the doc comment of `SettingsBook` to mention `setMusic`.
- [ ] **Step 4: Run** same tests → PASS.
- [ ] **Step 5: Commit** `feat(settings): music setting, settings format v2 that still reads v1`

### Task 2: Music core — `Track`, `MusicOut`, `BackgroundMusic`

**Files:**
- Modify: `lib/game/sim/day_sim.dart` (add `inRush`), `lib/screens/run_phase/run_status_card.dart:30` (use it)
- Create: `lib/music/track.dart`, `lib/music/music_out.dart`, `lib/music/background_music.dart`
- Create: `test/music/recording_music.dart`, `test/music/background_music_test.dart`, `test/music/track_test.dart`

**Interfaces:**
- Consumes: `Settings.music`, `SettingsBook` (ChangeNotifier) from Task 1; `DaySim.minute/rushFrom/rushTo`.
- Produces:
  - `bool get DaySim.inRush` = `minute >= rushFrom * 60 && minute < rushTo * 60`.
  - `enum Track { calm('music_calm'), tense('music_tense') }` with `final String file` (asset `assets/audio/<file>.wav`) and `static Track forDay(DaySim day)` → `day.inRush ? tense : calm`.
  - `abstract interface class MusicOut { void play(Track? track, {Duration fade = Duration.zero, Duration delay = Duration.zero}); }` — doc: wait [delay], then old track down / [track] up over [fade] (zero = instantly); `null` = silence; a paused track resumes from its position; each call cancels the previous call's pending delay; a running fade keeps going during a new call's delay and is replaced only when the new fade starts (so the 24:00 dim survives the delayed result calm). `class SilentMusic implements MusicOut` (const, no-op).
  - `abstract final class MusicTiming { static const crossfade = Duration(seconds: 1); static const dayEndFade = Duration(milliseconds: 400); static const resultDelay = Duration(milliseconds: 1500); }`
  - `class BackgroundMusic { BackgroundMusic({required SettingsBook settings, MusicOut out = const SilentMusic()}); Track? get audible; void request(Track track); void endDay(); void setForeground(bool foreground); }`
  - Test helper: `class RecordingMusic implements MusicOut { final calls = <MusicCall>[]; Track? get current; }`, `typedef MusicCall = ({Track? track, Duration fade, Duration delay})`.

- [ ] **Step 1: Failing tests**
  - `track_test.dart` (use `sim_fixtures`/a `DaySim` of level 1, rush 19–22): minute 18:59 → calm; 19:00 → tense; 21:59 → tense; 22:00 → calm; a level with its own rush hours (e.g. one from `levels_late.dart` with 18–22) at 18:00 → tense.
  - `background_music_test.dart` (`BackgroundMusic` over `SettingsBook.memory()` + `RecordingMusic`):
    - `request(calm)` → one call `(calm, crossfade, zero)`; `request(calm)` again → still one call (dedup).
    - `request(tense)` → `(tense, crossfade, zero)`; `audible == tense`.
    - `endDay()` → `(null, dayEndFade, zero)`; then `request(calm)` → `(calm, crossfade, resultDelay)`; a later `request(tense)` → no delay.
    - `setForeground(false)` → `(null, zero, zero)`; `setForeground(true)` → `(calm, zero, zero)` (the wanted track, resumed).
    - `background cancels pending result calm`: endDay → request(calm) → setForeground(false) → last call `(null, zero, zero)`; setForeground(true) → `(calm, zero, zero)`.
    - `settings.setMusic(false)` → `(null, zero, zero)`; `setMusic(true)` → `(wanted, zero, zero)`.
    - Music off from the start: `request(calm)`, `request(tense)` → `calls` empty.
- [ ] **Step 2: Run** `flutter test test/music` → FAIL.
- [ ] **Step 3: Implement.** `BackgroundMusic` keeps `_wanted`, `_foreground = true`, `_afterDayEnd`, `_audible`; listens to `settings`. One private `_sync({Duration fade, Duration delay})`: target = `settings.settings.music && _foreground ? _wanted : null`; if `target == _audible` return; else `out.play(target, fade:, delay:)` and store. `request` ignores an unchanged `_wanted` unless `_afterDayEnd`; after day end it uses `delay: resultDelay` once. `endDay` sets `_wanted = null`, `_afterDayEnd = true`, fades with `dayEndFade`. Settings/foreground changes sync with zero fade. Replace the inline rush check in `run_status_card.dart` with `day.inRush`.
- [ ] **Step 4: Run** `flutter test test/music test/screens` → PASS.
- [ ] **Step 5: Commit** `feat(music): track rule by rush hours and background music controller`

### Task 3: Wire music into the app

**Files:**
- Modify: `lib/app/game_session.dart` (field `music`), `lib/app/app.dart` (router listener + lifecycle), `lib/screens/run_phase/run_phase_screen.dart` (request per tick, `endDay` in `_finish`)
- Test: `test/music/music_flow_test.dart`; extend `test/music/recording_music.dart` with `GameSession musicSession(RecordingMusic out, {SettingsBook? settings, ProgressBook? progress})`

**Interfaces:**
- Consumes: Task 2 API.
- Produces: `GameSession({ProgressBook? progress, GameFeedback? feedback, MusicOut music = const SilentMusic()})` and `final BackgroundMusic GameSession.music` built over `feedback.settings`.

- [ ] **Step 1: Failing widget tests** (`setUpFonts`, `pumpApp`, `_playUntil`/`designDay` pattern from `test/feedback/cue_flow_test.dart` — move `_playUntil` to `test/game/sim/sim_fixtures.dart` as `playUntil` and reuse it in both files):
  - `Beranda memutar santai`: after `pumpApp`, `out.current == Track.calm`; tap `Main` → still one call.
  - `jam sibuk menegang lalu santai lagi`: session begun with `playUntil(designDay(designFiberCables), 18 * 60 + 58)`, `pumpApp(location: AppRoutes.runOf(5), settle: false)` → `current == calm`; `playFor(tester, 1)` → `current == tense`; then advance via `playUntil` on `session.last!` to `21 * 60 + 58`, `playFor(tester, 1)` → `current == calm`; total calls ≤ 4 (no per-tick spam).
  - `back saat jam sibuk → Rancang santai`: as above until tense, then `tester.binding.handlePopRoute()` + `pumpAndSettle` → `current == calm`.
  - `deep link Panel Antrean = tegang` (design snapshot is inside rush): `pumpApp(location: AppRoutes.queueOf(5))` → `current == Track.tense`.
  - `hari selesai → redup lalu santai tertunda`: reuse the cue_flow day-end setup (`23 * 60 + 50`) → after `pumpAndSettle`, the last two calls are `(null, dayEndFade, zero)` then `(calm, crossfade, resultDelay)`.
  - `latar belakang menjeda`: `tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused)` → `current == null`; `resumed` → `calm`.
- [ ] **Step 2: Run** `flutter test test/music/music_flow_test.dart` → FAIL.
- [ ] **Step 3: Implement.**
  - `GameSession`: `music = BackgroundMusic(settings: this.feedback.settings, out: music)` (initializer list order: feedback first).
  - `app.dart`: `_JaringanSibukAppState with WidgetsBindingObserver`; add/remove observer; `didChangeAppLifecycleState(s) => _session.music.setForeground(s == AppLifecycleState.resumed)`. Listen to `_router.routerDelegate`; on change read `_router.routerDelegate.currentConfiguration.uri.path`; also apply once for `widget.initialLocation`. Path not starting with `AppRoutes.run` → `_session.music.request(Track.calm)`; under it, do nothing (Fase Jalan decides). Remove listener in `dispose`.
  - `run_phase_screen.dart`: in `initState` and in `_onGameChanged` while `_game.phase == GamePhase.run`: `widget.session.music.request(Track.forDay(_day))`. In `_finish`, call `widget.session.music.endDay()` before the cue. Update the class doc comment (music follows the day clock).
- [ ] **Step 4: Run** `flutter test` (whole suite; cue_flow still green after moving `playUntil`) → PASS.
- [ ] **Step 5: Commit** `feat(music): calm on menus, tense during rush hours in Fase Jalan, pause in background`

### Task 4: "Musik" toggle in Pengaturan

**Files:**
- Modify: `lib/widgets/icons/game_icons.dart` (add `music`), `lib/screens/settings/settings_screen.dart`
- Test: the existing settings screen widget test (grep `Efek suara` in `test/screens/`), plus a music check in `test/music/music_flow_test.dart`

**Interfaces:**
- Consumes: `SettingsBook.setMusic`, `Settings.music`, `RecordingMusic`.
- Produces: `GameIcons.music` — 24-grid stroke icon, doc `/// Pengaturan (tidak ada di desain): not balok.`, shapes `IconShape.path('M9 17.5V5.5l10-2v12')`, `IconShape.circle(Offset(6.5, 17.5), 2.5)`, `IconShape.circle(Offset(16.5, 15.5), 2.5)`, `strokeWidth: 2.2` (match `sound`).

- [ ] **Step 1: Failing tests**
  - Settings screen: finds `Musik` above `Efek suara` (compare `tester.getTopLeft` dy); tapping the Musik switch → `settings.music == false` and saved.
  - `music_flow_test`: on `/pengaturan` with recorder, toggling Musik off → `current == null`; on again → `current == calm`.
- [ ] **Step 2: Run** those tests → FAIL.
- [ ] **Step 3: Implement** a `_SwitchRow` (icon `GameIcons.music`, title `Musik`, subtitle from Global Constraints, `value: s.music`, `onChanged: settings.setMusic`) + `_Divider` as the first row in the "SUARA & GETAR" card.
- [ ] **Step 4: Run** `flutter test test/screens test/music`, including `test/screens/overflow_test.dart` → PASS. Render `flutter test test/screenshots --dart-define=SCREENSHOTS=true` and look at `build/screenshots/360x740/10-pengaturan.png` and `390x844/10-pengaturan.png` (row wraps cleanly, nothing cut).
- [ ] **Step 5: Commit** `feat(settings): music toggle`

### Task 5: Synthesized tracks + `AudioMusicOut`

**Files:**
- Create: `tool/make_music.py`, `assets/audio/music_calm.wav`, `assets/audio/music_tense.wav`, `lib/music/audio_music_out.dart`
- Modify: `lib/main.dart`, `pubspec.yaml` (asset comment mentions music), `tool/make_sounds.py` docstring only if shared helpers move

**Interfaces:**
- Consumes: `Track.file`, `MusicOut`.
- Produces: `class AudioMusicOut implements MusicOut` (`static const volume = 0.4`); `python tool/make_music.py` writes both WAVs.

- [ ] **Step 1: Write `tool/make_music.py`.** Import `note`, `RATE`, `OUT` from `make_sounds` (same directory; keep `make_sounds` import-safe under `if __name__ == '__main__'`). Render each track into a buffer of exact loop length `bars × 4 beats × 60/bpm` seconds, adding every note at `index % length` so tails wrap into the start (seamless loop). Normalize to peak 0.9 and write 16-bit mono 22.05 kHz.
  - calm: C major, 90 bpm, 16 bars (~42.7 s). Progression per 4 bars `C – Am – F – G`, soft sine pad chords (low amplitude, slow decay) on each bar, a bell melody on eighths/quarters over the chord tones, light sine bass on beats 1 and 3.
  - tense: A minor (same key signature, related to calm), 120 bpm, 16 bars (32 s). `Am – F – C – G`, soft-square bass pulsing on every eighth, short bell motif on offbeats, a soft high tick on each beat for urgency. Same instruments as calm (sine/bell/soft-square) so the crossfade blends.
  - No randomness; same output every run.
- [ ] **Step 2: Run** `python tool/make_music.py` → prints both paths and durations; check sizes ≤ ~2 MB (`ls -la assets/audio`). Check seamlessness numerically: the absolute difference between the last and first sample is small (< 0.05 of full scale) and there is no silence gap > 20 ms at either end. Listen if a player is available.
- [ ] **Step 3: Implement `AudioMusicOut`** (mirrors `AudioSoundOut` style): one `AudioPlayer` per `Track`, `PlayerMode.mediaPlayer`, `ReleaseMode.loop`, `AudioContextConfig(focus: mixWithOthers)`, source `AssetSource('audio/${track.file}.wav')`, loaded in background (`unawaited`), failures `debugPrint` only. `play`: cancel pending timers; after `delay` (Timer), ramp each player's volume linearly toward its target (target track `volume`, others 0) over `fade` with a 50 ms `Timer.periodic` (zero fade = set immediately); start (`resume`) the target before ramping up; `pause` (not stop) players that reach 0 so they resume from position. A `play` arriving before loading finishes is remembered and applied after load.
- [ ] **Step 4: Wire `main()`**: `GameSession(..., music: AudioMusicOut())`. Run `flutter analyze` → clean; `flutter test` → green.
- [ ] **Step 5: Device check** if `flutter devices` lists an Android device/emulator: `flutter run`, listen for loop gaps, crossfade at 19:00/22:00, background pause, toggle. If no device, say so in the PR (unverified on device).
- [ ] **Step 6: Commit** `feat(music): synthesized calm and tense loops played through audioplayers`

### Task 6: Docs

**Files:**
- Modify: `CLAUDE.md` (Struktur: new `lib/music/` entry; `Settings` mentions `music`; `tool/make_music.py`), `docs/DESIGN_NOTES.md` (music section next to sound effects), `docs/ROADMAP.md` only if it marks progress elsewhere (it does not today — leave it).

- [ ] **Step 1:** Write the entries (Indonesian, same style as neighbouring lines).
- [ ] **Step 2:** `flutter analyze` clean, `flutter test` green.
- [ ] **Step 3: Commit** `docs: background music`
