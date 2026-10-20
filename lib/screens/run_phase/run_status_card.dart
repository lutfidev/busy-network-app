import 'package:flutter/widgets.dart';

import '../../core/format.dart';
import '../../game/sim/sim.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

/// Bar atas fase jalan: jam, jam sibuk, linimasa hari, kepuasan.
class RunStatusCard extends StatelessWidget {
  const RunStatusCard({
    super.key,
    required this.day,
    required this.fastForward,
    required this.onFastForward,
    required this.onPause,
  });

  final DaySim day;

  /// Tombol percepat sedang menyala.
  final bool fastForward;
  final VoidCallback onFastForward;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final level = day.level;
    final target = level.targetSatisfaction;
    final rush = day.inRush;
    final satisfaction = day.satisfaction;
    return AppCard(
      tone: CardTone.night,
      radius: AppRadius.panel,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s14,
        AppSpacing.s12,
        AppSpacing.s14,
        AppSpacing.s14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama level panjang (level bos) mengecil, tidak
                    // dipotong.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'LEVEL ${level.number} · ${level.name.toUpperCase()}',
                        maxLines: 1,
                        style: AppTypography.label.copyWith(
                          color: AppColors.inkOnDarkMuted,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Row(
                      children: [
                        Text(
                          IdFormat.clock(day.minute),
                          style: AppTypography.clock,
                        ),
                        if (rush) ...[
                          const SizedBox(width: AppSpacing.s10),
                          const Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: RushHourBadge(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s10),
              CircleIconButton(
                icon: GameIcons.fastForward,
                semanticLabel: 'Percepat ke akhir hari',
                toggled: fastForward,
                onPressed: onFastForward,
                size: AppSizes.iconButtonMedium,
                iconSize: AppSizes.iconMd,
                background: fastForward
                    ? AppColors.primary
                    : AppColors.surfaceNightLine,
                iconColor: fastForward ? AppColors.ink : AppColors.inkOnDark,
              ),
              const SizedBox(width: AppSpacing.s10),
              CircleIconButton(
                icon: GameIcons.pause,
                semanticLabel: 'Jeda dan atur antrean',
                onPressed: onPause,
                iconSize: AppSizes.iconMd,
                background: AppColors.inkOnDark,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          _DayTimeline(day: day),
          const SizedBox(height: AppSpacing.s10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  'Kepuasan pelanggan',
                  style: AppTypography.captionStrong,
                ),
              ),
              Text.rich(
                TextSpan(
                  text: IdFormat.percent(satisfaction),
                  style: AppTypography.subtitle.copyWith(color: AppColors.star),
                  children: [
                    TextSpan(
                      text: ' / target ${IdFormat.percent(target)}',
                      style: AppTypography.small.copyWith(
                        color: AppColors.inkOnDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s6),
          ProgressBar(
            value: satisfaction / 100,
            marker: target / 100,
            color: AppColors.star,
            trackColor: AppColors.surfaceNightLine,
            height: AppSizes.progressThick,
            semanticLabel: 'Kepuasan pelanggan',
          ),
        ],
      ),
    );
  }
}

class _DayTimeline extends StatelessWidget {
  const _DayTimeline({required this.day});

  final DaySim day;

  static const _startHour = SimClock.dayStart ~/ 60;
  static const _endHour = SimClock.dayEnd ~/ 60;

  static double _frac(double hour) =>
      (hour - _startHour) / (_endHour - _startHour);

  @override
  Widget build(BuildContext context) {
    final now = _frac(day.minute / 60);
    final rushLabel = IdFormat.hourRange(day.rushFrom, day.rushTo);
    final noonInRush = day.rushFrom <= 12 && day.rushTo >= 12;
    final rushFrom = _frac(day.rushFrom.toDouble());
    final rushTo = _frac(day.rushTo.toDouble());
    final labelStyle = AppTypography.micro.copyWith(
      color: AppColors.inkOnDarkMuted,
    );
    return Semantics(
      label:
          'Linimasa hari ${IdFormat.hour(_startHour)}.00 sampai '
          '${IdFormat.hour(_endHour)}.00, jam sibuk '
          '${IdFormat.hour(day.rushFrom)}.00 sampai '
          '${IdFormat.hour(day.rushTo)}.00, sekarang '
          '${IdFormat.clock(day.minute).replaceAll(':', '.')}',
      excludeSemantics: true,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return SizedBox(
                height: AppSizes.progressMedium,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceNightLine,
                          borderRadius: AppRadius.pillAll,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: w * now,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.nightElapsed,
                          borderRadius: AppRadius.pillAll,
                        ),
                      ),
                    ),
                    Positioned(
                      left: w * rushFrom,
                      top: 0,
                      bottom: 0,
                      width: w * (rushTo - rushFrom),
                      child: Opacity(
                        opacity: 0.85,
                        child: Container(color: AppColors.primary),
                      ),
                    ),
                    Positioned(
                      left: w * now - 3,
                      top: -4,
                      width: 6,
                      height: 18,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.s4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(IdFormat.hour(_startHour), style: labelStyle),
              // Jam sibuk yang melewati tengah hari (level 7): labelnya di
              // tengah, menggantikan "12".
              if (noonInRush)
                Text(rushLabel, style: labelStyle)
              else ...[
                Text(IdFormat.hour(12), style: labelStyle),
                Padding(
                  padding: const EdgeInsets.only(left: 60),
                  child: Text(rushLabel, style: labelStyle),
                ),
              ],
              Text(IdFormat.hour(_endHour), style: labelStyle),
            ],
          ),
        ],
      ),
    );
  }
}
