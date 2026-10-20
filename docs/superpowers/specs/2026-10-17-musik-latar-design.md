# Langkah 11 — Musik latar

Roadmap: musik latar disintesis seperti `tool/make_sounds.py` (tanpa aset
berlisensi), berulang mulus: satu lagu santai untuk Beranda/Peta/Rancang dan
satu lebih tegang untuk Fase Jalan saat jam sibuk. Sakelar "Musik" baru di
Pengaturan (tersimpan di `Settings`), musik berhenti saat app ke latar
belakang dan lanjut saat kembali, efek suara tetap terdengar di atasnya.
Keluaran disuntik (default diam) supaya test senyap.

Desain tidak punya musik. Yang ditandai *(pemilik)* diputuskan pemilik repo
di brainstorming; *(sendiri)* = keputusan sendiri yang disetujui pemilik
dalam gambaran utuh; sisanya diserahkan ke pembuat.

## Tujuan
- Suasana: app terasa hidup di menu, dan jam sibuk terasa menegangkan
  karena musiknya ikut berubah tepat saat beban jaringan memuncak.
- Musik mengikuti permainan, bukan hiasan acak: lagu tegang = tanda "ini
  jam sibuk".

## Bukan tujuan / jangan
- Bukan aset berlisensi atau unduhan; semua disintesis skrip Python
  pustaka standar, deterministik.
- Jangan sampai efek suara tenggelam atau musik "meloncat" (klik/jeda)
  saat diulang atau berganti lagu.
- Jangan ada musik berbunyi di test, dan jangan sampai test jadi tidak
  stabil (`pumpAndSettle` tetap aman: musik tidak boleh memakai
  animasi/ticker Flutter yang tak berujung).
- Musik tidak berbunyi saat app di latar belakang.

## Kapan lagu apa
- **Santai** di Beranda, Peta Babak, Fase Rancang, Tutorial (semua
  langkah), Pengaturan (dan galeri), serta layar hasil.
- **Fase Jalan** *(pemilik)*: mulai dengan lagu santai; saat jam hari
  mencapai awal jam sibuk level itu (`DaySim.rushFrom`, default 19:00)
  berganti ke lagu **tegang**. Pergantian = crossfade ~1 detik, bukan
  potong.
- Setelah jam sibuk lewat (`DaySim.rushTo`, default 22:00) kembali santai
  (crossfade yang sama) sampai 24:00 *(sendiri)*. Batas pakai menit hari:
  tegang selama `rushFrom*60 ≤ menit < rushTo*60`.
- Panel Atur Antrean (rute anak Fase Jalan) dan pop-up komplain meneruskan
  lagu yang sedang jalan — tidak ganti, tidak diam *(sendiri)*. Jam berhenti
  di situ, jadi lagunya memang tidak akan berubah selama itu.
- Deep link / potret Fase Jalan (hari desain, jam di tengah jam sibuk) ikut
  aturan yang sama: lagu dipilih dari jam hari yang tampil.
- Mempercepat ×4 tidak mengubah tempo lagu; hanya pergantiannya yang datang
  lebih cepat.
- **24:00** *(sendiri)*: musik meredup cepat (≤ 0,5 s) supaya `Cue.win` /
  `Cue.fail` terdengar jelas, lalu layar hasil memutar lagu santai yang
  naik pelan setelah bunyi itu (sekitar 1,5 s setelah hari selesai).
- Back dari Fase Jalan ke Rancang (hari dibatalkan) → santai.
- Lagu yang sama yang sudah berjalan tidak diulang dari awal saat pindah
  layar (Beranda → Peta → Rancang tetap satu alur lagu santai).

## Lagu
- Disintesis skrip Python pustaka standar (perluas `tool/make_sounds.py`
  atau skrip saudara `tool/make_music.py`; pilihan pembuat), memakai gaya
  nada yang sama (sinus, bel, kotak halus) → `assets/audio/music_*.wav`
  (nama final terserah pembuat, dicatat di `Track`). WAV 16-bit mono
  22,05 kHz seperti efek suara; ukuran berkas wajar (target ≤ ~2 MB per
  lagu).
- Panjang ~30–40 detik per lagu, **berulang mulus**: tidak ada klik atau
  jeda di titik ulang (mis. ekor nada terakhir dibungkus ke awal / dirender
  dua putaran lalu diambil satu putaran utuh), panjang = kelipatan utuh
  ketukan.
- *(sendiri)* Santai: nada mayor, ~90 bpm, melodi bel ringan di atas
  akor lembut. Tegang: kunci dasar yang sama dengan nuansa minor, ~120 bpm,
  bas berdenyut yang mendorong. Kedua lagu harus terdengar sekeluarga
  (warna bunyi sama) supaya crossfade tidak janggal.
