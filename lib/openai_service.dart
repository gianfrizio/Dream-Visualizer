import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config/api_config.dart';

class OpenAIService {
  final String apiKey = ApiConfig.openaiApiKey;

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

  // Le funzioni extractDreamElements e createVisualPrompt sono state rimosse
  // per semplificare il processo e migliorare la corrispondenza testo-immagine

  // Wrapper di sicurezza per l'estrazione degli elementi
  Future<String> generateDreamImage(String dreamText) async {
    // Parole vietate che richiedono sempre la riscrittura del prompt
    final bannedWords = [
      'uccidere',
      'ucciso',
      'uccisione',
      'morte',
      'morto',
      'morti',
      'assassin',
      'ammazz',
      'sangue',
      'arma',
      'pistola',
      'coltello',
      'fucile',
      'bomba',
      'violenza',
      'violent',
      'suicid',
      'impicc',
      'sparatoria',
      'strage',
      'massacro',
      'decapit',
      'squart',
      'stupro',
      'abuso',
      'abusi',
      'abbandono',
      'autolesion',
      'autodistr',
      'autodistruttivo',
      'rapina',
      'furto',
      'omicidio',
      'homicide',
      'kill',
      'murder',
      'blood',
      'weapon',
      'gun',
      'knife',
      'shoot',
      'shooting',
      'bomb',
      'rape',
      'abuse',
      'suicide',
      'hang',
      'massacre',
      'decapitate',
      'dismember',
      'slaughter',
      'dead',
      'death',
      'corpse',
      'cadavere',
      'cadaveri',
      'corpo senza vita',
      'corpi',
      'strangol',
      'strangle',
      'overdose',
      'overdosing',
      'overdosed',
      'overdose',
      'poison',
      'veleno',
      'velenato',
      'anneg',
      'annegato',
      'annegare',
      'drown',
      'drowned',
      'drowning',
    ];
    final lowerText = dreamText.toLowerCase();
    final containsBanned = bannedWords.any((w) => lowerText.contains(w));
    String prompt;
    if (containsBanned) {
      // Prompt sempre riscritto da GPT in chiave simbolica/oscura
      prompt = await _makePromptSafeWithGPT(dreamText);
    } else {
      prompt =
          "$dreamText, dreamlike atmosphere, surreal art style, high quality digital art";
    }

    final dallEUri = Uri.parse("https://api.openai.com/v1/images/generations");
    final headers = {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    };
    final body = jsonEncode({
      "model": "dall-e-3",
      "prompt": prompt.length > 1000 ? prompt.substring(0, 1000) : prompt,
      "n": 1,
      "size": "1024x1024",
      "quality": "standard",
      "style": "vivid",
    });

    final response = await http.post(dallEUri, headers: headers, body: body);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data'][0]['url'];
    }

    // 2. Se fallisce per policy (contenuto violento ecc.), riformula con GPT e riprova
    if (response.statusCode == 400 &&
        response.body.contains('content policy')) {
      // Chiedi a GPT di "ripulire" il prompt
      String safePrompt = await _makePromptSafeWithGPT(dreamText);
      final safeBody = jsonEncode({
        "model": "dall-e-3",
        "prompt": safePrompt.length > 1000
            ? safePrompt.substring(0, 1000)
            : safePrompt,
        "n": 1,
        "size": "1024x1024",
        "quality": "standard",
        "style": "vivid",
      });
      final safeResponse = await http.post(
        dallEUri,
        headers: headers,
        body: safeBody,
      );
      if (safeResponse.statusCode == 200) {
        final decoded = jsonDecode(safeResponse.body);
        return decoded['data'][0]['url'];
      } else {
        throw Exception(
          'Immagine bloccata per policy. Nessuna immagine generata.',
        );
      }
    }

    // 3. Altri errori
    throw Exception(
      'Errore nella generazione immagine: ${response.statusCode} - ${response.body}',
    );
  }

  // Usa GPT per "ripulire" il prompt e renderlo accettabile per DALL-E
  Future<String> _makePromptSafeWithGPT(String dreamText) async {
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
                "Sei un assistente che trasforma descrizioni di sogni in prompt visivi per DALL-E. Se il sogno contiene elementi violenti, espliciti, illegali, discriminatori o non conformi alle content policy di OpenAI, devi rimuoverli, trasformarli o sostituirli con simboli onirici innocui, metafore astratte o atmosfere surreali. Mantieni solo l'atmosfera generale, le emozioni e il simbolismo onirico, ma rendi il prompt sempre accettabile per la generazione di immagini. Non includere mai armi, sangue, violenza, nudità, atti illegali o contenuti sensibili. Restituisci solo il prompt visivo, senza spiegazioni.",
          },
          {
            "role": "user",
            "content": "Rendi questo prompt sicuro per DALL-E: $dreamText",
          },
        ],
        "max_tokens": 200,
        "temperature": 0.2,
      }),
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      String visualPrompt = decoded['choices'][0]['message']['content'].trim();
      return "$visualPrompt, dreamlike atmosphere, surreal art style, high quality digital art";
    } else {
      // Fallback: prompt generico
      return "dreamlike surreal atmosphere, artistic interpretation, high quality";
    }
  }

  // Nuovo metodo per creare prompt più diretto e fedele
  Future<String> createDirectDreamPrompt(String dreamText) async {
    try {
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
                  """Sei un esperto nella trasformazione di racconti onirici in prompt visuali per DALL-E. 

Il tuo compito è creare un prompt che rappresenti fedelmente il contenuto del sogno, mantenendo:
- Tutti gli elementi chiave menzionati
- L'atmosfera e le emozioni descritte
- I dettagli specifici del racconto
- Lo stile onirico e surreale

Aggiungi solo miglioramenti tecnici per la qualità dell'immagine, ma mantieni il contenuto fedele al sogno originale.

Restituisci solo il prompt visivo, senza spiegazioni.""",
            },
            {
              "role": "user",
              "content":
                  "Trasforma questo sogno in un prompt visivo fedele: $dreamText",
            },
          ],
          "max_tokens": 200,
          "temperature": 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        String visualPrompt = decoded['choices'][0]['message']['content']
            .trim();

        // Aggiungi suffissi per qualità senza alterare il contenuto
        return "$visualPrompt, dreamlike atmosphere, surreal art style, high quality digital art";
      } else {
        // Fallback: usa il testo originale con miglioramenti minimi
        return "$dreamText, dreamlike surreal atmosphere, artistic interpretation, high quality";
      }
    } catch (e) {
      // Fallback: testo originale più sicuro
      return "$dreamText, dream-like, surreal, artistic style";
    }
  }

  // Funzione per ottenere solo il prompt (utile per debug)
  Future<String> getImagePrompt(String dreamText) async {
    try {
      return await createDirectDreamPrompt(dreamText);
    } catch (e) {
      return "Errore nella generazione del prompt: $e";
    }
  }
}
