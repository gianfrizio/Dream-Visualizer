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
      // Definisce i prompt in base alla lingua
      String systemPrompt;
      if (language == 'en') {
        systemPrompt =
            """You are an expert dream interpreter. Analyze and interpret the provided dream in a creative, poetic and meaningful way. Provide a detailed interpretation that includes:
- Symbolic meaning of the main elements
- Possible messages from the subconscious
- Connections with real life aspects
- Useful advice or reflections

Respond in English in an engaging and professional manner.""";
      } else {
        systemPrompt =
            """Sei un esperto interprete di sogni. Analizza e interpreta il sogno fornito in modo creativo, poetico e significativo. Fornisci un'interpretazione dettagliata che includa:
- Significato simbolico degli elementi principali
- Possibili messaggi del subconscio
- Connessioni con aspetti della vita reale
- Consigli o riflessioni utili

Rispondi in italiano in modo coinvolgente e professionale.""";
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
            {"role": "user", "content": dreamText},
          ],
          "max_tokens": 4096,
          "temperature": 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['choices'][0]['message']['content'];
      } else {
        throw Exception(
          'Errore API OpenAI: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Errore di connessione: $e');
    }
  }

  Future<String> createVisualPrompt(String dreamText) async {
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
                  """Sei un esperto nel convertire sogni in prompt DALL-E precisi e dettagliati. 
                  
ISTRUZIONI SPECIFICHE:
1. Identifica gli elementi chiave del sogno (persone, oggetti, luoghi, azioni, emozioni)
2. Trasforma ogni elemento in descrizioni visive concrete e specifiche
3. Aggiungi dettagli atmosferici che catturino l'essenza emotiva del sogno
4. Specifica uno stile artistico appropriato (surreale, onirico, fantasy, etc.)
5. Includi dettagli di illuminazione, colori e composizione

FORMATO RICHIESTO:
- Scrivi SOLO in inglese
- Usa descrizioni visive specifiche, non concetti astratti
- Massimo 400 caratteri
- Includi sempre: "dreamlike, surreal atmosphere" 
- Aggiungi dettagli di stile: "digital art, highly detailed, cinematic lighting"

ESEMPIO: Se il sogno parla di "volare sopra una città", scrivi: "person flying above glowing cityscape at sunset, ethereal wings of light, golden clouds, dreamlike surreal atmosphere, birds-eye view, digital art, highly detailed, cinematic lighting"

Trasforma il sogno fornito seguendo queste regole.""",
            },
            {"role": "user", "content": dreamText},
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

        return prompt;
      } else {
        throw Exception(
          'Errore nella creazione del prompt visivo: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Errore nella creazione del prompt visivo: $e');
    }
  }

  Future<Map<String, dynamic>> extractDreamElements(String dreamText) async {
    try {
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
                  """Analizza il sogno e estrai gli elementi chiave in formato JSON. Rispundi SOLO con il JSON, senza altre spiegazioni.

FORMATO:
{
  "characters": ["lista delle persone/creature presenti"],
  "objects": ["lista degli oggetti importanti"],
  "locations": ["luoghi/ambientazioni"],
  "actions": ["azioni principali che avvengono"],
  "emotions": ["emozioni predominanti"],
  "colors": ["colori menzionati o suggeriti"],
  "atmosphere": "descrizione dell'atmosfera generale"
}

Esempio: {"characters": ["unknown person"], "objects": ["flying car"], "locations": ["futuristic city"], "actions": ["flying"], "emotions": ["excitement", "wonder"], "colors": ["neon blue", "golden"], "atmosphere": "futuristic and magical"}""",
            },
            {"role": "user", "content": dreamText},
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
          return jsonDecode(content);
        } catch (e) {
          // Se il JSON non è valido, ritorna una struttura di default
          return {
            "characters": [],
            "objects": [],
            "locations": ["abstract dreamscape"],
            "actions": ["dream sequence"],
            "emotions": ["mysterious"],
            "colors": ["ethereal"],
            "atmosphere": "dreamlike and surreal",
          };
        }
      } else {
        throw Exception(
          'Errore nell\'analisi degli elementi: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Ritorna elementi di default in caso di errore
      return {
        "characters": [],
        "objects": [],
        "locations": ["abstract dreamscape"],
        "actions": ["dream sequence"],
        "emotions": ["mysterious"],
        "colors": ["ethereal"],
        "atmosphere": "dreamlike and surreal",
      };
    }
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
