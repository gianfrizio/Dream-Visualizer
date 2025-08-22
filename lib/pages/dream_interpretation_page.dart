import 'package:flutter/material.dart';
import '../openai_service.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import '../models/saved_dream.dart';
import '../services/dream_storage_service.dart';

class DreamInterpretationPage extends StatefulWidget {
  final String dreamText;
  final LanguageService languageService;

  const DreamInterpretationPage({
    super.key,
    required this.dreamText,
    required this.languageService,
  });

  @override
  State<DreamInterpretationPage> createState() =>
      _DreamInterpretationPageState();
}

class _DreamInterpretationPageState extends State<DreamInterpretationPage>
    with TickerProviderStateMixin {
  late AnimationController _sleepAnimationController;
  late AnimationController _fadeController;
  late Animation<double> _sleepAnimation;
  late Animation<double> _fadeAnimation;

  String _interpretation = '';
  String _imageUrl = '';
  bool _isGeneratingImage = false;
  bool _isComplete = false;
  bool _isSaved = false;

  final OpenAIService _openAI = OpenAIService();

  @override
  void initState() {
    super.initState();

    // Animazione della persona che dorme
    _sleepAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _sleepAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(
        parent: _sleepAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    // Avvia l'animazione in loop
    _sleepAnimationController.repeat(reverse: true);

    // Inizia l'interpretazione
    _startInterpretation();
  }

  @override
  void dispose() {
    _sleepAnimationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _startInterpretation() async {
    try {
      // Fase 1: Interpretazione del testo
      final interpretation = await _openAI.interpretDream(
        widget.dreamText,
        language: widget.languageService.currentLocale.languageCode,
      );

      setState(() {
        _interpretation = interpretation;
        _isGeneratingImage = true;
      });

      // Fase 2: Generazione dell'immagine
      final image = await _openAI.generateDreamImage(widget.dreamText);

      setState(() {
        _imageUrl = image;
        _isGeneratingImage = false;
        _isComplete = true;
      });

      // Ferma l'animazione del sonno e mostra il risultato
      _sleepAnimationController.stop();
      _fadeController.forward();

      // Salva automaticamente il sogno
      await _saveDreamAutomatically(interpretation, image);
    } catch (e) {
      setState(() {
        _interpretation = "Errore durante l'interpretazione: $e";
        _isComplete = true;
      });
      _sleepAnimationController.stop();
      _fadeController.forward();
    }
  }

  Future<void> _saveDreamAutomatically(
    String interpretation,
    String imageUrl,
  ) async {
    try {
      final dream = SavedDream(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        dreamText: widget.dreamText,
        interpretation: interpretation,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        title: _generateTitle(widget.dreamText),
      );

      final storageService = DreamStorageService();
      await storageService.saveDream(dream);

      // Aggiorna lo stato per mostrare il messaggio di salvataggio
      if (mounted) {
        setState(() {
          _isSaved = true;
        });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.dreamInterpretationTitle),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      body: Container(
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
      ),
    );
  }

  Widget _buildLoadingAnimation(
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return Center(
      child: Column(
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
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  ),
                  child: Icon(
                    Icons.bedtime_rounded,
                    size: 60,
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          // Testo di stato
          Text(
            _isGeneratingImage
                ? localizations.generatingImageText
                : localizations.interpretingDream,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onBackground,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

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

          const SizedBox(height: 20),

          // Sottotitolo
          Text(
            localizations.waitingMessage,
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ],
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
            if (_imageUrl.isNotEmpty) ...[
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
                  child: Image.network(
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
                        child: const Center(child: CircularProgressIndicator()),
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
