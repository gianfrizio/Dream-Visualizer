import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import '../openai_service.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import '../models/saved_dream.dart';
import '../services/dream_storage_service.dart';
import '../services/image_cache_service.dart';
import '../services/notification_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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

      return;
    }

    // Resume only if this page corresponds to the same dream text and it's still in progress
    if ((status == 'in_progress') &&
        dreamText.trim() == widget.dreamText.trim()) {
      // small delay to allow UI to settle
      if (mounted) {
        setState(() {
          _isGeneratingImage = true;
          _isComplete = false;
          // mark that we are resuming a pending job so UI can notify the user
          _resumedFromPending = true;
        });
      }
      // Resume full processing (interpretation + image)
      await _startInterpretation();
      return;
    } else if (status == 'interpretation_done' &&
        dreamText.trim() == widget.dreamText.trim()) {
      // Interpretation is already done but image generation did not finish.
      if (mounted) {
        setState(() {
          _interpretation = pendingInterpretation;
          _isGeneratingImage = true;
          _isComplete = false;
          _resumedFromPending = true;
        });
      }
      // Try to resume image generation from the interpretation stage
      await _resumeImageGenerationFromInterpretation(pendingInterpretation);
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
      print('Errore nel salvataggio automatico: $e');
    }
  }

  String _generateTitle(String dreamText) {
    final words = dreamText.trim().split(' ');
    if (words.length <= 3) return dreamText;
    return '${words.take(3).join(' ')}...';
  }

  // Try to split a localized banner string into two lines near the middle so it
  // appears compact and doesn't overflow full-width banners. This chooses a
  // nearby space to insert a newline rather than breaking words.
  String _wrapBannerText(String s, [int maxLines = 3]) {
    // Simple greedy word-wrapping into up to `maxLines` lines.
    final trimmed = s.trim();
    if (trimmed.isEmpty) return trimmed;
    if (maxLines <= 1) return trimmed;

    final words = trimmed.split(RegExp(r'\s+'));
    final totalLen = trimmed.length;
    final target = (totalLen / maxLines).ceil();

    final List<String> lines = [];
    String current = '';

    for (final w in words) {
      if (current.isEmpty) {
        current = w;
      } else if ((current.length + 1 + w.length) <= target ||
          lines.length + 1 >= maxLines) {
        current = '$current $w';
      } else {
        lines.add(current);
        current = w;
      }
    }
    if (current.isNotEmpty) lines.add(current);

    // If we somehow produced more than maxLines, merge the tail into the last line
    if (lines.length > maxLines) {
      final merged = <String>[];
      merged.addAll(lines.sublist(0, maxLines - 1));
      merged.add(lines.sublist(maxLines - 1).join(' '));
      return merged.join('\n');
    }

    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    // Build a body that can show a top banner when resuming a pending job
    final content = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: theme.brightness == Brightness.light
              ? [const Color(0xFFF8F9FF), const Color(0xFFE8EAFF)]
              : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
        ),
      ),
      child: _isComplete
          ? _buildCompletedInterpretation(theme, localizations)
          : _buildLoadingAnimation(theme, localizations),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.dreamInterpretationTitle),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            // builder scope for layout adjustments

            return Column(
              children: [
                if (_resumedFromPending)
                  Align(
                    alignment: Alignment.topCenter,
                    child: FractionallySizedBox(
                      widthFactor: 0.78, // leave ~22% total horizontal margin
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 520,
                          maxHeight: 140,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 10.0,
                            bottom: 8.0,
                          ),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: theme.colorScheme.surfaceVariant.withOpacity(
                              0.98,
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _wrapBannerText(
                                            localizations
                                                .doNotLeaveDuringInterpretation,
                                          ),
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface,
                                            fontSize: 13,
                                          ),
                                          softWrap: true,
                                          maxLines: 3,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _resumedFromPending = false;
                                          });
                                        },
                                        icon: Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Reserve vertical space for the resumed banner when present.
                      final double bannerHeight = _resumedFromPending
                          ? 140.0
                          : 0.0;
                      final double bodyHeight =
                          (constraints.maxHeight - bannerHeight) > 0
                          ? (constraints.maxHeight - bannerHeight)
                          : 0.0;

                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: bodyHeight),
                          child: Container(
                            width: double.infinity,
                            height: bodyHeight,
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Builder(
          builder: (context) {
            // Responsive scale based on screen width
            final width = MediaQuery.of(context).size.width;
            // base width 380 (typical phone); clamp scale to reasonable range
            final scale = (width / 380).clamp(0.85, 1.25);
            final headerFont = 20.0 * scale;
            final subtitleFont = 16.0 * scale;
            final adviceFont = 14.0 * scale;
            final iconSize = 60.0 * (scale.clamp(0.9, 1.15));

            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animazione della persona che dorme
                AnimatedBuilder(
                  animation: _sleepAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _sleepAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primaryContainer.withOpacity(
                            0.3,
                          ),
                        ),
                        child: Icon(
                          Icons.bedtime_rounded,
                          size: iconSize,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Testo di stato
                Text(
                  _isGeneratingImage
                      ? localizations.generatingImageText
                      : localizations.interpretingDream,
                  style: TextStyle(
                    fontSize: headerFont,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Indicatore di caricamento
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),

                // Sottotitolo e avviso compatti, centrati
                const SizedBox(height: 6),
                Text(
                  localizations.waitingMessage,
                  style: TextStyle(
                    fontSize: subtitleFont,
                    color: theme.colorScheme.onBackground.withOpacity(0.75),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Banner-like contained advice for clarity (narrowed)
                Align(
                  alignment: Alignment.center,
                  child: FractionallySizedBox(
                    widthFactor: 0.78,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(
                            0.95,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                              size: 18.0 * (scale.clamp(0.9, 1.1)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                localizations.doNotLeaveDuringInterpretation,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: adviceFont,
                                ),
                                textAlign: TextAlign.center,
                                softWrap: true,
                                maxLines: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titolo
            Text(
              localizations.yourDreamTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 16),

            // Testo del sogno
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Text(
                widget.dreamText,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Interpretazione
            Text(
              localizations.interpretation,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _interpretation,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                  height: 1.6,
                ),
              ),
            ),

            // Immagine del sogno
            if ((_imageUrl.isNotEmpty) ||
                (_localImagePath != null && _localImagePath!.isNotEmpty)) ...[
              const SizedBox(height: 32),

              Text(
                localizations.dreamVisualization,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
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
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(16),
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
                                        color:
                                            theme.colorScheme.onErrorContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],

            // Messaggio di salvataggio
            if (_isSaved)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        localizations.dreamSavedSuccessfully,
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
