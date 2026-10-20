# Jaringan Sibuk — panduan untuk Claude

Game puzzle mobile (Flutter + Flame, Android, portrait). Pemain jadi
pengelola RT/RW Net: tarik kabel dari router ke rumah, jaga trafik tetap
lancar saat jam sibuk.

## Sumber kebenaran visual
- `design/Jaringan Sibuk.html` — export desain (8 layar + "Design token &
  komponen"). Ukuran, warna, font, jarak, dan copy teks **ambil persis**
  dari sini. File ini bundel terkompres; untuk membacanya ekstrak dulu
  (lihat `docs/DESIGN_NOTES.md`).
- `design/reference/*.png` — render tiap layar 390×844 untuk dibandingkan.

## Perintah
```bash
flutter pub get
flutter analyze                 # harus bersih
flutter test                    # harus hijau (test screenshot di-skip)
flutter test test/screenshots --dart-define=SCREENSHOTS=true
                                # → build/screenshots/{390x844,360x740}/*.png
flutter run                     # perangkat/emulator Android
flutter build appbundle         # rilis; signing & ikon: docs/RELEASE.md
flutter test test/tool/store_test.dart --dart-define=STORE=true
                                # → store/*.png (materi Play Store)
```
Belum ada Flutter? `source scripts/setup_flutter.sh`.

## Struktur
- `lib/theme/` — token: `AppColors`, `AppTypography` (Fredoka/Nunito,
  tabular figures), `AppSpacing`, `AppRadius`, `AppElevation`, `AppMotion`,
  `AppSizes`, `AppTheme`. Import lewat `theme/theme.dart`.
- `lib/widgets/` — komponen reusable (barrel `widgets/widgets.dart`):
  `ChunkyButton`, `CircleIconButton`, badge/pill, `StarRating`, `AppCard`,
  `StatTile`, `ProgressBar`, `LevelNode`, `CableOptionCard`,
  `LevelHeaderCard`, `BottomPanel`, `DesignStage`,
  `GameIcon` (path SVG asli dari desain), `FillScrollView`, `LoopClock`
  (jam animasi berulang), `ToggleSwitch`, `LogoGlyph` (logo Beranda; juga
  sumber ikon launcher & splash).
- Animasi: `@keyframes` desain disalin jadi token `Keyframes` di
  `AppMotion` (persen + easing per segmen, persis CSS), digerakkan
  `LoopClock` (detik berjalan → pose). Pose peta di
  `game/render/map_motion.dart`, digerakkan `update(dt)` `NetworkGame`.
- `lib/game/` — `model/` (`LevelDef` + geometri grid (`snap`, `Cell`),
  `HouseDef`, `Cable`/`CableSpec`/`CableDraft`, `CableWalk` +
  `cablePolyline` (jalur tarikan di grid), `Network` topologi & beban,
  `GameState` fase rancang/jalan/hasil, anggaran, tarik kabel
  `beginCable`/`dragCable`/`endCable`, `removeCable`, mode hapus,
  `CableLesson` = tarikan tutorial (sumber & tujuan dibatasi, kabel
  panduan `guide`)),
  `levels/levels.dart` (`Levels.level1..12`, `all`, `byNumber`,
  `chapter`; isi level 2–4/6–11/12 di `part` `levels_early.dart`,
  `levels_late.dart`, `level_boss.dart`; `tutorialLesson`; level bos punya
  `TrafficSurge` = lonjakan pemakaian serentak),
  `scene_builder.dart` (`SceneBuilder.fromState(state)` → `MapScene`),
  `map_scene.dart` (model gambar), `render/map_renderer.dart` (gambar
  rumah/router/kabel/trafik di atas `Canvas`, per lapisan),
  `network_game.dart` (`NetworkGame`: `FlameGame`, kamera
  `withFixedResolution(390, 472)`, mendengarkan `GameState` dan
  menyamakan komponen; bila `interactive`, node menerima drag = tarik
  kabel dan kabel menerima ketuk = bongkar), `components/` (`GroundComponent`,
  `CableComponent`, `TrafficComponent`, `RouterComponent`/`HouseComponent`/
  `JunctionComponent`, `BadgeComponent`, `DragHandleComponent`; semuanya
  menggambar lewat `MapRenderer`), `network_game_view.dart`
  (`NetworkGameView`: `GameWidget` + overlay widget berkoordinat peta;
  dipakai Tutorial/Rancang/Jalan; Rancang & langkah 2 tutorial
  `interactive`).
- `lib/game/sim/` — simulasi hari, murni & deterministik (tanpa Flutter):
  `SimClock` (06→24 dalam 90 detik, percepat ×4), `UsageCurve` (puncak jam
  sibuk), `Flow.serve` (aliran per hop, prioritas dulu), `Patience`
  (status lancar/lambat/macet & laju sabar), `DaySim` (maju per menit utuh,
  kepuasan, komplain yang menjeda hari, batas & prioritas antrean,
  `preview`), `SimFrame`/`HouseLive`, `QueuePlan` (isi Panel Atur
  Antrean). `GameState.startDay()` membuat `DaySim`; `planDay()` menyalin
  rancangan jadi hari baru; `advanceDay(detik)` memajukannya. `DaySim`
  juga mencatat menit kabel penuh, beban terparah, dan sabar yang habis.
- `lib/game/result/` — `LevelResult.of(state)` (murni): bintang (gagal <
  `passSatisfaction` ≤ 1★ < `targetSatisfaction` ≤ 2★, 3★ bila juga sisa
  ≥ `savingsTarget`), rumah pindah, biang kerok `Culprit` (`FullCable`
  → `Unconnected` → `TightLimit`; fakta saja, teksnya di layar).
- `lib/game/progress/` — `Progress` (murni): bintang terbaik per level +
  `tutorialDone`; level terbuka & level sekarang diturunkan; `canPlay`
  (level bos butuh `ChapterDef.bossStars` bintang level 1–11);
  `Progress.empty` = awal permainan; `encode`/`decode` JSON.
- `lib/screens/<layar>/` — satu folder per layar (8 layar desain +
  `settings/` Pengaturan, yang tidak ada di desain).
- `lib/app/` — `routes.dart` (path; `play(n, tutorialDone:)`,
  `runOf`/`queueOf` membawa `?level=`), `router.dart` (go_router,
  bersarang), `app.dart`, `game_session.dart` (`GameSession`: hari dioper
  dari Rancang/Tutorial ke Jalan & Antrean; tanpa hari → potret desain;
  `finish()` di 24:00 → `result`, dicatat ke `progress` hanya bila hari
  dimulai lewat `begin`; juga membawa `feedback`, `settings` & `music`),
  `progress_book.dart` (`ProgressBook`: progres yang dibaca Beranda/Peta,
  `record`/`completeTutorial`/`reset` lalu simpan), `settings_book.dart`
  (`SettingsBook`: setelan suara, getar & musik, ubah lalu simpan).
  `app.dart` juga meminta lagu santai untuk tiap rute di luar Fase Jalan
  dan meneruskan lifecycle app ke musik.
- `lib/settings/` — `Settings` (murni): `sound`, `vibration`, `music`,
  `encode`/`decode` JSON (versi 2; versi 1 masih terbaca, musik nyala).
- `lib/feedback/` — `Cue` (tap, connect, refuse, remove, complaint, win,
  fail), `GameFeedback.cue` (suara/getar sesuai setelan; keluaran
  disuntik: `AudioSoundOut` = `audioplayers` + `assets/audio/*.wav` hasil
  `tool/make_sounds.py`, `SystemHaptics`; default diam),
  `FeedbackScope.of/cue/tap` (dipasang `JaringanSibukApp`; tanpa scope =
  diam). `NetworkGame.onCableDrop`/`onCableRemoved` → cue di
  `NetworkGameView`.
- `lib/music/` — musik latar: `Track` (calm/tense; `Track.forDay` =
  tegang selama `DaySim.inRush`), `BackgroundMusic` (di `GameSession`:
  lagu yang diminta layar × setelan `music` × latar depan → `MusicOut`;
  `request`, `endDay` = redup lalu lagu hasil menunggu bunyi menang/kalah,
  `setForeground`; `MusicTiming`), `MusicOut` (default `SilentMusic`;
  `AudioMusicOut` = `audioplayers` loop + fade lewat `Timer`, dipasang
  `main()`). Lagu `assets/audio/music_*.wav` hasil `tool/make_music.py`
  (berulang mulus). Fase Jalan meminta lagu dari jam hari. Test memakai
  `RecordingMusic`/`musicSession` (`test/music/recording_music.dart`).
- `lib/data/` — `dummy_states.dart` (potret `GameState` Tutorial (deep
  link `?langkah=`; tutorial yang dimainkan memakai satu state) & bingkai
  Fase Jalan desain, yang dihitung `DaySim` dari jam/sabar/komplain
  potret), `dummy_data.dart` (`designProgress` = progres Beranda/Peta di
  desain untuk screenshot & test, potret layar hasil untuk deep link), dan
  `progress_store.dart`
  (`PrefsProgressStore` = `shared_preferences`, `MemoryProgressStore`),
  `settings_store.dart` (sama, untuk setelan).
- `lib/core/format.dart` — `IdFormat`: `Rp 850.000`, `8,5 Mbps`, `20:15`.
- `lib/gallery/` — galeri komponen (rute `/pengaturan/galeri`, baris di
  Pengaturan hanya di build non-release).
- Android: `applicationId` `dev.lutfidev.jaringansibuk`, signing lewat
  `android/key.properties` (tidak di git). Lihat `docs/RELEASE.md`.
- `store/` — materi Play Store: `listing.md` (judul, deskripsi, daftar
  gambar), `privacy-policy.md`, dan PNG yang dirender
  `test/tool/store_test.dart` (layar app asli dalam bingkai; render ulang
  bila tampilan berubah). `test/tool/` juga berisi `brand_test.dart`
  (ikon & splash), `logo_render.dart`, `png_rgb.dart` (PNG tanpa alfa).

## Aturan
- **Jangan hardcode warna/ukuran di widget.** Tambah token di `lib/theme/`
  kalau butuh nilai baru. Koordinat peta/ilustrasi dari desain boleh
  ditulis sebagai data (kanvas 390×844 atau area peta 390×472).
- Angka selalu lewat `IdFormat` (format Indonesia).
- Copy teks Bahasa Indonesia persis seperti desain; jangan dipotong
  (`ellipsis`) — pakai wrap atau `FittedBox(scaleDown)`.
- Wajib bebas overflow di lebar 360 px: `test/screens/overflow_test.dart`
  mengecek semua rute di 360×640 s.d. 412×915 dan teks 130%. Rute baru →
  tambahkan ke daftar di test itu dan di `test/screenshots/`.
- Tombol/kontrol kustom: bungkus `Semantics(container: true, button: true,
  label: ...)`, dan ketukannya lewat `FeedbackScope.tap(context, onPressed)`
  supaya berbunyi. Kejadian game baru yang perlu terdengar → tambah `Cue`
  + berkas di `tool/make_sounds.py`; test memakai `RecordingFeedback`
  (`test/feedback/recording_feedback.dart`).
- Animasi tak berujung membuat `pumpAndSettle` macet. Animasi berulang
  wajib lewat `LoopClock` (berhenti di pose `still` bila
  `MediaQuery.disableAnimations`); animasi sekali jalan langsung ke akhir.
  Peta Flame: mesin `NetworkGame` hanya jalan bila scene bergerak dan
  animasi boleh; selain itu tiap perubahan digambar satu bingkai lalu
  mesin berhenti sendiri (`pumpAndSettle` aman).
  Test memompa app lewat `pumpApp`/`disableAnimations` di
  `test/test_helpers.dart`; uji gerakannya di
  `test/screens/animation_test.dart` (tanpa `pumpAndSettle`).
- Jam hari (Fase Jalan) adalah permainan, bukan hiasan: `Ticker` layar
  tetap jalan walau animasi mati, berhenti saat rute tertutup, komplain
  menunggu, atau hari selesai. Deep link Fase Jalan/Antrean = potret desain
  yang dijeda komplain, jadi `pumpAndSettle` aman; hari yang berjalan
  di-pompa dengan `playFor` / `pumpApp(settle: false)`, dan
  `pumpAndSettle` menjalankannya sampai 24:00 (layar hasil).
- Peta: kamera Flame beresolusi tetap 390×472 (koordinat desain, (0, 0)
  kiri atas). Overlay Flutter di atas peta (tooltip, banner, pop-up) tetap
  widget, diletakkan dengan koordinat peta lewat `NetworkGameView.overlays`
  (`DesignStage`). Gaya gambar hanya di `MapRenderer`;
  `test/game/network_game_test.dart` membandingkan piksel game dengan
  `MapRenderer.drawScene`.
- Level baru / ubah angka level: tambah rancangan acuan di
  `test/game/levels/level_plans.dart` (`referencePlans`, ditarik sungguhan
  lewat `GameState`) yang harus 3★ di `level_balance_test.dart`, plus
  jebakan (rancangan wajar yang tidak 3★). `level_def_test.dart` menjaga
  node di grid, muat di peta (label), berjarak ≥ 90 px, dan pemakaian ×
  lonjakan ≤ paket. Lihat potretnya: `level/NN-rancang` & `level/NN-jalan`
  di screenshot.
- Peta digambar dari state: ubah data level / `GameState`, bukan
  `MapScene` atau komponen langsung. `test/game/scene_builder_test.dart` menjaga snapshot
  tetap identik dengan desain (Fase Rancang: tarikan sungguhan
  `test/game/design_pull.dart`).
- Input peta: logika (snap, rute, biaya, bongkar) di `GameState`, diuji
  tanpa Flutter; komponen Flame hanya uji sentuh lalu memanggil API
  berbasis id. Widget test menyeret peta lewat `dragOnMap`/`mapToScreen`
  di `test/test_helpers.dart`; titik antara jalur seret taruh di titik
  grid (mis. (165, 255)), bukan di batas sel, supaya jalurnya sama di skala
  peta mana pun.
- Progres: `main()` membuka `PrefsProgressStore`; test & `GameSession()`
  default memakai progres di memori yang kosong (mulai level 1). Layar
  yang harus sama dengan desain (screenshot, alur dari level 5) memakai
  `GameSession(progress: ProgressBook.memory(DummyData.designProgress))`.
  Deep link layar hasil (tanpa `session.result`) = potret `DummyData`,
  jadi screenshot tetap sama dengan referensi. Test "aplikasi dibuka
  ulang": `pumpWidget(const SizedBox())` dulu — `pumpApp` kedua tanpa itu
  tetap memakai State, router, dan sesi lama.
- Commit kecil per langkah, pesan bahasa Inggris singkat
  (`feat(scope): ...`, `fix: ...`, `test: ...`).

## Alur git per langkah roadmap
Pemilik repo biasanya `/clear` setelah tiap sesi, jadi aturan ini yang
berlaku, bukan ingatan percakapan. Kerjakan sendiri tanpa bertanya dan
tanpa menyuruh pemilik repo menjalankan perintah:
- **Awal langkah:** `git fetch`, pastikan PR langkah sebelumnya sudah
  di-merge ke `origin/main`, lalu `git checkout main && git pull --ff-only`,
  buat `feat/<nama-langkah>`, hapus branch lokal yang sudah di-merge,
  `flutter pub get && flutter analyze && flutter test`. Kalau PR sebelumnya
  belum di-merge, jangan bercabang dari `main` lama; beri tahu pemilik repo.
- **Akhir langkah** (analyze bersih, test hijau, temuan review sudah
  diperbaiki): `git push -u origin <branch>` lalu `gh pr create --base main`
  langsung, tanpa menu pilihan. Kirim link PR-nya. Badan PR berbahasa
  Indonesia, gaya PR #2/#3: daftar perubahan, lalu baris "Verifikasi:".
- **Merge PR** dilakukan pemilik repo di GitHub; jangan merge sendiri
  kecuali diminta.
- Kesepakatan baru soal alur kerja langsung dicatat di file ini, jangan
  hanya diucapkan di chat.
- **Tanya hanya lewat brainstorming, dan hanya untuk hal yang belum
  diputuskan prompt roadmap atau desain** (lihat "Skill dan effort"). Hal
  kecil lainnya diputuskan sendiri dengan pilihan wajar, lalu dicatat di
  badan PR ("Keputusan sendiri") supaya bisa dikoreksi.

## Skill dan effort

Pemilik repo nyaman dengan skill superpowers: selalu pakai skill yang cocok. Effort sesi utama diatur pemilik repo lewat `/effort`; effort subagent ditulis di sini dan berlaku sebagai permintaan pemilik repo.

- **Planning:** `superpowers:brainstorming` lalu `superpowers:writing-plans` di sesi utama (high; xhigh untuk langkah dengan banyak keputusan, mis. 12 Babak 2). Brainstorming hanya untuk hal yang belum diputuskan prompt roadmap atau desain, dan pertanyaan yang diminta prompt roadmap diajukan di sini. Jalankan rencana dengan `superpowers:executing-plans` di sesi utama, bukan `subagent-driven-development`.
- **Cari bug:** `superpowers:systematic-debugging` di sesi utama (high). Kalau penyebabnya bisa di banyak tempat, sebar pencarian ke subagent `Explore` effort low; analisis akar masalah tetap di sesi utama.
- **Cari kode yang lebar:** subagent `Explore` effort low, hanya kalau bagian "Struktur" di atas dan `grep` langsung tidak cukup.
- **Review sebelum PR:** `superpowers:requesting-code-review` dengan satu subagent effort high, lalu `superpowers:receiving-code-review` untuk menimbang temuannya sebelum diperbaiki. Sesudah itu `superpowers:verification-before-completion` sebelum push.
- **Desain, logo, ikon, dan gambar lain:** di sesi utama (high), bukan subagent, karena butuh konteks desain lengkap. Yang ada di `design/` disalin persis; yang belum ada desainnya (mis. layar atau ikon baru di Babak 2) mulai dengan `superpowers:brainstorming`, pakai palet dan gaya desain, cek hasilnya lewat potret layar `test/screenshots/`, lalu catat di `docs/DESIGN_NOTES.md`.

## Lanjut ke mana
Lihat `docs/ROADMAP.md` — langkah berurutan beserta prompt siap tempel.
