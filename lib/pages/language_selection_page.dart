import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';

class LanguageSelectionPage extends StatelessWidget {
  final LanguageService languageService;

  const LanguageSelectionPage({super.key, required this.languageService});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.selectLanguage),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.light
                ? [
                    const Color(0xFFFCFCFD), // Bianco purissimo con sfumatura
                    const Color(0xFFF7F8FC), // Bianco con hint di viola
                    const Color(
                      0xFFF0F4FF,
                    ), // Bianco con tocco di blu molto tenue
                  ]
                : [
                    const Color(0xFF0F172A), // Blu scuro profondo
                    const Color(0xFF1E293B), // Blu scuro medio
                    const Color(0xFF334155), // Grigio-blu
                  ],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: LanguageService.supportedLanguages.length,
          itemBuilder: (context, index) {
            final language = LanguageService.supportedLanguages[index];
            final isSelected =
                language['code'] == languageService.currentLanguageCode;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: theme.colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      language['flag']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                title: Text(
                  language['name']!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  language['code'] == 'it'
                      ? 'Riconoscimento vocale in italiano'
                      : 'Speech recognition in English',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                        size: 28,
                      )
                    : null,
                onTap: () async {
                  if (!isSelected) {
                    await languageService.changeLanguage(language['code']!);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(localizations.languageChanged),
                                    Text(
                                      localizations.restartForFullEffect,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );

                      // Torna alla pagina precedente
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
