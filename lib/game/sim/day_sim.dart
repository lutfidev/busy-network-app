import 'dart:math' as math;

import '../map_scene.dart';
import '../model/level_def.dart';
import '../model/network.dart';
import 'flow.dart';
import 'patience.dart';
import 'sim_clock.dart';
import 'sim_frame.dart';
import 'usage_curve.dart';

/// Satu hari permainan di jaringan [network]: jam, pemakaian, aliran,
/// status & kesabaran rumah, kepuasan, komplain, dan antrean.
///
/// Murni & deterministik: maju per menit utuh lewat [advance], tanpa acak
/// dan tanpa Flutter. Nilai awal selain jam 06:00 dipakai untuk melanjutkan
/// hari dari potret (Fase Jalan di desain).
class DaySim {
  DaySim({
    required this.level,
    required this.network,
    int minute = SimClock.dayStart,
    Map<String, double> patience = const {},
    Map<String, int> limits = const {},
    Set<String> priority = const {},
    Complaint? complaint,
    this._complaints = 0,
  }) : assert(minute >= SimClock.dayStart && minute <= SimClock.dayEnd),
       _minute = minute,
       _patience = {
         for (final id in _houseIds(level, network)) id: patience[id] ?? 1.0,
       },
       _complaint = complaint {
    _limits = _checkedLimits(limits);
    _priority = _checkedPriority(priority);
    if (complaint != null) {
      _lastComplaint[complaint.houseId] = complaint.minute;
      _complained.add(complaint.houseId);
    }
    _frame = _assess(_limits, _priority);
    _recordExhausted();
  }

  /// Rumah yang sama tidak komplain lagi dalam sekian menit.
  static const complaintCooldown = 120;

  /// Rumah macet yang sudah komplain sejak terakhir kali mulai macet.
  final _complained = <String>{};

  final LevelDef level;
  final Network network;

  int _minute;
  double _carry = 0;
  final Map<String, double> _patience;
  late Map<String, int> _limits;
  late Set<String> _priority;
  Complaint? _complaint;
  int _complaints;
  final _lastComplaint = <String, int>{};
  late SimFrame _frame;
  final _fullMinutes = <String, int>{};
  final _firstFull = <String, int>{};
  final _peak = <String, ({double ratio, int minute})>{};
  final _exhausted = <String>{};

  /// Jam sekarang (menit sejak 00:00).
  int get minute => _minute;

  /// Hari sudah sampai 24:00.
  bool get over => _minute >= SimClock.dayEnd;

  SimFrame get frame => _frame;

  /// Kepuasan pelanggan 0..100.
  int get satisfaction => _frame.satisfaction;

  /// Komplain yang menunggu dijawab; selama ada, hari berhenti.
  Complaint? get complaint => _complaint;

  /// Jumlah komplain sepanjang hari.
  int get complaints => _complaints;

  /// Batas antrean tiap rumah tersambung (Mbps).
  Map<String, int> get limits => Map.unmodifiable(_limits);

  /// Rumah yang dilayani dulu saat kabel penuh.
  Set<String> get priority => Set.unmodifiable(_priority);

  /// Menit kabel [cableId] penuh (badge "Penuh!") sepanjang hari.
  int fullMinutes(String cableId) => _fullMinutes[cableId] ?? 0;

  /// Menit pertama kabel [cableId] penuh; `null` bila tidak pernah.
  int? firstFullMinute(String cableId) => _firstFull[cableId];

  /// Menit pertama beban kabel [cableId] paling berat (beban/kapasitas)
  /// selama penuh; `null` bila tidak pernah penuh.
  int? peakMinute(String cableId) => _peak[cableId]?.minute;

  /// Rumah tersambung yang sabarnya sempat habis (0%).
  Set<String> get exhausted => Set.unmodifiable(_exhausted);

  int get rushFrom => level.rushHourFrom ?? SimClock.defaultRushFrom;
  int get rushTo => level.rushHourTo ?? SimClock.defaultRushTo;

  /// Jam sekarang di dalam jam sibuk ([rushFrom] ≤ jam < [rushTo]).
  bool get inRush => minute >= rushFrom * 60 && minute < rushTo * 60;

  /// Maju [minutes] menit permainan; pecahan ditabung untuk panggilan
  /// berikutnya. Berhenti di akhir hari atau saat komplain muncul (sisa
  /// tabungan dibuang). `true` bila jam berubah.
  bool advance(double minutes) {
    if (over || _complaint != null) return false;
    _carry += minutes;
    var moved = false;
    while (_carry >= 1 && !over && _complaint == null) {
      _carry -= 1;
      _step();
      moved = true;
    }
    if (over || _complaint != null) _carry = 0;
    return moved;
  }

  /// Simpan batas & prioritas antrean (Panel Atur Antrean); berlaku mulai
  /// menit ini.
  void setQueue({
    required Map<String, int> limits,
    required Set<String> priority,
  }) {
    _limits = _checkedLimits(limits);
    _priority = _checkedPriority(priority);
    _frame = _assess(_limits, _priority);
  }

