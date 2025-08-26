import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:math';
import 'dart:async';
import 'services/language_service.dart';
import 'services/theme_service.dart';
import 'services/biometric_auth_service.dart';
import 'services/encryption_service.dart';
import 'pages/dream_interpretation_page.dart';
import 'pages/simple_biometric_test_page_new.dart';
import 'l10n/app_localizations.dart';
import 'services/notification_service.dart';
import 'widgets/starry_background.dart';
import 'widgets/global_bottom_menu.dart';

// Temporary global notifier used for debugging touch events on-device.
// Set to an Offset when a pointer down occurs and cleared shortly after.
final ValueNotifier<Offset?> _touchNotifier = ValueNotifier<Offset?>(null);

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
  // Initialize notifications
  await NotificationService().init();
  // Note: For Android 13+ you must request POST_NOTIFICATIONS at runtime.
  // We avoid a global request here; during testing you can call
  // `permission_handler` to request the permission from the first screen.

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
  // Keep a persistent navigator key and route observer at the widget level
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  DreamApp({
    super.key,
    required this.languageService,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    // Use class-level navigatorKey and routeObserver so they persist across rebuilds
    final _navigatorKey = navigatorKey;
    final _routeObserver = routeObserver;

    return AnimatedBuilder(
      animation: Listenable.merge([languageService, themeService]),
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          navigatorObservers: [_routeObserver],
          title: 'Dreamsy',
          debugShowCheckedModeBanner: false,
          // Inject a global star layer as a subtle overlay so stars are visible
          // even when pages draw full-bleed backgrounds. Use IgnorePointer so
          // interactions are unaffected and adjust opacity by theme.
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            // On light backgrounds we need a stronger star overlay so stars
            // remain visible; increase opacity for light theme only.
            // Raised to make stars more prominent on pale backgrounds.
            final overlayOpacity = isDark ? 0.14 : 0.45;

            // Allow content to extend under the global bottom menu.
            // We intentionally do not add extra bottom padding here so full-
            // bleed backgrounds remain continuous up to the bottom edge.

            return Stack(
              children: [
                if (child != null)
                  // Allow the app content (including full-bleed gradients) to
                  // extend under the global bottom menu. The menu will be
                  // rendered on top and should be transparent or semi-transparent
                  // so no hard seam appears. Individual pages should still
                  // respect SafeArea / viewInsets for interactive controls.
                  Positioned.fill(child: child),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: overlayOpacity,
                      child: StarryBackground(),
                    ),
                  ),
                ),
                // Global bottom menu overlay: let the menu size itself and sit above
                // system insets. Use SafeArea(top: false) so it respects the bottom
                // inset (navigation bar) and isn't clipped by a hard height.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (ev) {
                      // Debug: log pointer events that hit the overlay container
                      print('Overlay Listener: pointer down at ${ev.position}');

                      // Update the global touch notifier so a visual indicator
                      // can be shown on-device. Clear it after a short delay.
                      try {
                        _touchNotifier.value = ev.position;
                        Future.delayed(const Duration(milliseconds: 600), () {
                          if (_touchNotifier.value == ev.position) {
                            _touchNotifier.value = null;
                          }
                        });
                      } catch (_) {}
                    },
                    child: Container(
                      // Transparent container wrapping the global menu. Top
                      // border removed to avoid a thin visible separator on some devices.
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: SafeArea(
                          top: false,
                          child: GlobalBottomMenu(
                            navigatorKey: _navigatorKey,
                            routeObserver: _routeObserver,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // NOTE: visual touch indicator removed for production. Listener still logs pointer events.
              ],
            );
          },
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

class _DreamHomePageState extends State<DreamHomePage>
    with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
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
    WidgetsBinding.instance.addObserver(this);
    _initSpeech();
    _checkBiometricAuth();
    // Ask for notification permissions on first run (non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _askNotificationPermissionIfFirstRun();
    });
  }

  static const String _kNotifiedPromptKey = 'notified_prompt_shown_v1';

  Future<void> _askNotificationPermissionIfFirstRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final already = prefs.getBool(_kNotifiedPromptKey) ?? false;
      if (already) return;

      // Show a simple dialog asking the user to enable notifications
      if (!mounted) return;
      final localizations = AppLocalizations.of(context);
      final result = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(
            localizations?.enableNotificationsTitle ?? 'Enable notifications',
          ),
          content: Text(
            localizations?.enableNotificationsMessage ??
                'Enable notifications to be informed when your dream image is ready and other updates.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: Text(localizations?.enableNotificationsLater ?? 'Later'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: Text(
                localizations?.enableNotificationsNow ?? 'Enable now',
              ),
            ),
          ],
        ),
      );

      if (result == true) {
        final granted = await NotificationService().requestPermissions();
        // Optionally show a small confirmation
        if (granted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations?.notificationEnabledConfirmation ??
                    'Notifications enabled',
              ),
            ),
          );
        }
      }

      await prefs.setBool(_kNotifiedPromptKey, true);
    } catch (e) {
      print('Error showing notification prompt: $e');
    }
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
    WidgetsBinding.instance.removeObserver(this);
    _textFieldFocusNode.dispose(); // Cleanup del FocusNode
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // Ensure we stop recording when the app is backgrounded or otherwise not active
      _stopListeningAction();
    }
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
        // Haptic feedback + play start sound (synthesized, improved)
        await HapticFeedback.lightImpact();
        // Start beep and give it a short moment to play before starting the microphone.
        // If speech recognition starts immediately it can cut the audio output on some devices.
        _playStartBeep();
        await Future.delayed(const Duration(milliseconds: 140));
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
      // Stop listening using shared helper (includes haptic)
      await _stopListeningAction();
    }
  }

  // Shared helper to stop listening safely (used from lifecycle and navigation)
  Future<void> _stopListeningAction() async {
    if (!_isListening) return;
    try {
      // Provide tactile feedback for stop
      await HapticFeedback.mediumImpact();
    } catch (_) {}
    setState(() {
      _isListening = false;
      _updateInterpretationAdvice();
    });
    _confirmedText = _transcription.trim(); // Confirm all text
    _stopWatchdog();
    try {
      await _speech.stop();
    } catch (_) {}
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

  // --- Audio helper: synthesize simple beep WAV in memory and play ---
  Future<void> _playBeep({
    double freq = 1000,
    int ms = 120,
    double volume = 0.7,
  }) async {
    final sampleRate = 22050;
    final samples = (sampleRate * ms / 1000).round();
    final bytes = BytesBuilder();

    // WAV header (PCM 16-bit mono)
    int byteRate = sampleRate * 2;
    bytes.add(_stringToBytes('RIFF'));
    bytes.add(_intToBytesLE(36 + samples * 2, 4));
    bytes.add(_stringToBytes('WAVE'));
    bytes.add(_stringToBytes('fmt '));
    bytes.add(_intToBytesLE(16, 4)); // Subchunk1Size
    bytes.add(_intToBytesLE(1, 2)); // PCM
    bytes.add(_intToBytesLE(1, 2)); // Mono
    bytes.add(_intToBytesLE(sampleRate, 4));
    bytes.add(_intToBytesLE(byteRate, 4));
    bytes.add(_intToBytesLE(2, 2)); // BlockAlign
    bytes.add(_intToBytesLE(16, 2)); // BitsPerSample
    bytes.add(_stringToBytes('data'));
    bytes.add(_intToBytesLE(samples * 2, 4));

    final rnd = Random();
    // ADSR envelope params (fractions of duration)
    final attack = max(1, (0.02 * samples).round());
    final decay = max(1, (0.05 * samples).round());
    final release = max(1, (0.08 * samples).round());
    final sustain = max(0, samples - attack - decay - release);
    final sustainLevel = 0.7;

    for (int i = 0; i < samples; i++) {
      final t = i / sampleRate;

      // Envelope
      double env;
      if (i < attack) {
        env = i / attack;
      } else if (i < attack + decay) {
        env = 1 - (1 - sustainLevel) * ((i - attack) / decay);
      } else if (i < attack + decay + sustain) {
        env = sustainLevel;
      } else {
        env = sustainLevel * (1 - ((i - (attack + decay + sustain)) / release));
      }

      // Harmonic content
      final fundamental = sin(2 * pi * freq * t);
      final second = 0.45 * sin(2 * pi * freq * 2 * t);
      final sub = 0.12 * sin(2 * pi * (freq / 2) * t);

      // Transient noise for attack
      final noise = (i < attack) ? (rnd.nextDouble() * 2 - 1) * 0.12 : 0.0;

      final sampleVal = (fundamental + second + sub) * env + noise * env;
      final value = (sampleVal * volume * 32767).clamp(-32767, 32767).toInt();
      bytes.add(_intToBytesLE(value, 2));
    }

    final data = bytes.toBytes();
    try {
      await _audioPlayer.play(BytesSource(Uint8List.fromList(data)));
    } catch (e) {
      // fallback: do nothing
      print('Errore riproduzione beep: $e');
    }
  }

  Future<void> _playStartBeep() async {
    await _playBeep(freq: 1100, ms: 90, volume: 0.001);
  }

  List<int> _stringToBytes(String s) => s.codeUnits;

  List<int> _intToBytesLE(int value, int bytes) {
    final out = <int>[];
    for (int i = 0; i < bytes; i++) {
      out.add((value >> (8 * i)) & 0xFF);
    }
    return out;
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
                          fontSize: 48,
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
                        // (RIMOSSO) Status Info Card durante la registrazione

                        // Dream Input Area (stile WhatsApp)
                        _buildDreamInputArea(theme, localizations),
                        const SizedBox(height: 20),

                        // Bottoni principali (sempre visibili)
                        _buildMainActionButtons(theme, localizations),

                        // Spacing between action buttons and the suggestions box
                        const SizedBox(height: 16),

                        // Suggestion box placed directly below the main action
                        // buttons (no Expanded). We remove bottom view insets so
                        // the card doesn't move when the keyboard opens, and add
                        // a small fixed bottom padding to keep distance from the
                        // global menu.
                        MediaQuery.removeViewInsets(
                          context: context,
                          removeBottom: true,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _interpretation.isNotEmpty
                                  ? _buildInterpretationCard(
                                      theme,
                                      localizations,
                                    )
                                  : const SizedBox.shrink(),
                            ),
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
      resizeToAvoidBottomInset:
          false, // Evita che il menu si muova con la tastiera
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
                ? () async {
                    // Ensure recording is stopped before navigating
                    _textFieldFocusNode.unfocus();
                    await _stopListeningAction();
                    // Naviga alla pagina di interpretazione
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DreamInterpretationPage(
                          dreamText: _transcription,
                          languageService: widget.languageService,
                        ),
                      ),
                    );
                    // Quando si torna indietro, svuota il campo testo, chiudi la tastiera e aggiorna i suggerimenti
                    setState(() {
                      _textController.clear();
                      _transcription = '';
                      _showingAdvice = true;
                      _updateInterpretationAdvice();
                    });
                    _textFieldFocusNode.unfocus();
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
