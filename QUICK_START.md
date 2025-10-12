# ReLink - Quick Start Guide

Panduan cepat untuk menjalankan aplikasi ReLink dalam waktu kurang dari 15 menit.

---

## ⚡ Quick Setup (15 Minutes)

### 1️⃣ Prerequisites (2 min)

```bash
# Verify installations
flutter --version  # Should be >= 3.9.2
git --version
```

### 2️⃣ Clone & Install (2 min)

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/relink.git
cd relink

# Install dependencies
flutter pub get
```

### 3️⃣ Firebase Setup (5 min)

1. **Create Firebase Project**
   - Visit: https://console.firebase.google.com/
   - Click "Create a project"
   - Name: `relink-app`
   - Enable Google Analytics (optional)

2. **Add Android App**
   - Click Android icon
   - Package name: `com.example.relink`
   - Download `google-services.json`
   - Place in: `android/app/google-services.json`

3. **Enable Services**
   - **Authentication** → Enable:
     - Email/Password
     - Google
     - Anonymous
   - **Firestore Database** → Create database (test mode)
   - **Storage** → Get started (test mode)

### 4️⃣ API Keys Setup (3 min)

1. **Get Firebase Config**
   - Firebase Console → Settings → Your apps
   - Copy: apiKey, appId, messagingSenderId, projectId

2. **Get Google Maps Key**
   - Visit: https://console.cloud.google.com/
   - Enable "Maps SDK for Android"
   - Create API key → Copy

3. **Get Gemini AI Key**
   - Visit: https://makersuite.google.com/app/apikey
   - Create API key → Copy

### 5️⃣ Configure .env File (2 min)

Create `.env` file in project root:

```bash
# Required
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_APP_ID=your_firebase_app_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_PROJECT_ID=relink-app

GOOGLE_MAPS_API_KEY=your_google_maps_key
GOOGLE_AI_API_KEY=your_gemini_key

# Optional
OPENWEATHER_API_KEY=your_weather_key
```

### 6️⃣ Run App (1 min)

```bash
# Start emulator or connect device
flutter devices

# Run app
flutter run
```

---

## 🎯 Essential Commands

```bash
# Clean and rebuild
flutter clean && flutter pub get && flutter run

# Run tests
flutter test

# Check for issues
flutter doctor -v
flutter analyze

# View logs
flutter run --verbose
```

---

## 🚨 Common Quick Fixes

### Google Sign-In Not Working?
```bash
cd android
./gradlew signingReport
# Copy SHA-1 and add to Firebase Console
```

### Maps Not Loading?
- Verify Maps SDK enabled in GCP Console
- Check API key in `.env` file
- Rebuild app: `flutter clean && flutter run`

### Firebase Errors?
- Verify `google-services.json` exists in `android/app/`
- Check internet connection
- Verify services enabled in Firebase Console

---

## 📚 Need More Help?

- **Detailed Setup**: Read [FIREBASE_SETUP_GUIDE.md](FIREBASE_SETUP_GUIDE.md)
- **Project Setup**: Read [SETUP_GUIDE.md](SETUP_GUIDE.md)
- **Issues**: Check [GitHub Issues](https://github.com/YOUR_USERNAME/relink/issues)

---

## ✅ Quick Verification

Test these features to ensure everything works:

1. **Authentication**: Try guest mode or email login
2. **Firestore**: View destinations list
3. **Maps**: Check if map loads in explore screen
4. **AI**: Try AI itinerary generator
5. **Storage**: Upload profile picture

---

**Setup Complete! 🎉 Start developing!**

*For production deployment, read the full setup guide.*
