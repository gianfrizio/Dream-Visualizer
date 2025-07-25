import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionService {
  static const String _keyStorageKey = 'encryption_key';
  static const String _ivStorageKey = 'encryption_iv';

  late final Encrypter _encrypter;
  late final IV _iv;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Recupera o genera la chiave di crittografia
    String? keyString = prefs.getString(_keyStorageKey);
    String? ivString = prefs.getString(_ivStorageKey);

    if (keyString == null || ivString == null) {
      await _generateNewKeys();
    } else {
      _loadKeysFromStorage(keyString, ivString);
    }

    _isInitialized = true;
  }

  Future<void> _generateNewKeys() async {
    final prefs = await SharedPreferences.getInstance();

    // Genera una chiave casuale di 256 bit (32 bytes)
    final keyBytes = List<int>.generate(
      32,
      (i) => Random.secure().nextInt(256),
    );
    final key = Key(Uint8List.fromList(keyBytes));

    // Genera un IV casuale di 128 bit (16 bytes)
    final ivBytes = List<int>.generate(16, (i) => Random.secure().nextInt(256));
    _iv = IV(Uint8List.fromList(ivBytes));

    // Configura l'encrypter
    _encrypter = Encrypter(AES(key));

    // Salva le chiavi nel storage locale (in modo sicuro)
    final keyString = base64Encode(keyBytes);
    final ivString = base64Encode(ivBytes);

    await prefs.setString(_keyStorageKey, keyString);
    await prefs.setString(_ivStorageKey, ivString);

    print('Nuove chiavi di crittografia generate');
  }

  void _loadKeysFromStorage(String keyString, String ivString) {
    final keyBytes = base64Decode(keyString);
    final ivBytes = base64Decode(ivString);

    final key = Key(Uint8List.fromList(keyBytes));
    _iv = IV(Uint8List.fromList(ivBytes));

    _encrypter = Encrypter(AES(key));
  }

  /// Cripta un testo
  String encryptText(String plainText) {
    if (!_isInitialized) {
      throw StateError('EncryptionService non inizializzato');
    }

    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Decripta un testo
  String decryptText(String encryptedText) {
    if (!_isInitialized) {
      throw StateError('EncryptionService non inizializzato');
    }

    try {
      final encrypted = Encrypted.fromBase64(encryptedText);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      print('Errore nella decrittazione: $e');
      rethrow;
    }
  }

  /// Cripta un oggetto JSON
  String encryptJson(Map<String, dynamic> jsonData) {
    final jsonString = jsonEncode(jsonData);
    return encryptText(jsonString);
  }

  /// Decripta un oggetto JSON
  Map<String, dynamic> decryptJson(String encryptedData) {
    final jsonString = decryptText(encryptedData);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Cripta dati binari (per immagini)
  String encryptBytes(Uint8List data) {
    if (!_isInitialized) {
      throw StateError('EncryptionService non inizializzato');
    }

    final encrypted = _encrypter.encryptBytes(data, iv: _iv);
    return encrypted.base64;
  }

  /// Decripta dati binari
  Uint8List decryptBytes(String encryptedData) {
    if (!_isInitialized) {
      throw StateError('EncryptionService non inizializzato');
    }

    try {
      final encrypted = Encrypted.fromBase64(encryptedData);
      final decryptedList = _encrypter.decryptBytes(encrypted, iv: _iv);
      return Uint8List.fromList(decryptedList);
    } catch (e) {
      print('Errore nella decrittazione dei bytes: $e');
      rethrow;
    }
  }

  /// Genera un hash sicuro per verificare l'integrità
  String generateHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifica l'integrità dei dati
  bool verifyIntegrity(String data, String expectedHash) {
    final actualHash = generateHash(data);
    return actualHash == expectedHash;
  }

  /// Rigenera le chiavi di crittografia (attenzione: rende inaccessibili i dati esistenti)
  Future<void> regenerateKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStorageKey);
    await prefs.remove(_ivStorageKey);
    await _generateNewKeys();
    print('Chiavi di crittografia rigenerate');
  }

  /// Elimina le chiavi di crittografia
  Future<void> clearKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStorageKey);
    await prefs.remove(_ivStorageKey);
    _isInitialized = false;
  }
}
