import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';

import '../services/theme_service.dart';

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

// Public simple data class and notifier so other parts of the app can observe
// whether the background videos are initialized/playing. This is used by the
// top-level overlay in main.dart so the status is visible above all UI.
// debug artifacts removed

/// Procedural animated starry background.
class StarryBackground extends StatefulWidget {
  final int starCount;
  // optional video asset paths for light and dark theme (e.g. 'assets/video/bg_light.mp4')
  // If provided, the matching video will play in loop, muted, and act as the app background.
  final String? videoAssetLight;
  final String? videoAssetDark;
  // debug flag: when false, procedural star overlays/backgrounds are hidden
  // Use to verify the raw video layer is visible on device during testing.
  final bool showStars;
  const StarryBackground({
    Key? key,
    this.starCount = 420,
    this.videoAssetLight,
    this.videoAssetDark,
    this.showStars = true,
  }) : super(key: key);
  // NOTE: default starCount increased later by patch to better match dense sky

  @override
  State<StarryBackground> createState() => _StarryBackgroundState();
}

class _StarryBackgroundState extends State<StarryBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Star> _stars;
  VideoPlayerController? _videoControllerLight;
  VideoPlayerController? _videoControllerDark;
  bool _initializingLight = false;
  bool _initializingDark = false;
  ThemeService? _themeService;
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

    // Create the controller but don't start it until we know animations are enabled.
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    // advance star depths on each tick when running
    // Update animations (twinkle / nebula wobble) but do not move stars along z.
    // This removes the 'approaching' effect where stars fly toward the viewer.
    _ctrl.addListener(() {
      // Keep star properties constant (no z updates). We only repaint for
      // subtle twinkle and nebula motion driven by _ctrl.value.
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

  // We will decide whether to start animations/videos in
  // didChangeDependencies so this happens as soon as the widget is
  // inserted and a valid BuildContext is available (no extra frame delay).
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bool animationsEnabled = true;
    try {
      final ts = context.read<ThemeService>();
      animationsEnabled = ts.animationsEnabled;
      // Attach listener so we react to runtime changes immediately
      if (_themeService != ts) {
        _themeService?.removeListener(_onThemeServiceChanged);
        _themeService = ts;
        _themeService?.addListener(_onThemeServiceChanged);
      }
    } catch (_) {
      animationsEnabled = true;
    }

    // Initialize only the active theme's video to avoid allocating two
    // heavy native decoders at once which can cause OOM on some devices.
    // Guard against re-initialization on transient MediaQuery changes
    // (for example when the IME/keyboard appears) by only initializing
    // if we don't already have an initialized controller for the active
    // theme. This prevents unnecessary native decoder allocations.
    if (animationsEnabled) {
      final brightness = Theme.of(context).brightness;
      if (brightness == Brightness.light &&
          widget.videoAssetLight != null &&
          _videoControllerLight == null) {
        _initVideos(target: Brightness.light);
      } else if (brightness == Brightness.dark &&
          widget.videoAssetDark != null &&
          _videoControllerDark == null) {
        _initVideos(target: Brightness.dark);
      }
    }

    if (animationsEnabled) {
      try {
        _ctrl.repeat();
      } catch (_) {}
    } else {
      try {
        _ctrl.stop();
      } catch (_) {}
    }
  }

  void _onThemeServiceChanged() {
    // Defensive: avoid operating when widget unmounted and defer any
    // VideoPlayerController calls to a post-frame callback to prevent
    // re-entrant or context-related crashes during theme changes.
    if (!mounted) return;
    try {
      final enabled = _themeService?.animationsEnabled ?? true;
      if (enabled) {
        try {
          _ctrl.repeat();
        } catch (_) {}
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          try {
            // Ensure the currently visible theme's video is initialized when
            // animations become enabled. Avoid initializing both controllers
            // at once to reduce native memory pressure.
            final brightness = Theme.of(context).brightness;
            if (brightness == Brightness.light &&
                _videoControllerLight == null &&
                widget.videoAssetLight != null) {
              _initVideos(target: Brightness.light);
            } else if (brightness == Brightness.dark &&
                _videoControllerDark == null &&
                widget.videoAssetDark != null) {
              _initVideos(target: Brightness.dark);
            }
            _updateVideoPlayback(brightness);
          } catch (e) {
            debugPrint('Deferred video playback update failed: $e');
          }
        });
      } else {
        try {
          _ctrl.stop();
        } catch (_) {}
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // pause any playing video so it remains a static frame
          try {
            if (_videoControllerLight != null && _videoControllerLight!.value.isPlaying) {
              _videoControllerLight!.pause();
            }
            if (_videoControllerDark != null && _videoControllerDark!.value.isPlaying) {
              _videoControllerDark!.pause();
            }
          } catch (e) {
            debugPrint('Deferred video pause failed: $e');
          }
        });
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Theme change handler failed: $e');
    }
  }

  /// Initialize only the video controller matching [target]. Dispose the
  /// other controller to free native resources and reduce memory usage.
  Future<void> _initVideos({required Brightness target}) async {
    if (!mounted) return;

    if (target == Brightness.light) {
  // If already initializing or already initialized, skip to avoid
  // allocating native decoder resources again (keyboard/showing IME
  // can trigger rebuilds / didChangeDependencies).
  if (_initializingLight) return;
  if (_videoControllerLight != null && _isControllerReady(_videoControllerLight)) return;
      _initializingLight = true;
      // Dispose dark controller if present to free memory
      if (_videoControllerDark != null) {
        try {
          await _videoControllerDark!.pause();
        } catch (_) {}
        try {
          _videoControllerDark!.dispose();
        } catch (_) {}
        _videoControllerDark = null;
      }

  if (widget.videoAssetLight == null) {
        _initializingLight = false;
        return;
      }

      try {
        _videoControllerLight = VideoPlayerController.asset(widget.videoAssetLight!);
        await _videoControllerLight!.initialize();
        await _videoControllerLight!.setVolume(0.0);
        await _videoControllerLight!.setLooping(true);
        await _videoControllerLight!.seekTo(Duration.zero);
        debugPrint(
          'Light video initialized: '
          'size=${_videoControllerLight!.value.size}, '
          'duration=${_videoControllerLight!.value.duration}, '
          'isPlaying=${_videoControllerLight!.value.isPlaying}',
        );
      } catch (e, st) {
        debugPrint('Failed to initialize light video asset "${widget.videoAssetLight}": $e');
        debugPrint('$st');
        try {
          _videoControllerLight?.dispose();
        } catch (_) {}
        _videoControllerLight = null;
      } finally {
        _initializingLight = false;
      }
    } else {
      // If already initializing or already initialized, skip to avoid
      // allocating native decoder resources again (keyboard/showing IME
      // can trigger rebuilds / didChangeDependencies).
      if (_initializingDark) return;
      if (_videoControllerDark != null && _isControllerReady(_videoControllerDark)) return;
      _initializingDark = true;
      // Dispose light controller if present to free memory
      if (_videoControllerLight != null) {
        try {
          await _videoControllerLight!.pause();
        } catch (_) {}
        try {
          _videoControllerLight!.dispose();
        } catch (_) {}
        _videoControllerLight = null;
      }

      if (widget.videoAssetDark == null) {
        _initializingDark = false;
        return;
      }

      try {
        _videoControllerDark = VideoPlayerController.asset(widget.videoAssetDark!);
        await _videoControllerDark!.initialize();
        await _videoControllerDark!.setVolume(0.0);
        await _videoControllerDark!.setLooping(true);
        await _videoControllerDark!.seekTo(Duration.zero);
        debugPrint(
          'Dark video initialized: '
          'size=${_videoControllerDark!.value.size}, '
          'duration=${_videoControllerDark!.value.duration}, '
          'isPlaying=${_videoControllerDark!.value.isPlaying}',
        );
      } catch (e, st) {
        debugPrint('Failed to initialize dark video asset "${widget.videoAssetDark}": $e');
        debugPrint('$st');
        try {
          _videoControllerDark?.dispose();
        } catch (_) {}
        _videoControllerDark = null;
      } finally {
        _initializingDark = false;
      }
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _accSub?.cancel();
  _themeService?.removeListener(_onThemeServiceChanged);
    _ctrl.dispose();
    _videoControllerLight?.dispose();
    _videoControllerDark?.dispose();
  // Note: do not synchronously delete thumbnail files here; deleting while
  // the UI is rendering Image.file can create race conditions and crashes
  // on some platforms. Leaving them in temp is acceptable; the OS will
  // periodically clear tmp files.
    super.dispose();
  }

  // Ensure only the appropriate theme video is playing. Called from build().
  void _updateVideoPlayback(Brightness brightness) {
    // Defer actual play/pause to after this frame to avoid calling
    // VideoPlayerController methods during build which can cause re-entrant
    // issues on some platforms. Wrap each call in try/catch as a safety net.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (brightness == Brightness.light) {
          if (_videoControllerLight != null &&
              _videoControllerLight!.value.isInitialized) {
            if (!_videoControllerLight!.value.isPlaying) {
              try {
                debugPrint('Starting light video playback');
                _videoControllerLight!.play();
              } catch (_) {}
            }
          }
          if (_videoControllerDark != null &&
              _videoControllerDark!.value.isInitialized) {
            if (_videoControllerDark!.value.isPlaying) {
              try {
                debugPrint('Pausing dark video playback');
                _videoControllerDark!.pause();
              } catch (_) {}
            }
          }
        } else {
          if (_videoControllerDark != null &&
              _videoControllerDark!.value.isInitialized) {
            if (!_videoControllerDark!.value.isPlaying) {
              try {
                debugPrint('Starting dark video playback');
                _videoControllerDark!.play();
              } catch (_) {}
            }
          }
          if (_videoControllerLight != null &&
              _videoControllerLight!.value.isInitialized) {
            if (_videoControllerLight!.value.isPlaying) {
              try {
                debugPrint('Pausing light video playback');
                _videoControllerLight!.pause();
              } catch (_) {}
            }
          }
        }
      } catch (e) {
        debugPrint('Video playback update failed: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final brightness = Theme.of(context).brightness;
    final animationsEnabled = context.select<ThemeService, bool>((s) => s.animationsEnabled);
    // Light theme: draw the warm cream background and overlay the same
    // procedural starfield used by the dark theme, but draw stars in a
    // golden color so they remain crisp and behave identically (perspective + tilt).
    // If animations are disabled, ensure we don't attempt to update or
    // play video controllers; render a static painter instead.
    if (animationsEnabled) {
      _updateVideoPlayback(brightness);
    }

  // No large debug overlay will be shown in production.

    if (brightness == Brightness.light) {
      final hasVideo = _isControllerReady(_videoControllerLight);
      // If animations are disabled, prefer the static painter or the
      // available video playback when animations are enabled.
      if (!animationsEnabled) {
        // animations disabled: show a static frame from the video when available,
        // otherwise use the static painter.
        if (hasVideo) {
          // show paused video frame (video is initialized and seeked to 0)
          try {
            return RepaintBoundary(child: _buildVideo(controller: _videoControllerLight!));
          } catch (e) {
            debugPrint('Safe build video failed (light): $e');
            // fall through to thumbnail/painter fallback
          }
        }

        // Prefer a user-supplied static asset frame while video isn't initialized
        try {
          return RepaintBoundary(
            child: SizedBox.expand(
              child: Image.asset(
                'assets/images/bg_light_frame.png',
                fit: BoxFit.cover,
              ),
            ),
          );
        } catch (e) {
          debugPrint('Asset fallback display failed (light): $e');
        }

        return RepaintBoundary(
          child: CustomPaint(
            size: size,
            painter: _LightStarPainter(t: 0.0),
          ),
        );
      }

      return RepaintBoundary(
        child: Stack(
          children: [
            // bottom-most: video background when available
            if (hasVideo)
              Positioned.fill(
                child: _buildVideo(controller: _videoControllerLight!),
              ),
            // if video not ready, prefer user-supplied static asset frame as bottom-most
            if (!hasVideo)
              Positioned.fill(
                child: (() {
                  try {
                    return Image.asset('assets/images/bg_light_frame.png', fit: BoxFit.cover);
                  } catch (e) {
                    debugPrint('Asset positioned failed (light): $e');
                  }
                  return const SizedBox.shrink();
                })(),
              ),

            // no debug overlay

            // background layer (cream + soft nebula) only when not using video
            if (widget.showStars && !hasVideo)
              CustomPaint(
                size: size,
                painter: _LightStarPainter(t: _ctrl.value),
              ),

            // animated starfield overlay in warm yellow when not using video
            if (widget.showStars && !hasVideo)
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
                        starColor: const Color(0xFFFFD36B),
                        showBackground: true,
                      ),
                    );
                  },
                ),
              ),

            // debug artifacts removed
          ],
        ),
      );
    }

  // Dark theme branch
  final hasDarkVideo = _isControllerReady(_videoControllerDark);

    if (!animationsEnabled) {
      // Animations disabled: prefer showing a static frame from the dark video
      if (hasDarkVideo) {
        try {
          return RepaintBoundary(child: _buildVideo(controller: _videoControllerDark!));
        } catch (e) {
          debugPrint('Safe build video failed (dark): $e');
        }
      }

      // Prefer a user-supplied static asset frame while video isn't initialized
      try {
        return RepaintBoundary(
          child: SizedBox.expand(
            child: Image.asset(
              'assets/images/bg_dark_frame.png',
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (e) {
        debugPrint('Asset fallback display failed (dark): $e');
      }

      return RepaintBoundary(
        child: CustomPaint(
          size: size,
          painter: _StarFieldPainter(
            stars: _stars,
            t: 0.0,
            tilt: Offset.zero,
            starColor: Colors.white,
            showBackground: true,
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: Stack(
        children: [
          if (hasDarkVideo)
            Positioned.fill(
              child: _buildVideo(controller: _videoControllerDark!),
            ),
          // when video not ready, prefer user-supplied asset frame if available
          if (!hasDarkVideo)
            Positioned.fill(
              child: (() {
                try {
                  return Image.asset('assets/images/bg_dark_frame.png', fit: BoxFit.cover);
                } catch (e) {
                  debugPrint('Asset positioned failed (dark): $e');
                }
                return const SizedBox.shrink();
              })(),
            ),

          // no debug overlay

          // debug artifacts removed

          if (widget.showStars && !hasDarkVideo)
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                return CustomPaint(
                  size: size,
                  painter: _StarFieldPainter(
                    stars: _stars,
                    t: _ctrl.value,
                    tilt: _tilt,
                    starColor: Colors.white,
                    showBackground: true,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildVideo({required VideoPlayerController controller}) {
    final vc = controller;
    try {
      if (!_isControllerReady(vc)) return const SizedBox.shrink();
      // Fills the area while preserving aspect ratio and cropping as needed
      final w = vc.value.size.width;
      final h = vc.value.size.height;
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(
            width: w,
            height: h,
            child: VideoPlayer(vc),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Safe _buildVideo failed: $e');
      return const SizedBox.shrink();
    }
  }

  // Safe check whether a VideoPlayerController is non-null and initialized.
  bool _isControllerReady(VideoPlayerController? c) {
    try {
      return c != null && c.value.isInitialized;
    } catch (_) {
      return false;
    }
  }

  // Generate a thumbnail PNG for an asset video and return the temporary file path.
  // Returns null on failure. This uses `video_thumbnail` to extract an image and
  // stores it in the app's temporary directory.
  // Thumbnail generation removed. We prefer static asset frames provided
  // by the project under assets/images/bg_light_frame.png and
  // assets/images/bg_dark_frame.png. Keeping the code path simple avoids
  // runtime native plugin usage and reduces race conditions.
}

// Large debug overlay widget that shows when a video is active.
// large overlay removed

class _StarFieldPainter extends CustomPainter {
  final List<Star> stars;
  final double t; // animation value 0..1
  final Offset tilt;
  final Color starColor;
  // when false, do not draw the full gradient/nebula background and only draw stars
  final bool showBackground;
  _StarFieldPainter({
    required this.stars,
    required this.t,
    required this.tilt,
    this.starColor = Colors.white,
    this.showBackground = true,
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
    if (showBackground) {
      _drawGradient(canvas, size);
      _drawNebulas(canvas, size);
    }
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

// Simple visible badge used for debugging to confirm a video controller is active
// removed debug badge

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

// Debug overlay widget that shows whether light/dark video controllers
// are initialized and playing. Only used in debug builds.
// removed debug overlay
