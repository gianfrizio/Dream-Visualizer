import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import 'dart:async';
import 'openai_service.dart';
import 'models/saved_dream.dart';
import 'services/dream_storage_service.dart';
import 'services/language_service.dart';
import 'services/theme_service.dart';
import 'services/image_cache_service.dart';
import 'services/biometric_auth_service.dart';
import 'services/encryption_service.dart';
import 'pages/dream_history_page.dart';
import 'pages/settings_page.dart';
import 'pages/dream_analytics_page.dart';
import 'pages/simple_biometric_test_page_new.dart';
import 'pages/improved_community_page.dart';
import 'l10n/app_localizations.dart';
import 'pages/language_selection_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  // await Firebase.initializeApp();

  final languageService = LanguageService();
  final themeService = ThemeService();
  final biometricService = BiometricAuthService();
  final encryptionService = EncryptionService();
  // final authService = AuthService();
  // final cloudSyncService = CloudSyncService();
  // final communityService = CommunityService();

  await languageService.initialize();
  await themeService.initialize();
  await biometricService.initialize();
  await encryptionService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: languageService),
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: biometricService),
        // ChangeNotifierProvider.value(value: authService),
        // ChangeNotifierProvider.value(value: cloudSyncService),
        // ChangeNotifierProvider.value(value: communityService),
        Provider.value(value: encryptionService),
      ],
      child: DreamApp(
        languageService: languageService,
        themeService: themeService,
      ),
    ),
  );
}

class DreamApp extends StatelessWidget {
  final LanguageService languageService;
  final ThemeService themeService;

  const DreamApp({
    super.key,
    required this.languageService,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([languageService, themeService]),
      builder: (context, child) {
        return MaterialApp(
          title: 'Dream Visualizer',
          debugShowCheckedModeBanner: false,
          locale: languageService.currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('it', 'IT'), Locale('en', 'US')],
          themeMode: themeService.themeMode, // Usa il tema dal servizio
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1), // Colore primario
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFFCFCFD),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
              iconTheme: IconThemeData(color: Color(0xFF2D3748)),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1), // Stesso colore primario
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0F172A), // Sfondo scuro
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              iconTheme: IconThemeData(color: Colors.white),
            ),
          ),
          home: DreamHomePage(
            languageService: languageService,
            themeService: themeService,
          ),
        );
      },
    );
  }
}

class DreamHomePage extends StatefulWidget {
  final LanguageService languageService;
  final ThemeService themeService;

  const DreamHomePage({
    super.key,
    required this.languageService,
    required this.themeService,
  });

  @override
  _DreamHomePageState createState() => _DreamHomePageState();
}

