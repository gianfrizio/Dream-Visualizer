import 'dart:convert';
import '../l10n/app_localizations.dart';

class SavedDream {
  final String id;
  final String dreamText;
  final String interpretation;
  final String? imageUrl;
  final String? localImagePath; // Percorso locale dell'immagine
  final DateTime createdAt;
  final String title;
  final List<String> tags;
  final bool isSharedWithCommunity; // Nuovo campo per indicare se è condiviso

  SavedDream({
    required this.id,
    required this.dreamText,
    required this.interpretation,
    this.imageUrl,
    this.localImagePath,
    required this.createdAt,
    required this.title,
    this.tags = const [],
    this.isSharedWithCommunity = false, // Default: non condiviso
  });

  // Converti in JSON per il salvataggio
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dreamText': dreamText,
      'interpretation': interpretation,
      'imageUrl': imageUrl,
      'localImagePath': localImagePath,
      'createdAt': createdAt.toIso8601String(),
      'title': title,
      'tags': tags,
      'isSharedWithCommunity': isSharedWithCommunity,
    };
  }

  // Crea da JSON per il caricamento
  factory SavedDream.fromJson(Map<String, dynamic> json) {
    return SavedDream(
      id: json['id'],
      dreamText: json['dreamText'],
      interpretation: json['interpretation'],
      imageUrl: json['imageUrl'],
      localImagePath: json['localImagePath'],
      createdAt: DateTime.parse(json['createdAt']),
      title: json['title'],
      tags: List<String>.from(json['tags'] ?? []),
      isSharedWithCommunity: json['isSharedWithCommunity'] ?? false,
    );
  }

  // Converti in stringa JSON
  String toJsonString() => jsonEncode(toJson());

  // Crea da stringa JSON
  factory SavedDream.fromJsonString(String jsonString) {
    return SavedDream.fromJson(jsonDecode(jsonString));
  }

  // Ottieni il percorso dell'immagine (preferisce il percorso locale se disponibile)
  String? get imagePath {
    if (localImagePath != null && localImagePath!.isNotEmpty) {
      return localImagePath;
    }
    return imageUrl;
  }

  // Verifica se ha un'immagine disponibile
  bool get hasImage {
    return (localImagePath != null && localImagePath!.isNotEmpty) ||
        (imageUrl != null && imageUrl!.isNotEmpty);
  }

  // Crea un titolo automatico dal sogno
  static String generateTitle(String dreamText) {
    if (dreamText.isEmpty) return 'Sogno senza titolo';

    // Prendi le prime parole e crea un titolo
    List<String> words = dreamText.trim().split(' ');
    if (words.length <= 5) {
      return words.join(' ');
    } else {
      return '${words.take(5).join(' ')}...';
    }
  }

  // Genera automaticamente i tag dal testo del sogno
  static List<String> generateTags(
    String dreamText,
    String interpretation, [
    AppLocalizations? localizations,
  ]) {
    final List<String> tags = [];
    final combinedText = '$dreamText $interpretation'.toLowerCase();

    // Se non abbiamo localizations, usa i tag italiani di default
    if (localizations == null) {
      return _generateItalianTags(combinedText);
    }

    // Tag basati su emozioni
    final emotionTags = {
      'felice': localizations.tagPositiveDream,
      'gioia': localizations.tagPositiveDream,
      'allegro': localizations.tagPositiveDream,
      'happy': localizations.tagPositiveDream,
      'joy': localizations.tagPositiveDream,
      'cheerful': localizations.tagPositiveDream,
      'paura': localizations.tagNightmare,
      'terrore': localizations.tagNightmare,
      'spavento': localizations.tagNightmare,
      'angoscia': localizations.tagNightmare,
      'fear': localizations.tagNightmare,
      'terror': localizations.tagNightmare,
      'scary': localizations.tagNightmare,
      'triste': localizations.tagMelancholicDream,
      'dolore': localizations.tagMelancholicDream,
      'sad': localizations.tagMelancholicDream,
      'pain': localizations.tagMelancholicDream,
      'amore': localizations.tagRomanticDream,
      'innamorato': localizations.tagRomanticDream,
      'love': localizations.tagRomanticDream,
      'romantic': localizations.tagRomanticDream,
      'pace': localizations.tagSereneDream,
      'tranquillo': localizations.tagSereneDream,
      'calma': localizations.tagSereneDream,
      'peace': localizations.tagSereneDream,
      'calm': localizations.tagSereneDream,
      'serene': localizations.tagSereneDream,
    };

    // Tag basati su luoghi/ambientazioni
    final locationTags = {
      'casa': localizations.tagHome,
      'home': localizations.tagHome,
      'house': localizations.tagHome,
      'scuola': localizations.tagSchool,
      'school': localizations.tagSchool,
      'lavoro': localizations.tagWork,
      'work': localizations.tagWork,
      'office': localizations.tagWork,
      'mare': localizations.tagNature,
      'montagna': localizations.tagNature,
      'bosco': localizations.tagNature,
      'natura': localizations.tagNature,
      'sea': localizations.tagNature,
      'mountain': localizations.tagNature,
      'forest': localizations.tagNature,
      'nature': localizations.tagNature,
      'città': localizations.tagUrban,
      'strada': localizations.tagUrban,
      'city': localizations.tagUrban,
      'street': localizations.tagUrban,
      'urban': localizations.tagUrban,
      'cielo': localizations.tagSkyFlight,
      'volare': localizations.tagSkyFlight,
      'volo': localizations.tagSkyFlight,
      'sky': localizations.tagSkyFlight,
      'fly': localizations.tagSkyFlight,
      'flying': localizations.tagSkyFlight,
      'flight': localizations.tagSkyFlight,
    };

    // Tag basati su persone/relazioni
    final peopleTags = {
      'famiglia': localizations.tagFamily,
      'madre': localizations.tagFamily,
      'padre': localizations.tagFamily,
      'figlio': localizations.tagFamily,
      'family': localizations.tagFamily,
      'mother': localizations.tagFamily,
      'father': localizations.tagFamily,
      'son': localizations.tagFamily,
      'daughter': localizations.tagFamily,
      'amico': localizations.tagFriends,
      'friend': localizations.tagFriends,
      'friends': localizations.tagFriends,
      'partner': localizations.tagRelationships,
      'relationship': localizations.tagRelationships,
      'sconosciuto': localizations.tagUnknownPeople,
      'stranger': localizations.tagUnknownPeople,
      'unknown': localizations.tagUnknownPeople,
    };

    // Tag basati su azioni/eventi
    final actionTags = {
      'correre': localizations.tagMovement,
      'camminare': localizations.tagMovement,
      'cadere': localizations.tagMovement,
      'saltare': localizations.tagMovement,
      'run': localizations.tagMovement,
      'walk': localizations.tagMovement,
      'fall': localizations.tagMovement,
      'jump': localizations.tagMovement,
      'parlare': localizations.tagCommunication,
      'talk': localizations.tagCommunication,
      'speak': localizations.tagCommunication,
      'cantare': localizations.tagCreativity,
      'disegnare': localizations.tagCreativity,
      'sing': localizations.tagCreativity,
      'draw': localizations.tagCreativity,
      'create': localizations.tagCreativity,
      'studiare': localizations.tagLearning,
      'study': localizations.tagLearning,
      'learn': localizations.tagLearning,
      'lavorare': localizations.tagWork,
      'working': localizations.tagWork,
    };

    // Aggiungi tag basati sul contenuto
    for (final entry in {
      ...emotionTags,
      ...locationTags,
      ...peopleTags,
      ...actionTags,
    }.entries) {
      if (combinedText.contains(entry.key) && !tags.contains(entry.value)) {
        tags.add(entry.value);
      }
    }

    // Tag speciali
    if (combinedText.contains('lucido') ||
        combinedText.contains('controllo') ||
        combinedText.contains('lucid') ||
        combinedText.contains('control')) {
      tags.add(localizations.tagLucidDream);
    }
    if (combinedText.contains('ricorrente') ||
        combinedText.contains('ripete') ||
        combinedText.contains('recurrent') ||
        combinedText.contains('repeat')) {
      tags.add(localizations.tagRecurrentDream);
    }

    // Limita a 5 tag massimo
    return tags.take(5).toList();
  }

  // Metodo di fallback per tag italiani quando AppLocalizations non è disponibile
  static List<String> _generateItalianTags(String combinedText) {
    final List<String> tags = [];

    // Tag basati su emozioni (hardcoded in italiano)
    final emotionTags = {
      'felice': 'Sogno Positivo',
      'gioia': 'Sogno Positivo',
      'allegro': 'Sogno Positivo',
      'paura': 'Incubo',
      'terrore': 'Incubo',
      'spavento': 'Incubo',
      'angoscia': 'Incubo',
      'triste': 'Sogno Malinconico',
      'dolore': 'Sogno Malinconico',
      'amore': 'Sogno Romantico',
      'innamorato': 'Sogno Romantico',
      'pace': 'Sogno Sereno',
      'tranquillo': 'Sogno Sereno',
      'calma': 'Sogno Sereno',
    };

    // Tag basati su luoghi/ambientazioni (hardcoded in italiano)
    final locationTags = {
      'casa': 'Casa',
      'scuola': 'Scuola',
      'lavoro': 'Lavoro',
      'mare': 'Natura',
      'montagna': 'Natura',
      'bosco': 'Natura',
      'città': 'Urbano',
      'strada': 'Urbano',
      'cielo': 'Cielo/Volo',
      'volare': 'Cielo/Volo',
      'volo': 'Cielo/Volo',
    };

    // Tag basati su persone/relazioni (hardcoded in italiano)
    final peopleTags = {
      'famiglia': 'Famiglia',
      'madre': 'Famiglia',
      'padre': 'Famiglia',
      'figlio': 'Famiglia',
      'amico': 'Amici',
      'partner': 'Relazioni',
      'sconosciuto': 'Persone Sconosciute',
    };

    // Tag basati su azioni/eventi (hardcoded in italiano)
    final actionTags = {
      'correre': 'Movimento',
      'camminare': 'Movimento',
      'cadere': 'Movimento',
      'saltare': 'Movimento',
      'parlare': 'Comunicazione',
      'cantare': 'Creatività',
      'disegnare': 'Creatività',
      'studiare': 'Apprendimento',
      'lavorare': 'Lavoro',
    };

    // Aggiungi tag basati sul contenuto
    for (final entry in {
      ...emotionTags,
      ...locationTags,
      ...peopleTags,
      ...actionTags,
    }.entries) {
      if (combinedText.contains(entry.key) && !tags.contains(entry.value)) {
        tags.add(entry.value);
      }
    }

    // Tag speciali
    if (combinedText.contains('lucido') || combinedText.contains('controllo')) {
      tags.add('Sogno Lucido');
    }
    if (combinedText.contains('ricorrente') ||
        combinedText.contains('ripete')) {
      tags.add('Sogno Ricorrente');
    }

    return tags.take(5).toList();
  }

  // Metodo per creare una copia con stato di condivisione aggiornato
  SavedDream copyWith({
    String? id,
    String? dreamText,
    String? interpretation,
    String? imageUrl,
    String? localImagePath,
    DateTime? createdAt,
    String? title,
    List<String>? tags,
    bool? isSharedWithCommunity,
  }) {
    return SavedDream(
      id: id ?? this.id,
      dreamText: dreamText ?? this.dreamText,
      interpretation: interpretation ?? this.interpretation,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      isSharedWithCommunity:
          isSharedWithCommunity ?? this.isSharedWithCommunity,
    );
  }
}
