import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String _baseUrl = 'https://api.mymemory.translated.net/get';

  // Cache per le traduzioni per evitare chiamate ripetute
  static final Map<String, String> _translationCache = {};

  // Traduzioni predefinite per i tag più comuni
  static final Map<String, Map<String, String>> _commonTranslations = {
    'it_en': {
      'avventura': 'adventure',
      'paura': 'fear',
      'amore': 'love',
      'famiglia': 'family',
      'lavoro': 'work',
      'scuola': 'school',
      'animali': 'animals',
      'natura': 'nature',
      'volare': 'flying',
      'cadere': 'falling',
      'acqua': 'water',
      'fuoco': 'fire',
      'casa': 'home',
      'viaggio': 'travel',
      'amici': 'friends',
      'incubo': 'nightmare',
      'felice': 'happy',
      'triste': 'sad',
      'strano': 'strange',
      'colorato': 'colorful',
      'buio': 'dark',
      'luce': 'light',
      'musica': 'music',
      'cibo': 'food',
      'macchina': 'car',
      'treno': 'train',
      'aereo': 'airplane',
      'mare': 'sea',
      'montagna': 'mountain',
      'città': 'city',
      'bambino': 'child',
      'persona': 'person',
      'mistero': 'mystery',
      'magia': 'magic',
      'futuro': 'future',
      'passato': 'past',
      'ricordo': 'memory',
      'simbolico': 'symbolic',
      'ricorrente': 'recurring',
      'lucido': 'lucid',
    },
    'en_it': {
      'adventure': 'avventura',
      'fear': 'paura',
      'love': 'amore',
      'family': 'famiglia',
      'work': 'lavoro',
      'school': 'scuola',
      'animals': 'animali',
      'nature': 'natura',
      'flying': 'volare',
      'falling': 'cadere',
      'water': 'acqua',
      'fire': 'fuoco',
      'home': 'casa',
      'travel': 'viaggio',
      'friends': 'amici',
      'nightmare': 'incubo',
      'happy': 'felice',
      'sad': 'triste',
      'strange': 'strano',
      'colorful': 'colorato',
      'dark': 'buio',
      'light': 'luce',
      'music': 'musica',
      'food': 'cibo',
      'car': 'macchina',
      'train': 'treno',
      'airplane': 'aereo',
      'sea': 'mare',
      'mountain': 'montagna',
      'city': 'città',
      'child': 'bambino',
      'person': 'persona',
      'mystery': 'mistero',
      'magic': 'magia',
      'future': 'futuro',
      'past': 'passato',
      'memory': 'ricordo',
      'symbolic': 'simbolico',
      'recurring': 'ricorrente',
      'lucid': 'lucido',
    },
  };

  static Future<String> translateText(
    String text,
    String fromLang,
    String toLang,
  ) async {
    // Normalizza i codici lingua per l'API MyMemory
    fromLang = _normalizeLanguageCode(fromLang);
    toLang = _normalizeLanguageCode(toLang);

    // Se il testo è uguale, non tradurre
    if (fromLang == toLang) return text;

    // Se il testo è troppo lungo, dividi in parti
    if (text.length > 400) {
      return await _translateLongText(text, fromLang, toLang);
    }

    final cacheKey = '${text}_${fromLang}_$toLang';

    // Controlla la cache
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }

    // Controlla le traduzioni predefinite
    final commonTranslation = _getCommonTranslation(
      text.toLowerCase(),
      fromLang,
      toLang,
    );
    if (commonTranslation != null) {
      _translationCache[cacheKey] = commonTranslation;
      return commonTranslation;
    }

    return await _translateSingleText(text, fromLang, toLang);
  }

  // Normalizza i codici lingua per l'API MyMemory
  static String _normalizeLanguageCode(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'auto':
      case 'it':
      case 'italian':
        return 'it';
      case 'en':
      case 'english':
        return 'en';
      case 'es':
      case 'spanish':
        return 'es';
      case 'fr':
      case 'french':
        return 'fr';
      case 'de':
      case 'german':
        return 'de';
      default:
        // Se il codice non è riconosciuto, usa 'auto' che MyMemory dovrebbe accettare
        return 'auto';
    }
  }

  static Future<String> _translateSingleText(
    String text,
    String fromLang,
    String toLang,
  ) async {
    final cacheKey = '${text}_${fromLang}_$toLang';

    try {
      // Normalizza i codici lingua prima di chiamare l'API
      final normalizedFromLang = _normalizeLanguageCode(fromLang);
      final normalizedToLang = _normalizeLanguageCode(toLang);

      // Gestione speciale per 'auto' - prova a rilevare automaticamente
      String apiFromLang = normalizedFromLang;
      if (normalizedFromLang == 'auto') {
        // Se è auto, prova prima con l'italiano come default
        apiFromLang = 'it';
      }

      // Usa l'API di traduzione gratuita MyMemory
      final url = Uri.parse(
        '$_baseUrl?q=${Uri.encodeComponent(text)}&langpair=$apiFromLang|$normalizedToLang',
      );

      print('Translation URL: $url'); // Debug

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Controlla se la risposta contiene un errore
        if (data['responseStatus'] != null && data['responseStatus'] != 200) {
          print('Translation API error: ${data['responseDetails']}');
          return text;
        }

        final translatedText = data['responseData']['translatedText'] as String;

        // Controlla se la traduzione è identica al testo originale e prova con un'altra lingua
        if (translatedText.toLowerCase() == text.toLowerCase() &&
            normalizedFromLang == 'auto') {
          // Prova con inglese se italiano non ha funzionato
          final urlEn = Uri.parse(
            '$_baseUrl?q=${Uri.encodeComponent(text)}&langpair=en|$normalizedToLang',
          );
          final responseEn = await http.get(urlEn);

          if (responseEn.statusCode == 200) {
            final dataEn = json.decode(responseEn.body);
            if (dataEn['responseStatus'] == null ||
                dataEn['responseStatus'] == 200) {
              final translatedTextEn =
                  dataEn['responseData']['translatedText'] as String;
              if (translatedTextEn.toLowerCase() != text.toLowerCase()) {
                _translationCache[cacheKey] = translatedTextEn;
                return translatedTextEn;
              }
            }
          }
        }

        // Salva nella cache
        _translationCache[cacheKey] = translatedText;
        return translatedText;
      } else {
        print('Translation API HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Errore nella traduzione: $e');
    }

    // Se la traduzione fallisce, ritorna il testo originale
    return text;
  }

  static Future<String> _translateLongText(
    String text,
    String fromLang,
    String toLang,
  ) async {
    // Normalizza i codici lingua
    fromLang = _normalizeLanguageCode(fromLang);
    toLang = _normalizeLanguageCode(toLang);

    // Dividi il testo in frasi o parti più piccole
    final sentences = text
        .split(RegExp(r'[.!?]\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    if (sentences.length <= 1) {
      // Se è una sola frase lunga, dividi per parole
      final words = text.split(' ');
      final chunks = <String>[];
      String currentChunk = '';

      for (final word in words) {
        if ((currentChunk + ' ' + word).length > 350) {
          if (currentChunk.isNotEmpty) {
            chunks.add(currentChunk.trim());
            currentChunk = word;
          }
        } else {
          currentChunk = currentChunk.isEmpty ? word : '$currentChunk $word';
        }
      }

      if (currentChunk.isNotEmpty) {
        chunks.add(currentChunk.trim());
      }

      // Traduci ogni chunk
      final translatedChunks = <String>[];
      for (final chunk in chunks) {
        final translated = await _translateSingleText(chunk, fromLang, toLang);
        translatedChunks.add(translated);
      }

      return translatedChunks.join(' ');
    } else {
      // Traduci ogni frase separatamente
      final translatedSentences = <String>[];
      for (final sentence in sentences) {
        if (sentence.trim().isNotEmpty) {
          final translated = await _translateSingleText(
            sentence.trim(),
            fromLang,
            toLang,
          );
          translatedSentences.add(translated);
        }
      }

      return translatedSentences.join('. ') + (text.endsWith('.') ? '' : '.');
    }
  }

  static String? _getCommonTranslation(
    String text,
    String fromLang,
    String toLang,
  ) {
    final key = '${fromLang}_$toLang';
    return _commonTranslations[key]?[text];
  }

  static Future<List<String>> translateTags(
    List<String> tags,
    String fromLang,
    String toLang,
  ) async {
    final translatedTags = <String>[];

    for (String tag in tags) {
      final translatedTag = await translateText(tag, fromLang, toLang);
      translatedTags.add(translatedTag);
    }

    return translatedTags;
  }

  // Funzione per rilevare la lingua di un testo (semplificata)
  static String detectLanguage(String text) {
    // Pattern per parole italiane comuni (ampliato)
    final italianWords = [
      // Articoli
      'il', 'la', 'lo', 'le', 'gli', 'i', 'un', 'una', 'uno',
      // Preposizioni
      'di', 'da', 'in', 'con', 'su', 'per', 'tra', 'fra', 'a',
      // Congiunzioni e avverbi
      'e', 'ma', 'o', 'se', 'che', 'come', 'quando', 'dove', 'perché',
      'non', 'più', 'molto', 'tutto', 'anche', 'ancora', 'già', 'poi',
      // Pronomi
      'io',
      'tu',
      'lui',
      'lei',
      'noi',
      'voi',
      'loro',
      'mi',
      'ti',
      'si',
      'ci',
      'vi',
      // Verbi comuni
      'sono', 'è', 'era', 'ho', 'hai', 'ha', 'abbiamo', 'avete', 'hanno',
      'essere', 'avere', 'fare', 'dire', 'andare', 'vedere', 'sapere',
      // Aggettivi comuni
      'questo', 'questa', 'quello', 'quella', 'mio', 'mia', 'suo', 'sua',
      'grande', 'piccolo', 'buono', 'bello', 'nuovo', 'vecchio',
      // Parole specifiche per sogni
      'sogno', 'sognare', 'dormire', 'notte', 'incubo', 'ricordo',
      'della', 'del', 'delle', 'dei', 'dalla', 'dal', 'dalle', 'dai',
      'nella', 'nel', 'nelle', 'nei', 'sulla', 'sul', 'sulle', 'sui',
    ];

    // Pattern per parole inglesi comuni (ampliato)
    final englishWords = [
      // Articoli
      'the', 'a', 'an',
      // Preposizioni
      'of', 'to', 'in', 'for', 'with', 'on', 'at', 'by', 'from', 'about',
      // Congiunzioni e avverbi
      'and', 'or', 'but', 'if', 'that', 'when', 'where', 'why', 'how',
      'not', 'no', 'yes', 'very', 'all', 'also', 'still', 'already', 'then',
      // Pronomi
      'i',
      'you',
      'he',
      'she',
      'it',
      'we',
      'they',
      'me',
      'him',
      'her',
      'us',
      'them',
      'my',
      'your',
      'his',
      'hers',
      'our',
      'their',
      'this',
      'that',
      'these',
      'those',
      // Verbi comuni
      'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had',
      'do', 'does', 'did', 'will', 'would', 'can', 'could', 'should',
      'go', 'get', 'make', 'take', 'come', 'see', 'know', 'think', 'look',
      // Aggettivi comuni
      'good',
      'bad',
      'big',
      'small',
      'new',
      'old',
      'long',
      'short',
      'high',
      'low',
      // Parole specifiche per sogni
      'dream', 'dreaming', 'sleep', 'night', 'nightmare', 'memory',
      'was', 'were', 'there', 'here', 'what', 'which', 'who',
    ];

    // Caratteristiche specifiche italiane
    final italianEndings = [
      'zione',
      'mente',
      'ando',
      'endo',
      'ato',
      'uto',
      'ito',
    ];
    final englishEndings = ['tion', 'ing', 'ed', 'ly', 'er', 'est'];

    final words = text.toLowerCase().split(RegExp(r'[^\w]+'));

    int italianScore = 0;
    int englishScore = 0;

    for (String word in words) {
      if (word.length < 2) continue;

      // Controlla parole comuni
      if (italianWords.contains(word)) italianScore += 2;
      if (englishWords.contains(word)) englishScore += 2;

      // Controlla terminazioni tipiche
      for (String ending in italianEndings) {
        if (word.endsWith(ending)) italianScore += 1;
      }
      for (String ending in englishEndings) {
        if (word.endsWith(ending)) englishScore += 1;
      }
    }

    // Aggiunge bonus se il testo è molto breve ma contiene parole chiave
    if (text.length < 50) {
      if (text.toLowerCase().contains('sogno') ||
          text.toLowerCase().contains('ho sognato')) {
        italianScore += 5;
      }
      if (text.toLowerCase().contains('dream') ||
          text.toLowerCase().contains('i dreamed')) {
        englishScore += 5;
      }
    }

    print(
      'Language detection - Italian score: $italianScore, English score: $englishScore',
    );

    // Se i punteggi sono molto vicini o bassi, usa italiano come default
    if ((italianScore - englishScore).abs() <= 1 &&
        italianScore + englishScore < 3) {
      print('Language detection uncertain, defaulting to Italian');
      return 'it'; // Default a italiano invece di 'auto'
    }

    return italianScore > englishScore ? 'it' : 'en';
  }
}
