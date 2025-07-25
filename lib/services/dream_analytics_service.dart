import '../models/saved_dream.dart';
import '../services/dream_storage_service.dart';
import '../l10n/app_localizations.dart';

class DreamAnalyticsService {
  final DreamStorageService _storageService = DreamStorageService();

  // Analisi frequenza sogni per settimana
  Future<Map<String, int>> getDreamFrequencyByWeek() async {
    final dreams = await _storageService.getSavedDreams();
    final Map<String, int> weeklyCount = {};

    for (final dream in dreams) {
      final weekKey = _getWeekKey(dream.createdAt);
      weeklyCount[weekKey] = (weeklyCount[weekKey] ?? 0) + 1;
    }

    return weeklyCount;
  }

  // Analisi emozioni più comuni
  Future<Map<String, int>> getEmotionAnalysis(
    AppLocalizations localizations,
  ) async {
    final dreams = await _storageService.getSavedDreams();
    final Map<String, int> emotions = {};

    for (final dream in dreams) {
      final dreamEmotions = _extractEmotionsFromText(
        dream.dreamText + ' ' + dream.interpretation,
        localizations,
      );
      for (final emotion in dreamEmotions) {
        emotions[emotion] = (emotions[emotion] ?? 0) + 1;
      }
    }

    return emotions;
  }

