import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleBiometricTestPage extends StatefulWidget {
  const SimpleBiometricTestPage({super.key});

  @override
  State<SimpleBiometricTestPage> createState() =>
      _SimpleBiometricTestPageState();
}

class _SimpleBiometricTestPageState extends State<SimpleBiometricTestPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLoading = false;
  String _statusMessage = 'Rilevamento automatico errore...';

  @override
  void initState() {
    super.initState();
    // Avvia automaticamente il test quando la pagina si apre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: Text('Test Biometrico'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Rimuove il pulsante indietro
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fingerprint, size: 80, color: Colors.blue[400]),

            const SizedBox(height: 40),

            Text(
              _statusMessage,
              style: TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            if (_isLoading)
              CircularProgressIndicator(color: Colors.blue)
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _testAuth,
                    child: Text('Riprova Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _disableAndExit,
                    child: Text('Disabilita Biometrico e Accedi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => SystemNavigator.pop(),
                    child: Text(
                      'Esci dall\'App',
                      style: TextStyle(color: Colors.red[400]),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testAuth() async {
    debugPrint('SimpleBiometricTestPage: _testAuth chiamato');

    setState(() {
      _isLoading = true;
      _statusMessage = 'Test in corso...';
    });

    try {
      final result = await _localAuth.authenticate(
        localizedReason: 'Test autenticazione biometrica',
      );

      debugPrint('SimpleBiometricTestPage: Risultato autenticazione - $result');

      if (result) {
        setState(() {
          _statusMessage = 'Autenticazione riuscita! Accesso consentito.';
        });

        await Future.delayed(Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _statusMessage =
              'Autenticazione fallita. Riprova o disabilita il biometrico.';
        });
      }
    } on PlatformException catch (e) {
      debugPrint(
        'SimpleBiometricTestPage: PlatformException - ${e.code}: ${e.message}',
      );

      if (e.code == 'no_fragment_activity') {
        setState(() {
          _statusMessage =
              '''ERRORE DI COMPATIBILITÀ RILEVATO

Il tuo dispositivo ha un problema noto con l'autenticazione biometrica (errore: ${e.code}).

Questo è un bug del plugin local_auth su alcuni dispositivi Android.

SOLUZIONE: Disabilita l'autenticazione biometrica cliccando il pulsante arancione sotto.''';
        });
      } else {
        setState(() {
          _statusMessage =
              'Errore: ${e.code}\n${e.message ?? "Errore sconosciuto"}';
        });
      }
    } catch (e) {
      debugPrint('SimpleBiometricTestPage: Errore generico - $e');
      setState(() {
        _statusMessage = 'Errore generico: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _disableAndExit() async {
    debugPrint('SimpleBiometricTestPage: _disableAndExit chiamato');

    setState(() {
      _isLoading = true;
      _statusMessage = 'Disabilitazione autenticazione biometrica...';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', false);

      setState(() {
        _statusMessage =
            'Autenticazione biometrica disabilitata. Accesso consentito.';
      });

      await Future.delayed(Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Errore durante disabilitazione: $e');
      // Anche se c'è un errore, permetti l'accesso
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }
}
