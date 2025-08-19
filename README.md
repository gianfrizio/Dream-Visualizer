# Dream Visualizer 🌙✨

*[English](#english) | [Italiano](#italiano)*

---

## English

### 📱 About Dream Visualizer

Dream Visualizer is an innovative Flutter application that transforms your dreams into stunning visual interpretations using AI technology. Share your dreams with a community of dreamers, get personalized interpretations, and discover the hidden meanings behind your subconscious mind.

### 🌟 Key Features

- **🎨 AI-Powered Dream Visualization**: Convert your dream descriptions into beautiful, artistic images using advanced AI
- **🧠 Intelligent Dream Interpretation**: Get personalized psychological insights and symbolic analysis of your dreams
- **👥 Dream Community**: Share your dreams and interpretations with other users in a supportive community
- **🌍 Multi-language Support**: Full support for Italian and English with automatic translation
- **❤️ Favorites System**: Save and organize your most meaningful dreams and interpretations
- **🔒 Secure Authentication**: Safe login with Google Sign-In and Firebase authentication
- **📱 Cross-Platform**: Works seamlessly on Android and iOS devices

### 🛠️ Technology Stack

- **Framework**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Authentication, Storage)
- **AI Integration**: 
  - OpenAI GPT-4 for dream interpretation
  - DALL-E for dream visualization
- **Translation**: MyMemory API for multi-language support
- **Authentication**: Google Sign-In, Firebase Auth
- **State Management**: Flutter's built-in state management
- **UI/UX**: Material Design with custom components

### 🚀 Getting Started

#### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- Firebase account
- OpenAI API key

#### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/gianfrizio/Dream-Visualizer.git
   cd Dream-Visualizer/dream_visualizer
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Firestore, Authentication, and Storage
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the appropriate directories

4. **API Configuration**
   - Copy the example configuration file:
     ```bash
     cp lib/config/api_config.dart.example lib/config/api_config.dart
     ```
   - Edit `lib/config/api_config.dart` and add your OpenAI API key:
     ```dart
     static const String openaiApiKey = 'your-actual-openai-api-key-here';
     ```
   - Configure Firebase options in `lib/firebase_options.dart`

5. **Run the app**
   ```bash
   flutter run
   ```

### 📖 How to Use

1. **Sign In**: Use Google Sign-In to create your account
2. **Record Your Dream**: Describe your dream in detail using text or voice input
3. **Get AI Interpretation**: Receive psychological insights and symbolic analysis
4. **Visualize Your Dream**: Generate artistic images representing your dream
5. **Share & Explore**: Share with the community and explore other users' dreams
6. **Save Favorites**: Keep your most meaningful dreams and interpretations

### 🔧 Configuration

The app uses several configuration files:
- `lib/firebase_options.dart` - Firebase configuration
- `lib/config/api_config.dart` - API keys (not included in repository for security)
- `lib/config/api_config.dart.example` - Example configuration file
- `lib/openai_service.dart` - OpenAI API integration with safety wrappers
- `lib/services/translation_service.dart` - Multi-language support

**⚠️ Security Note**: Never commit API keys to version control. The `api_config.dart` file is excluded from git tracking.

### 🛡️ Safety Features

- **Content Safety**: Advanced prompt wrappers ensure appropriate AI responses
- **Privacy Protection**: Dreams are stored securely with user permission
- **Community Guidelines**: Moderated community with reporting features
- **Fallback Mechanisms**: Graceful handling of API limitations

### 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

### 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### 🙏 Acknowledgments

- OpenAI for GPT-4 and DALL-E APIs
- Firebase for backend infrastructure
- Flutter team for the amazing framework
- MyMemory for translation services

---

## Italiano

### 📱 Informazioni su Dream Visualizer

Dream Visualizer è un'applicazione Flutter innovativa che trasforma i tuoi sogni in straordinarie interpretazioni visive utilizzando la tecnologia AI. Condividi i tuoi sogni con una comunità di sognatori, ottieni interpretazioni personalizzate e scopri i significati nascosti della tua mente subconscia.

### 🌟 Caratteristiche Principali

- **🎨 Visualizzazione dei Sogni con AI**: Converti le descrizioni dei tuoi sogni in bellissime immagini artistiche usando AI avanzata
- **🧠 Interpretazione Intelligente dei Sogni**: Ottieni approfondimenti psicologici personalizzati e analisi simboliche dei tuoi sogni
- **👥 Comunità dei Sogni**: Condividi i tuoi sogni e interpretazioni con altri utenti in una comunità di supporto
- **🌍 Supporto Multi-lingua**: Supporto completo per italiano e inglese con traduzione automatica
- **❤️ Sistema Preferiti**: Salva e organizza i tuoi sogni e interpretazioni più significative
- **🔒 Autenticazione Sicura**: Accesso sicuro con Google Sign-In e autenticazione Firebase
- **📱 Cross-Platform**: Funziona perfettamente su dispositivi Android e iOS