- *(sendiri)* Volume musik ~40% dari penuh, supaya efek suara (yang dipakai
  penuh) terdengar jelas di atasnya. Normalisasi berkas boleh tetap ke
  puncak 0,9; peredamannya lewat volume pemutar.

## Pengaturan
- `Settings.music` (bool, default nyala) di samping `sound` & `vibration`;
  `copyWith`, `==`, `encode`/`decode` ikut. Kunci JSON `musik`.
- Format naik ke versi 2. Setelan versi 1 yang tersimpan **tetap dibaca**
  (suara & getar dipertahankan, musik = nyala), bukan dibuang.
- `SettingsBook.setMusic(bool)`.
- Layar Pengaturan, kartu "Suara & getar": baris sakelar baru **"Musik"**
  di atas "Efek suara", dengan subjudul satu baris gaya baris lain (copy
  ditentukan pembuat, Bahasa Indonesia, mis. "Lagu latar di menu dan saat
  hari berjalan."). Judul kartu tetap. Wajib bebas overflow 360 px / teks
  130% (test overflow & screenshot `pengaturan` diperbarui).
- Mematikan "Musik" menghentikan musik seketika; menyalakan lagi memutar
  lagu yang sesuai layar saat itu. Sakelar "Efek suara" tidak memengaruhi
  musik, dan sebaliknya.

## Perilaku app
- App ke latar belakang (lifecycle bukan `resumed`) → musik dijeda; kembali
  `resumed` → lanjut dari posisi yang sama (bila musik nyala).
- *(sendiri)* Fokus audio: musik **tidak** menghentikan musik dari aplikasi
  lain (sama seperti efek suara, `mixWithOthers`); pemain yang tidak mau
  dua musik tinggal mematikan sakelar "Musik".
- Kegagalan memuat/memutar audio tidak menghentikan permainan (cukup
  `debugPrint`, seperti `AudioSoundOut`).

## Struktur (arah, rincian diserahkan ke rencana)
- Pola sama dengan efek suara: antarmuka keluaran (mis. `MusicOut`) dengan
  implementasi diam sebagai default dan implementasi `audioplayers`
  (mode media player, `ReleaseMode.loop`, dua pemain untuk crossfade)
  yang dipasang hanya di `main()`. Test memakai perekam (pola
  `RecordingFeedback`) yang mencatat lagu yang diminta / jeda / lanjut.
- Satu pengendali (mis. `BackgroundMusic`) di `GameSession` (pola
  `feedback`) memutuskan lagu yang terdengar dari: lagu yang diminta layar,
  setelan `music`, dan status latar depan. Logika pilih lagu & aturan
  jam sibuk murni dan diuji tanpa Flutter (mis. `trackAt(menit, rushFrom,
  rushTo)`).
- Cara layar meminta lagu (dari rute, dari layar, atau keduanya) diserahkan
  ke rencana; syaratnya: Fase Jalan memilih lagu dari jam hari setiap
  hari maju, layar lain cukup "santai".
- Risiko: `ReleaseMode.loop` lewat MediaPlayer Android bisa menyisakan
  jeda kecil di titik ulang pada sebagian perangkat. Cek di perangkat
  sungguhan; bila terdengar, ganti cara memutar (keputusan pembuat, dicatat
  di PR) — syarat "berulang mulus" tetap berlaku.
- Kembali dari tegang ke santai melanjutkan lagu santai dari posisinya
  (tidak mulai ulang) — keputusan pembuat.
- Crossfade & redup memakai timer/`Future` di implementasi audio, bukan
  animasi Flutter, supaya `pumpAndSettle` tidak terpengaruh; implementasi
  diam/perekam tidak menunda apa pun.

## Test
- Unit: `Settings` (music, encode v2, decode v1 → music nyala, decode
  rusak); `SettingsBook.setMusic`; aturan lagu menurut jam (sebelum, tepat
  di, selama, sesudah jam sibuk; level dengan jam sibuk sendiri); pengendali
  musik mematuhi setelan & latar belakang.
- Widget: Beranda memutar santai; Fase Jalan yang dimainkan berganti ke
  tegang saat masuk jam sibuk dan kembali santai sesudahnya (`playFor`);
  Panel Antrean tidak mengganti lagu; hari selesai → redup lalu santai di
  hasil; sakelar Musik di Pengaturan menghentikan/menyalakan & menyimpan;
  lifecycle `paused`/`resumed` menjeda/melanjutkan.
- Overflow & screenshot: layar Pengaturan dengan baris baru.
- `tool/make_music` (atau setara) dijalankan dan WAV hasilnya di-commit.

## Catatan
- Catat lagu & keputusan di badan PR ("Keputusan sendiri") dan di
  `CLAUDE.md` bagian Struktur (`lib/feedback/` / musik) bila ada berkas
  atau konsep baru.