class _DreamHomePageState extends State<DreamHomePage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _transcription = '';
  String _interpretation = '✍️ Loading...';
  bool _showingAdvice =
      true; // Traccia se stiamo mostrando advice o interpretazione
  String _imageUrl = '';
  final OpenAIService _openAI = OpenAIService();
  final DreamStorageService _storageService = DreamStorageService();
  final ImageCacheService _imageCacheService = ImageCacheService();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode(); // Controllo focus tastiera
  String _confirmedText = '';
  Timer? _watchdogTimer;
  String _lastKnownText = '';
  int _noChangeCount = 0;
  bool _speechAvailable = false; // New: tracks speech availability
  DateTime _lastUpdateTime = DateTime.now(); // New: tracks last update
  bool _dreamSaved = false; // Traccia se il sogno corrente è stato salvato

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    _checkBiometricAuth();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Aggiorna gli advice quando cambiano le dipendenze (inclusa la localizzazione)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _updateInterpretationAdvice();
        });
      }
    });
  }

  void _checkBiometricAuth() async {
    final biometricService = context.read<BiometricAuthService>();
    if (biometricService.isAuthenticationRequired) {
      // Naviga alla pagina di test semplice
      final authenticated = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => const SimpleBiometricTestPage(),
          fullscreenDialog: true,
        ),
      );

      if (authenticated != true) {
        // Se l'autenticazione fallisce o viene annullata, chiudi l'app
        SystemNavigator.pop();
      }
    }
  }

  @override
  void dispose() {
    _stopWatchdog(); // Cleans up the timer when the app is closed
    _speech.stop();
    _textFieldFocusNode.dispose(); // Cleanup del FocusNode
    super.dispose();
  }

  void _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) {
        print('Speech error: $error');
        // Automatically restart in case of error
        if (_isListening) {
          _restartListeningIfStuck();
        }
      },
      onStatus: (status) {
        print('Speech status: $status');
        if (status == 'notListening' && _isListening) {
          // If it should be listening but isn't, restart
          _restartListeningIfStuck();
        }
      },
    );
    setState(() {});
  }

  void _listen() async {
    if (!_isListening) {
      if (!_speechAvailable) {
        _speechAvailable = await _speech.initialize();
      }

      if (_speechAvailable) {
        setState(() => _isListening = true);
        // DO NOT clear _confirmedText here - keep existing text
        // _confirmedText = '';  // <-- Remove this line
        _lastKnownText = '';
        _noChangeCount = 0;
        _lastUpdateTime = DateTime.now();

        _startWatchdog();
        _startListening();
      }
    } else {
      setState(() {
        _isListening = false;
        _updateInterpretationAdvice(); // Aggiorna i consigli quando si ferma l'ascolto
      });
      _confirmedText = _transcription.trim(); // Confirm all text
      _stopWatchdog();
      _speech.stop();
    }
  }

  void _startListening() {
    _speech.listen(
      onResult: (val) {
        _lastUpdateTime = DateTime.now();
        setState(() {
          String currentSessionText = val.recognizedWords.trim();

          // Advanced deduplication logic
          if (_confirmedText.isNotEmpty && currentSessionText.isNotEmpty) {
            String confirmedTextTrimmed = _confirmedText.trim();
            String currentLower = currentSessionText.toLowerCase();
            String confirmedLower = confirmedTextTrimmed.toLowerCase();

            // Case 1: Current text completely contains confirmed text - use only current
            if (currentLower.contains(confirmedLower)) {
              _transcription = currentSessionText;
            }
            // Case 2: Check for partial overlap at the end of confirmed text
            else {
              // Split by spaces but preserve punctuation attached to words
              List<String> confirmedWords = confirmedTextTrimmed.split(
                RegExp(r'\s+'),
              );
              List<String> currentWords = currentSessionText.split(
                RegExp(r'\s+'),
              );

              // Look for overlap: check if current text starts with last words of confirmed text
              bool hasOverlap = false;
              for (
                int i = 1;
                i <= confirmedWords.length && i <= currentWords.length;
                i++
              ) {
                List<String> lastConfirmedWords = confirmedWords.sublist(
                  confirmedWords.length - i,
                );
                List<String> firstCurrentWords = currentWords.sublist(0, i);

                // Compare words without punctuation for overlap detection
                String lastConfirmedText = lastConfirmedWords
                    .join(' ')
                    .toLowerCase()
                    .replaceAll(RegExp(r'[^\w\s]'), '');
                String firstCurrentText = firstCurrentWords
                    .join(' ')
                    .toLowerCase()
                    .replaceAll(RegExp(r'[^\w\s]'), '');

                if (lastConfirmedText == firstCurrentText &&
                    lastConfirmedText.isNotEmpty) {
                  // Found overlap, but preserve punctuation from the most recent version
                  List<String> uniqueCurrentWords = currentWords.sublist(i);

                  // If the confirmed text ends with punctuation, keep it
                  // Otherwise, use the punctuation from the current session if available
                  String baseText = confirmedTextTrimmed;
                  if (i < currentWords.length) {
                    // Take punctuation from current session if it's more complete
                    String currentPrefix = firstCurrentWords.join(' ');
                    if (currentPrefix.length >
                        lastConfirmedWords
                            .join(' ')
                            .replaceAll(RegExp(r'[^\w\s]'), '')
                            .length) {
                      // Replace the overlapping part with the current version (which might have punctuation)
                      String beforeOverlap = '';
                      if (confirmedWords.length > i) {
                        beforeOverlap = confirmedWords
                            .sublist(0, confirmedWords.length - i)
                            .join(' ');
                      }
                      baseText = beforeOverlap.isEmpty
                          ? currentPrefix
                          : beforeOverlap + ' ' + currentPrefix;
                    }
                  }

                  if (uniqueCurrentWords.isNotEmpty) {
                    _transcription =
                        baseText + ' ' + uniqueCurrentWords.join(' ');
                  } else {
                    _transcription = baseText;
                  }
                  hasOverlap = true;
                  break;
                }
              }

              // No overlap found, concatenate normally
              if (!hasOverlap) {
                _transcription =
                    confirmedTextTrimmed + ' ' + currentSessionText;
              }
            }
          } else if (_confirmedText.isNotEmpty) {
            // If there's no text in the current session, keep only the confirmed one
            _transcription = _confirmedText.trim();
          } else {
            // If there's no confirmed text, use only the current session text
            _transcription = currentSessionText;
          }

          _textController.text = _transcription;
          _updateInterpretationAdvice(); // Aggiorna i consigli durante il riconoscimento vocale
        });
      },
      localeId: widget.languageService.speechLanguageCode,
      listenFor: const Duration(
        seconds: 30,
      ), // Reduced from 1 day to 30 seconds
      pauseFor: const Duration(seconds: 5), // Reduced from 1 hour to 5 seconds
      partialResults: true,
      cancelOnError: false,
      listenMode: stt.ListenMode.dictation,
      onSoundLevelChange: (level) => {},
    );
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _lastKnownText = _transcription;
    _noChangeCount = 0;
    _lastUpdateTime = DateTime.now();

    _watchdogTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // Reduced to 3 seconds
      if (_isListening) {
        final now = DateTime.now();
        final timeSinceLastUpdate = now.difference(_lastUpdateTime).inSeconds;

        // If there are no updates for more than 8 seconds, restart
        if (timeSinceLastUpdate > 8) {
          print(
            'Watchdog: Nessun aggiornamento da $timeSinceLastUpdate secondi, riavvio...',
          );
          _restartListeningIfStuck();
          return;
        }

        // Also check if the text doesn't change
        if (_transcription == _lastKnownText) {
          _noChangeCount++;
          if (_noChangeCount >= 2) {
            // Reduced from 3 to 2 (6 seconds total)
            print(
              'Watchdog: Testo non cambia da ${_noChangeCount * 3} secondi, riavvio...',
            );
            _restartListeningIfStuck();
            _noChangeCount = 0;
          }
        } else {
          _lastKnownText = _transcription;
          _noChangeCount = 0;
        }

        // Also check the recognition state
        if (!_speech.isListening && _isListening) {
          print('Watchdog: Speech non sta ascoltendo ma dovrebbe, riavvio...');
          _restartListeningIfStuck();
        }
      }
    });
  }

  void _stopWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  void _restartListeningIfStuck() async {
    if (!_isListening) return;

    print('Restarting voice recognition...');

    // Save all current text as confirmed, but only if it's not already confirmed
    String tempText = _transcription.trim();
    if (tempText.isNotEmpty && tempText != _confirmedText) {
      if (tempText.endsWith(' ')) {
        _confirmedText = tempText;
      } else {
        _confirmedText = tempText + ' ';
      }
    }

    // Completely stop the recognition
    await _speech.stop();
    await Future.delayed(const Duration(milliseconds: 500));

    // Reinitialize if necessary
    if (!_speechAvailable || !_speech.isAvailable) {
      _speechAvailable = await _speech.initialize();
    }

    // Restart only if we're still listening
    if (_isListening && _speechAvailable) {
      _lastUpdateTime = DateTime.now();
      _startListening();
    }
  }

  // Dialog di conferma per cancellazione
  void _showDeleteConfirmDialog(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                _dreamSaved ? Icons.check_circle : Icons.warning_amber_rounded,
                color: _dreamSaved ? Colors.green : Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _dreamSaved
                      ? localizations.dreamAlreadySaved
                      : localizations.confirmDeletion,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            _dreamSaved
                ? localizations.dreamSavedMessage
                : localizations.confirmDeletionMessage,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            // Pulsante Mantieni/Annulla con bordo visibile
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _dreamSaved ? Colors.blue : Colors.grey[400]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _dreamSaved ? localizations.keep : localizations.cancelAction,
                  style: TextStyle(
                    color: _dreamSaved ? Colors.blue : Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearAllContent();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _dreamSaved ? Colors.blue : Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _dreamSaved
                    ? localizations.clearAndStartNew
                    : localizations.clear,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Funzione per cancellare tutto il contenuto
  void _clearAllContent() {
    setState(() {
      _isListening = false;
      _transcription = '';
      _confirmedText = '';
      _textController.clear();
      _showingAdvice = true; // Torna a mostrare gli advice
      _imageUrl = '';
      _dreamSaved = false; // Reset del flag di salvataggio

      // Aggiorna gli advice con la lingua corretta all'interno del setState
      _updateInterpretationAdvice();
    });
    _stopWatchdog();
    _speech.stop();
  }

  // Helper per controllare se il testo è valido per l'interpretazione
  bool _isTextValidForInterpretation() {
    final trimmedText = _transcription.trim();
    return trimmedText.isNotEmpty && trimmedText.length >= 10;
  }

  // Aggiorna il messaggio di consiglio in base al contenuto del testo
  void _updateInterpretationAdvice() {
    // Solo aggiorna gli advice se non stiamo mostrando un'interpretazione reale
    if (!_showingAdvice) return;

    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      // Se le localizzazioni non sono ancora disponibili, usa testi di fallback
      _interpretation = '✍️ Write your dream in the text field above...';
      return;
    }

    final trimmedText = _transcription.trim();

    if (trimmedText.isEmpty) {
      _interpretation = localizations.adviceEmptyText;
    } else if (trimmedText.length < 10) {
      _interpretation = localizations.adviceShortText;
    } else if (trimmedText.split(' ').length < 3) {
      _interpretation = localizations.adviceFewWords;
    } else {
      _interpretation = localizations.adviceReadyToInterpret;
    }
  }

  void _processDream() async {
    final localizations = AppLocalizations.of(context)!;

    // Controllo più intelligente del contenuto
    final trimmedText = _transcription.trim();

    if (trimmedText.isEmpty) {
      setState(() {
        _showingAdvice = true;
        _interpretation =
            "⚠️ Non hai ancora scritto nulla!\n\nScrivi il tuo sogno nel campo di testo sopra e poi premi 'Interpreta sogno'.";
      });
      // Non chiudere la tastiera se non c'è testo - l'utente deve scrivere
      return;
    }

    // Controlla se il testo è troppo corto per essere un sogno significativo
    if (trimmedText.length < 10) {
      setState(() {
        _showingAdvice = true;
        _interpretation =
            "📝 Il testo è troppo breve!\n\nPer ottenere un'interpretazione accurata, descrivi il tuo sogno con almeno qualche parola in più. Un sogno ha bisogno di dettagli per essere interpretato correttamente.";
      });
      // Non chiudere la tastiera - l'utente deve continuare a scrivere
      return;
    }

    // Se arriviamo qui, il testo è valido - chiudi la tastiera
    _textFieldFocusNode.unfocus();

    setState(() {
      _showingAdvice = false; // Non stiamo più mostrando advice
      _interpretation = localizations.analyzingDream;
      _imageUrl = "";
    });

    try {
      // Passa la lingua corrente al servizio OpenAI
      final interpretation = await _openAI.interpretDream(
        _transcription,
        language: widget.languageService.currentLocale.languageCode,
      );
      setState(() => _interpretation = interpretation);

      setState(
        () => _interpretation =
            "$interpretation\n\n${localizations.analyzingVisualElements}",
      );

      // Passa il testo originale del sogno, non l'interpretazione
      final image = await _openAI.generateDreamImage(_transcription);
      setState(() => _imageUrl = image);

      // Remove the "Generating image" message once completed
      setState(() => _interpretation = interpretation);

      // Salva automaticamente il sogno dopo l'interpretazione completa
      await _saveDreamAutomatically(interpretation, image, localizations);
    } catch (e) {
      setState(() {
        _interpretation =
            "${localizations.analysisError}: $e\n\n"
            "${localizations.possibleCauses}\n"
            "${localizations.internetProblem}\n"
            "${localizations.invalidApiKey}\n"
            "${localizations.usageLimitReached}\n\n"
            "${localizations.checkConnectionAndRetry}";
        _imageUrl = "";
      });
    }
  }

  Future<void> _saveDreamAutomatically(
    String interpretation,
    String imageUrl,
    AppLocalizations localizations,
  ) async {
    try {
      final dreamId = DateTime.now().millisecondsSinceEpoch.toString();

      // Scarica e caching dell'immagine se disponibile
      String? localImagePath;
      if (imageUrl.isNotEmpty) {
        localImagePath = await _imageCacheService.downloadAndCacheImage(
          imageUrl,
          dreamId,
        );
      }

      final dream = SavedDream(
        id: dreamId,
        dreamText: _transcription,
        interpretation: interpretation,
        imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
        localImagePath: localImagePath,
        createdAt: DateTime.now(),
        title: SavedDream.generateTitle(_transcription),
        tags: SavedDream.generateTags(
          _transcription,
          interpretation,
          localizations,
        ),
        language: SavedDream.detectLanguage('$_transcription $interpretation'),
      );

      await _storageService.saveDream(dream);

      // Imposta il flag che indica che il sogno è stato salvato
      setState(() {
        _dreamSaved = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(localizations.dreamSavedAutomatically),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Errore nel salvataggio automatico: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          // Nasconde la tastiera quando si clicca fuori dal campo di testo
          _textFieldFocusNode.unfocus();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: theme.brightness == Brightness.light
                  ? [
                      const Color(0xFFFCFCFD), // Bianco purissimo con sfumatura
                      const Color(0xFFF7F8FC), // Bianco con hint di viola
                      const Color(
                        0xFFF0F4FF,
                      ), // Bianco con tocco di blu molto tenue
                    ]
                  : [
                      const Color(0xFF0F172A), // Blu scuro profondo
                      const Color(0xFF1E293B), // Blu scuro medio
                      const Color(0xFF334155), // Grigio-blu
                    ],
            ),
          ),
          child: SafeArea(
            // Assicurati che il contenuto non venga coperto dai controlli di sistema
            top: true, // Evita la notch/status bar
            bottom: true, // Evita i tasti di navigazione Android
            left: true, // Evita i bordi laterali
            right: true, // Evita i bordi laterali
            child: Padding(
              // Padding aggiuntivo per i tasti di navigazione Android
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewPadding.bottom > 0
                    ? 8.0 // Padding extra se ci sono controlli di sistema
                    : 0.0,
              ),
              child: CustomScrollView(
                slivers: [
                  // Modern App Bar
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    actions: [],
                    flexibleSpace: FlexibleSpaceBar(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(
                                0.15,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.3,
                                ),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.1,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/icon/app_icon.png',
                                width: 28,
                                height: 28,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            localizations.appTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      centerTitle: true,
                    ),
                  ),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Status Info Card (solo se sta registrando)
                        if (_isListening)
                          _buildRecordingStatusCard(theme, localizations),
                        if (_isListening) const SizedBox(height: 16),

                        // Dream Input Area (stile WhatsApp)
                        _buildDreamInputArea(theme, localizations),
                        const SizedBox(height: 16),

                        // Bottoni principali (sempre visibili)
                        _buildMainActionButtons(theme, localizations),
                        const SizedBox(height: 16),

                        // Quick Action Buttons (solo se c'è testo)
                        _buildQuickActionButtons(theme, localizations),
                        const SizedBox(height: 24),

                        // Interpretation Card
                        if (_interpretation.isNotEmpty)
                          _buildInterpretationCard(theme, localizations),
                        if (_interpretation.isNotEmpty)
                          const SizedBox(height: 24),

                        // Dream Image Card
                        if (_imageUrl.isNotEmpty)
                          _buildDreamImageCard(theme, localizations),
                      ]),
                    ),
                  ),
                ],
              ), // Chiusura CustomScrollView
            ), // Chiusura Padding
          ), // Chiusura SafeArea
        ), // Chiusura Container e GestureDetector
      ), // Chiusura body
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(
            right: 1,
            bottom: 5,
          ), // Molto vicino al bordo inferiore
          child: _buildFloatingActionMenu(theme, localizations),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      resizeToAvoidBottomInset:
          false, // Evita che il floating menu si muova con la tastiera
    );
  }

  // Floating Action Menu per accesso rapido a funzioni secondarie
  Widget _buildFloatingActionMenu(
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return SafeArea(
      left: false, // Permette di andare verso il bordo sinistro
      top: false, // Permette di andare verso l'alto
      right: false, // Permette di andare verso il bordo destro
      child: Padding(
        padding: const EdgeInsets.only(right: 8), // Minimo spazio dal bordo
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Analytics (cambiato colore)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: "analytics",
                mini: true,
                backgroundColor: const Color(0xFF0EA5E9), // Azzurro cielo
                foregroundColor: Colors.white,
                elevation: 0,
                onPressed: () {
                  // Rimuovi focus per evitare che la tastiera si riapra
                  _textFieldFocusNode.unfocus();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DreamAnalyticsPage(),
                    ),
                  );
                },
                child: const Icon(Icons.analytics_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 12),

            // History
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: "history",
                mini: true,
                backgroundColor: const Color(0xFF8B5CF6), // Viola
                foregroundColor: Colors.white,
                elevation: 0,
                onPressed: () {
                  // Rimuovi focus per evitare che la tastiera si riapra
                  _textFieldFocusNode.unfocus();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DreamHistoryPage(),
                    ),
                  );
                },
                child: const Icon(Icons.history_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            // Menu principale (più grande e più visibile)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.brightness == Brightness.light
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: "main_menu",
                mini: true, // Stessa dimensione degli altri
                backgroundColor: theme.brightness == Brightness.light
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                onPressed: () {
                  _showOptionsBottomSheet(context, theme, localizations);
                },
                child: const Icon(Icons.more_vert_rounded, size: 28),
              ),
            ),
          ],
        ), // Chiusura Column
      ), // Chiusura Padding
    ); // Chiusura SafeArea
  }

  // Bottom Sheet con tutte le opzioni
  void _showOptionsBottomSheet(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(
            bottom: 16,
          ), // Spazio extra per tasti Android
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Language
              _buildOptionTile(
                theme,
                localizations.language,
                Icons.language_rounded,
                () {
                  Navigator.pop(context);
                  // Rimuovi focus per evitare che la tastiera si riapra
                  _textFieldFocusNode.unfocus();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LanguageSelectionPage(
                        languageService: widget.languageService,
                      ),
                    ),
                  );
                },
              ),

              // Settings
              _buildOptionTile(
                theme,
                localizations.settings,
                Icons.settings_rounded,
                () {
                  Navigator.pop(context);
                  // Rimuovi focus per evitare che la tastiera si riapra
                  _textFieldFocusNode.unfocus();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          SettingsPage(themeService: widget.themeService),
                    ),
                  );
                },
              ),
            ],
          ),
        ), // Chiusura Container
      ), // Chiusura SafeArea
    );
  }

  // Helper per creare tile delle opzioni
  Widget _buildOptionTile(
    ThemeData theme,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }

  // Widget per status di registrazione (minimalista)
  Widget _buildRecordingStatusCard(
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.mic, color: const Color(0xFFEF4444), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              localizations.recording,
              style: TextStyle(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            localizations.speakFreely,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Widget principale di input stile WhatsApp
  Widget _buildDreamInputArea(ThemeData theme, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Campo di testo
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 40, maxHeight: 120),
              child: TextField(
                controller: _textController,
                focusNode:
                    _textFieldFocusNode, // Controllo focus personalizzato
                maxLines: null,
                autofocus:
                    false, // Evita che si apra automaticamente la tastiera
                textInputAction: TextInputAction.newline,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: localizations.writeDreamHere,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                onChanged: (text) {
                  setState(() {
                    _transcription = text;
                    _showingAdvice =
                        true; // Torna a mostrare gli advice quando si modifica il testo
                    _updateInterpretationAdvice(); // Aggiorna il messaggio di consiglio
                  });
                },
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Pulsante microfono/stop
          GestureDetector(
            onTap: _listen,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isListening
                      ? [const Color(0xFFEF4444), const Color(0xFFF97316)]
                      : [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        (_isListening
                                ? const Color(0xFFEF4444)
                                : theme.colorScheme.primary)
                            .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Pulsante cestino (solo se c'è testo e non sta registrando)
          if (_transcription.trim().isNotEmpty && !_isListening)
            GestureDetector(
              onTap: () => _showDeleteConfirmDialog(context, localizations),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Bottoni principali sempre visibili
  Widget _buildMainActionButtons(
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return Column(
      children: [
        // Pulsante principale: INTERPRETA SOGNO (sempre visibile ma disabilitato se no testo)
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isTextValidForInterpretation()
                  ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
                  : [Colors.grey.shade400, Colors.grey.shade500],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color:
                    (_isTextValidForInterpretation()
                            ? const Color(0xFF667EEA)
                            : Colors.grey.shade400)
                        .withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
                spreadRadius: 2,
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _isTextValidForInterpretation() ? _processDream : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 28,
            ),
            label: Text(
              localizations.interpretWithAI,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Riga secondaria: Community (sempre visibile) + Cancella (solo se c'è testo)
        Row(
          children: [
            // Community (sempre visibile)
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Rimuovi focus per evitare che la tastiera si riapra
                    _textFieldFocusNode.unfocus();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ImprovedCommunityPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.people_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    localizations.community,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Pulsanti di azione rapida (solo quando c'è testo)
  Widget _buildQuickActionButtons(
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    // Se non c'è testo, non mostrare nulla
    if (_transcription.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // Non mostriamo più nulla qui dato che il cestino è nell'input area
    return const SizedBox.shrink();
  }

  Widget _buildInterpretationCard(
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return Card(
      elevation: 8,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade600,
                          Colors.indigo.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      localizations.dreamInterpretationTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _interpretation,
                  style: const TextStyle(fontSize: 16, height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDreamImageCard(ThemeData theme, AppLocalizations localizations) {
    return Card(
      elevation: 8,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.tertiary.withOpacity(0.05),
              theme.colorScheme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade600, Colors.cyan.shade600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.image_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      localizations.dreamImageTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _imageUrl,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(localizations.loadingImage),
                            ],
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported_rounded,
                              size: 48,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              localizations.cannotLoadImage,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              localizations.tryAgainLater,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
