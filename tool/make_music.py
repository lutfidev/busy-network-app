"""Sintesis musik latar Jaringan Sibuk → assets/audio/music_*.wav.

    python tool/make_music.py

Hanya pustaka standar Python; memakai nada dari `make_sounds.py` (sinus,
bel, kotak halus) supaya musik sekeluarga dengan efek suara. Hasilnya
deterministik, WAV 16-bit mono 22,05 kHz. Nama berkas = `Track.file` di
lib/music/track.dart.

Tiap lagu dirender ke penyangga sepanjang tepat satu putaran (kelipatan
utuh ketukan); ekor nada yang melewati ujung dibungkus ke awal, jadi lagu
berulang mulus tanpa klik atau jeda.
"""

import os

from make_sounds import OUT, RATE, note, write


def freq(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


class Loop:
    """Penyangga satu putaran: [bars] birama 4/4 pada [bpm]."""

    def __init__(self, bpm, bars):
        self.beat = 60.0 / bpm
        self.samples = [0.0] * round(RATE * self.beat * 4 * bars)

    def add(self, bar, beat, midi, beats, **kw):
        """Nada [midi] mulai birama [bar] ketukan [beat], [beats] ketukan."""
        start = round(RATE * self.beat * (bar * 4 + beat))
        n = len(self.samples)
        for i, s in enumerate(note(freq(midi), self.beat * beats, **kw)):
            self.samples[(start + i) % n] += s

    def chord(self, bar, midis, beats, **kw):
        for midi in midis:
            self.add(bar, 0, midi, beats, **kw)


# ── Santai: C mayor, 90 bpm, C – Am – F – G ─────────────────────────────

CALM_CHORDS = [
    # (bas, nada akor)
    (48, [60, 64, 67]),  # C
    (45, [57, 60, 64]),  # Am
    (41, [57, 60, 65]),  # F
    (43, [59, 62, 67]),  # G
]

# Melodi bel per birama: (ketukan, midi, panjang ketukan). Frasa A lalu B,
# masing-masing empat birama mengikuti akor; G di akhir B kembali ke C.
CALM_MELODY = [
    [(0, 76, 1), (1, 79, 1), (2, 84, 1.5), (3.5, 79, 0.5)],
    [(0, 81, 1.5), (1.5, 79, 0.5), (2, 76, 2)],
    [(0, 77, 1), (1, 81, 1), (2, 84, 1), (3, 81, 1)],
    [(0, 79, 1.5), (1.5, 74, 0.5), (2, 71, 1), (3, 74, 1)],
    [(0, 84, 1), (1, 79, 0.5), (1.5, 76, 0.5), (2, 79, 2)],
    [(0, 76, 1), (1, 72, 1), (2, 69, 2)],
    [(0, 69, 0.5), (0.5, 72, 0.5), (1, 77, 1), (2, 76, 1), (3, 72, 1)],
    [(0, 74, 2), (2, 71, 1), (3, 67, 1)],
]


def calm():
    loop = Loop(bpm=90, bars=16)
    for bar in range(16):
        bass, tones = CALM_CHORDS[bar % 4]
        # Akor lembut sepanjang birama, ekornya menyambung ke birama berikut.
        loop.chord(bar, tones, 4.5, amp=0.07, decay=0.9, attack=0.25)
        # Bas: akar di ketukan 1, kuin di ketukan 3.
        loop.add(bar, 0, bass, 1.5, amp=0.22, decay=3)
        loop.add(bar, 2, bass + 7, 1.5, amp=0.16, decay=3)
        for beat, midi, beats in CALM_MELODY[bar % 8]:
            loop.add(bar, beat, midi, beats + 0.5, amp=0.17, decay=4,
                     wave_='bell')
        # Paruh kedua: arpeggio seperdelapan tipis sebagai tekstur.
        if bar >= 8:
            for i in range(8):
                loop.add(bar, i * 0.5, tones[i % 3] + 12, 0.6, amp=0.045,
                         decay=7)
    return loop.samples


# ── Tegang: A minor, 120 bpm, Am – F – C – G ────────────────────────────

TENSE_CHORDS = [
    (45, [69, 72, 76]),  # Am
    (41, [65, 69, 72]),  # F
    (48, [67, 72, 76]),  # C
    (43, [67, 71, 74]),  # G
]

# Bas berdenyut tiap seperdelapan: selisih nada dari akar.
TENSE_BASS = [0, 0, 12, 0, 0, 12, 0, 7]

# Lead bel di paruh kedua.
TENSE_LEAD = [
    [(0, 76, 1), (1, 76, 0.5), (1.5, 74, 0.5), (2, 72, 1), (3, 74, 1)],
    [(0, 72, 1.5), (1.5, 69, 0.5), (2, 72, 2)],
    [(0, 79, 1), (1, 76, 1), (2, 72, 1), (3, 76, 1)],
    [(0, 74, 1.5), (1.5, 71, 0.5), (2, 74, 1), (3, 76, 1)],
]


def tense():
    loop = Loop(bpm=120, bars=16)
    for bar in range(16):
        bass, tones = TENSE_CHORDS[bar % 4]
        loop.chord(bar, [t - 12 for t in tones], 4.3, amp=0.05, decay=1.5,
                   attack=0.05)
        for i, step in enumerate(TENSE_BASS):
            loop.add(bar, i * 0.5, bass + step, 0.45, amp=0.16, decay=9,
                     wave_='soft-square')
        # Motif bel di ketukan lemah.
        for i, tone in enumerate([tones[0], tones[1], tones[2], tones[1]]):
            loop.add(bar, i + 0.5, tone, 0.5, amp=0.11, decay=10,
                     wave_='bell')
        # Detak tinggi tiap ketukan, ketukan 1 lebih keras.
        for beat in range(4):
            loop.add(bar, beat, 96, 0.08, amp=0.06 if beat else 0.09,
                     decay=70)
        if bar >= 8:
            for beat, midi, beats in TENSE_LEAD[bar % 4]:
                loop.add(bar, beat, midi + 12, beats + 0.25, amp=0.13,
                         decay=5, wave_='bell')
    return loop.samples


TRACKS = {'music_calm': calm, 'music_tense': tense}

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for name, render in TRACKS.items():
        write(name, render())
