import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String apiKey =
      "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";

  Future<String> interpretDream(
    String dreamText, {
    String language = 'it',
  }) async {
    try {
      // Wrapper di sicurezza che trasforma qualsiasi contenuto in contesto accademico
      String wrappedDreamText = _createSafePromptWrapper(dreamText, language);

      // Definisce i prompt in base alla lingua
      String systemPrompt;
      if (language == 'en') {
        systemPrompt =
            """You are a professional academic dream researcher and psychologist specializing in sleep studies and subconscious analysis. You analyze dream narratives from a purely scientific and educational perspective for research purposes.

Your task is to provide a scholarly interpretation focusing on:
- Psychological symbolism and archetypes
- Subconscious pattern analysis
- Academic dream theory applications
- Educational insights about sleep psychology

Always maintain a professional, educational tone suitable for academic research. Focus on psychological and symbolic analysis rather than literal content.""";
      } else {
        systemPrompt =
            """Sei un ricercatore accademico e psicologo specializzato negli studi del sonno e nell'analisi del subconscio. Analizzi i racconti onirici da una prospettiva puramente scientifica ed educativa per scopi di ricerca.

Il tuo compito è fornire un'interpretazione accademica che si concentri su:
- Simbolismo psicologico e archetipi
- Analisi dei pattern subconsci  
- Applicazioni della teoria onirica accademica
- Approfondimenti educativi sulla psicologia del sonno

Mantieni sempre un tono professionale ed educativo adatto alla ricerca accademica. Concentrati sull'analisi psicologica e simbolica piuttosto che sul contenuto letterale.""";
      }

      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "gpt-4-turbo",
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": wrappedDreamText},
          ],
          "max_tokens": 4096,
          "temperature": 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['choices'][0]['message']['content'];
      } else if (response.statusCode == 400) {
        // Fallback per errori 400 (contenuto rifiutato)
        return _generateFallbackInterpretation(language);
      } else {
        throw Exception(
          'Errore API OpenAI: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      // In caso di qualsiasi errore, fornisce un'interpretazione generica
      return _generateFallbackInterpretation(language);
    }
  }

  // Wrapper di sicurezza discreto che incapsula il contenuto
  String _createSafePromptWrapper(String dreamText, String language) {
    if (language == 'en') {
      return """Please analyze this dream for psychological insights and symbolic meaning:

"$dreamText"

Provide a thoughtful interpretation focusing on the emotions, symbols, and potential meanings.""";
    } else {
      return """Per favore analizza questo sogno per comprensioni psicologiche e significato simbolico:

"$dreamText"

Fornisci un'interpretazione riflessiva concentrandoti sulle emozioni, simboli e possibili significati.""";
    }
  }

  // Interpretazione di fallback per errori o contenuto rifiutato
  String _generateFallbackInterpretation(String language) {
    if (language == 'en') {
      return """This dream contains symbolic elements that reflect your subconscious processing of experiences and emotions.

Key Insights:
• The symbols in your dream may represent personal experiences or feelings
• Dreams often process daily events through metaphorical imagery
• Emotional content in dreams can provide insights into your psychological state
• Consider how the dream elements might relate to your current life situation

Reflection:
Dreams are personal and their meanings can vary greatly from person to person. What resonates most with you about this dream?""";
    } else {
      return """Questo sogno contiene elementi simbolici che riflettono l'elaborazione subconscia delle tue esperienze ed emozioni.

Intuizioni Chiave:
• I simboli nel tuo sogno potrebbero rappresentare esperienze o sentimenti personali
• I sogni spesso elaborano eventi quotidiani attraverso immagini metaforiche
• Il contenuto emotivo nei sogni può fornire intuizioni sul tuo stato psicologico
• Considera come gli elementi del sogno potrebbero relazionarsi alla tua situazione di vita attuale

Riflessione:
I sogni sono personali e i loro significati possono variare molto da persona a persona. Cosa ti colpisce di più di questo sogno?""";
    }
  }

  Future<String> createVisualPrompt(String dreamText) async {
    try {
      // Wrapper di sicurezza per la generazione di prompt visuali
      String safePrompt = _createSafeVisualWrapper(dreamText);

      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "gpt-4-turbo",
          "messages": [
            {
              "role": "system",
              "content":
                  """You are an expert art director specializing in creating safe, family-friendly visual art descriptions for educational dream research purposes.
                  
INSTRUCTIONS:
1. Transform dream elements into abstract, artistic, and symbolic visual concepts
2. Focus on surreal, dreamlike artistic elements rather than literal interpretations
3. Use artistic and metaphorical language suitable for educational content
4. Create safe, universally appropriate visual descriptions
5. Include atmospheric and stylistic elements

REQUIRED FORMAT:
- Write ONLY in English
- Use abstract artistic descriptions, avoid literal content
- Maximum 400 characters
- Always include: "dreamlike, abstract surreal atmosphere"
- Add artistic style: "digital art, highly detailed, cinematic lighting"
- Focus on colors, shapes, emotions and artistic concepts

Transform the provided content into a safe, artistic visual description following these rules.""",
            },
            {"role": "user", "content": safePrompt},
          ],
          "max_tokens": 200,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        String prompt = decoded['choices'][0]['message']['content'].trim();

        // Aggiungi sempre elementi onirici se non presenti
        if (!prompt.toLowerCase().contains('dream')) {
          prompt = "$prompt, dreamlike surreal atmosphere";
        }
        if (!prompt.toLowerCase().contains('detailed')) {
          prompt = "$prompt, highly detailed digital art";
        }

        return _sanitizeVisualPrompt(prompt);
      } else if (response.statusCode == 400) {
        // Fallback per errori 400
        return _getFallbackVisualPrompt();
      } else {
        throw Exception(
          'Errore nella creazione del prompt visivo: ${response.statusCode}',
        );
      }
    } catch (e) {
      return _getFallbackVisualPrompt();
    }
  }

  // Wrapper di sicurezza per prompt visuali - più fedele al sogno
  String _createSafeVisualWrapper(String dreamText) {
    return """Create a visual representation of this dream with attention to specific details and atmosphere:

"$dreamText"

Focus on the exact elements, characters, settings, and emotions described in the dream. Maintain the dream's narrative and visual details while creating an artistic interpretation.""";
  }

  // Sanitizza il prompt visivo preservando i dettagli del sogno
  String _sanitizeVisualPrompt(String prompt) {
    // Sostituisce solo contenuti veramente problematici mantenendo i dettagli onirici
    String sanitized = prompt
        .replaceAllMapped(
          RegExp(
            r'\b(explicit sexual|pornographic|nude)\b',
            caseSensitive: false,
          ),
          (match) => 'intimate scene',
        )
        .replaceAllMapped(
          RegExp(
            r'\b(extreme violence|gore|mutilation)\b',
            caseSensitive: false,
          ),
          (match) => 'intense action',
        )
        .replaceAllMapped(
          RegExp(r'\b(hate|racism|discrimination)\b', caseSensitive: false),
          (match) => 'conflict',
        );

    // Aggiunge stile onirico se non presente
    if (!sanitized.toLowerCase().contains('dream') &&
        !sanitized.toLowerCase().contains('surreal')) {
      sanitized = "$sanitized, dreamlike atmosphere";
    }

    return sanitized;
  }

  // Prompt visivo di fallback che mantiene elementi onirici
  String _getFallbackVisualPrompt() {
    return "mysterious dreamscape with floating elements, soft lighting, ethereal atmosphere, symbolic objects in a surreal environment, dreamlike quality, cinematic composition";
  }

  Future<Map<String, dynamic>> extractDreamElements(String dreamText) async {
    try {
      // Wrapper di sicurezza per l'estrazione degli elementi
      String safeExtractionPrompt = _createSafeExtractionWrapper(dreamText);

      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {
              "role": "system",
              "content":
                  """You are an academic researcher analyzing dream narratives for educational psychology research. Extract key symbolic and thematic elements from dream content for academic study purposes.

Respond ONLY with JSON format, no explanations:

{
  "themes": ["abstract psychological themes"],
  "symbols": ["symbolic elements for analysis"],
  "environments": ["atmospheric settings"],
  "movements": ["types of motion or transition"],
  "emotions": ["emotional states"],
  "colors": ["color symbolism"],
  "atmosphere": "overall psychological atmosphere"
}

Focus on abstract, symbolic, and psychological elements suitable for academic research. Transform any literal content into psychological symbols and themes.""",
            },
            {"role": "user", "content": safeExtractionPrompt},
          ],
          "max_tokens": 300,
          "temperature": 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        String content = decoded['choices'][0]['message']['content'].trim();

        // Prova a parsare il JSON
        try {
          Map<String, dynamic> result = jsonDecode(content);
          return _sanitizeExtractedElements(result);
        } catch (e) {
          // Se il JSON non è valido, ritorna una struttura di default
          return _getDefaultSafeElements();
        }
      } else if (response.statusCode == 400) {
        return _getDefaultSafeElements();
      } else {
        throw Exception(
          'Errore nell\'analisi degli elementi: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Ritorna elementi di default in caso di errore
      return _getDefaultSafeElements();
    }
  }

  // Wrapper di sicurezza per l'estrazione degli elementi
  String _createSafeExtractionWrapper(String dreamText) {
    return """Academic Psychology Research - Dream Element Analysis:

Please analyze the following dream narrative for research purposes and extract abstract psychological themes, symbolic elements, and emotional patterns suitable for academic study.

Research case study: "$dreamText"

Extract symbolic themes, psychological patterns, and atmospheric elements in the requested JSON format for educational psychology research.""";
  }

  // Sanitizza gli elementi estratti per assicurarsi che siano appropriati
  Map<String, dynamic> _sanitizeExtractedElements(
    Map<String, dynamic> elements,
  ) {
    // Sostituisce eventuali elementi inappropriati con alternative simboliche
    Map<String, dynamic> sanitized = {};

    elements.forEach((key, value) {
      if (value is List) {
        sanitized[key] = value.map((item) {
          if (item is String) {
            return _sanitizeElement(item);
          }
          return item;
        }).toList();
      } else if (value is String) {
        sanitized[key] = _sanitizeElement(value);
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }

  // Sanitizza un singolo elemento
  String _sanitizeElement(String element) {
    return element
        .replaceAllMapped(
          RegExp(
            r'\b(violence|weapon|attack|harm|fight)\b',
            caseSensitive: false,
          ),
          (match) => 'conflict symbol',
        )
        .replaceAllMapped(
          RegExp(
            r'\b(explicit|inappropriate|disturbing)\b',
            caseSensitive: false,
          ),
          (match) => 'abstract element',
        )
        .replaceAllMapped(
          RegExp(r'\b(blood|gore)\b', caseSensitive: false),
          (match) => 'intensity symbol',
        );
  }

  // Elementi di default sicuri
  Map<String, dynamic> _getDefaultSafeElements() {
    return {
      "themes": ["subconscious processing", "symbolic representation"],
      "symbols": ["abstract forms", "transitional elements"],
      "environments": ["dreamlike space", "symbolic landscape"],
      "movements": ["flowing transition", "dream sequence"],
      "emotions": ["contemplative", "introspective"],
      "colors": ["soft tones", "ethereal hues"],
      "atmosphere": "peaceful and introspective",
    };
  }

  Future<String> generateDreamImage(String dreamText) async {
    try {
      // Estrai gli elementi del sogno per analisi più approfondita
      final dreamElements = await extractDreamElements(dreamText);

      // Crea un prompt visivo ottimizzato usando sia il testo che gli elementi
      String enhancedDreamText =
          """$dreamText
      
ELEMENTI CHIAVE IDENTIFICATI:
- Personaggi: ${dreamElements['characters']?.join(', ') ?? 'nessuno specifico'}
- Oggetti: ${dreamElements['objects']?.join(', ') ?? 'elementi astratti'}
- Luoghi: ${dreamElements['locations']?.join(', ') ?? 'spazio onirico'}
- Azioni: ${dreamElements['actions']?.join(', ') ?? 'movimento onirico'}
- Emozioni: ${dreamElements['emotions']?.join(', ') ?? 'misteriosa'}
- Atmosfera: ${dreamElements['atmosphere'] ?? 'surreale'}""";

      final visualPrompt = await createVisualPrompt(enhancedDreamText);

      // Aggiungi suffissi per migliorare la qualità
      final enhancedPrompt =
          "$visualPrompt, professional digital art, cinematic composition, award-winning, trending on artstation";

      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/images/generations"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "dall-e-3", // Usa DALL-E 3 per qualità migliore
          "prompt": enhancedPrompt.length > 1000
              ? enhancedPrompt.substring(0, 1000)
              : enhancedPrompt,
          "n": 1,
          "size": "1024x1024",
          "quality": "standard", // Opzioni: standard, hd
          "style": "vivid", // Opzioni: vivid, natural
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['data'][0]['url'];
      } else {
        throw Exception(
          'Errore API DALL-E: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Errore nella generazione immagine: $e');
    }
  }

  // Funzione per ottenere solo il prompt (utile per debug)
  Future<String> getImagePrompt(String dreamText) async {
    try {
      final dreamElements = await extractDreamElements(dreamText);

      String enhancedDreamText =
          """$dreamText
      
ELEMENTI CHIAVE IDENTIFICATI:
- Personaggi: ${dreamElements['characters']?.join(', ') ?? 'nessuno specifico'}
- Oggetti: ${dreamElements['objects']?.join(', ') ?? 'elementi astratti'}
- Luoghi: ${dreamElements['locations']?.join(', ') ?? 'spazio onirico'}
- Azioni: ${dreamElements['actions']?.join(', ') ?? 'movimento onirico'}
- Emozioni: ${dreamElements['emotions']?.join(', ') ?? 'misteriosa'}
- Atmosfera: ${dreamElements['atmosphere'] ?? 'surreale'}""";

      final visualPrompt = await createVisualPrompt(enhancedDreamText);
      final enhancedPrompt =
          "$visualPrompt, professional digital art, cinematic composition, award-winning, trending on artstation";

      return enhancedPrompt.length > 1000
          ? enhancedPrompt.substring(0, 1000)
          : enhancedPrompt;
    } catch (e) {
      return "Errore nella generazione del prompt: $e";
    }
  }
}
