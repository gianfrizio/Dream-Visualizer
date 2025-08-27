import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_dream.dart';
import 'image_cache_service.dart';

class DreamStorageService {
  static const String _dreamsKey = 'saved_dreams';
  final ImageCacheService _imageCacheService = ImageCacheService();

  // Salva un nuovo sogno o aggiorna uno esistente
  Future<void> saveDream(SavedDream dream) async {
    final prefs = await SharedPreferences.getInstance();
    List<SavedDream> dreams = await getSavedDreams();

    // Controlla se il sogno esiste già (basandosi sull'ID)
    final existingIndex = dreams.indexWhere((d) => d.id == dream.id);

    if (existingIndex != -1) {
      // Aggiorna il sogno esistente
      dreams[existingIndex] = dream;
  debugPrint('Debug: Sogno ${dream.id} aggiornato');
    } else {
      // Aggiungi il nuovo sogno all'inizio della lista
      dreams.insert(0, dream);
  debugPrint('Debug: Nuovo sogno ${dream.id} aggiunto');
    }

    // Converti la lista in JSON
    List<String> dreamsJson = dreams
        .map((dream) => dream.toJsonString())
        .toList();

    // Salva nei SharedPreferences
    await prefs.setStringList(_dreamsKey, dreamsJson);
  }

  // Carica tutti i sogni salvati
  Future<List<SavedDream>> getSavedDreams() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // Debug: Controlla cosa c'è effettivamente salvato
      final keys = prefs.getKeys();
  debugPrint('Chiavi disponibili: $keys');

      // Controlla se esiste la chiave
      if (!prefs.containsKey(_dreamsKey)) {
        debugPrint('Nessun dato trovato per la chiave $_dreamsKey');
        return [];
      }

      // Prova prima con la nuova struttura (StringList)
      try {
        List<String>? dreamsJson = prefs.getStringList(_dreamsKey);
  debugPrint('Tentativo StringList: $dreamsJson');

        if (dreamsJson != null) {
          debugPrint('Trovati ${dreamsJson.length} sogni in formato StringList');
          final dreams = <SavedDream>[];

          for (int i = 0; i < dreamsJson.length; i++) {
            try {
              final dream = SavedDream.fromJsonString(dreamsJson[i]);
              dreams.add(dream);
              } catch (e) {
              debugPrint('Errore nel parsing del sogno $i: $e');
              debugPrint('Dati problematici: ${dreamsJson[i]}');
            }
          }

          debugPrint('Caricati con successo ${dreams.length} sogni');
          return dreams;
        }
      } catch (e) {
  debugPrint('Errore nel caricamento StringList: $e');
      }

