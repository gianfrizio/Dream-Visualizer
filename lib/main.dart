import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'openai_service.dart';
import 'models/saved_dream.dart';
import 'services/dream_storage_service.dart';
import 'services/language_service.dart';
import 'services/theme_service.dart';
import 'services/image_cache_service.dart';
import 'services/biometric_auth_service.dart';
import 'services/encryption_service.dart';
import 'services/auth_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/community_service.dart';
import 'pages/dream_history_page.dart';
import 'pages/settings_page.dart';
import 'pages/dream_analytics_page.dart';
import 'pages/biometric_auth_page.dart';
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
  String _interpretation = '';
  String _imageUrl = '';
  final OpenAIService _openAI = OpenAIService();
  final DreamStorageService _storageService = DreamStorageService();
  final ImageCacheService _imageCacheService = ImageCacheService();
  final TextEditingController _textController = TextEditingController();
  bool _isEditingText = false;
  String _confirmedText = '';
  Timer? _watchdogTimer;
  String _lastKnownText = '';
  int _noChangeCount = 0;
  bool _speechAvailable = false; // New: tracks speech availability
  DateTime _lastUpdateTime = DateTime.now(); // New: tracks last update

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    _checkBiometricAuth();
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
      setState(() => _isListening = false);
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

          if (!_isEditingText) {
            _textController.text = _transcription;
          }
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
      if (_isListening && !_isEditingText) {
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
    if (_isListening && !_isEditingText && _speechAvailable) {
      _lastUpdateTime = DateTime.now();
      _startListening();
    }
  }

  void _continueListening() async {
    if (!_isListening) {
      // Save existing text as confirmed only if it hasn't been saved already
      String tempText = _transcription.trim();
      if (tempText.isNotEmpty && tempText != _confirmedText) {
        if (tempText.endsWith(' ')) {
          _confirmedText = tempText;
        } else {
          _confirmedText = tempText + ' ';
        }
      }

      _lastKnownText = '';
      _noChangeCount = 0;
      _lastUpdateTime = DateTime.now();

      if (!_speechAvailable) {
        _speechAvailable = await _speech.initialize();
      }

      if (_speechAvailable) {
        setState(() => _isListening = true);
        _startWatchdog();
        _startListening();
      }
    }
  }

  void _startTextEditing() {
    setState(() {
      _isEditingText = true;
      _textController.text = _transcription;
    });
  }

  void _saveTextEditing() {
    setState(() {
      _isEditingText = false;
      _transcription = _textController.text;
    });
  }

  void _cancelTextEditing() {
    setState(() {
      _isEditingText = false;
      _textController.text = _transcription;
    });
  }

  void _processDream() async {
    final localizations = AppLocalizations.of(context)!;

    if (_transcription.isEmpty) {
      setState(() {
        _interpretation = localizations.noDreamRecorded;
      });
      return;
    }

    setState(() {
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
      body: Container(
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
          child: CustomScrollView(
            slivers: [
              // Modern App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                actions: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DreamHistoryPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    tooltip: localizations.history,
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'history':
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const DreamHistoryPage(),
                            ),
                          );
                          break;
                        case 'analytics':
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const DreamAnalyticsPage(),
                            ),
                          );
                          break;
                        case 'community':
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ImprovedCommunityPage(),
                            ),
                          );
                          break;
                        case 'language':
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => LanguageSelectionPage(
                                languageService: widget.languageService,
                              ),
                            ),
                          );
                          break;
                        case 'settings':
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SettingsPage(
                                themeService: widget.themeService,
                              ),
                            ),
                          );
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'history',
                        child: Row(
                          children: [
                            const Icon(Icons.history),
                            const SizedBox(width: 8),
                            Text(localizations.history),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'analytics',
                        child: Row(
                          children: [
                            const Icon(Icons.analytics),
                            const SizedBox(width: 8),
                            Text(localizations.analytics),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'community',
                        child: Row(
                          children: [
                            const Icon(Icons.people),
                            const SizedBox(width: 8),
                            Text(localizations.community),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'language',
                        child: Row(
                          children: [
                            const Icon(Icons.language),
                            const SizedBox(width: 8),
                            Text(localizations.language),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            const Icon(Icons.settings),
                            const SizedBox(width: 8),
                            Text(localizations.settings),
                          ],
                        ),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.1),
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
                    // Voice Recording Card
                    _buildVoiceRecordingCard(theme, localizations),
                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(theme, localizations),
                    const SizedBox(height: 24),

                    // AI Analysis Buttons
                    _buildAnalysisButtons(theme, localizations),
                    const SizedBox(height: 24),

                    // Interpretation Card
                    if (_interpretation.isNotEmpty)
                      _buildInterpretationCard(theme, localizations),
                    if (_interpretation.isNotEmpty) const SizedBox(height: 24),

                    // Dream Image Card
                    if (_imageUrl.isNotEmpty)
                      _buildDreamImageCard(theme, localizations),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceRecordingCard(
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: _isListening
              ? LinearGradient(
                  colors: [
                    const Color(0xFFEF4444),
                    const Color(0xFFF97316),
                  ], // Rosso-arancione per ascolto
                )
              : LinearGradient(
                  colors: [
                    const Color(0xFF6366F1),
                    const Color(0xFF667EEA),
                  ], // Incrocio tra primary e AI colors
                ),
          boxShadow: [
            BoxShadow(
              color: (_isListening
                  ? const Color(0xFFEF4444).withOpacity(0.25)
                  : const Color(0xFF6366F1).withOpacity(0.25)),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 1,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Status Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? const Color(
                              0xFF1E293B,
                            ) // Blu scuro elegante che si abbina al tema
                          : theme.colorScheme.primary,
                      border: _isListening
                          ? Border.all(
                              color: Colors.white.withOpacity(0.8),
                              width: 2,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_isListening
                                      ? const Color(0xFF1E293B)
                                      : theme.colorScheme.primary)
                                  .withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_off_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isListening
                            ? localizations.recording
                            : localizations.tapToRecord,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors
                              .white, // Testo bianco per il gradiente scuro
                        ),
                      ),
                      Text(
                        _isListening
                            ? localizations.speakFreely
                            : localizations.tapToStart,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(
                            0.9,
                          ), // Testo bianco trasparente
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Dream Text Area
              _isEditingText
                  ? Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: theme.colorScheme.surface,
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: TextField(
                            controller: _textController,
                            maxLines: null,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: localizations.writeDreamHere,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _saveTextEditing,
                                icon: const Icon(Icons.check_circle_outline),
                                label: Text(localizations.save),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _cancelTextEditing,
                                icon: const Icon(Icons.cancel_outlined),
                                label: Text(localizations.cancel),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: _startTextEditing,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: theme.brightness == Brightness.light
                                ? [
                                    const Color(
                                      0xFFF8FAFC,
                                    ), // Bianco-grigio molto chiaro
                                    const Color(
                                      0xFFF1F5F9,
                                    ), // Grigio più evidente
                                  ]
                                : [
                                    const Color(0xFF1E293B), // Grigio scuro
                                    const Color(
                                      0xFF334155,
                                    ), // Grigio più chiaro per il tema scuro
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(
                                0.08,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: theme.brightness == Brightness.light
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.black.withOpacity(0.3),
                              blurRadius: 1,
                              offset: const Offset(0, 1),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Text(
                          _transcription.isEmpty
                              ? localizations.tapToWriteDream
                              : _transcription,
                          style: TextStyle(
                            fontSize: 16,
                            color: _transcription.isNotEmpty
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),

              if (_isListening) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          localizations.continuousListening,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, AppLocalizations localizations) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isListening
                    ? [Colors.red, Colors.red.shade700]
                    : [theme.colorScheme.primary, theme.colorScheme.tertiary],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (_isListening ? Colors.red : theme.colorScheme.primary)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isEditingText ? null : _listen,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(
                _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                size: 24,
                color: Colors.white,
              ),
              label: Text(
                _isListening
                    ? localizations.stopRecording
                    : localizations.recordDream,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.9), Colors.grey.shade200],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: _isEditingText ? null : _startTextEditing,
            icon: Icon(
              Icons.edit_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
        ),
        if (_transcription.isNotEmpty && !_isListening) ...[
          const SizedBox(width: 12),
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _isListening = false;
                  _transcription = '';
                  _confirmedText = '';
                  _textController.clear();
                  _isEditingText = false;
                  _interpretation = '';
                  _imageUrl = '';
                });
                _stopWatchdog();
                _speech.stop();
              },
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnalysisButtons(
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return Column(
      children: [
        if (!_isListening && _transcription.isNotEmpty && !_isEditingText) ...[
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.green.shade700],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _continueListening,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(
                Icons.record_voice_over_rounded,
                size: 24,
                color: Colors.white,
              ),
              label: Text(
                localizations.continueTalking,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        Row(
          children: [
            Expanded(
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _processDream,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(
                    Icons.psychology_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: Text(
                    localizations.interpretWithAI,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.people, size: 20, color: Colors.white),
                  label: Text(
                    localizations.community,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
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
