import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleBiometricTestPage extends StatefulWidget {
  const SimpleBiometricTestPage({super.key});

  @override
  State<SimpleBiometricTestPage> createState() => _SimpleBiometricTestPageState();
}

class _SimpleBiometricTestPageState extends State<SimpleBiometricTestPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLoading = false;
  String _statusMessage = 'Pronto per il test';

  @override
  void initState() {
    super.initState();
    // Avvia automaticamente il test quando la pagina si apre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testAuth();
    });
  }
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: Text('Test Biometrico Semplice'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fingerprint,
              size: 80,
              color: Colors.blue[400],
            ),
            
            const SizedBox(height: 40),
            
            Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
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
                    child: Text('Test Autenticazione'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  ElevatedButton(
                    onPressed: _checkSupport,
                    child: Text('Verifica Supporto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  ElevatedButton(
                    onPressed: _disableAndExit,
                    child: Text('Disabilita e Accedi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Esci App',
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
    print('SimpleBiometricTestPage: _testAuth called');
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Test in corso...';
    });

    try {
      final result = await _localAuth.authenticate(
        localizedReason: 'Test autenticazione biometrica semplice',
      );
      
      print('SimpleBiometricTestPage: Auth result - $result');
      
      if (result) {
        setState(() {
          _statusMessage = 'Autenticazione riuscita!';
        });
        
        // Aspetta un po' e poi chiudi con successo
        await Future.delayed(Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _statusMessage = 'Autenticazione fallita';
        });
      }
    } on PlatformException catch (e) {
      print('SimpleBiometricTestPage: PlatformException - ${e.code}: ${e.message}');
      
      setState(() {
        _statusMessage = 'Errore: ${e.code}\n${e.message ?? ""}';
      });
      
      if (e.code == 'no_fragment_activity') {
        // Mostra dialog di errore dopo un delay
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            _showCompatibilityError();
          }
        });
      }
    } catch (e) {
      print('SimpleBiometricTestPage: General error - $e');
      setState(() {
        _statusMessage = 'Errore generico: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkSupport() async {
    print('SimpleBiometricTestPage: _checkSupport called');
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Verifica supporto...';
    });

    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      setState(() {
        _statusMessage = '''Supporto Dispositivo: $isDeviceSupported
Può Verificare: $canCheckBiometrics
Metodi Disponibili: $availableBiometrics''';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Errore verifica: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _disableAndExit() async {
    print('SimpleBiometricTestPage: _disableAndExit called');
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Disabilitazione...';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', false);
      
      setState(() {
        _statusMessage = 'Biometrico disabilitato';
      });
      
      await Future.delayed(Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error disabling: $e');
      // Anche se c'è un errore, permetti l'accesso
      if (mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCompatibilityError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Incompatibilità Rilevata'),
        content: Text(
          'Il tuo dispositivo ha un problema di compatibilità con l\'autenticazione biometrica.\n\n'
          'Questo è un bug noto del plugin local_auth su alcuni dispositivi Android.\n\n'
          'L\'autenticazione biometrica verrà disabilitata automaticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Chiudi dialog
              _disableAndExit(); // Disabilita e accedi
            },
            child: Text('OK, Disabilita'),
          ),
        ],
      ),
    );
  }
}
