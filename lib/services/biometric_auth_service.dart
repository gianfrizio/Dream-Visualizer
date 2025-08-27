import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuthService extends ChangeNotifier {
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastAuthTimeKey = 'last_auth_time';
  static const int _authValidityDuration = 300000; // 5 minuti in milliseconds

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isBiometricEnabled = false;
  bool _isAuthenticated = false;
  DateTime? _lastAuthTime;

  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAuthenticationRequired =>
      _isBiometricEnabled && !_isCurrentSessionValid();

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isBiometricEnabled = prefs.getBool(_biometricEnabledKey) ?? false;

    final lastAuthTimeMs = prefs.getInt(_lastAuthTimeKey);
    if (lastAuthTimeMs != null) {
      _lastAuthTime = DateTime.fromMillisecondsSinceEpoch(lastAuthTimeMs);
    }

    notifyListeners();
  }

  Future<bool> checkBiometricSupport() async {
    try {
      debugPrint('BiometricAuthService: Checking device support...');
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      debugPrint('BiometricAuthService: Device supported - $isDeviceSupported');

      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      debugPrint('BiometricAuthService: Can check biometrics - $canCheckBiometrics');

      final result = isDeviceSupported && canCheckBiometrics;
      debugPrint('BiometricAuthService: Final support result - $result');

      return result;
    } catch (e) {
      debugPrint('BiometricAuthService: Error checking biometric support: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  Future<bool> authenticate({String? reason}) async {
    debugPrint('BiometricAuthService: Starting authentication...');

    try {
      final isSupported = await checkBiometricSupport();
      debugPrint('BiometricAuthService: Biometric support check - $isSupported');

      if (!isSupported) {
        debugPrint('BiometricAuthService: Biometric not supported');
        return false;
      }

      final availableBiometrics = await getAvailableBiometrics();
      debugPrint(
        'BiometricAuthService: Available biometrics - $availableBiometrics',
      );

      if (availableBiometrics.isEmpty) {
        debugPrint('BiometricAuthService: No biometric methods available');
        return false;
      }

      debugPrint('BiometricAuthService: Calling _localAuth.authenticate...');
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason ?? 'Autenticati per accedere ai tuoi sogni',
        options: const AuthenticationOptions(
          biometricOnly: false, // Permette anche PIN/Pattern come fallback
          stickyAuth: false,
          sensitiveTransaction: false,
        ),
      );

      debugPrint('BiometricAuthService: Authentication result - $didAuthenticate');

      if (didAuthenticate) {
        _isAuthenticated = true;
        _lastAuthTime = DateTime.now();
        await _saveLastAuthTime();
        notifyListeners();
        debugPrint(
          'BiometricAuthService: Authentication successful, session updated',
        );
      }

      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint(
        'BiometricAuthService: PlatformException - ${e.code}: ${e.message}',
      );

      // Se si verifica l'errore no_fragment_activity, disabilita automaticamente l'autenticazione biometrica
      if (e.code == 'no_fragment_activity' || e.code.contains('fragment')) {
        debugPrint(
          'BiometricAuthService: Fragment activity error detected, disabling biometric auth',
        );
        await _handleFragmentActivityError();
        return true; // Permettiamo l'accesso senza biometrico
      }

      return false;
    } catch (e) {
      debugPrint('BiometricAuthService: General error - $e');
      return false;
    }
  }

  // Gestisce l'errore di fragment activity disabilitando automaticamente l'autenticazione biometrica
  Future<void> _handleFragmentActivityError() async {
    debugPrint(
      'BiometricAuthService: Handling fragment activity error by disabling biometric auth',
    );
    final prefs = await SharedPreferences.getInstance();

    // Disabilita l'autenticazione biometrica
    _isBiometricEnabled = false;
    await prefs.setBool(_biometricEnabledKey, false);

    // Marca come autenticato per questa sessione
    _isAuthenticated = true;
    _lastAuthTime = DateTime.now();
    await _saveLastAuthTime();

    notifyListeners();
  }

  Future<void> enableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    _isBiometricEnabled = true;
    await prefs.setBool(_biometricEnabledKey, true);
    notifyListeners();
  }

  Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    _isBiometricEnabled = false;
    _isAuthenticated = false;
    _lastAuthTime = null;
    await prefs.setBool(_biometricEnabledKey, false);
    await prefs.remove(_lastAuthTimeKey);
    notifyListeners();
  }

  bool _isCurrentSessionValid() {
    if (_lastAuthTime == null || !_isAuthenticated) {
      return false;
    }

    final now = DateTime.now();
    final timeDifference = now.difference(_lastAuthTime!).inMilliseconds;
    return timeDifference < _authValidityDuration;
  }

  Future<void> _saveLastAuthTime() async {
    if (_lastAuthTime != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _lastAuthTimeKey,
        _lastAuthTime!.millisecondsSinceEpoch,
      );
    }
  }

  void invalidateSession() {
    _isAuthenticated = false;
    _lastAuthTime = null;
    notifyListeners();
  }

  Future<bool> promptAuthentication({String? reason}) async {
    if (!_isBiometricEnabled) {
      return true; // Se non è abilitata, permetti l'accesso
    }

    if (_isCurrentSessionValid()) {
      return true; // Sessione già valida
    }

    return await authenticate(reason: reason);
  }

  String getBiometricStatusText() {
    if (!_isBiometricEnabled) {
      return 'Autenticazione biometrica disabilitata';
    }

    if (_isCurrentSessionValid()) {
      return 'Autenticato (sessione attiva)';
    }

    return 'Autenticazione richiesta';
  }

  Future<String> getDetailedBiometricStatus() async {
    final isSupported = await checkBiometricSupport();
    final availableBiometrics = await getAvailableBiometrics();
    final isDeviceSupported = await _localAuth.isDeviceSupported();
    final canCheckBiometrics = await _localAuth.canCheckBiometrics;

    return '''
Biometric Status Debug:
- Enabled: $_isBiometricEnabled
- Authenticated: $_isAuthenticated
- Session Valid: ${_isCurrentSessionValid()}
- Device Supported: $isDeviceSupported
- Can Check Biometrics: $canCheckBiometrics
- Available Biometrics: $availableBiometrics
- Last Auth: $_lastAuthTime
''';
  }

  // Metodo di test alternativo per debug
  Future<bool> testAuthenticate() async {
    debugPrint('BiometricAuthService: Starting TEST authentication...');

    try {
      // Test più semplice senza opzioni complesse
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Test autenticazione biometrica',
      );

      debugPrint(
        'BiometricAuthService: TEST Authentication result - $didAuthenticate',
      );
      return didAuthenticate;
    } catch (e) {
      debugPrint('BiometricAuthService: TEST Authentication error - $e');
      return false;
    }
  }
}
