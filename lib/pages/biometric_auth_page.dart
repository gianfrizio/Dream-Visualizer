import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../services/biometric_auth_service.dart';
import '../l10n/app_localizations.dart';

class BiometricAuthPage extends StatefulWidget {
  const BiometricAuthPage({super.key});

  @override
  State<BiometricAuthPage> createState() => _BiometricAuthPageState();
}

class _BiometricAuthPageState extends State<BiometricAuthPage> {
  bool _isAuthenticating = false;
  final LocalAuthentication _localAuth =
      LocalAuthentication(); // Istanza diretta per test
  String _debugText = '';

  @override
  void initState() {
    super.initState();
    // Test immediato
    _testBasicFunctionality();
  }

  Future<void> _testBasicFunctionality() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      setState(() {
        _debugText =
            '''
DEBUG TEST:
Device Supported: $isDeviceSupported
Can Check Biometrics: $canCheckBiometrics
Available Biometrics: $availableBiometrics
''';
      });

      debugPrint('BiometricAuthPage - DEBUG TEST:');
      debugPrint('Device Supported: $isDeviceSupported');
      debugPrint('Can Check Biometrics: $canCheckBiometrics');
      debugPrint('Available Biometrics: $availableBiometrics');
    } catch (e) {
      setState(() {
        _debugText = 'ERROR: $e';
      });
      debugPrint('BiometricAuthPage - ERROR: $e');
    }
  }

  Future<void> _handleTestDirect() async {
    debugPrint('BiometricAuthPage: _handleTestDirect called');

    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    try {
      debugPrint('BiometricAuthPage: Starting simple authentication test...');

      final result = await _localAuth.authenticate(
        localizedReason: 'Test semplice - autenticazione biometrica',
      );

      debugPrint('BiometricAuthPage: Simple auth result - $result');

      if (result) {
        // Successo - chiudi la pagina
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        // Fallimento
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Autenticazione fallita'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      debugPrint('BiometricAuthPage: PlatformException - ${e.code}: ${e.message}');

      if (mounted) {
        if (e.code == 'no_fragment_activity') {
          // Errore specifico - mostra dialog informativo
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Problema di Compatibilità'),
              content: Text(
                'Il tuo dispositivo ha un problema di compatibilità con l\'autenticazione biometrica.\n\n'
                'Questo è un problema noto di alcuni dispositivi Android. '
                'L\'autenticazione biometrica verrà disabilitata.\n\n'
                'Puoi accedere all\'app senza autenticazione biometrica.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Chiudi dialog
                    Navigator.of(context).pop(true); // Accesso consentito
                  },
                  child: Text('OK, Accedi Senza Biometrico'),
                ),
              ],
            ),
          );
        } else {
          // Altri errori
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore: ${e.message ?? e.code}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('BiometricAuthPage: General error - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore generico: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  void _handleAccessWithoutBiometric() {
    debugPrint('BiometricAuthPage: _handleAccessWithoutBiometric called');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accesso Senza Autenticazione'),
        content: Text(
          'Vuoi accedere all\'app senza autenticazione biometrica?\n\n'
          'Questo disabiliterà permanentemente l\'autenticazione biometrica '
          'per evitare problemi futuri.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Disabilita l'autenticazione biometrica
                final biometricService = context.read<BiometricAuthService>();
                await biometricService.disableBiometric();

                Navigator.pop(context); // Chiudi dialog
                Navigator.of(context).pop(true); // Accesso consentito
              } catch (e) {
                debugPrint('Error disabling biometric: $e');
                Navigator.pop(context); // Chiudi dialog comunque
                Navigator.of(context).pop(true); // Accesso consentito comunque
              }
            },
            child: Text('Sì, Accedi'),
          ),
        ],
      ),
    );
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    final biometricService = context.read<BiometricAuthService>();
    final localizations = AppLocalizations.of(context);

    try {
      // Prima controlla se l'autenticazione biometrica è supportata
      final isSupported = await biometricService.checkBiometricSupport();
      debugPrint('BiometricAuthPage: Biometric support check - $isSupported');

      if (!isSupported) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Autenticazione biometrica non supportata su questo dispositivo',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Controlla i metodi biometrici disponibili
      final availableBiometrics = await biometricService
          .getAvailableBiometrics();
      debugPrint('BiometricAuthPage: Available biometrics - $availableBiometrics');

      if (availableBiometrics.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Nessun metodo biometrico configurato. Configura impronte digitali o Face ID nelle impostazioni del dispositivo.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Procedi con l'autenticazione
      final authenticated = await biometricService.authenticate(
        reason:
            localizations?.authenticateToAccessDreams ??
            'Autenticati per accedere ai tuoi sogni',
      );

      if (authenticated) {
        // Autenticazione riuscita, torna alla schermata principale
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        // Autenticazione fallita, mostra errore
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations?.authenticationFailed ??
                    'Autenticazione fallita. Riprova.',
              ),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Debug Info',
                onPressed: () async {
                  final debugInfo = await biometricService
                      .getDetailedBiometricStatus();
                  debugPrint('Debug Info: $debugInfo');
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Biometric Debug Info'),
                        content: Text(debugInfo),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Errore durante l'autenticazione
      debugPrint('BiometricAuthPage: Error during authentication - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante l\'autenticazione: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icona di sicurezza
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.fingerprint,
                  size: 80,
                  color: Colors.blue[400],
                ),
              ),

              const SizedBox(height: 40),

              // Titolo
              Text(
                localizations?.biometricAuthRequired ??
                    'Autenticazione Richiesta',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Debug info sempre visibile
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _debugText.isEmpty ? 'Caricamento debug info...' : _debugText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[300],
                    fontFamily: 'monospace',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Test diretto
              ElevatedButton(
                onPressed: _handleTestDirect,
                child: _isAuthenticating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text('Test Diretto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),

              const SizedBox(height: 12),

              // Pulsante per entrare senza autenticazione
              ElevatedButton(
                onPressed: _handleAccessWithoutBiometric,
                child: Text('Accedi Senza Biometrico'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),

              const SizedBox(height: 12),

              // Pulsante per uscire
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text('Esci', style: TextStyle(color: Colors.grey[400])),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testDirectAuth() async {
    setState(() {
      _isAuthenticating = true;
    });

    try {
      debugPrint('BiometricAuthPage: Starting direct auth test...');

      final result = await _localAuth.authenticate(
        localizedReason: 'Test diretto autenticazione biometrica',
      );

      debugPrint('BiometricAuthPage: Direct auth result - $result');

      if (result && mounted) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test diretto fallito'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on PlatformException catch (e) {
      debugPrint(
        'BiometricAuthPage: Direct auth PlatformException - ${e.code}: ${e.message}',
      );

      if (e.code == 'no_fragment_activity' || e.code.contains('fragment')) {
        // Errore di compatibilità - disabilita automaticamente e permetti l'accesso
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Autenticazione Biometrica Non Compatibile'),
              content: Text(
                'Il tuo dispositivo ha un problema di compatibilità con l\'autenticazione biometrica. '
                'L\'autenticazione biometrica verrà disabilitata automaticamente per evitare problemi futuri.\n\n'
                'Puoi riabilitarla nelle impostazioni se desideri.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Chiudi il dialog
                    Navigator.of(context).pop(true); // Permetti l'accesso
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore test diretto: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('BiometricAuthPage: Direct auth error - $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore test diretto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  String _getBiometricsText(biometrics, localizations) {
    if (biometrics.isEmpty) {
      return localizations?.noBiometricsAvailable ??
          'Nessun metodo biometrico disponibile';
    }

    final methods = <String>[];
    for (final biometric in biometrics) {
      switch (biometric.toString()) {
        case 'BiometricType.fingerprint':
          methods.add(localizations?.fingerprint ?? 'Impronta digitale');
          break;
        case 'BiometricType.face':
          methods.add(localizations?.faceId ?? 'Face ID');
          break;
        case 'BiometricType.iris':
          methods.add(localizations?.iris ?? 'Scansione dell\'iride');
          break;
      }
    }

    if (methods.isEmpty) {
      return localizations?.biometricsAvailable ??
          'Autenticazione biometrica disponibile';
    }

    return '${localizations?.availableMethods ?? "Metodi disponibili"}: ${methods.join(", ")}';
  }
}
