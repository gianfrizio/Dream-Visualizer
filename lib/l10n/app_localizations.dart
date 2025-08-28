import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Traduzioni per l'app
  static final Map<String, Map<String, String>> _localizedValues = {
    'it': {
      'appTitle': 'Dreamsy',
      'dreamInterpretation': 'Interpretazione dei Sogni',
      'tapToRecord': 'Pronto per registrare',
      'recording': 'Registrazione in corso...',
      'stopRecording': 'Ferma registrazione',
      'editText': 'Modifica testo',
      'saveText': 'Salva testo',
      'cancelEdit': 'Annulla',
      'processingDream': 'Elaborazione sogno...',
      'generatingImage': 'Generazione immagine...',
      'testDemo': 'Test Demo',
      'interpretation': 'Interpretazione',
      'dreamSaved': 'Sogno salvato automaticamente',
      'menu': 'Menu',
      'history': 'Cronologia',
      'analytics': 'Statistiche',
      'settings': 'Impostazioni',
      'themeSettings': 'Tema',
      'lightTheme': 'Chiaro',
      'darkTheme': 'Scuro',
      'systemTheme': 'Sistema',
      'selectTheme': 'Seleziona tema',
      'language': 'Lingua',
      'noDataAvailable': 'Nessun dato disponibile',
      'recordDreamsToSeeAnalytics':
          'Registra e interpreta alcuni sogni\\nper vedere le tue analytics!',
      'generalStats': 'Statistiche Generali',
      'totalDreams': 'Sogni Totali',
      'averageWords': 'Parole Medie',
      'withImages': 'Con Immagini',
      'activePeriod': 'Periodo Attivo',
      'emotionAnalysis': 'Analisi Emozioni',
      'dreamsByTimeOfDay': 'Sogni per Fascia Oraria',
      'patternsAndInsights': 'Pattern e Insights',
      'recurringKeywords': 'Parole Chiave Ricorrenti',
      'recentActivity': 'Attività Recente',
      'dreamsInLast7Days': 'sogni negli ultimi 7 giorni',
      'veryActivePeriod': 'Periodo molto attivo!',
      'goodActivity': 'Buona attività',
      'recordingManyDreams': 'Stai registrando molti sogni ultimamente',
      'keepRecordingDreams': 'Continua a registrare i tuoi sogni',
      'errorLoadingAnalytics': 'Errore nel caricamento analytics',
      'errorLoadingDreams': 'Errore nel caricamento dei sogni',
      'recordSomeDreams':
          'Registra e interpreta alcuni sogni\nper vedere le tue analytics!',
      'generalStatistics': 'Statistiche Generali',
      'interpreted': 'Interpretato',
      'withImage': 'Con Immagine',
      'morning': 'Mattina (6-12)',
      'afternoon': 'Pomeriggio (12-18)',
      'evening': 'Sera (18-22)',
      'night': 'Notte (22-6)',
      'predominantEmotion': 'Emozione predominante',
      'veryActivePeriodAnalytics':
          'Periodo molto attivo: {count} sogni negli ultimi 7 giorni',
      'happiness': 'Felicità',
      'fear': 'Paura',
      'sadness': 'Tristezza',
      'anger': 'Rabbia',
      'surprise': 'Sorpresa',
      'love': 'Amore',
      'recurringElements': 'Elementi ricorrenti',
      'speechNotAvailable': 'Riconoscimento vocale non disponibile',
      'speechPermissionDenied': 'Permesso microfono negato',
      'speechRecognitionError': 'Errore nel riconoscimento vocale',
      'noInternetConnection': 'Nessuna connessione internet',
      'selectLanguage': 'Seleziona Lingua',
      'languageChanged': 'Lingua cambiata',
      'restartForFullEffect': 'Riavvia l\'app per l\'effetto completo',
      'speakFreely': 'Parla liberamente',
      'tapToStart': 'Tocca per iniziare',
      'writeDreamHere': '✨ Racconta il tuo sogno qui...',
      'tapToWriteDream': '💭 Tocca qui per scrivere il tuo sogno...',
      'save': 'Salva',
      'cancel': 'Annulla',
      'continuousListening':
          'Ascolto continuo attivo. Premi "Ferma" quando hai finito.',
      'recordDream': 'Registra Sogno',
      'continueTalking': 'Continua a Parlare',
      'interpretWithAI': 'Interpreta sogno',
      'demoTest': 'Demo Test',
      'dreamInterpretationTitle': 'Interpretazione del Sogno',
      'dreamImageTitle': 'Immagine del Sogno',
      'loadingImage': 'Caricamento immagine...',
      'cannotLoadImage': 'Impossibile caricare l\'immagine',
      'tryAgainLater': 'Riprova più tardi',
      'myDreams': 'I Miei Sogni',
      'noDreamsYet': 'Nessun sogno ancora',
      'yourInterpretedDreamsWillAppearHere':
          'I tuoi sogni interpretati appariranno qui.\nRegistra il tuo primo sogno per iniziare!',
      'startRecording': 'Inizia a registrare i tuoi sogni!',
      'deleteDream': 'Elimina Sogno',
      'confirmDelete': 'Confermi di voler eliminare questo sogno?',
      'delete': 'Elimina',
      'deleteAll': 'Elimina Tutti',
      'deleteAllDreams': 'Elimina Tutti i Sogni',
      'confirmDeleteAll': 'Confermi di voler eliminare tutti i sogni?',
      'dreamDeleted': 'Sogno eliminato',
      'allDreamsDeleted': 'Tutti i sogni eliminati',
      'dreamDetails': 'Dettagli Sogno',
      'yourDream': '🌙 Il Tuo Sogno',
      'interpretationTitle': '🔮 Interpretazione',
      'visualization': '🎨 Visualizzazione',
      'imageNotAvailable': 'Immagine non disponibile',
      'statistics': '📊 Statistiche',
      'dreamsSaved': 'Sogni Salvati',
      'dataManagement': '💾 Gestione Dati',
      'deleteAllDreamsSettings': 'Elimina Tutti i Sogni',
      'removeAllSavedDreams': 'Rimuovi tutti i sogni salvati',
      'appInfo': '📱 Informazioni App',
      'version': 'Versione',
      'developer': 'Sviluppatore',
      'developedBy': 'Sviluppato da',
      'dreamVisualizerTeam': 'Dream Visualizer Team',
      'aiFunctionality': '🤖 Funzionalità AI',
      'dreamInterpretationFeature': 'Interpretazione dei Sogni',
      'poweredByGPT4': 'Powered by OpenAI GPT-4 Turbo',
      'imageGeneration': 'Generazione Immagini',
      'poweredByDalle': 'Powered by DALL-E 3',
      'speechRecognition': 'Riconoscimento Vocale',
      'speechToTextIntegrated': 'Speech-to-Text integrato',
      'noDreamsToDelete': 'Non ci sono sogni da eliminare',
      'warning': '⚠️ Attenzione',
      'deleteAllConfirmation':
          'Stai per eliminare tutti i {count} sogni salvati.\n\nQuesta azione non può essere annullata. Sei sicuro?',
      'deleteEverything': 'Elimina Tutto',
      'operationCompleted': 'Operazione completata',
      'noDreamRecorded':
          '⚠️ Nessun sogno registrato! Registra prima il tuo sogno.',
      'generatingDemoInterpretation': 'Generando interpretazione demo...',
      'analyzingDream': 'Sto analizzando il sogno...',
      'analyzingVisualElements': '🎨 Analizzando elementi visuali del sogno...',
      'analysisError': '❌ Errore nell\'analisi del sogno',
      'possibleCauses': 'Possibili cause:',
      'internetProblem': '• Problema di connessione internet',
      'invalidApiKey': '• Chiave API non valida',
      'usageLimitReached': '• Limite di utilizzo raggiunto',
      'checkConnectionAndRetry': 'Controlla la tua connessione e riprova.',
      'dreamSavedAutomatically': 'Sogno salvato automaticamente',
      'demoInterpretationText':
          '🌟 **Interpretazione Demo del tuo sogno:**\n\nIl tuo sogno rivela un viaggio interiore profondo. Gli elementi che hai descritto simboleggiano:\n\n• **Trasformazione personale** - Stai attraversando un periodo di crescita\n• **Nuove opportunità** - Il subconscio ti sta preparando per cambiamenti positivi\n• **Creatività** - La tua mente sta elaborando nuove idee e possibilità\n\n✨ Questo sogno suggerisce che sei pronto per abbracciare nuove sfide e scoprire aspetti nascosti di te stesso.\n\n💫 I simboli onirici indicano un periodo favorevole per prendere decisioni importanti e seguire la tua intuizione.\n\n*Questa è una demo. Per l\'interpretazione AI completa, configura la chiave API OpenAI.*',
      'close': 'Chiudi',
      'sogna': 'Sogna',

      // Dream Tags - Italian
      'tagPositiveDream': 'Sogno Positivo',
      'tagNightmare': 'Incubo',
      'tagMelancholicDream': 'Sogno Malinconico',
      'tagRomanticDream': 'Sogno Romantico',
      'tagSereneDream': 'Sogno Sereno',
      'tagHome': 'Casa',
      'tagSchool': 'Scuola',
      'tagWork': 'Lavoro',
      'tagNature': 'Natura',
      'tagUrban': 'Urbano',
      'tagSkyFlight': 'Cielo/Volo',
      'tagFamily': 'Famiglia',
      'tagFriends': 'Amici',
      'tagRelationships': 'Relazioni',
      'tagUnknownPeople': 'Persone Sconosciute',
      'tagMovement': 'Movimento',
      'tagCommunication': 'Comunicazione',
      'tagCreativity': 'Creatività',
      'tagLearning': 'Apprendimento',
      'tagLucidDream': 'Sogno Lucido',
      'tagRecurrentDream': 'Sogno Ricorrente',

      // Additional Authentication & Cloud Sync - Italian
      'signInWithGoogle': 'Accedi con Google',
      'signInWithEmail': 'Accedi con Email',
      'createAccount': 'Crea Account',
      'authenticationFailed': 'Autenticazione fallita',
      'invalidCredentials': 'Credenziali non valide',
      'userNotFound': 'Utente non trovato',
      'emailAlreadyInUse': 'Email già in uso',
      'weakPassword': 'Password troppo debole',
      'syncNow': 'Sincronizza Ora',
      'autoSync': 'Sync Automatica',
      'lastSync': 'Ultima Sincronizzazione',
      'syncInProgress': 'Sincronizzazione in corso...',
      'syncCompleted': 'Sincronizzazione completata',
      'syncFailed': 'Sincronizzazione fallita',
      'uploadDream': 'Carica Sogno',
      'downloadDreams': 'Scarica Sogni',
      'storageUsed': 'Spazio Utilizzato',
      'deleteCloudData': 'Elimina Dati Cloud',
      'deleteCloudDataWarning':
          'Questa azione eliminerà tutti i tuoi dati dal cloud. Continuare?',
      'enableBiometric': 'Abilita Biometrica',
      'biometricRequired': 'Autenticazione biometrica richiesta',
      'biometricSuccess': 'Autenticazione riuscita',
      'biometricFailed': 'Autenticazione fallita',
      'appLocked': 'App Bloccata',
      'unlockWithBiometric': 'Sblocca con biometrica',
      'authenticateToAccessDreams': 'Autenticati per accedere ai tuoi sogni',
      'authenticationError': 'Errore durante l\'autenticazione',
      'biometricAuthRequired': 'Autenticazione Richiesta',
      'authenticating': 'Autenticazione in corso...',
      'authenticateNow': 'Autentica Ora',
      'exitApp': 'Esci dall\'App',
      'noBiometricsAvailable': 'Nessun metodo biometrico disponibile',
      'fingerprint': 'Impronta digitale',
      'faceId': 'Face ID',
      'iris': 'Scansione dell\'iride',
      'biometricsAvailable': 'Autenticazione biometrica disponibile',
      'availableMethods': 'Metodi disponibili',

      // Community translations
      'community': 'Community',
      'explore': 'Esplora',
      'searchDreams': 'Cerca sogni...',
      'noDreamsPublished': 'Nessun sogno pubblicato',
      'publishFirstDream':
          'Pubblica il tuo primo sogno per condividerlo con la community!',
      'loginRequired': 'Accesso richiesto',
      'loginToAccessCommunity':
          'Effettua l\'accesso per accedere alle funzionalità community',
      'login': 'Accedi',
      'loginNotImplemented': 'Login non ancora implementato',
      'retry': 'Riprova',
      'noDreamsFound': 'Nessun sogno trovato',
      'share': 'Condividi',
      'report': 'Segnala',
      'readMore': 'Leggi di più',
      'dream': 'Sogno',
      'tags': 'Tag',
      'comments': 'Commenti',
      'noComments': 'Nessun commento ancora',
      'writeComment': 'Scrivi un commento...',
      'reportDream': 'Segnala Sogno',
      'selectReportReason': 'Seleziona il motivo della segnalazione:',
      'inappropriateContent': 'Contenuto inappropriato',
      'spam': 'Spam',
      'other': 'Altro',
      'submit': 'Invia',
      'reportSubmitted': 'Segnalazione inviata',
      // Security translations
      'security': 'Sicurezza',
      'biometricLock': 'Blocco Biometrico',
      'enableBiometricAuth': 'Abilita autenticazione biometrica',
      'biometricDescription':
          'Proteggi l\'app con impronte digitali o riconoscimento facciale',
      'cloudSync': 'Sincronizzazione Cloud',
      'enableCloudSync': 'Abilita sincronizzazione cloud',
      'cloudSyncDescription':
          'Sincronizza i tuoi sogni in modo sicuro su Firebase',
      'encryption': 'Crittografia',
      'dataEncryption': 'Crittografia Dati',
      'encryptionDescription':
          'I tuoi dati sono protetti con crittografia AES-256',
      // Login translations
      'register': 'Registrati',
      'loginToAccount': 'Accedi al tuo account',
      'createNewAccount': 'Crea un nuovo account',
      'displayName': 'Nome visualizzato',
      'nameRequired': 'Il nome è richiesto',
      'email': 'Email',
      'emailRequired': 'L\'email è richiesta',
      'emailInvalid': 'Email non valida',
      'password': 'Password',
      'passwordRequired': 'La password è richiesta',
      'passwordTooShort': 'La password deve essere di almeno 6 caratteri',
      'forgotPassword': 'Password dimenticata?',
      'or': 'o',
      'noAccount': 'Non hai un account?',
      'alreadyHaveAccount': 'Hai già un account?',
      'resetPassword': 'Reimposta Password',
      'resetPasswordDescription':
          'Inserisci la tua email per ricevere il link di reset',
      'send': 'Invia',
      'resetEmailSent': 'Email di reset inviata',
      'resetEmailError': 'Errore nell\'invio dell\'email',
      'logout': 'Disconnetti',

      // Dynamic advice messages - Italian
      'adviceEmptyText':
          '✍️ Scrivi il tuo sogno nel campo di testo sopra...\n\nPer ottenere un\'interpretazione accurata, descrivi il tuo sogno con almeno qualche dettaglio. Più dettagli fornisci, migliore sarà l\'analisi!',
      'adviceShortText':
          '📝 Continua a scrivere...\n\nIl testo è ancora troppo breve per un\'interpretazione accurata. Aggiungi più dettagli del tuo sogno: dove eri, cosa succedeva, come ti sentivi, chi c\'era con te.',
      'adviceFewWords':
          '💭 Aggiungi più dettagli...\n\nPer una buona interpretazione servono almeno alcune parole che descrivano il sogno. Racconta cosa hai sognato in modo più dettagliato.',
      'adviceReadyToInterpret':
          '✅ Testo pronto per l\'interpretazione!\n\nOra puoi premere "Interpreta sogno" per ottenere un\'analisi dettagliata del tuo sogno.',

      // Dream interpretation page - Italian
      'interpretingDream': 'Sto interpretando il tuo sogno...',
      'generatingImageText': 'Generando immagine del sogno...',
      'waitingMessage': 'Un momento di pazienza...',
      'doNotLeaveDuringInterpretation':
          'Per favore, non chiudere questa pagina o uscire dall\'app finché l\'interpretazione non è completata.',
      'yourDreamTitle': 'Il tuo sogno',
      'dreamVisualization': 'Visualizzazione del sogno',
      'imageLoadError': 'Impossibile caricare l\'immagine',
      'dreamSavedSuccessfully': 'Sogno salvato nella cronologia!',
      'suggestions': 'Suggerimenti',
      'profile': 'Profilo',
      'dreamVisualizerUser': 'Utente Dream Visualizer',
      'memberSince': 'Membro da Agosto 2025',
      'changeLanguage': 'Cambia lingua',
      'languageSelection': 'Selezione Lingua',
      'about': 'Informazioni',
      'appVersion': 'Versione App',
      'aboutAppDescription':
          'Dream Visualizer ti aiuta a interpretare e visualizzare i tuoi sogni usando l\'intelligenza artificiale.',

      // Profile page sections - Italian
      'personalInfo': 'Informazioni Personali',
      'editNameEmailDetails': 'Modifica nome, email e altri dettagli',
      'privacySecurity': 'Privacy e Sicurezza',
      'managePrivacySettings': 'Gestisci le tue impostazioni di privacy',
      'notifications': 'Notifiche',
      'manageNotificationSettings': 'Gestisci le tue notifiche',
      'aboutApp': 'Info App',
      'appInfoAndVersion': 'Informazioni sull\'app e versione',

      // Profile dialog messages - Italian
      'personalInfoDialog':
          'Questa funzionalità sarà disponibile presto per permetterti di modificare le tue informazioni personali.',
      'privacySettingsDialog':
          'Gestisci le tue impostazioni di privacy e sicurezza. Questa funzionalità sarà disponibile presto.',
      'notificationSettingsTitle': 'Impostazioni Notifiche',
      'notificationSettingsDialog':
          'Personalizza le tue notifiche. Questa funzionalità sarà disponibile presto.',
      'ok': 'OK',
      'enableNotificationsTitle': 'Attiva le notifiche',
      'enableNotificationsMessage':
          'Vuoi abilitare le notifiche per ricevere aggiornamenti quando le immagini dei tuoi sogni sono pronte e altre notifiche dell\'app?',
      'enableNotificationsNow': 'Attiva ora',
      'enableNotificationsLater': 'Pi\u00f9 tardi',
      'notificationEnabledConfirmation': 'Le notifiche sono state abilitate',

      // Delete confirmation dialog - Italian
      'dreamAlreadySaved': 'Sogno già salvato',
      'confirmDeletion': 'Conferma cancellazione',
      'dreamSavedMessage':
          'Non preoccuparti! Il tuo sogno è già stato salvato nella cronologia. Puoi cancellare il testo dall\'interfaccia senza perdere nulla.',
      'confirmDeletionMessage':
          'Sei sicuro di voler cancellare tutto il contenuto scritto? Questa azione non può essere annullata.',
      'keep': 'Mantieni',
      'cancelAction': 'Annulla',
      'clearAndStartNew': 'Cancella e inizia nuovo',
      'clear': 'Cancella',
    // Animations setting label
    'enableAnimatedBackgrounds': 'Abilita sfondi animati',
    },
    'en': {
      'appTitle': 'Dreamsy',
      'dreamInterpretation': 'Dream Interpretation',
      'tapToRecord': 'Tap to record your dream',
      'recording': 'Recording...',
      'stopRecording': 'Stop recording',
      'editText': 'Edit text',
      'saveText': 'Save text',
      'cancelEdit': 'Cancel',
      'processingDream': 'Processing dream...',
      'generatingImage': 'Generating image...',
      'testDemo': 'Test Demo',
      'interpretation': 'Interpretation',
      'dreamSaved': 'Dream saved automatically',
      'menu': 'Menu',
      'history': 'History',
      'analytics': 'Analytics',
      'settings': 'Settings',
      'themeSettings': 'Theme',
      'lightTheme': 'Light',
      'darkTheme': 'Dark',
      'systemTheme': 'System',
      'selectTheme': 'Select theme',
      'language': 'Language',
      'noDataAvailable': 'No data available',
      'recordDreamsToSeeAnalytics':
          'Record and interpret some dreams\\nto see your analytics!',
      'generalStats': 'General Statistics',
      'totalDreams': 'Total Dreams',
      'averageWords': 'Average Words',
      'withImages': 'With Images',
      'activePeriod': 'Active Period',
      'emotionAnalysis': 'Emotion Analysis',
      'dreamsByTimeOfDay': 'Dreams by Time of Day',
      'patternsAndInsights': 'Patterns & Insights',
      'recurringKeywords': 'Recurring Keywords',
      'recentActivity': 'Recent Activity',
      'dreamsInLast7Days': 'dreams in the last 7 days',
      'veryActivePeriod': 'Very active period!',
      'goodActivity': 'Good activity',
      'recordingManyDreams': 'You\'re recording many dreams lately',
      'keepRecordingDreams': 'Keep recording your dreams',
      'errorLoadingAnalytics': 'Error loading analytics',
      'errorLoadingDreams': 'Error loading dreams',
      'recordSomeDreams':
          'Record and interpret some dreams\nto see your analytics!',
      'generalStatistics': 'General Statistics',
      'interpreted': 'Interpreted',
      'withImage': 'With Image',
      'morning': 'Morning (6-12)',
      'afternoon': 'Afternoon (12-18)',
      'evening': 'Evening (18-22)',
      'night': 'Night (22-6)',
      'predominantEmotion': 'Predominant emotion',
      'veryActivePeriodAnalytics':
          'Very active period: {count} dreams in the last 7 days',
      'happiness': 'Happiness',
      'fear': 'Fear',
      'sadness': 'Sadness',
      'anger': 'Anger',
      'surprise': 'Surprise',
      'love': 'Love',
      'recurringElements': 'Recurring elements',
      'speechNotAvailable': 'Speech recognition not available',
      'speechPermissionDenied': 'Microphone permission denied',
      'speechRecognitionError': 'Speech recognition error',
      'noInternetConnection': 'No internet connection',
      'selectLanguage': 'Select Language',
      'languageChanged': 'Language changed',
      'restartForFullEffect': 'Restart the app for full effect',
      'speakFreely': 'Speak freely',
      'tapToStart': 'Tap to start',
      'writeDreamHere': '✨ Tell your dream here...',
      'tapToWriteDream': '💭 Tap here to write your dream...',
      'save': 'Save',
      'cancel': 'Cancel',
      'continuousListening':
          'Continuous listening active. Press "Stop" when finished.',
      'recordDream': 'Record Dream',
      'continueTalking': 'Continue Talking',
      'interpretWithAI': 'Interpret dream',
      'demoTest': 'Demo Test',
      'dreamInterpretationTitle': 'Dream Interpretation',
      'dreamImageTitle': 'Dream Image',
      'loadingImage': 'Loading image...',
      'cannotLoadImage': 'Cannot load image',
      'tryAgainLater': 'Try again later',
      'myDreams': 'My Dreams',
      'noDreamsYet': 'No dreams yet',
      'yourInterpretedDreamsWillAppearHere':
          'Your interpreted dreams will appear here.\nRecord your first dream to get started!',
      'startRecording': 'Start recording your dreams!',
      'deleteDream': 'Delete Dream',
      'confirmDelete': 'Do you want to delete this dream?',
      'delete': 'Delete',
      'deleteAll': 'Delete All',
      'deleteAllDreams': 'Delete All Dreams',
      'confirmDeleteAll': 'Do you want to delete all dreams?',
      'dreamDeleted': 'Dream deleted',
      'allDreamsDeleted': 'All dreams deleted',
      'dreamDetails': 'Dream Details',
      'yourDream': '🌙 Your Dream',
      'interpretationTitle': '🔮 Interpretation',
      'visualization': '🎨 Visualization',
      'imageNotAvailable': 'Image not available',
      'statistics': '📊 Statistics',
      'dreamsSaved': 'Dreams Saved',
      'dataManagement': '💾 Data Management',
      'deleteAllDreamsSettings': 'Delete All Dreams',
      'removeAllSavedDreams': 'Remove all saved dreams',
      'appInfo': '📱 App Info',
      'version': 'Version',
      'developer': 'Developer',
      'developedBy': 'Developed by',
      'dreamVisualizerTeam': 'Dream Visualizer Team',
      'aiFunctionality': '🤖 AI Functionality',
      'dreamInterpretationFeature': 'Dream Interpretation',
      'poweredByGPT4': 'Powered by OpenAI GPT-4 Turbo',
      'imageGeneration': 'Image Generation',
      'poweredByDalle': 'Powered by DALL-E 3',
      'speechRecognition': 'Speech Recognition',
      'speechToTextIntegrated': 'Speech-to-Text integrated',
      'noDreamsToDelete': 'No dreams to delete',
      'warning': '⚠️ Warning',
      'deleteAllConfirmation':
          'You are about to delete all {count} saved dreams.\n\nThis action cannot be undone. Are you sure?',
      'deleteEverything': 'Delete Everything',
      'operationCompleted': 'Operation completed',
      'noDreamRecorded':
          '⚠️ No dream recorded! Please record your dream first.',
      'generatingDemoInterpretation': 'Generating demo interpretation...',
      'analyzingDream': 'Analyzing the dream...',
      'analyzingVisualElements': '🎨 Analyzing visual elements of the dream...',
      'analysisError': '❌ Error in dream analysis',
      'possibleCauses': 'Possible causes:',
      'internetProblem': '• Internet connection problem',
      'invalidApiKey': '• Invalid API key',
      'usageLimitReached': '• Usage limit reached',
      'checkConnectionAndRetry': 'Check your connection and try again.',
      'dreamSavedAutomatically': 'Dream saved automatically',
      'demoInterpretationText':
          '🌟 **Demo Interpretation of your dream:**\n\nYour dream reveals a deep inner journey. The elements you described symbolize:\n\n• **Personal transformation** - You are going through a period of growth\n• **New opportunities** - Your subconscious is preparing you for positive changes\n• **Creativity** - Your mind is processing new ideas and possibilities\n\n✨ This dream suggests you are ready to embrace new challenges and discover hidden aspects of yourself.\n\n💫 The dream symbols indicate a favorable period for making important decisions and following your intuition.\n\n*This is a demo. For complete AI interpretation, configure the OpenAI API key.*',
      'close': 'Close',
      'sogna': 'Dream',

      // Dream Tags - English
      'tagPositiveDream': 'Positive Dream',
      'tagNightmare': 'Nightmare',
      'tagMelancholicDream': 'Melancholic Dream',
      'tagRomanticDream': 'Romantic Dream',
      'tagSereneDream': 'Serene Dream',
      'tagHome': 'Home',
      'tagSchool': 'School',
      'tagWork': 'Work',
      'tagNature': 'Nature',
      'tagUrban': 'Urban',
      'tagSkyFlight': 'Sky/Flight',
      'tagFamily': 'Family',
      'tagFriends': 'Friends',
      'tagRelationships': 'Relationships',
      'tagUnknownPeople': 'Unknown People',
      'tagMovement': 'Movement',
      'tagCommunication': 'Communication',
      'tagCreativity': 'Creativity',
      'tagLearning': 'Learning',
      'tagLucidDream': 'Lucid Dream',
      'tagRecurrentDream': 'Recurrent Dream',

      // Additional Authentication & Cloud Sync - English
      'signInWithGoogle': 'Sign In with Google',
      'signInWithEmail': 'Sign In with Email',
      'createAccount': 'Create Account',
      'authenticationFailed': 'Authentication Failed',
      'invalidCredentials': 'Invalid Credentials',
      'userNotFound': 'User Not Found',
      'emailAlreadyInUse': 'Email Already in Use',
      'weakPassword': 'Password Too Weak',
      'syncNow': 'Sync Now',
      'autoSync': 'Auto Sync',
      'lastSync': 'Last Sync',
      'syncInProgress': 'Syncing...',
      'syncCompleted': 'Sync Completed',
      'syncFailed': 'Sync Failed',
      'uploadDream': 'Upload Dream',
      'downloadDreams': 'Download Dreams',
      'storageUsed': 'Storage Used',
      'deleteCloudData': 'Delete Cloud Data',
      'deleteCloudDataWarning':
          'This will delete all your cloud data. Continue?',
      'enableBiometric': 'Enable Biometric',
      'biometricRequired': 'Biometric authentication required',
      'biometricSuccess': 'Authentication successful',
      'biometricFailed': 'Authentication failed',
      'appLocked': 'App Locked',
      'unlockWithBiometric': 'Unlock with biometric',
      'authenticateToAccessDreams': 'Authenticate to access your dreams',
      'authenticationError': 'Authentication error',
      'biometricAuthRequired': 'Authentication Required',
      'authenticating': 'Authenticating...',
      'authenticateNow': 'Authenticate Now',
      'exitApp': 'Exit App',
      'noBiometricsAvailable': 'No biometric methods available',
      'fingerprint': 'Fingerprint',
      'faceId': 'Face ID',
      'iris': 'Iris scan',
      'biometricsAvailable': 'Biometric authentication available',
      'availableMethods': 'Available methods',

      // Community translations
      'community': 'Community',
      'explore': 'Explore',
      'searchDreams': 'Search dreams...',
      'noDreamsPublished': 'No dreams published',
      'publishFirstDream':
          'Publish your first dream to share it with the community!',
      'loginRequired': 'Login required',
      'loginToAccessCommunity': 'Please log in to access community features',
      'login': 'Login',
      'loginNotImplemented': 'Login not yet implemented',
      'retry': 'Retry',
      'noDreamsFound': 'No dreams found',
      'share': 'Share',
      'report': 'Report',
      'readMore': 'Read more',
      'dream': 'Dream',
      'tags': 'Tags',
      'comments': 'Comments',
      'noComments': 'No comments yet',
      'writeComment': 'Write a comment...',
      'reportDream': 'Report Dream',
      'selectReportReason': 'Select report reason:',
      'inappropriateContent': 'Inappropriate content',
      'spam': 'Spam',
      'other': 'Other',
      'submit': 'Submit',
      'reportSubmitted': 'Report submitted',
      // Security translations
      'security': 'Security',
      'biometricLock': 'Biometric Lock',
      'enableBiometricAuth': 'Enable biometric authentication',
      'biometricDescription':
          'Protect the app with fingerprint or face recognition',
      'cloudSync': 'Cloud Sync',
      'enableCloudSync': 'Enable cloud synchronization',
      'cloudSyncDescription': 'Securely sync your dreams on Firebase',
      'encryption': 'Encryption',
      'dataEncryption': 'Data Encryption',
      'encryptionDescription': 'Your data is protected with AES-256 encryption',
      // Login translations
      'register': 'Register',
      'loginToAccount': 'Login to your account',
      'createNewAccount': 'Create a new account',
      'displayName': 'Display name',
      'nameRequired': 'Name is required',
      'email': 'Email',
      'emailRequired': 'Email is required',
      'emailInvalid': 'Invalid email',
      'password': 'Password',
      'passwordRequired': 'Password is required',
      'passwordTooShort': 'Password must be at least 6 characters',
      'forgotPassword': 'Forgot password?',
      'or': 'or',
      'noAccount': 'Don\'t have an account?',
      'alreadyHaveAccount': 'Already have an account?',
      'resetPassword': 'Reset Password',
      'resetPasswordDescription': 'Enter your email to receive the reset link',
      'send': 'Send',
      'resetEmailSent': 'Reset email sent',
      'resetEmailError': 'Error sending email',
      'logout': 'Logout',

      // Dynamic advice messages - English
      'adviceEmptyText':
          '✍️ Write your dream in the text field above...\n\nTo get an accurate interpretation, describe your dream with at least some detail. The more details you provide, the better the analysis will be!',
      'adviceShortText':
          '📝 Keep writing...\n\nThe text is still too short for an accurate interpretation. Add more details about your dream: where you were, what was happening, how you felt, who was with you.',
      'adviceFewWords':
          '💭 Add more details...\n\nFor a good interpretation you need at least a few words describing the dream. Tell what you dreamed in more detail.',
      'adviceReadyToInterpret':
          '✅ Text ready for interpretation!\n\nNow you can press "Interpret dream" to get a detailed analysis of your dream.',

      // Dream interpretation page - English
      'interpretingDream': 'Interpreting your dream...',
      'generatingImageText': 'Generating dream image...',
      'waitingMessage': 'Please wait a moment...',
      'doNotLeaveDuringInterpretation':
          'Please do not close this page or leave the app until the interpretation is complete.',
      'yourDreamTitle': 'Your dream',
      'dreamVisualization': 'Dream visualization',
      'imageLoadError': 'Unable to load image',
      'dreamSavedSuccessfully': 'Dream saved to history!',
      'suggestions': 'Suggestions',
      'profile': 'Profile',
      'dreamVisualizerUser': 'Dream Visualizer User',
      'memberSince': 'Member since August 2025',
      'changeLanguage': 'Change language',
      'languageSelection': 'Language Selection',
      'about': 'About',
      'appVersion': 'App Version',
      'aboutAppDescription':
          'Dream Visualizer helps you interpret and visualize your dreams using artificial intelligence.',

      // Profile page sections - English
      'personalInfo': 'Personal Information',
      'editNameEmailDetails': 'Edit name, email and other details',
      'privacySecurity': 'Privacy & Security',
      'managePrivacySettings': 'Manage your privacy settings',
      'notifications': 'Notifications',
      'manageNotificationSettings': 'Manage your notifications',
      'aboutApp': 'About App',
      'appInfoAndVersion': 'App information and version',

      // Profile dialog messages - English
      'personalInfoDialog':
          'This feature will be available soon to allow you to edit your personal information.',
      'privacySettingsDialog':
          'Manage your privacy and security settings. This feature will be available soon.',
      'notificationSettingsTitle': 'Notification Settings',
      'notificationSettingsDialog':
          'Customize your notifications. This feature will be available soon.',
      'ok': 'OK',
      'enableNotificationsTitle': 'Enable notifications',
      'enableNotificationsMessage':
          'Would you like to enable notifications to be informed when your dream image is ready and for other app updates?',
      'enableNotificationsNow': 'Enable now',
      'enableNotificationsLater': 'Later',
      'notificationEnabledConfirmation': 'Notifications enabled',

      // Delete confirmation dialog - English
      'dreamAlreadySaved': 'Dream Already Saved',
      'confirmDeletion': 'Confirm Deletion',
      'dreamSavedMessage':
          'Don\'t worry! Your dream has already been saved in the history. You can clear the text from the interface without losing anything.',
      'confirmDeletionMessage':
          'Are you sure you want to delete all the written content? This action cannot be undone.',
      'keep': 'Keep',
      'cancelAction': 'Cancel',
      'clearAndStartNew': 'Clear and Start New',
      'clear': 'Clear',
    // Animations setting label (keep English text in both languages per UX request)
    'enableAnimatedBackgrounds': 'Enable animated backgrounds',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Getter methods per facile accesso
  String get appTitle => translate('appTitle');
  String get dreamInterpretation => translate('dreamInterpretation');
  String get tapToRecord => translate('tapToRecord');
  String get recording => translate('recording');
  String get stopRecording => translate('stopRecording');
  String get editText => translate('editText');
  String get saveText => translate('saveText');
  String get cancelEdit => translate('cancelEdit');
  String get processingDream => translate('processingDream');
  String get generatingImage => translate('generatingImage');
  String get testDemo => translate('testDemo');
  String get interpretation => translate('interpretation');
  String get dreamSaved => translate('dreamSaved');
  String get menu => translate('menu');
  String get history => translate('history');
  String get analytics => translate('analytics');
  String get settings => translate('settings');
  String get language => translate('language');
  String get noDataAvailable => translate('noDataAvailable');
  String get recordDreamsToSeeAnalytics =>
      translate('recordDreamsToSeeAnalytics');
  String get generalStats => translate('generalStats');
  String get totalDreams => translate('totalDreams');
  String get averageWords => translate('averageWords');
  String get withImages => translate('withImages');
  String get activePeriod => translate('activePeriod');
  String get emotionAnalysis => translate('emotionAnalysis');
  String get dreamsByTimeOfDay => translate('dreamsByTimeOfDay');
  String get patternsAndInsights => translate('patternsAndInsights');
  String get recurringKeywords => translate('recurringKeywords');
  String get recentActivity => translate('recentActivity');
  String get dreamsInLast7Days => translate('dreamsInLast7Days');
  String get veryActivePeriod => translate('veryActivePeriod');
  String get goodActivity => translate('goodActivity');
  String get recordingManyDreams => translate('recordingManyDreams');
  String get keepRecordingDreams => translate('keepRecordingDreams');
  String get errorLoadingAnalytics => translate('errorLoadingAnalytics');
  String get errorLoadingDreams => translate('errorLoadingDreams');
  String get recordSomeDreams => translate('recordSomeDreams');
  String get generalStatistics => translate('generalStatistics');
  String get interpreted => translate('interpreted');
  String get withImage => translate('withImage');
  String get morning => translate('morning');
  String get afternoon => translate('afternoon');
  String get evening => translate('evening');
  String get night => translate('night');
  String get predominantEmotion => translate('predominantEmotion');
  String get veryActivePeriodAnalytics =>
      translate('veryActivePeriodAnalytics');
  String get happiness => translate('happiness');
  String get fear => translate('fear');
  String get sadness => translate('sadness');
  String get anger => translate('anger');
  String get surprise => translate('surprise');
  String get love => translate('love');
  String get recurringElements => translate('recurringElements');
  String get speechNotAvailable => translate('speechNotAvailable');
  String get speechPermissionDenied => translate('speechPermissionDenied');
  String get speechRecognitionError => translate('speechRecognitionError');
  String get noInternetConnection => translate('noInternetConnection');
  String get selectLanguage => translate('selectLanguage');
  String get languageChanged => translate('languageChanged');
  String get restartForFullEffect => translate('restartForFullEffect');
  String get speakFreely => translate('speakFreely');
  String get tapToStart => translate('tapToStart');
  String get writeDreamHere => translate('writeDreamHere');
  String get tapToWriteDream => translate('tapToWriteDream');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get continuousListening => translate('continuousListening');
  String get recordDream => translate('recordDream');
  String get continueTalking => translate('continueTalking');
  String get interpretWithAI => translate('interpretWithAI');
  String get demoTest => translate('demoTest');
  String get dreamInterpretationTitle => translate('dreamInterpretationTitle');
  String get dreamImageTitle => translate('dreamImageTitle');
  String get loadingImage => translate('loadingImage');
  String get cannotLoadImage => translate('cannotLoadImage');
  String get tryAgainLater => translate('tryAgainLater');
  String get myDreams => translate('myDreams');
  String get noDreamsYet => translate('noDreamsYet');
  String get startRecording => translate('startRecording');
  String get deleteDream => translate('deleteDream');
  String get confirmDelete => translate('confirmDelete');
  String get delete => translate('delete');
  String get deleteAll => translate('deleteAll');
  String get deleteAllDreams => translate('deleteAllDreams');
  String get confirmDeleteAll => translate('confirmDeleteAll');
  String get dreamDeleted => translate('dreamDeleted');
  String get allDreamsDeleted => translate('allDreamsDeleted');
  String get dreamDetails => translate('dreamDetails');
  String get yourDream => translate('yourDream');
  String get interpretationTitle => translate('interpretationTitle');
  String get visualization => translate('visualization');
  String get imageNotAvailable => translate('imageNotAvailable');
  String get statistics => translate('statistics');
  String get dreamsSaved => translate('dreamsSaved');
  String get dataManagement => translate('dataManagement');
  String get deleteAllDreamsSettings => translate('deleteAllDreamsSettings');
  String get removeAllSavedDreams => translate('removeAllSavedDreams');
  String get appInfo => translate('appInfo');
  String get version => translate('version');
  String get developer => translate('developer');
  String get developedBy => translate('developedBy');
  String get dreamVisualizerTeam => translate('dreamVisualizerTeam');
  String get aiFunctionality => translate('aiFunctionality');
  String get dreamInterpretationFeature =>
      translate('dreamInterpretationFeature');
  String get poweredByGPT4 => translate('poweredByGPT4');
  String get imageGeneration => translate('imageGeneration');
  String get poweredByDalle => translate('poweredByDalle');
  String get speechRecognition => translate('speechRecognition');
  String get speechToTextIntegrated => translate('speechToTextIntegrated');
  String get noDreamsToDelete => translate('noDreamsToDelete');
  String get warning => translate('warning');
  String get deleteAllConfirmation => translate('deleteAllConfirmation');
  String get deleteEverything => translate('deleteEverything');
  String get operationCompleted => translate('operationCompleted');
  String get noDreamRecorded => translate('noDreamRecorded');
  String get generatingDemoInterpretation =>
      translate('generatingDemoInterpretation');
  String get analyzingDream => translate('analyzingDream');
  String get analyzingVisualElements => translate('analyzingVisualElements');
  String get analysisError => translate('analysisError');
  String get possibleCauses => translate('possibleCauses');
  String get internetProblem => translate('internetProblem');
  String get invalidApiKey => translate('invalidApiKey');
  String get usageLimitReached => translate('usageLimitReached');
  String get checkConnectionAndRetry => translate('checkConnectionAndRetry');
  String get dreamSavedAutomatically => translate('dreamSavedAutomatically');
  String get demoInterpretationText => translate('demoInterpretationText');
  String get yourInterpretedDreamsWillAppearHere =>
      translate('yourInterpretedDreamsWillAppearHere');
  String get close => translate('close');
  String get sogna => translate('sogna');

  // Dream Tags getters
  String get tagPositiveDream => translate('tagPositiveDream');
  String get tagNightmare => translate('tagNightmare');
  String get tagMelancholicDream => translate('tagMelancholicDream');
  String get tagRomanticDream => translate('tagRomanticDream');
  String get tagSereneDream => translate('tagSereneDream');
  String get tagHome => translate('tagHome');
  String get tagSchool => translate('tagSchool');
  String get tagWork => translate('tagWork');
  String get tagNature => translate('tagNature');
  String get tagUrban => translate('tagUrban');
  String get tagSkyFlight => translate('tagSkyFlight');
  String get tagFamily => translate('tagFamily');
  String get tagFriends => translate('tagFriends');
  String get tagRelationships => translate('tagRelationships');
  String get tagUnknownPeople => translate('tagUnknownPeople');
  String get tagMovement => translate('tagMovement');
  String get tagCommunication => translate('tagCommunication');
  String get tagCreativity => translate('tagCreativity');
  String get tagLearning => translate('tagLearning');
  String get tagLucidDream => translate('tagLucidDream');
  String get tagRecurrentDream => translate('tagRecurrentDream');

  // Authentication & Cloud Sync getters
  String get signInWithGoogle => translate('signInWithGoogle');
  String get signInWithEmail => translate('signInWithEmail');
  String get createAccount => translate('createAccount');
  String get authenticationFailed => translate('authenticationFailed');
  String get invalidCredentials => translate('invalidCredentials');
  String get userNotFound => translate('userNotFound');
  String get emailAlreadyInUse => translate('emailAlreadyInUse');
  String get weakPassword => translate('weakPassword');
  String get syncNow => translate('syncNow');
  String get autoSync => translate('autoSync');
  String get lastSync => translate('lastSync');
  String get syncInProgress => translate('syncInProgress');
  String get syncCompleted => translate('syncCompleted');
  String get syncFailed => translate('syncFailed');
  String get uploadDream => translate('uploadDream');
  String get downloadDreams => translate('downloadDreams');
  String get storageUsed => translate('storageUsed');
  String get deleteCloudData => translate('deleteCloudData');
  String get deleteCloudDataWarning => translate('deleteCloudDataWarning');
  String get enableBiometric => translate('enableBiometric');
  String get biometricRequired => translate('biometricRequired');
  String get biometricSuccess => translate('biometricSuccess');
  String get biometricFailed => translate('biometricFailed');
  String get appLocked => translate('appLocked');
  String get unlockWithBiometric => translate('unlockWithBiometric');
  String get authenticateToAccessDreams =>
      translate('authenticateToAccessDreams');
  String get authenticationError => translate('authenticationError');
  String get biometricAuthRequired => translate('biometricAuthRequired');
  String get authenticating => translate('authenticating');
  String get authenticateNow => translate('authenticateNow');
  String get exitApp => translate('exitApp');
  String get noBiometricsAvailable => translate('noBiometricsAvailable');
  String get fingerprint => translate('fingerprint');
  String get faceId => translate('faceId');
  String get iris => translate('iris');
  String get biometricsAvailable => translate('biometricsAvailable');
  String get availableMethods => translate('availableMethods');

  // Community getters
  String get community => translate('community');
  String get explore => translate('explore');
  String get searchDreams => translate('searchDreams');
  String get noDreamsPublished => translate('noDreamsPublished');
  String get publishFirstDream => translate('publishFirstDream');
  String get loginRequired => translate('loginRequired');
  String get loginToAccessCommunity => translate('loginToAccessCommunity');
  String get login => translate('login');
  String get loginNotImplemented => translate('loginNotImplemented');
  String get retry => translate('retry');
  String get noDreamsFound => translate('noDreamsFound');
  String get share => translate('share');
  String get report => translate('report');
  String get readMore => translate('readMore');
  String get dream => translate('dream');
  String get tags => translate('tags');
  String get comments => translate('comments');
  String get noComments => translate('noComments');
  String get writeComment => translate('writeComment');
  String get reportDream => translate('reportDream');
  String get selectReportReason => translate('selectReportReason');
  String get inappropriateContent => translate('inappropriateContent');
  String get spam => translate('spam');
  String get other => translate('other');
  String get submit => translate('submit');
  String get reportSubmitted => translate('reportSubmitted');

  // Security getters
  String get security => translate('security');
  String get biometricLock => translate('biometricLock');
  String get enableBiometricAuth => translate('enableBiometricAuth');
  String get biometricDescription => translate('biometricDescription');
  String get cloudSync => translate('cloudSync');
  String get enableCloudSync => translate('enableCloudSync');
  String get cloudSyncDescription => translate('cloudSyncDescription');
  String get encryption => translate('encryption');
  String get dataEncryption => translate('dataEncryption');
  String get encryptionDescription => translate('encryptionDescription');

  // Theme settings
  String get themeSettings => translate('themeSettings');
  String get lightTheme => translate('lightTheme');
  String get darkTheme => translate('darkTheme');
  String get systemTheme => translate('systemTheme');
  String get selectTheme => translate('selectTheme');

  // Login getters
  String get register => translate('register');
  String get loginToAccount => translate('loginToAccount');
  String get createNewAccount => translate('createNewAccount');
  String get displayName => translate('displayName');
  String get nameRequired => translate('nameRequired');
  String get email => translate('email');
  String get emailRequired => translate('emailRequired');
  String get emailInvalid => translate('emailInvalid');
  String get password => translate('password');
  String get passwordRequired => translate('passwordRequired');
  String get passwordTooShort => translate('passwordTooShort');
  String get forgotPassword => translate('forgotPassword');
  String get or => translate('or');
  String get noAccount => translate('noAccount');
  String get alreadyHaveAccount => translate('alreadyHaveAccount');
  String get resetPassword => translate('resetPassword');
  String get resetPasswordDescription => translate('resetPasswordDescription');
  String get send => translate('send');
  String get resetEmailSent => translate('resetEmailSent');
  String get resetEmailError => translate('resetEmailError');
  String get logout => translate('logout');

  // Dynamic advice messages getters
  String get adviceEmptyText => translate('adviceEmptyText');
  String get adviceShortText => translate('adviceShortText');
  String get adviceFewWords => translate('adviceFewWords');
  String get adviceReadyToInterpret => translate('adviceReadyToInterpret');

  // Dream interpretation page getters
  String get interpretingDream => translate('interpretingDream');
  String get generatingImageText => translate('generatingImageText');
  String get waitingMessage => translate('waitingMessage');
  String get doNotLeaveDuringInterpretation =>
      translate('doNotLeaveDuringInterpretation');
  String get yourDreamTitle => translate('yourDreamTitle');
  String get dreamVisualization => translate('dreamVisualization');
  String get imageLoadError => translate('imageLoadError');
  String get dreamSavedSuccessfully => translate('dreamSavedSuccessfully');
  String get suggestions => translate('suggestions');
  String get profile => translate('profile');
  String get dreamVisualizerUser => translate('dreamVisualizerUser');
  String get memberSince => translate('memberSince');
  String get changeLanguage => translate('changeLanguage');
  String get languageSelection => translate('languageSelection');
  String get about => translate('about');
  String get appVersion => translate('appVersion');
  String get aboutAppDescription => translate('aboutAppDescription');

  // Profile page sections getters
  String get personalInfo => translate('personalInfo');
  String get editNameEmailDetails => translate('editNameEmailDetails');
  String get privacySecurity => translate('privacySecurity');
  String get managePrivacySettings => translate('managePrivacySettings');
  String get notifications => translate('notifications');
  String get manageNotificationSettings =>
      translate('manageNotificationSettings');
  String get aboutApp => translate('aboutApp');
  String get appInfoAndVersion => translate('appInfoAndVersion');

  // Profile dialog messages getters
  String get personalInfoDialog => translate('personalInfoDialog');
  String get privacySettingsDialog => translate('privacySettingsDialog');
  String get notificationSettingsTitle =>
      translate('notificationSettingsTitle');
  String get notificationSettingsDialog =>
      translate('notificationSettingsDialog');
  String get enableNotificationsTitle => translate('enableNotificationsTitle');
  String get enableNotificationsMessage =>
      translate('enableNotificationsMessage');
  String get enableNotificationsNow => translate('enableNotificationsNow');
  String get enableNotificationsLater => translate('enableNotificationsLater');
  String get notificationEnabledConfirmation =>
      translate('notificationEnabledConfirmation');
  String get ok => translate('ok');

  // Delete confirmation dialog getters
  String get dreamAlreadySaved => translate('dreamAlreadySaved');
  String get confirmDeletion => translate('confirmDeletion');
  String get dreamSavedMessage => translate('dreamSavedMessage');
  String get confirmDeletionMessage => translate('confirmDeletionMessage');
  String get keep => translate('keep');
  String get cancelAction => translate('cancelAction');
  String get clearAndStartNew => translate('clearAndStartNew');
  String get clear => translate('clear');
    String get enableAnimatedBackgrounds => translate('enableAnimatedBackgrounds');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['it', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
