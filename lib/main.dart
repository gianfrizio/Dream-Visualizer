import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import 'dart:async';
import 'services/language_service.dart';
import 'services/theme_service.dart';
import 'services/biometric_auth_service.dart';
import 'services/encryption_service.dart';
import 'pages/dream_history_page.dart';
import 'pages/settings_page.dart';
import 'pages/dream_analytics_page.dart';
import 'pages/dream_interpretation_page.dart';
import 'pages/simple_biometric_test_page_new.dart';
import 'pages/improved_community_page.dart';
import 'pages/profile_page.dart';
import 'l10n/app_localizations.dart';

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
          title: 'Dreamsy',
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
      true; // Indica se stiamo mostrando consigli o un'interpretazione reale
  String _imageUrl = '';
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
            child: Column(
              children: [
                // Header con titolo centrato
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Colors.purple.shade400,
                          Colors.indigo.shade400,
                          Colors.blue.shade400,
                          Colors.purple.shade300,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'Dreamsy',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2.0,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 3),
                              blurRadius: 6,
                              color: Colors.black.withOpacity(0.8),
                            ),
                            Shadow(
                              offset: const Offset(0, 0),
                              blurRadius: 12,
                              color: Colors.purple.withOpacity(0.6),
                            ),
                            Shadow(
                              offset: const Offset(2, 2),
                              blurRadius: 3,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Contenuto principale - Espandibile per riempire spazio disponibile
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      children: [
                        // Status Info Card (solo se sta registrando)
                        if (_isListening) ...[
                          _buildRecordingStatusCard(theme, localizations),
                          const SizedBox(height: 20),
                        ],

                        // Dream Input Area (stile WhatsApp)
                        _buildDreamInputArea(theme, localizations),
                        const SizedBox(height: 20),

                        // Bottoni principali (sempre visibili)
                        _buildMainActionButtons(theme, localizations),

                        // Spazio flessibile per centrare i suggerimenti
                        Expanded(
                          child: Center(
                            child: _interpretation.isNotEmpty
                                ? _buildInterpretationCard(theme, localizations)
                                : const SizedBox.shrink(),
                          ),
                        ),

                        // Dream Image Card (se presente)
                        if (_imageUrl.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildDreamImageCard(theme, localizations),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ), // Chiusura Container e GestureDetector
      ), // Chiusura body
      bottomNavigationBar: _buildBottomMenu(theme, localizations),
      resizeToAvoidBottomInset:
          false, // Evita che il menu si muova con la tastiera
    );
  }

  // Bottom Menu fisso integrato con lo sfondo
  Widget _buildBottomMenu(ThemeData theme, AppLocalizations localizations) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.surface.withOpacity(0.0),
            theme.colorScheme.surface.withOpacity(0.95),
            theme.colorScheme.surface,
          ],
        ),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Profilo
              Expanded(
                child: _buildBottomMenuItem(
                  icon: Icons.person_rounded,
                  label: localizations.profile,
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    _textFieldFocusNode.unfocus();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfilePage(themeService: widget.themeService),
                      ),
                    );
                  },
                  theme: theme,
                ),
              ),

              // Cronologia
              Expanded(
                child: _buildBottomMenuItem(
                  icon: Icons.history_rounded,
                  label: localizations.history,
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    _textFieldFocusNode.unfocus();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DreamHistoryPage(),
                      ),
                    );
                  },
                  theme: theme,
                ),
              ),

              // Community
              Expanded(
                child: _buildBottomMenuItem(
                  icon: Icons.people_rounded,
                  label: localizations.community,
                  color: const Color(0xFF10B981),
                  onTap: () {
                    _textFieldFocusNode.unfocus();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ImprovedCommunityPage(),
                      ),
                    );
                  },
                  theme: theme,
                ),
              ),

              // Analytics
              Expanded(
                child: _buildBottomMenuItem(
                  icon: Icons.analytics_rounded,
                  label: localizations.analytics,
                  color: const Color(0xFF0EA5E9),
                  onTap: () {
                    _textFieldFocusNode.unfocus();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DreamAnalyticsPage(),
                      ),
                    );
                  },
                  theme: theme,
                ),
              ),

              // Impostazioni
              Expanded(
                child: _buildBottomMenuItem(
                  icon: Icons.settings_rounded,
                  label: localizations.settings,
                  color: const Color(0xFF6B7280),
                  onTap: () {
                    _textFieldFocusNode.unfocus();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            SettingsPage(themeService: widget.themeService),
                      ),
                    );
                  },
                  theme: theme,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget per elementi secondari del menu
  Widget _buildBottomMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
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
            onPressed: _isTextValidForInterpretation()
                ? () {
                    // Naviga alla pagina di interpretazione
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DreamInterpretationPage(
                          dreamText: _transcription,
                          languageService: widget.languageService,
                        ),
                      ),
                    );
                  }
                : null,
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
      ],
    );
  }

  Widget _buildInterpretationCard(
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return Card(
      elevation: 6,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade600,
                          Colors.indigo.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      localizations.suggestions,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _interpretation,
                  style: const TextStyle(fontSize: 15, height: 1.6),
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
