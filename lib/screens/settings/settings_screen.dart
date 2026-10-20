import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/progress_book.dart';
import '../../app/routes.dart';
import '../../app/settings_book.dart';
import '../../feedback/feedback_scope.dart';
import '../../game/levels/levels.dart';
import '../../game/progress/progress.dart';
import '../../settings/settings.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'reset_progress_dialog.dart';

/// Pengaturan (tidak ada di desain; gaya Peta Babak): suara, getar, reset
/// progres, dan — di luar build release — galeri komponen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.progress,
  });

  final SettingsBook settings;
  final ProgressBook progress;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([settings, progress]),
      builder: (context, _) =>
          _build(context, settings.settings, progress.progress),
    );
  }

  Widget _build(BuildContext context, Settings s, Progress p) {
    return Scaffold(
      backgroundColor: AppColors.groundMap,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20,
                AppSpacing.s20,
                AppSpacing.s20,
                0,
              ),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: GameIcons.back,
                    semanticLabel: 'Kembali ke Beranda',
                    onPressed: () => context.go(AppRoutes.home),
                    borderColor: AppColors.surfaceLine,
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Pengaturan',
                        style: AppTypography.titleLarge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.s20),
                children: [
                  const _SectionLabel('SUARA & GETAR'),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SwitchRow(
                          icon: GameIcons.music,
                          title: 'Musik',
                          subtitle:
                              'Lagu santai di menu, lebih tegang saat jam '
                              'sibuk.',
                          value: s.music,
                          onChanged: settings.setMusic,
                        ),
                        const _Divider(),
                        _SwitchRow(
                          icon: GameIcons.sound,
                          title: 'Efek suara',
                          subtitle:
                              'Bunyi saat kabel tersambung, ada komplain, '
                              'dan hari selesai.',
                          value: s.sound,
                          onChanged: settings.setSound,
                        ),
                        const _Divider(),
                        _SwitchRow(
                          icon: GameIcons.vibrate,
                          title: 'Getar',
                          subtitle:
                              'Getar halus saat kabel dipasang, '
                              'ditolak, atau ada komplain.',
                          value: s.vibration,
                          onChanged: settings.setVibration,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  const _SectionLabel('PROGRES'),
                  _ProgressCard(
                    progress: p,
                    onReset: () => _confirmReset(context, p),
                  ),
                  if (!kReleaseMode) ...[
                    const SizedBox(height: AppSpacing.s24),
                    const _SectionLabel('PENGEMBANG'),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: _LinkRow(
                        title: 'Galeri komponen',
                        onPressed: () => context.go(AppRoutes.gallery),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, Progress p) async {
    if (await showResetProgressDialog(context, stars: p.totalStars)) {
      await progress.reset();
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.s4,
        bottom: AppSpacing.s8,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: AppTypography.captionStrong.copyWith(
            color: AppColors.inkMuted,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding),
      child: SizedBox(
        height: 1,
        width: double.infinity,
        child: ColoredBox(color: AppColors.track),
      ),
    );
  }
}

/// Baris sakelar: seluruh baris bisa diketuk.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final GameIconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final onTap = ToggleSwitch.toggle(context, value, onChanged);
    return Semantics(
      container: true,
      button: true,
      toggled: value,
      label: title,
      hint: subtitle,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Row(
            children: [
              _IconTile(icon: icon),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyStrong),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              ToggleTrack(value: value),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final GameIconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.iconButtonSmall,
      height: AppSizes.iconButtonSmall,
      decoration: const BoxDecoration(
        color: AppColors.bubble,
        borderRadius: AppRadius.iconTileAll,
      ),
      alignment: Alignment.center,
      child: GameIcon(icon, size: AppSizes.iconMd, color: AppColors.ink),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress, required this.onReset});

  final Progress progress;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    const chapter = Levels.chapter;
    final empty = progress == Progress.empty;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StarCounterPill(
                value: progress.totalStars,
                total: chapter.starsTotal,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  '${progress.levelsDone(chapter.levelCount)} / '
                  '${chapter.levelCount} level selesai',
                  style: AppTypography.bodyStrong,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          Text(
            empty
                ? 'Belum ada progres. Semua mulai dari tutorial level 1.'
                : 'Hapus semua bintang dan mulai lagi dari tutorial level 1.',
            style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.s12),
          ChunkyButton(
            label: 'Reset progres',
            variant: ChunkyVariant.outline,
            size: ChunkySize.small,
            leadingIcon: GameIcons.retry,
            onPressed: empty ? null : onReset,
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.title, required this.onPressed});

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: title,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: FeedbackScope.tap(context, onPressed),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Row(
            children: [
              Expanded(child: Text(title, style: AppTypography.bodyStrong)),
              const GameIcon(
                GameIcons.chevronRight,
                size: AppSizes.iconMd,
                color: AppColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
