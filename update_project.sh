#!/bin/bash

# Script per aggiornare Dream Visualizer
# Questo script aggiorna le dipendenze e risolve problemi comuni

echo "🚀 Aggiornamento Dream Visualizer"
echo "================================="

# Pulizia del progetto
echo "🧹 Pulizia del progetto..."
flutter clean

# Aggiornamento dipendenze
echo "📦 Aggiornamento dipendenze..."
flutter pub get

# Controlla configurazione Android NDK
echo "🔧 Controllo configurazione Android..."
NDK_VERSION=$(grep "ndkVersion" android/app/build.gradle.kts | cut -d'"' -f2)
echo "Versione NDK configurata: $NDK_VERSION"

if [ "$NDK_VERSION" != "27.0.12077973" ]; then
    echo "⚠️  NDK non aggiornato, aggiornamento in corso..."
    sed -i 's/ndkVersion = "[^"]*"/ndkVersion = "27.0.12077973"/' android/app/build.gradle.kts
    echo "✅ NDK aggiornato a 27.0.12077973"
fi

# Verifica build
echo "🔨 Test di compilazione..."
flutter analyze

echo ""
echo "✨ Aggiornamento completato!"
echo "💡 Per compilare l'APK: flutter build apk"
echo "🚀 Per avviare l'app: flutter run"
