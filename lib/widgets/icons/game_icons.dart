import 'package:flutter/widgets.dart';

import '../../theme/theme.dart';
import 'svg_path.dart';

/// Cara menggambar satu bentuk di dalam ikon.
enum IconPaintMode { fill, stroke }

/// Peran warna: [primary] = warna ikon, [secondary] = warna kedua
/// (mis. isi bintang vs garisnya, isi tangan vs outline-nya).
enum IconColorRole { primary, secondary }

/// Satu bentuk di dalam ikon 24×24 (atau viewBox lain).
@immutable
class IconShape {
  const IconShape.path(
    String this.d, {
    this.mode = IconPaintMode.stroke,
    this.role = IconColorRole.primary,
  }) : rect = null,
       center = null,
       radius = 0;

  const IconShape.rect(
    Rect this.rect, {
    this.radius = 0,
    this.mode = IconPaintMode.fill,
    this.role = IconColorRole.primary,
  }) : d = null,
       center = null;

  const IconShape.circle(
    Offset this.center,
    this.radius, {
    this.mode = IconPaintMode.stroke,
    this.role = IconColorRole.primary,
  }) : d = null,
       rect = null;

  final String? d;
  final Rect? rect;
  final Offset? center;

  /// Radius sudut (rect) atau jari-jari (circle).
  final double radius;
  final IconPaintMode mode;
  final IconColorRole role;
}

/// Definisi ikon: kumpulan bentuk dalam viewBox persegi.
@immutable
class GameIconData {
  const GameIconData(this.shapes, {this.strokeWidth = 2.4, this.viewBox = 24});

  final List<IconShape> shapes;
  final double strokeWidth;
  final double viewBox;
}

/// Semua ikon yang dipakai di desain, disalin dari path SVG aslinya.
abstract final class GameIcons {
  static const star = GameIconData([
    IconShape.path(
      'M12 2.5l2.9 6 6.6.9-4.8 4.6 1.2 6.5L12 17.4 6.1 20.5l1.2-6.5L2.5 9.4l6.6-.9z',
      mode: IconPaintMode.fill,
    ),
    IconShape.path(
      'M12 2.5l2.9 6 6.6.9-4.8 4.6 1.2 6.5L12 17.4 6.1 20.5l1.2-6.5L2.5 9.4l6.6-.9z',
      role: IconColorRole.secondary,
    ),
  ], strokeWidth: 1.2);

  static const starOutline = GameIconData([
    IconShape.path(
      'M12 2.5l2.9 6 6.6.9-4.8 4.6 1.2 6.5L12 17.4 6.1 20.5l1.2-6.5L2.5 9.4l6.6-.9z',
    ),
  ], strokeWidth: 1.8);

  static const play = GameIconData([
    IconShape.path(
      'M7 4.5v15a1 1 0 0 0 1.5.86l12-7.5a1 1 0 0 0 0-1.72l-12-7.5A1 1 0 0 0 7 4.5z',
      mode: IconPaintMode.fill,
    ),
  ]);

  static const pause = GameIconData([
    IconShape.rect(Rect.fromLTWH(5, 4, 5, 16), radius: 1.5),
    IconShape.rect(Rect.fromLTWH(14, 4, 5, 16), radius: 1.5),
  ]);

  static const fastForward = GameIconData([
    IconShape.path(
      'M3 6.2v11.6a.8.8 0 0 0 1.2.7L12 13v4.8a.8.8 0 0 0 1.2.7l8.6-5.8a.8.8 0 0 0 0-1.4L13.2 5.5a.8.8 0 0 0-1.2.7V11L4.2 5.5A.8.8 0 0 0 3 6.2z',
      mode: IconPaintMode.fill,
    ),
  ]);

  static const settings = GameIconData([
    IconShape.path('M20 7h-9'),
    IconShape.path('M14 17H5'),
    IconShape.circle(Offset(17, 17), 3),
    IconShape.circle(Offset(7, 7), 3),
  ], strokeWidth: 2.2);

  /// Pengaturan (tidak ada di desain): pengeras suara.
  static const sound = GameIconData([
    IconShape.path('M11 5L6.5 9H3.5v6h3l4.5 4z'),
    IconShape.path('M15.5 9a4.5 4.5 0 0 1 0 6M18.5 6a8.5 8.5 0 0 1 0 12'),
  ], strokeWidth: 2.2);

  /// Pengaturan (tidak ada di desain): not balok.
  static const music = GameIconData([
    IconShape.path('M9 17.5V5.5l10-2v12'),
    IconShape.circle(Offset(6.5, 17.5), 2.5),
    IconShape.circle(Offset(16.5, 15.5), 2.5),
  ], strokeWidth: 2.2);

  /// Pengaturan (tidak ada di desain): ponsel bergetar.
  static const vibrate = GameIconData([
    IconShape.rect(
      Rect.fromLTWH(8, 3.5, 8, 17),
      radius: 2,
      mode: IconPaintMode.stroke,
    ),
    IconShape.path('M4.5 8.5v7M19.5 8.5v7'),
  ], strokeWidth: 2.2);

  static const back = GameIconData([IconShape.path('M15 18l-6-6 6-6')]);

