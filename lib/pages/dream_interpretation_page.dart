import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import '../openai_service.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import '../models/saved_dream.dart';
import '../services/dream_storage_service.dart';
import '../services/image_cache_service.dart';
import '../services/notification_service.dart';
import '../services/favorites_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../widgets/global_bottom_menu.dart';

class DreamInterpretationPage extends StatefulWidget {
  final String dreamText;
  final LanguageService languageService;

  const DreamInterpretationPage({
    super.key,
    required this.dreamText,
    required this.languageService,
  });
  @override
  _DreamInterpretationPageState createState() =>
      _DreamInterpretationPageState();
}

// Overlay widget that animates a star icon from start -> end.
class _StarAnimationOverlay extends StatefulWidget {
  final Offset start;
  final Offset end;
  const _StarAnimationOverlay({required this.start, required this.end});

  @override
  State<_StarAnimationOverlay> createState() => _StarAnimationOverlayState();
}

class _StarAnimationOverlayState extends State<_StarAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  // We'll compute the position along a cubic Bezier in build to create a smooth arc.
  late final Animation<double> _anim;
  late final Animation<double> _scale;
  late Offset _c1;
  late Offset _c2;

  @override
  void initState() {
    super.initState();
    // Longer duration for a calmer, more readable motion
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();

    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.32,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo));

    // Precompute two control points for a cubic Bezier so the star flies on a soft arc
    final start = widget.start;
    final end = widget.end;
    final vec = end - start;
    final dist = vec.distance;
    // perpendicular normal (may be zero if vec is zero)
    final normal = vec == Offset.zero
        ? Offset(0, -1)
        : Offset(-vec.dy / dist, vec.dx / dist);
    // control points placed along the segment with outward offset proportional to distance
    _c1 = start + vec * 0.28 + normal * (min(160.0, dist * 0.18));
    _c2 = start + vec * 0.68 + normal * (min(80.0, dist * 0.06));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _anim.value; // 0..1 eased
        // Cubic Bezier interpolation
        Offset cubicBezier(Offset a, Offset b, Offset c, Offset d, double t) {
          final u = 1 - t;
          final p =
              a * (u * u * u) +
              b * (3 * u * u * t) +
              c * (3 * u * t * t) +
              d * (t * t * t);
          return p;
        }

        final pos = cubicBezier(widget.start, _c1, _c2, widget.end, t);
        final scale = _scale.value;

        // slight rotation while flying
        final rotation = (pi * 0.6) * Curves.easeInOut.transform(t);

        // glow behind the star to create a trail impression
        final glow = Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.amber.withOpacity(0.28 * (1 - t)),
                Colors.transparent,
              ],
            ),
          ),
        );

        // Small debug markers at start/end to make it obvious when animation runs
        final startMarker = Positioned(
          left: widget.start.dx - 6,
          top: widget.start.dy - 6,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
          ),
        );

        final endMarker = Positioned(
          left: widget.end.dx - 8,
          top: widget.end.dy - 8,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
          ),
        );

        return Stack(
          children: [
            startMarker,
            endMarker,
            Positioned(
              left: pos.dx - 24,
              top: pos.dy - 24,
              child: Transform.rotate(
                angle: rotation,
                child: Transform.scale(
                  scale: scale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      glow,
                      Icon(
                        Icons.star,
                        size: 44,
                        color: Colors.amber.withOpacity(0.98),
                        shadows: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18 * (1 - t)),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DreamInterpretationPageState extends State<DreamInterpretationPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // Services & controllers
  late final OpenAIService _openAI;
  late final AnimationController _sleepAnimationController;
  late final AnimationController _fadeController;
  late Animation<double> _sleepAnimation;
  late Animation<double> _fadeAnimation;

  // State flags
  String _imageUrl = '';
  String? _localImagePath;
  String _interpretation = '';
  bool _isGeneratingImage = false;
  bool _isComplete = false;
  bool _resumedFromPending = false;
  bool _isSaved = false;
  String? _lastSavedDreamId;
  final FavoritesService _favoritesService = FavoritesService();
  // Controls whether the inline advice is expanded (collapsible box)
  // Default to expanded so the responsive Wrap shows full text immediately.
  bool _isAdviceExpanded = true;
  @override
  void dispose() {
    _sleepAnimationController.dispose();
    _fadeController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkAndResumePending();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _openAI = OpenAIService();

    _sleepAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _sleepAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(
        parent: _sleepAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Kick off a check for any pending job once widget is mounted.
    // If there's nothing to resume, start a fresh interpretation automatically.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _checkAndResumePending();
        if (mounted && !_resumedFromPending && !_isProcessing && !_isComplete) {
          // Start interpretation for a fresh run
          await _startInterpretation();
        }
      } catch (_) {
        // ignore: do not crash the UI from post-frame operations
      }
    });
  }

  // --- Pending job persistence helpers ---
  static const String _kPendingKey = 'pending_interpretation_job';
  static const String _kLastSavedKey = 'last_saved_interpretation';
  bool _isProcessing = false;

  Future<void> _savePendingJob(Map<String, dynamic> job) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPendingKey, jsonEncode(job));
  }

  Future<void> _clearPendingJob() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPendingKey);
  }

  Future<Map<String, dynamic>?> _getPendingJob() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_kPendingKey);
    if (s == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(s));
    } catch (_) {
      return null;
    }
  }

  Future<void> _checkAndResumePending() async {
    final pending = await _getPendingJob();
    if (pending == null) return;
    if (_isProcessing) return;

    final status = pending['status'] as String? ?? '';
    final dreamText = pending['dreamText'] as String? ?? '';
    final pendingInterpretation = pending['interpretation'] as String? ?? '';
    // pendingLocalImage not used currently; keep parsing minimal
    final pendingImageUrl = pending['imageUrl'] as String? ?? '';

    // If an image URL was already produced by the server, show it immediately
    // (network image) and attempt to cache it in background so the local image
    // is available when the user returns later.
    if (pendingImageUrl.isNotEmpty &&
        dreamText.trim() == widget.dreamText.trim()) {
      if (mounted) {
        setState(() {
          _imageUrl = pendingImageUrl;
          _isGeneratingImage = false;
          _isComplete = true;
          _resumedFromPending = true;
        });
      }

      // Try to download/cache the image in background. If it succeeds, replace network
      // image with local file and clear pending job.
      try {
        final imageCacheService = ImageCacheService();
        final dreamId = DateTime.now().millisecondsSinceEpoch.toString();
        final localPath = await imageCacheService.downloadAndCacheImage(
          pendingImageUrl,
          dreamId,
        );
        if (localPath != null && localPath.isNotEmpty) {
          if (mounted) {
            setState(() {
              _localImagePath = localPath;
              _imageUrl = '';
              _isComplete = true;
              _isGeneratingImage = false;
            });
          }
          await _clearPendingJob();
          try {
            await NotificationService().showCompletedNotification(
              title: 'Immagine pronta',
              body: 'La visualizzazione del sogno è pronta.',
            );
          } catch (_) {}
        }
      } catch (_) {
        // ignore: fallback to network image only
      }

      // If the interpretation finished but the image was not generated yet,
      // resume image generation from the saved interpretation.
      if (status == 'interpretation_done' &&
          dreamText.trim() == widget.dreamText.trim()) {
        if (mounted) {
          setState(() {
            _interpretation = pendingInterpretation;
            _isGeneratingImage = true;
            _isComplete = false;
            _resumedFromPending = true;
          });
        }
        await _resumeImageGenerationFromInterpretation(pendingInterpretation);
        return;
      }
      return;
    } else {
      // If image generation was in progress and an imageUrl is available,
      // try to download the image directly (common case: server generated image but app was suspended before download).
      if (status == 'image_in_progress' &&
          pendingImageUrl.isNotEmpty &&
          dreamText.trim() == widget.dreamText.trim()) {
        try {
          setState(() {
            _isGeneratingImage = true;
            _resumedFromPending = true;
          });
          final imageCacheService = ImageCacheService();
          final dreamId = DateTime.now().millisecondsSinceEpoch.toString();
          final localPath = await imageCacheService.downloadAndCacheImage(
            pendingImageUrl,
            dreamId,
          );
          if (localPath != null && localPath.isNotEmpty) {
            setState(() {
              _localImagePath = localPath;
              _imageUrl = '';
              _isComplete = true;
              _isGeneratingImage = false;
            });
            // Clear pending and notify
            await _clearPendingJob();
            try {
              await NotificationService().showCompletedNotification(
                title: 'Immagine pronta',
                body: 'La visualizzazione del sogno è pronta.',
              );
            } catch (_) {}
            return;
          }
        } catch (e) {
          // Fall through to normal last-saved check below
        }
      }
      // No pending job: maybe the app completed the work in background and saved the image.
      // Try to read last saved metadata and render local image if it belongs to this dream.
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_kLastSavedKey);
      if (s != null) {
        try {
          final Map<String, dynamic> meta = Map<String, dynamic>.from(
            jsonDecode(s),
          );
          final savedText = (meta['dreamText'] as String?) ?? '';
          final localPath = (meta['localImagePath'] as String?) ?? '';
          if (savedText.trim() == widget.dreamText.trim() &&
              localPath.isNotEmpty) {
            final f = File(localPath);
            if (await f.exists()) {
              if (mounted) {
                setState(() {
                  _localImagePath = localPath;
                  _imageUrl = '';
                  _isComplete = true;
                  _isGeneratingImage = false;
                  _resumedFromPending = true;
                });
              }
            }
          }
        } catch (_) {}
      }
    }
  }

  /// Resume image generation given an already computed interpretation
  Future<void> _resumeImageGenerationFromInterpretation(
    String interpretation,
  ) async {
    try {
      try {
        await NotificationService().showGeneratingNotification(
          title: 'Ripresa generazione',
          body:
              'Sto riprendendo la generazione della visualizzazione del sogno',
        );
        WakelockPlus.enable();
      } catch (_) {}

      _isProcessing = true;
      await _savePendingJob({
        'status': 'image_in_progress',
        'dreamText': widget.dreamText,
        'interpretation': interpretation,
        'startedAt': DateTime.now().toIso8601String(),
      });

      String? image;
      try {
        // Try first using the original dream text to preserve fidelity
        image = await _openAI.generateDreamImage(widget.dreamText);
        await _savePendingJob({
          'status': 'image_in_progress',
          'dreamText': widget.dreamText,
          'interpretation': interpretation,
          'imageUrl': image,
          'startedAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Fallback to interpretation-derived prompt
        final fallbackPrompt = _extractImagePromptFromInterpretation(
          interpretation,
        );
        try {
          image = await _openAI.generateDreamImage(fallbackPrompt);
          await _savePendingJob({
            'status': 'image_in_progress',
            'dreamText': widget.dreamText,
            'interpretation': interpretation,
            'imageUrl': image,
            'startedAt': DateTime.now().toIso8601String(),
          });
        } catch (e2) {
          try {
            image = await _openAI.generateDreamImage(
              'dreamlike surreal atmosphere, artistic interpretation, high quality',
            );
            await _savePendingJob({
              'status': 'image_in_progress',
              'dreamText': widget.dreamText,
              'interpretation': interpretation,
              'imageUrl': image,
              'startedAt': DateTime.now().toIso8601String(),
            });
          } catch (e3) {
            image = '';
          }
        }
      }

      if (mounted) {
        setState(() {
          _imageUrl = image ?? '';
          _isGeneratingImage = false;
          _isComplete = true;
        });
      }

      _sleepAnimationController.stop();
      _fadeController.forward();

      await _saveDreamAutomatically(interpretation, image);

      _isProcessing = false;
      await _clearPendingJob();
      try {
        await NotificationService().cancelNotification();
        WakelockPlus.disable();
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        setState(() {
          _interpretation = "Errore durante la ripresa: $e";
          _isComplete = true;
        });
      }
      _sleepAnimationController.stop();
      _fadeController.forward();
      _isProcessing = false;
      await _clearPendingJob();
      try {
        await NotificationService().cancelNotification();
        WakelockPlus.disable();
      } catch (_) {}
    }
  }

  Future<void> _startInterpretation() async {
    try {
      // Try to keep device awake and show a notification so OS is less likely to suspend
      try {
        await NotificationService().showGeneratingNotification(
          title: 'Generazione in corso',
          body: 'Sto generando la visualizzazione del sogno',
        );
        WakelockPlus.enable();
      } catch (_) {}
      // Persist a pending job so we can resume if the app is backgrounded
      _isProcessing = true;
      await _savePendingJob({
        'status': 'in_progress',
        'dreamText': widget.dreamText,
        'startedAt': DateTime.now().toIso8601String(),
      });
      // Fase 1: Interpretazione del testo
      final interpretation = await _openAI.interpretDream(
        widget.dreamText,
        language: widget.languageService.currentLocale.languageCode,
      );

      // Persist that interpretation is done so we can resume image generation later
      await _savePendingJob({
        'status': 'interpretation_done',
        'dreamText': widget.dreamText,
        'interpretation': interpretation,
        'startedAt': DateTime.now().toIso8601String(),
      });

      setState(() {
        _interpretation = interpretation;
        _isGeneratingImage = true;
      });

      String? image;
      try {
        // 1. Prova con il testo utente
        image = await _openAI.generateDreamImage(widget.dreamText);
        // mark that image generation started/completed in pending job
        await _savePendingJob({
          'status': 'image_in_progress',
          'dreamText': widget.dreamText,
          'interpretation': interpretation,
          'imageUrl': image,
          'startedAt': DateTime.now().toIso8601String(),
        });
      } catch (imgErr) {
        // 2. Fallback: prompt estratto dall'interpretazione
        final fallbackPrompt = _extractImagePromptFromInterpretation(
          interpretation,
        );
        try {
          image = await _openAI.generateDreamImage(fallbackPrompt);
        } catch (imgErr2) {
          // 3. Fallback finale: prompt generico onirico
          try {
            image = await _openAI.generateDreamImage(
              'dreamlike surreal atmosphere, artistic interpretation, high quality',
            );
            await _savePendingJob({
              'status': 'image_in_progress',
              'dreamText': widget.dreamText,
              'interpretation': interpretation,
              'imageUrl': image,
              'startedAt': DateTime.now().toIso8601String(),
            });
          } catch (imgErr3) {
            image = '';
          }
        }
      }

      setState(() {
        _imageUrl = image ?? '';
        _isGeneratingImage = false;
        _isComplete = true;
      });

      // Ferma l'animazione del sonno e mostra il risultato
      _sleepAnimationController.stop();
      _fadeController.forward();

      // Salva automaticamente il sogno
      await _saveDreamAutomatically(interpretation, image);

      // Update pending as completed with localImagePath (will be cleared below)
      try {
        final prefs = await SharedPreferences.getInstance();
        final s = prefs.getString(_kLastSavedKey);
        String localPath = '';
        if (s != null) {
          final Map<String, dynamic> meta = Map<String, dynamic>.from(
            jsonDecode(s),
          );
          localPath = (meta['localImagePath'] as String?) ?? '';
        }
        await _savePendingJob({
          'status': 'completed',
          'dreamText': widget.dreamText,
          'interpretation': interpretation,
          'localImagePath': localPath,
          'completedAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      // Completed successfully — clear pending job
      _isProcessing = false;
      await _clearPendingJob();
      try {
        await NotificationService().cancelNotification();
        WakelockPlus.disable();
      } catch (_) {}
    } catch (e) {
      setState(() {
        _interpretation = "Errore durante l'interpretazione: $e";
        _isComplete = true;
      });
      _sleepAnimationController.stop();
      _fadeController.forward();
      // On error, make sure to clear pending state so user can retry
      _isProcessing = false;
      await _clearPendingJob();
      try {
        await NotificationService().cancelNotification();
        WakelockPlus.disable();
      } catch (_) {}
    }
  }

  /// Estrae un prompt sintetico dai primi elementi chiave dell'interpretazione
  String _extractImagePromptFromInterpretation(String interpretation) {
    // Prendi solo le prime 1-2 frasi significative, rimuovi testo superfluo
    final sentences = interpretation.split(RegExp(r'[.!?]\s+'));
    final filtered = sentences.where((s) => s.trim().isNotEmpty).toList();
    String base = filtered.take(2).join('. ');
    // Rimuovi eventuali prefissi tipo "Questo sogno contiene..." o "Key Insights:"
    base = base
        .replaceAll(
          RegExp(
            r'^(Questo sogno contiene|Key Insights:|Intuizioni Chiave:)',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    // Parole chiave per atmosfera dark
    final darkKeywords = [
      'oscuro',
      'notte',
      'ombra',
      'paura',
      'triste',
      'angoscia',
      'incubo',
      'dark',
      'gothic',
      'moody',
      'misterioso',
      'tenebra',
      'spavent',
      'horror',
      'night',
      'shadow',
      'fear',
      'sad',
      'gloom',
      'creepy',
      'mysterious',
      'fog',
      'foggy',
      'mist',
      'anxiety',
      'anxious',
      'disturb',
      'disturbing',
      'terror',
      'scary',
      'bleak',
      'melancholy',
      'sorrow',
      'dread',
      'eerie',
      'ominous',
      'bleak',
      'despair',
      'depression',
      'lonely',
      'solitude',
      'solitary',
      'cold',
      'rain',
      'storm',
      'stormy',
      'bleeding',
      'cry',
      'weeping',
      'scream',
      'crying',
      'screaming',
      'lost',
      'hopeless',
      'hopelessness',
      'abandoned',
      'abbandono',
      'solitudine',
      'pianto',
      'urlo',
      'urla',
      'piangere',
      'piangendo',
    ];
    final lowerInterp = interpretation.toLowerCase();
    final isDark = darkKeywords.any((k) => lowerInterp.contains(k));
    final style = isDark
        ? ', dark moody mysterious atmosphere, gothic surreal art style, high quality digital art'
        : ', dreamlike atmosphere, surreal art style, high quality digital art';
    return base + style;
  }

  Future<void> _saveDreamAutomatically(
    String interpretation,
    String imageUrl,
  ) async {
    try {
      // Genera i tag automaticamente
      final localizations = AppLocalizations.of(context);
      final tags = SavedDream.generateTags(
        widget.dreamText,
        interpretation,
        localizations,
      );

      final dreamId = DateTime.now().millisecondsSinceEpoch.toString();
      String? localImagePath;
      if (imageUrl.isNotEmpty) {
        final imageCacheService = ImageCacheService();
        localImagePath = await imageCacheService.downloadAndCacheImage(
          imageUrl,
          dreamId,
        );
      }

      final dream = SavedDream(
        id: dreamId,
        dreamText: widget.dreamText,
        interpretation: interpretation,
        imageUrl: imageUrl,
        localImagePath: localImagePath,
        createdAt: DateTime.now(),
        title: _generateTitle(widget.dreamText),
        tags: tags,
      );

      final storageService = DreamStorageService();
      await storageService.saveDream(dream);

      // Save last-saved metadata to help resume UI when app was backgrounded
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _kLastSavedKey,
          jsonEncode({
            'dreamText': widget.dreamText,
            'localImagePath': localImagePath ?? '',
            'savedAt': DateTime.now().toIso8601String(),
          }),
        );
      } catch (e) {
        // ignore
      }

      // Aggiorna lo stato per mostrare il messaggio di salvataggio
      if (mounted) {
        setState(() {
          _isSaved = true;
          // If we downloaded a local image, keep its path to render when returning from background
          _localImagePath = localImagePath;
        });
      }
      // Remember the last saved dream id so subsequent favorite toggles reference it
      _lastSavedDreamId = dreamId;

      // Play the star-flying animation toward the history button after the
      // current frame so we don't use BuildContext across async gaps.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _launchStarAnimation(context, true);
        }
      });
      // If we have a local image, show completion notification
      if (localImagePath != null && localImagePath.isNotEmpty) {
        try {
          await NotificationService().showCompletedNotification(
            title: 'Immagine pronta',
            body:
                'La visualizzazione del tuo sogno è pronta. Tocca per aprire l\'app.',
          );
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Errore nel salvataggio automatico: $e');
    }
  }

  String _generateTitle(String dreamText) {
    final words = dreamText.trim().split(' ');
    if (words.length <= 3) return dreamText;
    return '${words.take(3).join(' ')}...';
  }

  // ...existing code... (removed unused _wrapBannerText helper)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    // Build a body that can show a top banner when resuming a pending job.
    // Place the banner inside the same gradient container so it visually
    // blends with the background and doesn't produce a hard cut.
    // Make the main content transparent so the underlying scaffold/app
    // background (for example the cloud image behind the AppBar) remains visible.
    final content = Container(
      // intentionally transparent to let the background image show through
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // removed top resumed-from-pending banner to avoid overflow on some devices

          // The actual content (loading or completed) follows and will
          // naturally sit on the same gradient background.
          _isComplete
              ? _buildCompletedInterpretation(theme, localizations)
              : _buildLoadingAnimation(theme, localizations),
        ],
      ),
    );

    return Scaffold(
      // Extend the gradient behind the AppBar so there is no hard seam
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(localizations.dreamInterpretationTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            // builder scope for layout adjustments

            final double topOffset =
                MediaQuery.of(context).padding.top + kToolbarHeight;

            return Column(
              children: [
                // Push the main content slightly below the transparent AppBar
                // but keep the gap minimal so the page title and the section
                // header appear closer together on phones.
                SizedBox(height: max(8.0, topOffset - 36.0)),

                // Keep the content centered vertically when it's smaller than
                // the available space, and allow scrolling when it's larger.
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Add bottom padding to account for the on-screen keyboard
                      // and the global bottom menu so content can scroll above them
                      // and avoid BottomOverflowed when input expands.
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.only(
                          bottom:
                              MediaQuery.of(context).viewInsets.bottom +
                              kGlobalBottomMenuHeight +
                              16,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: content,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingAnimation(
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    // Modern, compact loading card with stronger visual hierarchy
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Floating animated icon
                  AnimatedBuilder(
                    animation: _sleepAnimation,
                    builder: (context, child) {
                      final scale = _sleepAnimation.value;
                      return Transform.translate(
                        offset: Offset(0, -8 * (scale - 1)),
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withOpacity(0.95),
                                theme.colorScheme.secondary.withOpacity(0.9),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.22,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.nights_stay,
                            size: 52,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  Text(
                    _isGeneratingImage
                        ? localizations.generatingImageText
                        : localizations.interpretingDream,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onBackground,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Circular progress with accent ring
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: CircularProgressIndicator(
                            strokeWidth: 6,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        Icon(
                          _isGeneratingImage ? Icons.image : Icons.auto_awesome,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    localizations.waitingMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onBackground.withOpacity(0.78),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 14),

                  // (removed duplicated non-wrapping advice block that caused overflow)
                  // Advice inline (no surrounding box) — icon + text
                  // Use a responsive Wrap so the line will naturally break on narrow screens
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: InkWell(
                      onTap: () => setState(() {
                        _isAdviceExpanded = !_isAdviceExpanded;
                      }),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxTextWidth = min(
                              540.0,
                              constraints.maxWidth - 80,
                            );
                            final adviceTextColor =
                                theme.brightness == Brightness.light
                                ? Colors.black87
                                : theme.colorScheme.onBackground.withOpacity(
                                    0.88,
                                  );

                            return Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.primary,
                                ),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: maxTextWidth,
                                  ),
                                  child: AnimatedCrossFade(
                                    firstChild: Text(
                                      localizations
                                          .doNotLeaveDuringInterpretation,
                                      style: TextStyle(color: adviceTextColor),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    secondChild: Text(
                                      localizations
                                          .doNotLeaveDuringInterpretation,
                                      style: TextStyle(color: adviceTextColor),
                                      textAlign: TextAlign.center,
                                    ),
                                    crossFadeState: _isAdviceExpanded
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                    duration: const Duration(milliseconds: 200),
                                    firstCurve: Curves.easeInOut,
                                    secondCurve: Curves.easeInOut,
                                  ),
                                ),
                                Icon(
                                  _isAdviceExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 20,
                                  color: theme.brightness == Brightness.light
                                      ? Colors.black45
                                      : theme.colorScheme.onBackground
                                            .withOpacity(0.6),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedInterpretation(
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Removed large top hero to avoid duplicate/empty image box; keep compact spacing
              const SizedBox(height: 8),
              // Use the same section headers and card styles as DreamDetail
              // Dream title / dream section header
              Row(
                children: [
                  Icon(
                    Icons.nights_stay,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    localizations.yourDreamTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  widget.dreamText,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Interpretation header
              Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    localizations.interpretation,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _interpretation,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Image block: mirror DreamDetail layout
              if ((_imageUrl.isNotEmpty) ||
                  (_localImagePath != null && _localImagePath!.isNotEmpty)) ...[
                Text(
                  localizations.dreamVisualization,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 12),

                Stack(
                  children: [
                    _imageCard(theme, localizations),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: GestureDetector(
                        onTap: () async {
                          // Ensure we have an id for saving
                          if (_lastSavedDreamId == null) {
                            final dreamId = DateTime.now()
                                .millisecondsSinceEpoch
                                .toString();
                            _lastSavedDreamId = dreamId;
                          }

                          final dream = SavedDream(
                            id:
                                _lastSavedDreamId ??
                                DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                            dreamText: widget.dreamText,
                            interpretation: _interpretation,
                            imageUrl: _imageUrl,
                            localImagePath: _localImagePath,
                            createdAt: DateTime.now(),
                            title: _generateTitle(widget.dreamText),
                            tags: [],
                          );

                          try {
                            // Add explicitly to favorites (no toggle) so the item is guaranteed added
                            await _favoritesService.addToFavorites(dream);

                            // provide the same star-flying animation; treat as 'added'
                            _launchStarAnimation(context, true);
                          } catch (e) {
                            debugPrint('Failed adding to favorites: $e');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.14),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            Icons.star,
                            color: Colors.amber.shade600,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Place the 'dream saved' badge at the bottom of the interpretation
              // so it doesn't push the title off-center.
              if (_isSaved) ...[
                const SizedBox(height: 12),
                // Align badge to the left so it lines up with other section
                // titles and content.
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.22)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          localizations.dreamSavedSuccessfully,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Reduce extra bottom spacing so the global bottom menu doesn't
              // consume too much of the interpretation page.
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable stylish card used in the redesigned layout
  // (helper removed) previously used for a different card layout; kept image card below

  Widget _imageCard(ThemeData theme, AppLocalizations localizations) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _localImagePath != null && _localImagePath!.isNotEmpty
            ? Image.file(File(_localImagePath!), fit: BoxFit.cover)
            : Image.network(
                _imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localizations.imageLoadError,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  // Simple flying star animation using an OverlayEntry. The target position is
  // approximated to the bottom-left area where the history/favorites button is.
  void _launchStarAnimation(BuildContext context, bool added) {
    // Prefer inserting into the root overlay so the entry is painted above
    // any app-level stacks the builder may create. Fall back to the nearest
    // overlay if rootOverlay isn't available.
    final overlay = Overlay.of(context, rootOverlay: true);
    final size = MediaQuery.of(context).size;

    final start = Offset(size.width * 0.75, size.height * 0.4);

    // Try to resolve the exact target from the history button's global key
    Offset end = Offset(size.width * 0.12, size.height * 0.92);
    try {
      final renderBox =
          historyButtonKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final targetPos = renderBox.localToGlobal(
          renderBox.size.center(Offset.zero),
        );
        end = targetPos;
      } else {
        debugPrint(
          'launchStarAnimation: historyButtonKey.renderBox == null, using fallback end=$end',
        );
      }
    } catch (e) {
      debugPrint(
        'launchStarAnimation: failed to compute history button position: $e — using fallback end=$end',
      );
    }

    // Overlay.of with rootOverlay=true is expected to return a valid OverlayState
    // in normal app execution; proceed assuming it's available.

    debugPrint('launchStarAnimation: start=$start end=$end');

    final entry = OverlayEntry(
      builder: (context) {
        // IgnorePointer ensures the temporary overlay doesn't block user input.
        return IgnorePointer(
          ignoring: true,
          child: Stack(
            children: [
              Positioned.fill(child: Container(color: Colors.transparent)),
              _StarAnimationOverlay(start: start, end: end),
            ],
          ),
        );
      },
    );

    overlay.insert(entry);

    // Remove after animation duration (controller now 1300ms) with small buffer
    Future.delayed(const Duration(milliseconds: 1500), () {
      try {
        entry.remove();
      } catch (_) {}
      // Intentionally do not show an inline snackbar for favorites to keep
      // the UI clean; the star animation provides sufficient feedback.
    });
  }
}