### 🛠️ Stack Tecnologico

- **Framework**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Authentication, Storage)
- **Integrazione AI**: 
  - OpenAI GPT-4 per l'interpretazione dei sogni
  - DALL-E per la visualizzazione dei sogni
- **Traduzione**: API MyMemory per il supporto multi-lingua
- **Autenticazione**: Google Sign-In, Firebase Auth
- **Gestione Stato**: Gestione stato integrata di Flutter
- **UI/UX**: Material Design con componenti personalizzati

### 🚀 Come Iniziare

#### Prerequisiti
- Flutter SDK (ultima versione stabile)
- Dart SDK
- Android Studio / VS Code
- Account Firebase
- Chiave API OpenAI

#### Installazione

1. **Clona il repository**
   ```bash
   git clone https://github.com/gianfrizio/Dream-Visualizer.git
   cd Dream-Visualizer/dream_visualizer
   ```

2. **Installa le dipendenze**
   ```bash
   flutter pub get
   ```

3. **Configurazione Firebase**
   - Crea un nuovo progetto Firebase
   - Abilita Firestore, Authentication e Storage
   - Scarica `google-services.json` (Android) e `GoogleService-Info.plist` (iOS)
   - Posizionali nelle directory appropriate

4. **Configurazione API**
   - Copia il file di configurazione di esempio:
     ```bash
     cp lib/config/api_config.dart.example lib/config/api_config.dart
     ```
   - Modifica `lib/config/api_config.dart` e aggiungi la tua chiave API OpenAI:
     ```dart
     static const String openaiApiKey = 'la-tua-chiave-api-openai-qui';
     ```
   - Configura le opzioni Firebase in `lib/firebase_options.dart`

5. **Esegui l'app**
   ```bash
   flutter run
   ```

### 📖 Come Usare l'App

1. **Accedi**: Usa Google Sign-In per creare il tuo account
2. **Registra il Tuo Sogno**: Descrivi il tuo sogno in dettaglio usando testo o input vocale
3. **Ottieni Interpretazione AI**: Ricevi approfondimenti psicologici e analisi simboliche
4. **Visualizza il Tuo Sogno**: Genera immagini artistiche che rappresentano il tuo sogno
5. **Condividi ed Esplora**: Condividi con la comunità ed esplora i sogni di altri utenti
6. **Salva i Preferiti**: Conserva i tuoi sogni e interpretazioni più significative

### 🔧 Configurazione

L'app utilizza diversi file di configurazione:
- `lib/firebase_options.dart` - Configurazione Firebase
- `lib/config/api_config.dart` - Chiavi API (non incluso nel repository per sicurezza)
- `lib/config/api_config.dart.example` - File di configurazione di esempio
- `lib/openai_service.dart` - Integrazione API OpenAI con wrapper di sicurezza
- `lib/services/translation_service.dart` - Supporto multi-lingua

**⚠️ Nota di Sicurezza**: Non committare mai le chiavi API nel controllo versione. Il file `api_config.dart` è escluso dal tracking git.

### 🛡️ Caratteristiche di Sicurezza

- **Sicurezza del Contenuto**: Wrapper di prompt avanzati garantiscono risposte AI appropriate
- **Protezione Privacy**: I sogni sono memorizzati in modo sicuro con il permesso dell'utente
- **Linee Guida Comunità**: Comunità moderata con funzionalità di segnalazione
- **Meccanismi di Fallback**: Gestione elegante delle limitazioni API

### 🤝 Contribuire

I contributi sono benvenuti! Sentiti libero di inviare pull request o aprire issue per bug e richieste di funzionalità.

### 📄 Licenza

Questo progetto è sotto licenza MIT - vedi il file [LICENSE](LICENSE) per i dettagli.

### 🙏 Ringraziamenti

- OpenAI per le API GPT-4 e DALL-E
- Firebase per l'infrastruttura backend
- Team Flutter per il fantastico framework
- MyMemory per i servizi di traduzione

---

## 📸 Screenshots

*Coming soon - Screenshots will be added to showcase the app's beautiful interface*

## 🔗 Links

- **Repository**: https://github.com/gianfrizio/Dream-Visualizer
- **Issues**: https://github.com/gianfrizio/Dream-Visualizer/issues
- **Releases**: https://github.com/gianfrizio/Dream-Visualizer/releases

---

*Made with ❤️ by Gianfrizio*
