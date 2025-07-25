import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ImageCacheService {
  static const String _imagesFolder = 'dream_images';

  /// Scarica un'immagine da URL e la salva localmente
  /// Restituisce il percorso locale del file salvato
  Future<String?> downloadAndCacheImage(String imageUrl, String dreamId) async {
    try {
      // Scarica l'immagine
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        print('Errore nel download dell\'immagine: ${response.statusCode}');
        return null;
      }

      // Ottieni la directory di archiviazione dell'app
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/$_imagesFolder');

      // Crea la cartella se non esiste
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Genera il nome del file
      final fileName = '${dreamId}_image.jpg';
      final filePath = '${imagesDir.path}/$fileName';

      // Salva l'immagine
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      print('Immagine salvata in: $filePath');
      return filePath;
    } catch (e) {
      print('Errore nel salvare l\'immagine: $e');
      return null;
    }
  }

  /// Verifica se un'immagine esiste nella cache locale
  Future<bool> imageExistsInCache(String dreamId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${dreamId}_image.jpg';
      final filePath = '${directory.path}/$_imagesFolder/$fileName';
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      print('Errore nel verificare la cache dell\'immagine: $e');
      return false;
    }
  }

  /// Ottieni il percorso locale di un'immagine dalla cache
  Future<String?> getCachedImagePath(String dreamId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${dreamId}_image.jpg';
      final filePath = '${directory.path}/$_imagesFolder/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        return filePath;
      }
      return null;
    } catch (e) {
      print('Errore nel recuperare il percorso dell\'immagine: $e');
      return null;
    }
  }

  /// Elimina un'immagine dalla cache
  Future<void> deleteCachedImage(String dreamId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${dreamId}_image.jpg';
      final filePath = '${directory.path}/$_imagesFolder/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        print('Immagine eliminata: $filePath');
      }
    } catch (e) {
      print('Errore nell\'eliminare l\'immagine: $e');
    }
  }

  /// Elimina tutte le immagini dalla cache
  Future<void> clearAllCachedImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/$_imagesFolder');

      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
        print('Tutte le immagini dalla cache sono state eliminate');
      }
    } catch (e) {
      print('Errore nell\'eliminare la cache delle immagini: $e');
    }
  }

  /// Ottieni la dimensione totale della cache delle immagini
  Future<int> getCacheSize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/$_imagesFolder');

      if (!await imagesDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (FileSystemEntity entity in imagesDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      return totalSize;
    } catch (e) {
      print('Errore nel calcolare la dimensione della cache: $e');
      return 0;
    }
  }
}