  static const chevronRight = GameIconData([
    IconShape.path('M9 6l6 6-6 6'),
  ], strokeWidth: 2.8);

  static const lock = GameIconData([
    IconShape.rect(
      Rect.fromLTWH(5, 11, 14, 10),
      radius: 2.5,
      mode: IconPaintMode.stroke,
    ),
    IconShape.path('M8 11V7.5a4 4 0 0 1 8 0V11'),
  ]);

  static const bolt = GameIconData([
    IconShape.path('M13 2L4 14h7l-1 8 9-12h-7z', mode: IconPaintMode.fill),
  ]);

  static const queue = GameIconData([
    IconShape.path('M4 6h10M4 12h16M4 18h7'),
    IconShape.circle(Offset(17, 6), 2.2),
    IconShape.circle(Offset(14, 18), 2.2),
  ]);

  static const eraser = GameIconData([
    IconShape.path('M7 21h10'),
    IconShape.path(
      'M5.5 14.5l7-7a2 2 0 0 1 2.8 0l2.2 2.2a2 2 0 0 1 0 2.8L13 17H8z',
    ),
  ]);

  static const retry = GameIconData([
    IconShape.path('M3 12a9 9 0 1 0 3-6.7L3 8'),
    IconShape.path('M3 3v5h5'),
  ], strokeWidth: 2.6);

  static const check = GameIconData([
    IconShape.path('M5 12.5l4.5 4.5L19 7.5'),
  ], strokeWidth: 3);

  static const close = GameIconData([
    IconShape.path('M7 7l10 10M17 7L7 17'),
  ], strokeWidth: 3.2);

  static const bulb = GameIconData([
    IconShape.path('M9 18h6M10 21h4'),
    IconShape.path(
      'M12 3a6 6 0 0 0-3.5 10.9c.6.4 1 1.1 1 1.8V16h5v-.3c0-.7.4-1.4 1-1.8A6 6 0 0 0 12 3z',
    ),
  ]);

  static const warning = GameIconData([
    IconShape.path('M12 3l9.5 17h-19z'),
    IconShape.path('M12 10v4.5M12 17.5v.2'),
  ]);

  /// Tangan penunjuk tutorial: isi = secondary (putih), garis = primary.
  static const hand = GameIconData([
    IconShape.path(
      'M10 9.5V4a2 2 0 0 0-4 0v10l-1.6-1.6a2 2 0 0 0-2.8 2.8l3.6 3.6C6.7 20.3 8.4 22 11.2 22H14a8 8 0 0 0 8-8v-3a2 2 0 0 0-4 0v0-1a2 2 0 0 0-4 0v0-1a2 2 0 0 0-4 0z',
      mode: IconPaintMode.fill,
      role: IconColorRole.secondary,
    ),
    IconShape.path(
      'M10 9.5V4a2 2 0 0 0-4 0v10l-1.6-1.6a2 2 0 0 0-2.8 2.8l3.6 3.6C6.7 20.3 8.4 22 11.2 22H14a8 8 0 0 0 8-8v-3a2 2 0 0 0-4 0v0-1a2 2 0 0 0-4 0v0-1a2 2 0 0 0-4 0z',
    ),
    IconShape.path('M10 9.5V13 M14 9v4 M18 11v2'),
  ], strokeWidth: 1.6);
}

/// Menggambar [GameIconData] pada ukuran [size].
class GameIcon extends StatelessWidget {
  const GameIcon(
    this.icon, {
    super.key,
    this.size = AppSizes.iconMd,
    this.color = AppColors.ink,
    this.secondaryColor,
    this.strokeWidth,
    this.semanticLabel,
  });

  final GameIconData icon;
  final double size;
  final Color color;
  final Color? secondaryColor;
  final double? strokeWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(
      size: Size.square(size),
      painter: GameIconPainter(
        icon,
        color: color,
        secondaryColor: secondaryColor ?? color,
        strokeWidth: strokeWidth,
      ),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: paint);
    return Semantics(label: semanticLabel, image: true, child: paint);
  }
}

class GameIconPainter extends CustomPainter {
  GameIconPainter(
    this.icon, {
    required this.color,
    required this.secondaryColor,
    this.strokeWidth,
  });

  final GameIconData icon;
  final Color color;
  final Color secondaryColor;
  final double? strokeWidth;

  static final Map<String, Path> _cache = {};

  static Path _pathFor(String d) =>
      _cache.putIfAbsent(d, () => parseSvgPath(d));

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / icon.viewBox;
    canvas.save();
    canvas.scale(scale);
    for (final shape in icon.shapes) {
      final paint = Paint()
        ..isAntiAlias = true
        ..color = shape.role == IconColorRole.primary ? color : secondaryColor;
      if (shape.mode == IconPaintMode.stroke) {
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth ?? icon.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
      }
      if (shape.d != null) {
        canvas.drawPath(_pathFor(shape.d!), paint);
      } else if (shape.rect != null) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(shape.rect!, Radius.circular(shape.radius)),
          paint,
        );
      } else if (shape.center != null) {
        canvas.drawCircle(shape.center!, shape.radius, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(GameIconPainter old) =>
      old.icon != icon ||
      old.color != color ||
      old.secondaryColor != secondaryColor ||
      old.strokeWidth != strokeWidth;
}
