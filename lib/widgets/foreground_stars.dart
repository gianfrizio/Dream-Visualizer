import 'dart:math';
import 'package:flutter/material.dart';

class _FgStar {
  double x;
  double y;
  double z;
  double fx;
  double fy;
  double radius;
  double phase;
  _FgStar(this.x, this.y, this.z, this.fx, this.fy, this.radius, this.phase);
}

/// Small lightweight foreground stars painter. Draws only the bright center
/// dots of the nearest stars (no soft halos) so they can be rendered above
/// UI without visually blurring text or cards.
class ForegroundStars extends StatefulWidget {
  final int count;
  const ForegroundStars({Key? key, this.count = 96}) : super(key: key);

  @override
  State<ForegroundStars> createState() => _ForegroundStarsState();
}

class _ForegroundStarsState extends State<ForegroundStars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_FgStar> _stars;
  final Random _rnd = Random(4242);

  @override
  void initState() {
    super.initState();
    _stars = List.generate(widget.count, (i) {
      final z = _rnd.nextDouble();
      final fx = 0.45 + (_rnd.nextDouble() - 0.5) * 0.22;
      final fy = 0.45 + (_rnd.nextDouble() - 0.5) * 0.22;
      return _FgStar(
        _rnd.nextDouble(),
        _rnd.nextDouble(),
        z,
        fx,
        fy,
        0.6 + _rnd.nextDouble() * 2.4,
        _rnd.nextDouble() * 2 * pi,
      );
    });
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _ctrl.addListener(() {
      // advance z for each foreground star so they move toward viewer
      for (final s in _stars) {
        // slow down foreground approach to be less jarring
        s.z -= 0.003 * (1.0 + (s.radius / 1.2));
        if (s.z <= 0.05) {
          s.z = 1.0 + _rnd.nextDouble() * 0.6;
          s.x = _rnd.nextDouble();
          s.y = _rnd.nextDouble();
          s.fx = 0.45 + (_rnd.nextDouble() - 0.5) * 0.22;
          s.fy = 0.45 + (_rnd.nextDouble() - 0.5) * 0.22;
          s.radius = 0.6 + _rnd.nextDouble() * 2.4;
          s.phase = _rnd.nextDouble() * 2 * pi;
        }
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFFFFD36B);
    return CustomPaint(
      painter: _FgPainter(stars: _stars, t: _ctrl.value, starColor: color),
      size: Size.infinite,
    );
  }
}

class _FgPainter extends CustomPainter {
  final List<_FgStar> stars;
  final double t;
  final Color starColor;
  _FgPainter({required this.stars, required this.t, required this.starColor});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final originX = s.fx;
      final originY = s.fy;
      final px = (s.x - originX) / s.z + originX;
      final py = (s.y - originY) / s.z + originY;
      final dx = (px * size.width);
      final dy = (py * size.height);

      final drawR = (s.radius / s.z).clamp(0.5, 18.0);
      final op = (0.7 + (sin(t * 2 * pi + s.phase) * 0.18)).clamp(0.28, 1.0);
      final paint = Paint()..color = starColor.withOpacity(op);
      canvas.drawCircle(Offset(dx, dy), drawR, paint);

      // small thin glints for larger foreground stars so they read like stars
      if (drawR >= 1.6) {
        final glintPaint = Paint()
          ..color = Colors.white.withOpacity((op * 0.6).clamp(0.12, 0.8))
          ..strokeWidth = (drawR * 0.12).clamp(0.4, 1.6)
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(dx - drawR * 1.8, dy),
          Offset(dx + drawR * 1.8, dy),
          glintPaint,
        );
        canvas.drawLine(
          Offset(dx, dy - drawR * 1.8),
          Offset(dx, dy + drawR * 1.8),
          glintPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FgPainter old) =>
      old.t != t || old.stars.length != stars.length;
}
