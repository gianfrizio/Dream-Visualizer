import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class Star {
  // normalized x,y positions and depth z (0..1 where 0 is near, 1 is far)
  double x;
  double y;
  double z;
  // each star has a personal focal origin (fx,fy) so stars don't all
  // appear to radiate from the exact screen center
  double fx;
  double fy;
  double radius;
  double phase;
  // parallax factor (how much this star responds to tilt)
  double parallax;

  Star(
    this.x,
    this.y,
    this.z,
    this.fx,
    this.fy,
    this.radius,
    this.phase,
    this.parallax,
  );
}

/// Procedural animated starry background.
class StarryBackground extends StatefulWidget {
  final int starCount;
  const StarryBackground({Key? key, this.starCount = 420}) : super(key: key);
  // NOTE: default starCount increased later by patch to better match dense sky

  @override
  State<StarryBackground> createState() => _StarryBackgroundState();
}

class _StarryBackgroundState extends State<StarryBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Star> _stars;
  final Random _rnd = Random(1337);
  // accelerometer-derived tilt offset
  Offset _tilt = Offset.zero;
  StreamSubscription<AccelerometerEvent>? _accSub;

  @override
  void initState() {
    super.initState();
    _stars = List.generate(widget.starCount, (i) {
      // distribute depth non-linearly to have more stars at distance
      final z = (pow(_rnd.nextDouble(), 1.6) as double);
      final par = _rnd.nextDouble() < 0.3
          ? (_rnd.nextDouble() * 0.9 + 0.1)
          : 0.0; // ~30% of stars respond to tilt
      // give each star a tiny random focal origin so motion vectors are not all centered
      final fx =
          0.45 + (_rnd.nextDouble() - 0.5) * 0.2; // near center but jittered
      final fy = 0.45 + (_rnd.nextDouble() - 0.5) * 0.2;
      final r = (pow(_rnd.nextDouble(), 2) as double) * 2.6 + 0.35;
      return Star(
        _rnd.nextDouble(),
        _rnd.nextDouble(),
        z,
        fx,
        fy,
        r,
        _rnd.nextDouble() * 2 * pi,
        par,
      );
    });

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    // advance star depths on each tick so they don't all appear to come from the exact center
    _ctrl.addListener(() {
      for (final s in _stars) {
        // move stars forward; speed scaled with size so larger stars approach faster
        // reduced multiplier to slow down perceived approach speed
        final speed = 0.00125 * (1.0 + (s.radius / 1.6));
        s.z -= speed * (1.0 + (_ctrl.value - 0.5).abs());
        if (s.z <= 0.02) {
          // recycle star to far depth with new random x,y and slight focal jitter
          s.z = 1.0 + _rnd.nextDouble() * 0.6;
          s.x = _rnd.nextDouble();
          s.y = _rnd.nextDouble();
          s.fx = 0.45 + (_rnd.nextDouble() - 0.5) * 0.22;
          s.fy = 0.45 + (_rnd.nextDouble() - 0.5) * 0.22;
          s.radius = (pow(_rnd.nextDouble(), 2) as double) * 2.8 + 0.3;
          s.phase = _rnd.nextDouble() * 2 * pi;
          s.parallax = _rnd.nextDouble() < 0.3
              ? (_rnd.nextDouble() * 0.9 + 0.1)
              : 0.0;
        }
      }
      if (mounted) setState(() {});
    });

    // subscribe to accelerometer events to compute a gentle parallax offset
    try {
      _accSub = accelerometerEventStream().listen((ev) {
        // map device acceleration to small offset, smooth with simple lerp
        final ax = ev.x / 9.8; // normalize roughly to g
        final ay = ev.y / 9.8;
        // invert x so tilting right moves stars left (parallax)
        final target = Offset(-ax * 12.0, ay * 12.0);
        _tilt = Offset.lerp(_tilt, target, 0.12) ?? target;
        // request repaint
        if (mounted) setState(() {});
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _accSub?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final brightness = Theme.of(context).brightness;
    // Light theme: draw the warm cream background and overlay the same
    // procedural starfield used by the dark theme, but draw stars in a
    // golden color so they remain crisp and behave identically (perspective + tilt).
    if (brightness == Brightness.light) {
      return RepaintBoundary(
        child: Stack(
          children: [
            // background layer (cream + soft nebula)
            CustomPaint(
              size: size,
              painter: _LightStarPainter(t: _ctrl.value),
            ),
            // animated starfield overlay in warm yellow
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  return CustomPaint(
                    size: size,
                    painter: _StarFieldPainter(
                      stars: _stars,
                      t: _ctrl.value,
                      tilt: _tilt,
                      starColor: const Color(0xFFFFD36B), // warm golden
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    // Dark theme: show animated starfield (white stars)
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return CustomPaint(
            size: size,
            painter: _StarFieldPainter(
              stars: _stars,
              t: _ctrl.value,
              tilt: _tilt,
              starColor: Colors.white,
            ),
          );
        },
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  final List<Star> stars;
  final double t; // animation value 0..1
  final Offset tilt;
  final Color starColor;
  _StarFieldPainter({
    required this.stars,
    required this.t,
    required this.tilt,
    this.starColor = Colors.white,
  }) : super();

  // Nebula definitions: offset (normalized), radius (fraction), color, phase, baseOpacity
  final List<_Nebula> _nebulas = const [
    // Increased baseOpacity to make nebula volumes more visible while remaining soft
    _Nebula(Offset(0.18, 0.18), 0.32, Color(0xFF24366F), 0.0, 0.28),
    _Nebula(Offset(0.76, 0.22), 0.26, Color(0xFF6A3D98), 1.1, 0.22),
    _Nebula(Offset(0.6, 0.78), 0.44, Color(0xFF0F2238), 2.3, 0.24),
    _Nebula(Offset(0.35, 0.6), 0.22, Color(0xFF2A5B8A), 4.1, 0.12),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    _drawGradient(canvas, size);
    _drawNebulas(canvas, size);
    _drawStars(canvas, size);
  }

  void _drawGradient(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width * 0.6, size.height),
        [Color(0xFF030617), Color(0xFF07183A), Color(0xFF0B2A52)],
        [0.0, 0.55, 1.0],
      );
    canvas.drawRect(rect, paint);

    // soft vignette
    final vignette = Paint()
      ..shader = ui.Gradient.radial(
        size.center(Offset.zero),
        max(size.width, size.height) * 0.9,
        [Colors.transparent, Colors.black.withOpacity(0.36)],
      )
      ..blendMode = BlendMode.darken;
    canvas.drawRect(rect, vignette);
  }

  void _drawNebulas(Canvas canvas, Size size) {
    // Layer several soft radial gradients with slight animated offsets and speckle
    for (int i = 0; i < _nebulas.length; i++) {
      final n = _nebulas[i];
      // animated offset to give nebula a slow drifting motion
      final wobble = Offset(
        sin((t + n.phase) * 2 * pi) * 12.0,
        cos((t + n.phase) * 2 * pi) * 8.0,
      );
      final center =
          Offset(n.offset.dx * size.width, n.offset.dy * size.height) + wobble;
      final r = n.radius * max(size.width, size.height);

      // primary soft volume (use screen blend to make colors build up softly)
      final grad = RadialGradient(
        colors: [
          n.color.withOpacity(0.0),
          n.color.withOpacity(n.baseOpacity * 1.1),
          n.color.withOpacity(n.baseOpacity * 0.6),
        ],
        stops: const [0.0, 0.18, 1.0],
      );
      final p = Paint()
        ..shader = grad.createShader(Rect.fromCircle(center: center, radius: r))
        ..blendMode = BlendMode.screen;
      canvas.drawCircle(center, r, p);

      // an outer faint rim with different hue for color richness
      final rim = RadialGradient(
        colors: [
          n.color.withOpacity(0.0),
          n.color.withOpacity(n.baseOpacity * 0.36),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      );
      final rimPaint = Paint()
        ..shader = rim.createShader(
          Rect.fromCircle(center: center, radius: r * 1.25),
        )
        ..blendMode = BlendMode.screen;
      canvas.drawCircle(center, r * 1.25, rimPaint);

      // procedural subtle speckle cloud near center to add texture (deterministic per nebula)
      final rng = Random(4219 + i * 97);
      final speckPaint = Paint()..style = PaintingStyle.fill;
      // increase speckle density and size slightly for richer nebula texture
      final speckCount = (32 + (r / 20)).clamp(20, 140).toInt();
      for (int s = 0; s < speckCount; s++) {
        final angle = rng.nextDouble() * 2 * pi;
        final rad = pow(rng.nextDouble(), 0.72) * (r * 0.7);
        final pos =
            center +
            Offset(cos(angle) * rad, sin(angle) * rad) +
            Offset(sin(t * 2 * pi + s) * 1.6, cos(t * 2 * pi + s) * 1.2);
        final alpha = (rng.nextDouble() * 0.7 + 0.08) * n.baseOpacity * 0.95;
        speckPaint.color = n.color.withOpacity(alpha.clamp(0.02, 0.36));
        canvas.drawCircle(pos, rng.nextDouble() * 3.2, speckPaint);
      }
    }

    // Add a broad, soft 'Milky Way' band across the middle for a denser central cloud
    final bandCenter = Offset(
      size.width * 0.5 + sin(t * 2 * pi) * 18.0,
      size.height * 0.48 + cos(t * 2 * pi * 0.6) * 12.0,
    );
    final bandRadius = max(size.width, size.height) * 0.6;
    final bandGrad = ui.Gradient.radial(
      bandCenter,
      bandRadius,
      [
        Colors.white.withOpacity(0.0),
        Color(0xFF86A8E6).withOpacity(0.06),
        Color(0xFF5B3F7A).withOpacity(0.04),
        Colors.transparent,
      ],
      [0.0, 0.18, 0.45, 1.0],
    );
    final bandPaint = Paint()
      ..shader = bandGrad
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(bandCenter, bandRadius, bandPaint);
  }

  void _drawStars(Canvas canvas, Size size) {
    // paint objects are created per-shape below
    // Implement simple 3D projection: stars move toward the camera by animating their z
    for (final s in stars) {
      // perspective projection using star-specific focal origin so motion vectors
      // radiate from each star's own focal point (fx,fy) rather than from global center
      final originX = s.fx;
      final originY = s.fy;
      final px = (s.x - originX) / s.z + originX;
      final py = (s.y - originY) / s.z + originY;

      // apply tilt parallax for responsive stars
      final parOffset = Offset(tilt.dx * s.parallax, tilt.dy * s.parallax);

      final dx = (px * size.width) + parOffset.dx;
      final dy = (py * size.height) + parOffset.dy;

      final tw = (sin(t * 2 * pi + s.phase) + 1) / 2; // 0..1
      final bright = 0.6 + tw * 0.9;

      // draw star using halo + center-dot shape (matches light theme style)
      final drawR = (s.radius / s.z).clamp(0.35, 18.0);
      final color = starColor;
      _drawStarShape(canvas, Offset(dx, dy), drawR, color, bright);
    }

    // subtle speckles - increase density for starfield
    final speck = Paint()..color = Colors.white.withOpacity(0.02 + t * 0.03);
    final rng = Random(2718);
    for (int i = 0; i < 220; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), rng.nextDouble() * 1.2, speck);
    }
  }

  // Shared star shape: soft halo + center dot + small core pop
  void _drawStarShape(
    Canvas canvas,
    Offset pos,
    double r,
    Color color,
    double bright,
  ) {
    // halo radius scales with r
    final haloRadius = (r * 6.0).clamp(4.0, 120.0);
    final haloPaint = Paint()
      ..shader = ui.Gradient.radial(pos, haloRadius, [
        color.withOpacity((0.12 * bright).clamp(0.0, 1.0)),
        Colors.transparent,
      ]);
    canvas.drawCircle(pos, haloRadius, haloPaint);

    // main center dot
    final centerPaint = Paint()
      ..color = color.withOpacity((0.65 * bright).clamp(0.0, 1.0));
    canvas.drawCircle(pos, r, centerPaint);

    // small bright core for a crisp highlight
    final corePaint = Paint()
      ..color = Colors.white.withOpacity((0.28 * bright).clamp(0.0, 1.0));
    final coreR = max(0.6, r * 0.45);
    canvas.drawCircle(pos, coreR, corePaint);

    // add a subtle cross-shaped glint for many stars (creates small spikes)
    // We draw this for medium+ sized stars to mimic the photographic glints
    if (r >= 1.2) {
      final glintAlpha = (0.14 * bright).clamp(0.0, 0.6);
      final glintPaint = Paint()
        ..color = Colors.white.withOpacity(glintAlpha)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = (r * 0.12).clamp(0.5, 2.5)
        ..style = PaintingStyle.stroke;

      // horizontal
      canvas.drawLine(
        pos.translate(-r * 2.0, 0),
        pos.translate(r * 2.0, 0),
        glintPaint,
      );
      // vertical
      canvas.drawLine(
        pos.translate(0, -r * 2.0),
        pos.translate(0, r * 2.0),
        glintPaint,
      );

      // small diagonal fainter strokes
      final diagPaint = Paint()
        ..color = Colors.white.withOpacity(glintAlpha * 0.6)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = (r * 0.08).clamp(0.3, 1.6)
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        pos.translate(-r * 1.4, -r * 1.4),
        pos.translate(r * 1.4, r * 1.4),
        diagPaint,
      );
      canvas.drawLine(
        pos.translate(-r * 1.4, r * 1.4),
        pos.translate(r * 1.4, -r * 1.4),
        diagPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.stars.length != stars.length;
  }
}

class _Nebula {
  final Offset offset;
  final double radius;
  final Color color;
  final double phase;
  final double baseOpacity;
  const _Nebula(
    this.offset,
    this.radius,
    this.color,
    this.phase,
    this.baseOpacity,
  );
}

class _LightStarPainter extends CustomPainter {
  final double t;
  _LightStarPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // warm cream gradient
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, size.height), [
        Color(0xFFFFFBF2),
        Color(0xFFF9F4E8),
      ]);
    canvas.drawRect(rect, paint);

    // soft golden nebula area slightly off-center
    final center = Offset(size.width * 0.6, size.height * 0.3);
    final r = max(size.width, size.height) * 0.35;
    final grad = RadialGradient(
      colors: [Color(0x00FFD9A6), Color(0x22FFD9A6), Color(0x06FFD9A6)],
      stops: [0.0, 0.16, 1.0],
    );
    final p = Paint()
      ..shader = grad.createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, p);

    // add additional soft pastel nebula layers for depth
    final neb1Center =
        center +
        Offset(
          -r * 0.28 + sin(t * 2 * pi) * 12,
          r * 0.14 + cos(t * 2 * pi) * 8,
        );
    final neb1R = r * 0.6;
    final grad1 = RadialGradient(
      colors: [Color(0x00FFEFD1), Color(0x18FFEFD1), Color(0x02FFEFD1)],
      stops: [0.0, 0.2, 1.0],
    );
    canvas.drawCircle(
      neb1Center,
      neb1R,
      Paint()
        ..shader = grad1.createShader(
          Rect.fromCircle(center: neb1Center, radius: neb1R),
        ),
    );

    final neb2Center =
        center +
        Offset(
          r * 0.35 + cos(t * 2 * pi * 0.7) * 10,
          -r * 0.12 + sin(t * 2 * pi * 0.7) * 6,
        );
    final neb2R = r * 0.45;
    final grad2 = RadialGradient(
      colors: [Color(0x0000D9FF), Color(0x20B3E8FF), Color(0x06B3E8FF)],
      stops: [0.0, 0.18, 1.0],
    );
    canvas.drawCircle(
      neb2Center,
      neb2R,
      Paint()
        ..shader = grad2.createShader(
          Rect.fromCircle(center: neb2Center, radius: neb2R),
        ),
    );

    // many tiny golden speckles to enrich background volume (increased density)
    final rng = Random(1999);
    final speckPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 320; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = 0.6 + rng.nextDouble() * 1.6; // slightly larger speckles
      final alpha =
          (0.35 + (sin(t * 2 * pi + i) * 0.12)) *
          (0.2 + rng.nextDouble() * 0.5);
      final c = Color.lerp(
        Colors.amber.shade100,
        Colors.blue.shade200,
        rng.nextDouble(),
      )!;
      speckPaint.color = c.withOpacity(alpha.clamp(0.03, 0.32));
      canvas.drawCircle(Offset(x, y), radius, speckPaint);
    }

    // a small set of larger but very soft golden stars (no cross-lines)
    for (int i = 0; i < 12; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final col = Colors.amber.shade300.withOpacity(
        0.18 + rng.nextDouble() * 0.22,
      );
      final r = 1.2 + rng.nextDouble() * 2.0;
      final halo = Paint()
        ..shader = ui.Gradient.radial(Offset(x, y), r * 3, [
          col.withOpacity(0.14),
          Colors.transparent,
        ]);
      canvas.drawCircle(Offset(x, y), r * 3, halo);
      canvas.drawCircle(Offset(x, y), r, Paint()..color = col);
    }
  }

  // removed: _drawTinyStar helper was unused after visual adjustments

  @override
  bool shouldRepaint(covariant _LightStarPainter oldDelegate) =>
      oldDelegate.t != t;
}
