import 'package:flutter/material.dart';
import 'dart:math';

class Star {
  final Offset pos;
  final double radius;
  final double phase;
  const Star(this.pos, this.radius, this.phase);
}

/// A lightweight animated starfield that sits behind the app UI.
class StarryBackground extends StatefulWidget {
  final int starCount;
  const StarryBackground({Key? key, this.starCount = 120}) : super(key: key);

  @override
  _StarryBackgroundState createState() => _StarryBackgroundState();
}

class _StarryBackgroundState extends State<StarryBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<Star> _stars = [];
  final Random _rnd = Random();
  Brightness? _lastBrightness;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateStars(Size size, int count, {bool clear = false}) {
    if (clear) _stars.clear();
    if (_stars.isNotEmpty) return;
    for (int i = 0; i < count; i++) {
      final x = _rnd.nextDouble() * size.width;
      final y = _rnd.nextDouble() * size.height;
      final r = _rnd.nextDouble() * 1.6 + (_rnd.nextBool() ? 0.2 : 0.0);
      final phase = _rnd.nextDouble();
      _stars.add(Star(Offset(x, y), r, phase));
    }
    // A few brighter/larger stars
    for (int i = 0; i < max(6, (count / 20).round()); i++) {
      final x = _rnd.nextDouble() * size.width;
      final y = _rnd.nextDouble() * size.height * 0.7;
      final r = _rnd.nextDouble() * 2.4 + 1.6;
      final phase = _rnd.nextDouble();
      _stars.add(Star(Offset(x, y), r, phase));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        // size available; star generation happens below with effective count

        // choose effective star count and regenerate if brightness changed
        final isDark = theme.brightness == Brightness.dark;
        final effectiveCount = widget.starCount; // same quantity in both themes
        if (_lastBrightness != theme.brightness) {
          _stars.clear();
          _lastBrightness = theme.brightness;
        }
        _generateStars(size, effectiveCount);

        return CustomPaint(
          size: size,
          painter: _StarFieldPainter(
            animation: _controller,
            stars: List.unmodifiable(_stars),
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Star> stars;
  final bool isDark;
  final Paint _paint = Paint()..style = PaintingStyle.fill;

  // Helper: create a star-shaped Path (n-pointed) centered at `c`.
  Path _starPath(
    Offset c,
    double outerRadius,
    int points,
    double innerRatio,
    double rotation,
  ) {
    final path = Path();
    final step = pi / points;
    for (int i = 0; i < points * 2; i++) {
      final isOuter = i.isEven;
      final r = isOuter ? outerRadius : outerRadius * innerRatio;
      final a = rotation + i * step;
      final x = c.dx + r * cos(a);
      final y = c.dy + r * sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  _StarFieldPainter({
    required this.animation,
    required this.stars,
    required this.isDark,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw stars with subtle twinkling and a soft glow. Parameters vary by theme.
    for (final s in stars) {
      final twinkle = 0.45 + 0.55 * sin(2 * pi * (animation.value + s.phase));
      final mainAlpha = (twinkle).clamp(0.05, 1.0);

      if (isDark) {
        // bright white stars with a slightly stronger halo and core to
        // improve visibility on dark backgrounds
        final halo = (s.radius * 3.2).clamp(1.8, 10.0);
        _paint.color = Colors.white.withOpacity(
          (mainAlpha * 0.28).clamp(0.04, 0.45),
        );
        canvas.drawCircle(s.pos, halo, _paint);

        // tiny bright core circle to act as a sparkle
        _paint.color = Colors.white.withOpacity(
          (mainAlpha * 0.9).clamp(0.35, 1.0),
        );
        canvas.drawCircle(s.pos, (s.radius * 0.5).clamp(0.6, 1.6), _paint);

        // Draw a small 5-point star for the core (slightly larger)
        final starOuter = max(0.8, s.radius * 1.1);
        final starPath = _starPath(
          s.pos,
          starOuter,
          5,
          0.48,
          animation.value * 2 * pi + s.phase * 3.14,
        );
        _paint.color = Colors.white.withOpacity((mainAlpha).clamp(0.45, 1.0));
        canvas.drawPath(starPath, _paint);
      } else {
        // warm yellow/amber stars for light theme with stronger halo and
        // a small bright core so they contrast on pale backgrounds.
        final baseAlpha = (mainAlpha * 1.25).clamp(0.06, 0.9);
        final haloAlpha = (mainAlpha * 0.6).clamp(0.03, 0.4);
        final halo = (s.radius * 2.4).clamp(1.2, 8.0);

        // soft warm halo
        _paint.color = Colors.amber.shade200.withOpacity(haloAlpha);
        canvas.drawCircle(s.pos, halo, _paint);

        // small bright white star core to increase contrast on very pale backgrounds
        final whiteStar = _starPath(
          s.pos,
          max(0.5, s.radius * 0.7),
          5,
          0.45,
          animation.value * 2 * pi + s.phase * 3.14,
        );
        _paint.color = Colors.white.withOpacity(
          (mainAlpha * 0.45).clamp(0.06, 0.95),
        );
        canvas.drawPath(whiteStar, _paint);

        // outer amber star
        final amberStar = _starPath(
          s.pos,
          max(0.7, s.radius * 0.95),
          5,
          0.5,
          -animation.value * 2 * pi + s.phase * 2.71,
        );
        _paint.color = Colors.amber.shade400.withOpacity(baseAlpha);
        canvas.drawPath(amberStar, _paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter old) {
    return old.stars != stars || old.isDark != isDark;
  }
}
