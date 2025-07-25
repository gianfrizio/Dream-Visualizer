import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_dream.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_dreams';

  // Ottiene tutti i sogni preferiti
  Future<List<SavedDream>> getFavoriteDreams() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];

    return favoritesJson.map((jsonString) {
      final json = jsonDecode(jsonString);
      return SavedDream.fromJson(json);
    }).toList();
  }

  // Aggiunge un sogno ai preferiti
  Future<void> addToFavorites(SavedDream dream) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavoriteDreams();

    // Controlla se non è già nei preferiti
    if (!favorites.any((d) => d.id == dream.id)) {
      favorites.add(dream);

      final favoritesJson = favorites.map((d) => d.toJsonString()).toList();
      await prefs.setStringList(_favoritesKey, favoritesJson);
    }
  }

  // Rimuove un sogno dai preferiti
  Future<void> removeFromFavorites(String dreamId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavoriteDreams();

    favorites.removeWhere((dream) => dream.id == dreamId);

    final favoritesJson = favorites.map((d) => d.toJsonString()).toList();
    await prefs.setStringList(_favoritesKey, favoritesJson);
  }

  // Controlla se un sogno è nei preferiti
  Future<bool> isFavorite(String dreamId) async {
    final favorites = await getFavoriteDreams();
    return favorites.any((dream) => dream.id == dreamId);
  }

  // Toggle preferito (aggiunge se non c'è, rimuove se c'è)
  Future<bool> toggleFavorite(SavedDream dream) async {
    final isFav = await isFavorite(dream.id);

    if (isFav) {
      await removeFromFavorites(dream.id);
      return false;
    } else {
      await addToFavorites(dream);
      return true;
    }
  }
}
