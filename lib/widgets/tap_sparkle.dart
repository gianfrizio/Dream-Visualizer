import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Spawn a small sparkle animation at the given global screen [position].
/// This inserts an OverlayEntry which removes itself when the animation
/// completes.
void showTapSparkle(BuildContext context, Offset position) {
  // Overlay.of(context) is available inside the app's widget tree.
  final overlay = Overlay.of(context);

  OverlayEntry? entry;
  entry = OverlayEntry(
    builder: (ctx) => _TapSparkle(
      globalPosition: position,
      onComplete: () {
        try {
          entry?.remove();
        } catch (_) {}
      },
    ),
  );

  overlay.insert(entry);
}

class _TapSparkle extends StatefulWidget {
  final Offset globalPosition;
  final VoidCallback onComplete;

  const _TapSparkle({
    Key? key,
    required this.globalPosition,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<_TapSparkle> createState() => _TapSparkleState();
}

class _TapSparkleState extends State<_TapSparkle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctr;
  late final Animation<double> _anim;
  final Random _rnd = Random();
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _ctr =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 600),
          )
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed) {
              widget.onComplete();
            }
          })
          ..forward();

    _anim = CurvedAnimation(parent: _ctr, curve: Curves.easeOutCubic);

    // Create a few particles with random directions
    _particles = List.generate(6, (i) {
      final angle = (_rnd.nextDouble() * pi * 2);
      final speed = 28 + _rnd.nextDouble() * 22;
      final color = Color.lerp(
        Colors.white,
        Colors.yellow.shade700,
        _rnd.nextDouble(),
      )!;
      return _Particle(
        angle: angle,
        speed: speed,
        color: color,
        size: 6 + _rnd.nextDouble() * 6,
      );
    });

    // Auto remove a bit after animation ends to be safe
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _ctr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Overlay coordinates are global; convert to top-left within the overlay by
    // subtracting the top-left origin of the overlay (which is 0,0 for app window)
    final left = widget.globalPosition.dx;
    final top = widget.globalPosition.dy;

    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            return CustomPaint(
              painter: _SparklePainter(
                progress: _anim.value,
                particles: _particles,
                origin: Offset(left, top),
                devicePixelRatio: mq.devicePixelRatio,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  _Particle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
  });
}

class _SparklePainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;
  final Offset origin;
  final double devicePixelRatio;

  _SparklePainter({
    required this.progress,
    required this.particles,
    required this.origin,
    required this.devicePixelRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final dx = cos(p.angle) * p.speed * progress;
      final dy = sin(p.angle) * p.speed * progress;
      final pos = origin + Offset(dx, dy);

      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = p.color.withOpacity(opacity);

      // outer glow
      final glowPaint = Paint()..color = p.color.withOpacity(opacity * 0.35);
      canvas.drawCircle(pos, p.size * (0.9 + 0.6 * (1 - progress)), glowPaint);

      // center dot
      canvas.drawCircle(pos, p.size * (0.5 * (1 - progress) + 0.3), paint);
    }

    // small central pop
    final centerOpacity = (1.0 - progress * 0.8).clamp(0.0, 1.0);
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(centerOpacity);
    canvas.drawCircle(origin, 2.5 * (1.0 - progress) + 0.3, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