  /// Status rumah bila antrean diubah jadi [limits] & [priority] (pratinjau
  /// panel), dengan jam & kesabaran sekarang.
  Map<String, HouseLive> preview({
    required Map<String, int> limits,
    required Set<String> priority,
  }) => _assess(_checkedLimits(limits), _checkedPriority(priority)).houses;

  /// Pemain menjawab komplain; hari bisa lanjut.
  void dismissComplaint() => _complaint = null;

  // ── Langkah ─────────────────────────────────────────────────────────
  void _step() {
    const hours = 1 / 60;
    final demand = _frame.demand;
    for (final MapEntry(key: id, value: live) in _frame.houses.entries) {
      final rate = Patience.ratePerHour(
        service: live.service,
        jam: live.state == HouseState.jam,
        congested: network.isJammed(network.parentOf(id)!.cable, demand),
      );
      _patience[id] = (_patience[id]! + rate * hours).clamp(0.0, 1.0);
    }
    _minute++;
    _frame = _assess(_limits, _priority);
    _recordStats();
    _raiseComplaint();
  }

  /// Catat kabel penuh & sabar habis pada menit [_minute].
  void _recordStats() {
    final demand = _frame.demand;
    for (final cable in network.cables) {
      if (!network.isOverloaded(cable, demand)) continue;
      _fullMinutes[cable.id] = fullMinutes(cable.id) + 1;
      _firstFull[cable.id] ??= _minute;
      final ratio = network.cableLoad(cable, demand) / cable.spec.capacityMbps;
      final peak = _peak[cable.id];
      if (peak == null || ratio > peak.ratio + 1e-9) {
        _peak[cable.id] = (ratio: ratio, minute: _minute);
      }
    }
    _recordExhausted();
  }

  void _recordExhausted() {
    for (final MapEntry(key: id, value: patience) in _patience.entries) {
      if (patience <= 0) _exhausted.add(id);
    }
  }

  /// Satu komplain per masa macet tiap rumah, paling sering sekali per
  /// [complaintCooldown]. Rumah yang macet bersamaan komplain bergiliran
  /// (satu per langkah, setelah komplain sebelumnya dijawab); yang macet
  /// saat masih jeda komplain menyusul begitu jedanya habis.
  void _raiseComplaint() {
    bool jammed(String id) => _frame.houses[id]?.state == HouseState.jam;
    _complained.removeWhere((id) => !jammed(id));
    for (final id in _frame.houses.keys) {
      final last = _lastComplaint[id];
      if (jammed(id) &&
          !_complained.contains(id) &&
          (last == null || _minute - last >= complaintCooldown)) {
        _complaint = Complaint(houseId: id, minute: _minute);
        _complaints++;
        _lastComplaint[id] = _minute;
        _complained.add(id);
        return;
      }
    }
  }

  /// Hitung pemakaian, aliran, & status pada menit sekarang. Kabel penuh
  /// diukur dari permintaan (sudah dibatasi antrean).
  SimFrame _assess(Map<String, int> limits, Set<String> priority) {
    final share = UsageCurve.shareAt(
      _minute,
      rushFrom: rushFrom,
      rushTo: rushTo,
    );
    final surge = level.surge?.factorAt(_minute) ?? 1.0;
    final usage = {
      for (final id in _patience.keys)
        id: level.house(id).peakMbps * share * surge,
    };
    final demand = {
      for (final id in _patience.keys)
        id: math.min(usage[id]!, limits[id]!.toDouble()),
    };
    final served = Flow.serve(network, demand, priority);
    final houses = <String, HouseLive>{};
    for (final id in _patience.keys) {
      final cable = network.parentOf(id)!.cable;
      final service = HouseLive.serviceOf(usage[id]!, served[id]!);
      houses[id] = HouseLive(
        state: Patience.status(
          jam: Patience.short(service) && network.isOverloaded(cable, demand),
          patience: _patience[id]!,
          service: service,
        ),
        patience: _patience[id]!,
        usageMbps: usage[id]!,
        demandMbps: demand[id]!,
        servedMbps: served[id]!,
      );
    }
    final total = _patience.values.fold(0.0, (sum, p) => sum + p);
    return SimFrame(
      minute: _minute,
      houses: houses,
      satisfaction: (100 * total / level.houses.length + 1e-9).floor(),
    );
  }

  Map<String, int> _checkedLimits(Map<String, int> limits) {
    for (final id in limits.keys) {
      if (!_patience.containsKey(id)) {
        throw ArgumentError.value(id, 'limits', 'rumah tidak tersambung');
      }
    }
    return {
      for (final id in _patience.keys)
        id: () {
          final package = level.house(id).packageMbps;
          final limit = limits[id] ?? package;
          if (limit < 1 || limit > package) {
            throw ArgumentError.value(limit, 'limits[$id]', '1..$package');
          }
          return limit;
        }(),
    };
  }

  Set<String> _checkedPriority(Set<String> priority) {
    for (final id in priority) {
      if (!_patience.containsKey(id)) {
        throw ArgumentError.value(id, 'priority', 'rumah tidak tersambung');
      }
    }
    return {...priority};
  }

  /// Rumah tersambung dalam urutan level.
  static Iterable<String> _houseIds(LevelDef level, Network network) => [
    for (final h in level.houses)
      if (network.connectedHouses.contains(h.id)) h.id,
  ];
}
