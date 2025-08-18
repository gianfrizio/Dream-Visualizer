#!/bin/bash

# 🚀 DreamVisualizer Firebase Setup Script
# Questo script automatizza il setup per il deployment online

echo "🌟 DreamVisualizer Firebase Setup"
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Flutter is installed
echo -e "${BLUE}📱 Checking Flutter installation...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Flutter found${NC}"

# Check if Firebase CLI is installed
echo -e "${BLUE}🔥 Checking Firebase CLI...${NC}"
if ! command -v firebase &> /dev/null; then
    echo -e "${YELLOW}⚠️  Firebase CLI not found. Installing...${NC}"
    npm install -g firebase-tools
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to install Firebase CLI${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✅ Firebase CLI ready${NC}"

# Flutter clean and get dependencies
echo -e "${BLUE}🧹 Cleaning and getting dependencies...${NC}"
flutter clean
flutter pub get

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to get dependencies${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Dependencies ready${NC}"

# Build debug APK to test
echo -e "${BLUE}🔨 Building debug APK...${NC}"
flutter build apk --debug

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to build APK${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Debug APK built successfully${NC}"

# Firebase login check
echo -e "${BLUE}🔐 Checking Firebase authentication...${NC}"
firebase projects:list > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Please login to Firebase${NC}"
    firebase login
fi

# Initialize Firebase project (if needed)
echo -e "${BLUE}🔥 Setting up Firebase project...${NC}"
if [ ! -f ".firebaserc" ]; then
    echo -e "${YELLOW}🆕 Creating new Firebase project configuration${NC}"
    firebase init
else
    echo -e "${GREEN}✅ Firebase project already configured${NC}"
fi

# Create production build
echo -e "${BLUE}🚀 Building production APK...${NC}"
flutter build apk --release

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to build release APK${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Production APK built successfully${NC}"

# Summary
echo ""
echo -e "${GREEN}🎉 Setup completato con successo!${NC}"
echo "=================================="
echo ""
echo -e "${BLUE}📁 File generati:${NC}"
echo "   • build/app/outputs/flutter-apk/app-debug.apk"
echo "   • build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo -e "${BLUE}📋 Prossimi passi:${NC}"
echo "   1. 🔧 Configura il tuo progetto Firebase:"
echo "      • Vai su https://console.firebase.google.com/"
echo "      • Crea progetto 'dream-visualizer-community'"
echo "      • Abilita Firestore Database e Authentication"
echo ""
echo "   2. 🔑 Aggiorna le credenziali Firebase:"
echo "      • Sostituisci lib/firebase_options.dart con le tue credenziali"
echo "      • Aggiungi google-services.json per Android"
echo "      • Aggiungi GoogleService-Info.plist per iOS"
echo ""
echo "   3. 🌐 Deploy opcionale su Firebase Hosting:"
echo "      • flutter build web"
echo "      • firebase deploy --only hosting"
echo ""
echo "   4. 📱 Pubblica su store:"
echo "      • Google Play: carica app-release.apk o app-release.aab"
echo "      • App Store: build iOS e carica su App Store Connect"
echo ""
echo -e "${YELLOW}📖 Leggi DEPLOYMENT_GUIDE.md per istruzioni complete${NC}"
echo ""
echo -e "${GREEN}🚀 La tua app è pronta per andare online!${NC}"
