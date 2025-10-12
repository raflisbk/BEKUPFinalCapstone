# ReLink - Firebase & GCP Setup Guide

Panduan lengkap untuk setup Firebase, Google Cloud Platform (GCP), dan konfigurasi project ReLink dari awal hingga aplikasi dapat berjalan.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Firebase Console Setup](#firebase-console-setup)
3. [Google Cloud Platform Setup](#google-cloud-platform-setup)
4. [Flutter Project Configuration](#flutter-project-configuration)
5. [Environment Variables](#environment-variables)
6. [Firebase Services Configuration](#firebase-services-configuration)
7. [Google Maps API Setup](#google-maps-api-setup)
8. [Google AI (Gemini) Setup](#google-ai-gemini-setup)
9. [Testing Configuration](#testing-configuration)
10. [Troubleshooting](#troubleshooting)

---

## 🔧 Prerequisites

Sebelum memulai, pastikan Anda memiliki:

- ✅ Akun Google (Gmail)
- ✅ Flutter SDK terinstall (version ≥ 3.9.2)
- ✅ Android Studio atau Xcode (untuk iOS)
- ✅ Git terinstall
- ✅ Node.js dan npm terinstall (untuk Firebase CLI)
- ✅ Kartu kredit/debit untuk verifikasi GCP (tidak akan dicharge kecuali Anda upgrade)

### Verifikasi Flutter Installation

```bash
flutter --version
flutter doctor
```

---

## 🔥 Firebase Console Setup

### Step 1: Buat Firebase Project

1. **Buka Firebase Console**
   - Kunjungi: https://console.firebase.google.com/
   - Login dengan akun Google Anda

2. **Create New Project**
   - Klik "Add project" atau "Create a project"
   - Masukkan nama project: **`relink-app`** (atau nama lain sesuai keinginan)
   - Klik "Continue"

3. **Google Analytics (Optional)**
   - Toggle ON untuk enable Google Analytics (recommended)
   - Pilih atau buat Analytics account
   - Pilih region: **Indonesia** atau **United States**
   - Accept terms dan klik "Create project"
   - Tunggu hingga project selesai dibuat (~30 detik)

4. **Project Created**
   - Klik "Continue" untuk masuk ke Firebase Console

### Step 2: Register Android App

1. **Tambah Android App**
   - Di Firebase Console, klik icon Android (robot icon)
   - Atau klik "Project Overview" → "Add app" → "Android"

2. **Register App**
   - **Android package name**: `com.example.relink` (atau sesuai package Anda)
     - Cek di: `android/app/build.gradle.kts` → `namespace`
   - **App nickname**: `ReLink Android` (optional)
   - **Debug signing certificate SHA-1**: (optional, untuk Google Sign-In)
     ```bash
     # Get SHA-1 untuk debug
     cd android
     ./gradlew signingReport
     # Copy SHA-1 dari output
     ```
   - Klik "Register app"

3. **Download google-services.json**
   - Download file `google-services.json`
   - **PENTING**: Simpan file ini di `android/app/google-services.json`
   - Klik "Next"

4. **Add Firebase SDK**
   - Steps ini sudah dilakukan di project (skip)
   - Klik "Next"

5. **Run App**
   - Klik "Continue to console"

### Step 3: Register iOS App (Optional)

1. **Tambah iOS App**
   - Di Firebase Console, klik icon iOS
   - Atau klik "Project Overview" → "Add app" → "iOS"

2. **Register App**
   - **iOS bundle ID**: `com.example.relink` (atau sesuai bundle ID Anda)
     - Cek di: `ios/Runner.xcodeproj/project.pbxproj`
   - **App nickname**: `ReLink iOS` (optional)
   - Klik "Register app"

3. **Download GoogleService-Info.plist**
   - Download file `GoogleService-Info.plist`
   - **PENTING**: Simpan file ini di `ios/Runner/GoogleService-Info.plist`
   - Klik "Next"

4. **Add Firebase SDK**
   - Steps ini sudah dilakukan di project (skip)
   - Klik "Next" → "Continue to console"

### Step 4: Enable Authentication Methods

1. **Buka Authentication**
   - Di sidebar, klik "Authentication"
   - Klik "Get started"

2. **Enable Email/Password**
   - Tab "Sign-in method"
   - Klik "Email/Password"
   - Toggle ON "Email/Password"
   - Klik "Save"

3. **Enable Google Sign-In**
   - Klik "Google"
   - Toggle ON "Enable"
   - **Project support email**: Pilih email Anda
   - Klik "Save"

4. **Enable Anonymous Sign-In**
   - Klik "Anonymous"
   - Toggle ON "Enable"
   - Klik "Save"

### Step 5: Create Firestore Database

1. **Buka Firestore Database**
   - Di sidebar, klik "Firestore Database"
   - Klik "Create database"

2. **Set Mode**
   - Pilih **"Start in test mode"** (untuk development)
   - Atau **"Start in production mode"** (untuk production)
   - Klik "Next"

3. **Set Location**
   - Pilih location: **asia-southeast2 (Jakarta)** (recommended untuk Indonesia)
   - Atau: **us-central** (untuk global access)
   - Klik "Enable"
   - Tunggu beberapa menit hingga database dibuat

4. **Set Security Rules** (Untuk Production)
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Users collection
       match /users/{userId} {
         allow read: if request.auth != null;
         allow write: if request.auth.uid == userId;
       }

       // Destinations collection
       match /destinations/{destinationId} {
         allow read: if true;
         allow write: if request.auth != null;
       }

       // Trips collection
       match /trips/{tripId} {
         allow read: if request.auth != null;
         allow write: if request.auth != null &&
                        (request.auth.uid == resource.data.userId ||
                         request.auth.uid in resource.data.participantIds);
       }

       // Reviews collection
       match /reviews/{reviewId} {
         allow read: if true;
         allow write: if request.auth != null;
       }

       // Chats collection
       match /chats/{chatId} {
         allow read, write: if request.auth != null &&
                              request.auth.uid in resource.data.participantIds;
       }
     }
   }
   ```

### Step 6: Setup Firebase Storage

1. **Buka Storage**
   - Di sidebar, klik "Storage"
   - Klik "Get started"

2. **Set Security Rules**
   - Pilih **"Start in test mode"** untuk development
   - Klik "Next"

3. **Set Location**
   - Pilih location yang sama dengan Firestore
   - Klik "Done"

4. **Production Storage Rules**
   ```javascript
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       // Profile images
       match /profile_images/{userId}/{allPaths=**} {
         allow read: if true;
         allow write: if request.auth != null && request.auth.uid == userId;
       }

       // Destination images
       match /destinations/{allPaths=**} {
         allow read: if true;
         allow write: if request.auth != null;
       }

       // Videos
       match /videos/{userId}/{allPaths=**} {
         allow read: if true;
         allow write: if request.auth != null && request.auth.uid == userId;
       }

       // Trip images
       match /trips/{tripId}/{allPaths=**} {
         allow read: if true;
         allow write: if request.auth != null;
       }
     }
   }
   ```

### Step 7: Enable Firebase Cloud Messaging (FCM)

1. **Buka Cloud Messaging**
   - Di sidebar, klik "Cloud Messaging"
   - Jika diminta, enable Cloud Messaging API

2. **Get Server Key**
   - Klik "Settings" (gear icon) → "Project settings"
   - Tab "Cloud Messaging"
   - Copy **Server key** (untuk backend notifications)

---

## ☁️ Google Cloud Platform Setup

### Step 1: Enable Required APIs

1. **Buka GCP Console**
   - Kunjungi: https://console.cloud.google.com/
   - Login dengan akun Google yang sama dengan Firebase

2. **Select Project**
   - Di top bar, pilih project Firebase Anda (relink-app)
   - Atau klik dropdown → pilih project

3. **Enable APIs & Services**
   - Di sidebar, klik "APIs & Services" → "Library"
   - Enable APIs berikut:

   **a. Maps SDK for Android**
   - Search "Maps SDK for Android"
   - Klik → "Enable"

   **b. Maps SDK for iOS** (jika support iOS)
   - Search "Maps SDK for iOS"
   - Klik → "Enable"

   **c. Places API**
   - Search "Places API"
   - Klik → "Enable"

   **d. Geocoding API**
   - Search "Geocoding API"
   - Klik → "Enable"

   **e. Generative Language API (Gemini)**
   - Search "Generative Language API"
   - Klik → "Enable"

### Step 2: Create API Keys

1. **Buka Credentials**
   - Di sidebar, klik "APIs & Services" → "Credentials"

2. **Create Google Maps API Key**
   - Klik "Create Credentials" → "API key"
   - API key akan dibuat
   - Klik "Edit API key"

   **Restrict API Key:**
   - **Name**: `ReLink Maps API Key`
   - **Application restrictions**:
     - Android apps: Add package name dan SHA-1
     - iOS apps: Add bundle ID
   - **API restrictions**:
     - Select "Restrict key"
     - Enable:
       - Maps SDK for Android
       - Maps SDK for iOS
       - Places API
       - Geocoding API
   - Klik "Save"
   - **COPY API KEY** - simpan untuk nanti

3. **Create Gemini AI API Key**
   - Kunjungi: https://makersuite.google.com/app/apikey
   - Klik "Create API key"
   - Pilih project: **relink-app**
   - Klik "Create API key in existing project"
   - **COPY API KEY** - simpan untuk nanti

### Step 3: Setup Billing (Optional but Recommended)

> ⚠️ **Note**: Beberapa API memerlukan billing enabled, tapi Google memberikan free tier yang cukup generous.

1. **Enable Billing**
   - Di GCP Console, klik "Billing"
   - Klik "Link a billing account"
   - Pilih atau create billing account
   - Masukkan payment method (kartu kredit/debit)
   - **PENTING**: Set budget alerts untuk menghindari tagihan tak terduga

2. **Set Budget Alert**
   - Di Billing, klik "Budgets & alerts"
   - Klik "Create budget"
   - Set amount: $10/month (atau sesuai kebutuhan)
   - Set alert at: 50%, 90%, 100%
   - Add notification email

---

## 📱 Flutter Project Configuration

### Step 1: Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/relink.git
cd relink
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Add Firebase Configuration Files

1. **Android**
   - Copy `google-services.json` ke `android/app/`
   - Verify file exists:
     ```bash
     ls android/app/google-services.json
     ```

2. **iOS**
   - Copy `GoogleService-Info.plist` ke `ios/Runner/`
   - Verify file exists:
     ```bash
     ls ios/Runner/GoogleService-Info.plist
     ```

### Step 4: Configure Android Build

1. **Edit android/build.gradle.kts**

   Pastikan sudah ada (sudah configured di project):
   ```kotlin
   buildscript {
       dependencies {
           classpath("com.google.gms:google-services:4.4.0")
       }
   }
   ```

2. **Edit android/app/build.gradle.kts**

   Pastikan sudah ada (sudah configured):
   ```kotlin
   plugins {
       id("com.android.application")
       id("kotlin-android")
       id("dev.flutter.flutter-gradle-plugin")
       id("com.google.gms.google-services")  // This line
   }
   ```

3. **Set Minimum SDK Version**

   Di `android/app/build.gradle.kts`:
   ```kotlin
   android {
       defaultConfig {
           minSdk = 26  // Required for some features
           targetSdk = 34
       }
   }
   ```

### Step 5: Configure iOS Build (Optional)

1. **Open Xcode**
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. **Set Bundle ID**
   - Select "Runner" in project navigator
   - Tab "General"
   - Set Bundle Identifier: `com.example.relink`

3. **Set Minimum iOS Version**
   - Set "Minimum Deployments" to iOS 12.0 or higher

---

## 🔐 Environment Variables

### Step 1: Create .env File

1. **Create .env file**
   ```bash
   touch .env
   ```

2. **Add Environment Variables**

   Edit `.env` file:
   ```bash
   # Firebase Configuration
   FIREBASE_API_KEY=YOUR_FIREBASE_API_KEY
   FIREBASE_APP_ID=YOUR_FIREBASE_APP_ID
   FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID
   FIREBASE_PROJECT_ID=relink-app

   # Google Maps API
   GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY

   # Google AI (Gemini) API
   GOOGLE_AI_API_KEY=YOUR_GEMINI_API_KEY

   # OpenWeatherMap API (Optional)
   OPENWEATHER_API_KEY=YOUR_OPENWEATHER_KEY
   ```

### Step 2: Get Firebase Config Values

1. **Get Firebase Configuration**
   - Buka Firebase Console
   - Settings (gear icon) → Project settings
   - Scroll to "Your apps" section
   - Klik Android/iOS app
   - Expand "SDK setup and configuration"
   - Copy values:
     - `FIREBASE_API_KEY`: apiKey
     - `FIREBASE_APP_ID`: appId
     - `FIREBASE_MESSAGING_SENDER_ID`: messagingSenderId
     - `FIREBASE_PROJECT_ID`: projectId

### Step 3: Add to .gitignore

Pastikan `.env` sudah ada di `.gitignore`:
```bash
echo ".env" >> .gitignore
```

---

## 🔥 Firebase Services Configuration

### 1. Cloud Firestore Indexes

Beberapa query kompleks memerlukan composite indexes.

1. **Buka Firestore Console**
   - Klik "Indexes" tab

2. **Create Required Indexes**

   Atau jalankan app dan Firestore akan memberikan link untuk create indexes otomatis.

   Example indexes needed:
   - Collection: `trips`
     - Fields: `isPublic` (Ascending), `createdAt` (Descending)
   - Collection: `destinations`
     - Fields: `category` (Ascending), `rating` (Descending)

### 2. Firebase Cloud Functions (Optional)

Jika Anda ingin setup server-side logic:

1. **Install Firebase CLI**
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**
   ```bash
   firebase login
   ```

3. **Initialize Functions**
   ```bash
   firebase init functions
   ```

---

## 🗺️ Google Maps API Setup

### Step 1: Configure Android

1. **Edit AndroidManifest.xml**

   File: `android/app/src/main/AndroidManifest.xml`

   Add inside `<application>` tag:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="${GOOGLE_MAPS_API_KEY}"/>
   ```

### Step 2: Configure iOS (Optional)

1. **Edit AppDelegate.swift**

   File: `ios/Runner/AppDelegate.swift`

   Add:
   ```swift
   import GoogleMaps

   GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
   ```

---

## 🤖 Google AI (Gemini) Setup

### Step 1: Verify API Key

1. **Test API Key**

   Buka terminal dan test:
   ```bash
   curl \
     -H 'Content-Type: application/json' \
     -d '{"contents":[{"parts":[{"text":"Hello"}]}]}' \
     -X POST 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=YOUR_API_KEY'
   ```

2. **Should Return JSON Response**

   Jika sukses, API key valid.

### Step 2: Set API Limits (Optional)

1. **Buka GCP Console**
   - APIs & Services → Credentials
   - Edit API key → Quotas

2. **Set Quotas**
   - Requests per day: 1,500 (free tier)
   - Requests per minute: 60

---

## 🧪 Testing Configuration

### Step 1: Run Tests

```bash
# Unit tests
flutter test test/unit/

# Widget tests
flutter test test/widgets/

# Integration tests
flutter test integration_test/
```

### Step 2: Run on Emulator/Device

1. **Start Android Emulator**
   ```bash
   flutter emulators
   flutter emulators --launch <emulator_id>
   ```

2. **Run App**
   ```bash
   flutter run
   ```

3. **Run in Debug Mode**
   ```bash
   flutter run --debug
   ```

4. **Run in Release Mode**
   ```bash
   flutter run --release
   ```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Google Sign-In Not Working

**Problem**: Google Sign-In button tidak berfungsi

**Solution**:
- Pastikan SHA-1 sudah ditambahkan di Firebase Console
- Get SHA-1:
  ```bash
  cd android
  ./gradlew signingReport
  ```
- Add SHA-1 di Firebase Console → Project Settings → Android app

#### 2. Maps Not Loading

**Problem**: Google Maps tidak muncul

**Solution**:
- Verify API key sudah benar di `.env`
- Pastikan Maps SDK for Android/iOS sudah enabled di GCP
- Check API restrictions di GCP Console
- Verify billing enabled (jika diperlukan)

#### 3. Firestore Permission Denied

**Problem**: Error "Insufficient permissions"

**Solution**:
- Check Firestore security rules
- Pastikan user sudah authenticated
- Verify rules match your data structure

#### 4. Firebase Not Initialized

**Problem**: "FirebaseApp is not initialized"

**Solution**:
- Verify `google-services.json` exists di `android/app/`
- Verify `GoogleService-Info.plist` exists di `ios/Runner/`
- Run `flutter clean` dan `flutter pub get`
- Rebuild app

#### 5. Gemini API Quota Exceeded

**Problem**: "Quota exceeded" error

**Solution**:
- Check API usage di GCP Console
- Upgrade to paid tier jika diperlukan
- Implement rate limiting di app

### Debug Commands

```bash
# Clean build
flutter clean
flutter pub get

# Check Flutter doctor
flutter doctor -v

# Check dependencies
flutter pub outdated

# Analyze code
flutter analyze

# Check for platform-specific issues
flutter doctor --android-licenses  # Android
pod install  # iOS (di folder ios/)

# View detailed logs
flutter run --verbose
adb logcat  # Android logs
```

---

## 📚 Additional Resources

### Documentation
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Google Maps Flutter Plugin](https://pub.dev/packages/google_maps_flutter)
- [Google AI Dart SDK](https://pub.dev/packages/google_generative_ai)

### Video Tutorials
- [Firebase Setup for Flutter](https://www.youtube.com/watch?v=sz4slPFwEvs)
- [Google Maps in Flutter](https://www.youtube.com/watch?v=RpQLFAFqMlw)

### Community Support
- [Flutter Discord](https://discord.gg/flutter)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [Reddit r/FlutterDev](https://www.reddit.com/r/FlutterDev/)

---

## ✅ Verification Checklist

Gunakan checklist ini untuk memastikan semua setup sudah benar:

### Firebase Setup
- [ ] Firebase project created
- [ ] Android app registered
- [ ] iOS app registered (jika applicable)
- [ ] `google-services.json` di `android/app/`
- [ ] `GoogleService-Info.plist` di `ios/Runner/`
- [ ] Authentication enabled (Email, Google, Anonymous)
- [ ] Firestore database created
- [ ] Storage bucket created
- [ ] Cloud Messaging enabled

### GCP Setup
- [ ] GCP project linked dengan Firebase
- [ ] Maps SDK for Android enabled
- [ ] Maps SDK for iOS enabled (jika applicable)
- [ ] Places API enabled
- [ ] Geocoding API enabled
- [ ] Generative Language API enabled
- [ ] API keys created dan restricted
- [ ] Billing account linked (jika diperlukan)

### Project Configuration
- [ ] Dependencies installed (`flutter pub get`)
- [ ] `.env` file created dengan semua keys
- [ ] `.env` added to `.gitignore`
- [ ] Android build.gradle configured
- [ ] iOS configuration done (jika applicable)
- [ ] App builds successfully
- [ ] All tests pass

### Testing
- [ ] App runs on emulator/device
- [ ] Firebase Authentication works
- [ ] Google Sign-In works
- [ ] Firestore read/write works
- [ ] Storage upload/download works
- [ ] Google Maps displays correctly
- [ ] Gemini AI API responds

---

## 🎉 Setup Complete!

Jika semua checklist sudah ✅, aplikasi ReLink Anda sudah siap untuk development dan testing!

Untuk production deployment, pastikan untuk:
1. Update Firestore dan Storage security rules
2. Enable production mode di Firebase
3. Set up proper API quotas dan limits
4. Configure proper error logging
5. Set up CI/CD pipeline

**Happy Coding! 🚀**

---

## 📞 Support

Jika mengalami masalah yang tidak tercantum di troubleshooting:
- Check project's GitHub Issues
- Baca SETUP_GUIDE.md untuk informasi tambahan
- Contact project maintainer

---

*Last Updated: 2025-10-12*
*Version: 4.1.0*