      // Se non trova StringList, prova con la vecchia struttura (String singolo)
      try {
        String? oldData = prefs.getString(_dreamsKey);
  debugPrint('Tentativo String singolo: ${oldData?.substring(0, 100)}...');

        if (oldData != null) {
          // Prova a decodificare come lista JSON
          dynamic decoded = jsonDecode(oldData);
    debugPrint('Tipo decodificato: ${decoded.runtimeType}');

          if (decoded is List) {
            List<dynamic> dreamsList = decoded;
            debugPrint('Trovati ${dreamsList.length} sogni in formato List');

            final dreams = <SavedDream>[];

            for (int i = 0; i < dreamsList.length; i++) {
              try {
                final item = dreamsList[i];
                SavedDream? dream;

                if (item is String) {
                  dream = SavedDream.fromJsonString(item);
                } else if (item is Map<String, dynamic>) {
                  dream = SavedDream.fromJson(item);
                } else {
                  debugPrint('Tipo item non supportato: ${item.runtimeType}');
                  continue;
                }

                dreams.add(dream);
                } catch (e) {
                debugPrint('Errore nel parsing del sogno legacy $i: $e');
                debugPrint('Dati problematici: ${dreamsList[i]}');
              }
            }

            debugPrint(
              'Caricati con successo ${dreams.length} sogni dal formato legacy',
            );
            return dreams;
          } else {
            debugPrint('Formato dati non riconosciuto: ${decoded.runtimeType}');
          }
        }
      } catch (e) {
  debugPrint('Errore nel caricamento String singolo: $e');
      }
    } catch (e) {
      debugPrint('Errore generale nel caricamento sogni: $e');
    }

    debugPrint('Nessun sogno caricato, ritorno lista vuota');
    return [];
  }

  // Metodo di emergenza per pulire i dati corrotti
  Future<void> clearCorruptedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dreamsKey);
  debugPrint('Dati corrotti rimossi');
  }

  // Elimina un sogno
  Future<void> deleteDream(String dreamId) async {
    final prefs = await SharedPreferences.getInstance();
    List<SavedDream> dreams = await getSavedDreams();

    // Elimina l'immagine dalla cache se presente
    await _imageCacheService.deleteCachedImage(dreamId);

    // Rimuovi il sogno con l'ID specificato
    dreams.removeWhere((dream) => dream.id == dreamId);

    // Salva la lista aggiornata
    List<String> dreamsJson = dreams
        .map((dream) => dream.toJsonString())
        .toList();
    await prefs.setStringList(_dreamsKey, dreamsJson);
  }

  // Elimina tutti i sogni
  Future<void> deleteAllDreams() async {
    final prefs = await SharedPreferences.getInstance();

    // Elimina tutte le immagini dalla cache
    await _imageCacheService.clearAllCachedImages();

    await prefs.remove(_dreamsKey);
  }

  // Conta il numero di sogni salvati
  Future<int> getDreamsCount() async {
    List<SavedDream> dreams = await getSavedDreams();
    return dreams.length;
  }

  // Ottieni i sogni più recenti (limitati)
  Future<List<SavedDream>> getRecentDreams({int limit = 5}) async {
    List<SavedDream> allDreams = await getSavedDreams();
    if (allDreams.length <= limit) {
      return allDreams;
    }
    return allDreams.take(limit).toList();
  }

  // Aggiorna lo stato di condivisione di un sogno
  Future<void> updateDreamSharingStatus(String dreamId, bool isShared) async {
    List<SavedDream> dreams = await getSavedDreams();

    // Trova e aggiorna il sogno
    for (int i = 0; i < dreams.length; i++) {
      if (dreams[i].id == dreamId) {
        dreams[i] = dreams[i].copyWith(isSharedWithCommunity: isShared);
        break;
      }
    }

    // Salva la lista aggiornata
    final prefs = await SharedPreferences.getInstance();
    final jsonList = dreams.map((dream) => dream.toJson()).toList();
    await prefs.setString(_dreamsKey, jsonEncode(jsonList));
  }

  // Ottieni solo i sogni condivisi con la community
  Future<List<SavedDream>> getSharedDreams() async {
    List<SavedDream> allDreams = await getSavedDreams();
    return allDreams.where((dream) => dream.isSharedWithCommunity).toList();
  }

  // Rimuove duplicati basandosi sull'ID del sogno
  Future<void> removeDuplicates() async {
    final prefs = await SharedPreferences.getInstance();
    List<SavedDream> dreams = await getSavedDreams();

    // Crea una mappa per rimuovere duplicati mantenendo solo l'ultima versione
    final Map<String, SavedDream> uniqueDreams = {};

    // Scandisce dalla fine all'inizio per mantenere le versioni più recenti
    for (int i = dreams.length - 1; i >= 0; i--) {
      final dream = dreams[i];
      if (!uniqueDreams.containsKey(dream.id)) {
        uniqueDreams[dream.id] = dream;
      }
    }

    // Ricostruisce la lista mantenendo l'ordine cronologico
    final uniqueDreamsList = uniqueDreams.values.toList();
    uniqueDreamsList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    debugPrint(
      'Debug: Rimossi ${dreams.length - uniqueDreamsList.length} sogni duplicati',
    );

    // Salva la lista pulita
    List<String> dreamsJson = uniqueDreamsList
        .map((dream) => dream.toJsonString())
        .toList();

    await prefs.setStringList(_dreamsKey, dreamsJson);
  }
}