  // Analisi parole chiave più frequenti
  Future<Map<String, int>> getKeywordAnalysis() async {
    final dreams = await _storageService.getSavedDreams();
    final Map<String, int> keywords = {};

    for (final dream in dreams) {
      final dreamKeywords = _extractKeywordsFromText(dream.dreamText);
      for (final keyword in dreamKeywords) {
        keywords[keyword] = (keywords[keyword] ?? 0) + 1;
      }
    }

    // Ritorna solo le top 20 parole
    final sortedEntries = keywords.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries.take(20));
  }

  // Analisi sogni per fascia oraria
  Future<Map<String, int>> getDreamsByTimeOfDay(
    AppLocalizations localizations,
  ) async {
    final dreams = await _storageService.getSavedDreams();
    final Map<String, int> timeSlots = {
      localizations.morning: 0,
      localizations.afternoon: 0,
      localizations.evening: 0,
      localizations.night: 0,
    };

    for (final dream in dreams) {
      final hour = dream.createdAt.hour;
      if (hour >= 6 && hour < 12) {
        timeSlots[localizations.morning] =
            timeSlots[localizations.morning]! + 1;
      } else if (hour >= 12 && hour < 18) {
        timeSlots[localizations.afternoon] =
            timeSlots[localizations.afternoon]! + 1;
      } else if (hour >= 18 && hour < 22) {
        timeSlots[localizations.evening] =
            timeSlots[localizations.evening]! + 1;
      } else {
        timeSlots[localizations.night] = timeSlots[localizations.night]! + 1;
      }
    }

    return timeSlots;
  }

  // Statistiche generali
  Future<Map<String, dynamic>> getGeneralStats(
    AppLocalizations localizations,
  ) async {
    final dreams = await _storageService.getSavedDreams();

    if (dreams.isEmpty) {
      return {
        'totalDreams': 0,
        'averageLength': 0,
        'dreamsWithImages': 0,
        'mostActivePeriod': 'N/A',
        'longestDream': 0,
      };
    }

    final totalWords = dreams.fold<int>(
      0,
      (sum, dream) => sum + dream.dreamText.split(' ').length,
    );
    final dreamsWithImages = dreams
        .where((dream) => dream.imageUrl != null && dream.imageUrl!.isNotEmpty)
        .length;
    final longestDream = dreams
        .map((dream) => dream.dreamText.length)
        .reduce((a, b) => a > b ? a : b);

    // Trova il periodo più attivo
    final timeAnalysis = await getDreamsByTimeOfDay(localizations);
    final mostActivePeriod = timeAnalysis.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return {
      'totalDreams': dreams.length,
      'averageLength': (totalWords / dreams.length).round(),
      'dreamsWithImages': dreamsWithImages,
      'dreamsWithImagesPercentage': ((dreamsWithImages / dreams.length) * 100)
          .round(),
      'mostActivePeriod': mostActivePeriod,
      'longestDream': longestDream,
    };
  }

  // Sogni recenti (ultimi 7 giorni)
  Future<List<SavedDream>> getRecentDreams() async {
    final dreams = await _storageService.getSavedDreams();
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return dreams
        .where((dream) => dream.createdAt.isAfter(sevenDaysAgo))
        .toList();
  }

  // Trova pattern nei sogni
  Future<List<String>> findDreamPatterns(AppLocalizations localizations) async {
    final dreams = await _storageService.getSavedDreams();
    final List<String> patterns = [];

    if (dreams.length < 3) return patterns;

    // Analizza parole ricorrenti
    final keywords = await getKeywordAnalysis();
    final frequentWords = keywords.entries
        .where((entry) => entry.value >= 3)
        .map((entry) => entry.key)
        .take(5)
        .toList();

    if (frequentWords.isNotEmpty) {
      patterns.add(
        '${localizations.recurringElements}: ${frequentWords.join(", ")}',
      );
    }

    // Analizza emozioni predominanti
    final emotions = await getEmotionAnalysis(localizations);
    final topEmotion = emotions.entries.isNotEmpty
        ? emotions.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : null;

    if (topEmotion != null) {
      patterns.add('${localizations.predominantEmotion}: $topEmotion');
    }

    // Analizza frequenza
    if (dreams.length >= 7) {
      final recentDreams = await getRecentDreams();
      if (recentDreams.length >= 5) {
        patterns.add(
          localizations.veryActivePeriodAnalytics.replaceAll(
            '{count}',
            '${recentDreams.length}',
          ),
        );
      }
    }

    return patterns;
  }

  // Utility functions
  String _getWeekKey(DateTime date) {
    final weekNumber =
        ((date.difference(DateTime(date.year, 1, 1)).inDays) / 7).floor() + 1;
    return 'W$weekNumber ${date.year}';
  }

  List<String> _extractEmotionsFromText(
    String text,
    AppLocalizations localizations,
  ) {
    final emotionKeywords = {
      localizations.happiness: [
        'felice',
        'gioia',
        'allegro',
        'contento',
        'euforia',
        'beatitudine',
        'happy',
        'joy',
        'cheerful',
        'content',
        'euphoria',
        'bliss',
      ],
      localizations.fear: [
        'paura',
        'terrore',
        'spavento',
        'ansia',
        'timore',
        'angoscia',
        'fear',
        'terror',
        'fright',
        'anxiety',
        'dread',
        'anguish',
      ],
      localizations.sadness: [
        'triste',
        'dolore',
        'malinconia',
        'depressione',
        'pianto',
        'sad',
        'pain',
        'melancholy',
        'depression',
        'crying',
      ],
      localizations.anger: [
        'rabbia',
        'collera',
        'ira',
        'furore',
        'indignazione',
        'anger',
        'rage',
        'wrath',
        'fury',
        'indignation',
      ],
      localizations.surprise: [
        'sorpresa',
        'stupore',
        'meraviglia',
        'incredulità',
        'surprise',
        'amazement',
        'wonder',
        'disbelief',
      ],
      localizations.love: [
        'amore',
        'affetto',
        'tenerezza',
        'passione',
        'innamoramento',
        'love',
        'affection',
        'tenderness',
        'passion',
        'infatuation',
      ],
    };

    final foundEmotions = <String>[];
    final lowerText = text.toLowerCase();

    for (final emotion in emotionKeywords.entries) {
      for (final keyword in emotion.value) {
        if (lowerText.contains(keyword)) {
          foundEmotions.add(emotion.key);
          break;
        }
      }
    }

    return foundEmotions;
  }

  List<String> _extractKeywordsFromText(String text) {
    // Parole comuni da escludere
    final stopWords = {
      'il',
      'la',
      'di',
      'che',
      'e',
      'a',
      'da',
      'in',
      'un',
      'è',
      'per',
      'con',
      'non',
      'una',
      'su',
      'le',
      'si',
      'lo',
      'mi',
      'ma',
      'me',
      'ci',
      'ti',
      'ho',
      'hai',
      'ha',
      'sono',
      'era',
      'del',
      'dalla',
      'della',
      'questo',
      'quello',
      'come',
      'più',
      'molto',
      'anche',
      'suo',
      'sua',
      'loro',
      'quando',
      'dove',
      'cosa',
      'mentre',
      'dopo',
      'prima',
      'sempre',
      'mai',
      'poi',
      'ancora',
      'già',
      'solo',
      'tanto',
      'tutti',
      'tutto',
      'qui',
      'così',
      'ogni',
      'stesso',
      'altra',
      'altro',
      'altri',
      'altre',
      'nel',
      'alla',
      'sul',
      'nei',
      'alle',
      'sui',
      'agli',
    };

    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 3 && !stopWords.contains(word))
        .toList();

    return words;
  }
}
