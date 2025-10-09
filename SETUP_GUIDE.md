# 🚀 ReLink Setup Guide

Panduan lengkap untuk setup ReLink app dari awal, termasuk konfigurasi Firebase, Google Cloud Platform, dan services lainnya.

---

## 📋 Prerequisites

Sebelum memulai, pastikan Anda sudah memiliki:

- ✅ Flutter SDK (3.9.2 atau lebih baru)
- ✅ Dart SDK (3.9.2 atau lebih baru)
- ✅ Android Studio / VS Code
- ✅ Google Account (untuk Firebase & GCP)
- ✅ Git
- ✅ Node.js (untuk Firebase CLI)

---

## 🔥 Firebase Setup

### 1. Buat Firebase Project

1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Klik **"Add project"** atau **"Create a project"**
3. Masukkan nama project: **ReLink** (atau nama sesuai keinginan)
4. Enable/Disable Google Analytics (opsional)
5. Klik **"Create project"**

### 2. Tambahkan Android App

1. Di Firebase Console, klik icon **Android** (⚙️)
2. Masukkan **Android package name**: `com.relink.app` (sesuaikan dengan `applicationId` di `android/app/build.gradle`)
3. Masukkan **App nickname**: ReLink Android
4. Download file `google-services.json`
5. Copy file ke folder `android/app/`

### 3. Tambahkan iOS App (Optional)

1. Klik icon **iOS** (🍎)
2. Masukkan **iOS bundle ID**: `com.relink.app` (sesuaikan dengan Xcode)
3. Download file `GoogleService-Info.plist`
4. Copy file ke folder `ios/Runner/`

### 4. Enable Firebase Services

Di Firebase Console, enable services berikut:

#### **Authentication**
1. Pergi ke **Authentication** → **Sign-in method**
2. Enable providers:
   - ✅ **Email/Password**
   - ✅ **Google Sign-In**
   - ✅ **Phone** (opsional untuk SMS verification)

#### **Firestore Database**
1. Pergi ke **Firestore Database**
2. Klik **"Create database"**
3. Pilih mode: **Start in test mode** (untuk development)
4. Pilih lokasi: **asia-southeast2** (Jakarta) atau yang terdekat
5. Klik **"Enable"**

**Security Rules** (Production): Lihat `firestore.rules` di repository

#### **Firebase Storage**
1. Pergi ke **Storage**
2. Klik **"Get started"**
3. Pilih mode: **Start in test mode**
4. Pilih lokasi: **asia-southeast2**
5. Klik **"Done"**

**Storage Rules** (Production): Lihat `storage.rules` di repository

#### **Cloud Messaging (FCM)**
1. Pergi ke **Cloud Messaging**
2. Note: FCM sudah enabled secara default
3. Download **Server Key** untuk push notifications (di Project Settings → Cloud Messaging)

---

## ☁️ Google Cloud Platform Setup

### 1. Enable Required APIs

1. Buka [Google Cloud Console](https://console.cloud.google.com/)
2. Pilih project Firebase Anda (nama yang sama)
3. Pergi ke **APIs & Services** → **Library**
4. Enable APIs berikut:

   - ✅ **Maps SDK for Android**
   - ✅ **Maps SDK for iOS**
   - ✅ **Places API**
   - ✅ **Places API (New)**
   - ✅ **Geocoding API**
   - ✅ **Geolocation API**
   - ✅ **Directions API**

### 2. Create API Key

1. Pergi ke **APIs & Services** → **Credentials**
2. Klik **"+ CREATE CREDENTIALS"** → **API key**
3. Copy API key yang di-generate
4. Klik icon **edit** (✏️) pada API key

#### **Restrict API Key (Recommended)**

**Application Restrictions**:
- Set application restrictions untuk Android/iOS dengan package name dan SHA-1 fingerprint

**API Restrictions**:
```
✅ Maps SDK for Android
✅ Maps SDK for iOS
✅ Places API
✅ Geocoding API
✅ Geolocation API
✅ Directions API
```

### 3. Enable Billing (Required for Places API)

1. Pergi ke **Billing**
2. Link credit card untuk billing
3. Note: Google memberikan **$200 free credit per bulan**
4. Set up **budget alerts** untuk monitoring (recommended: $50/month budget)

---

## 🔑 Google Gemini AI Setup

### 1. Get Gemini API Key

1. Buka [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Klik **"Get API Key"** atau **"Create API Key"**
3. Pilih project yang sama dengan Firebase
4. Copy API key yang di-generate

### 2. Enable Gemini APIs

Pastikan **Generative Language API** enabled di GCP

---

## 📝 Environment Variables Setup

### 1. Create `.env` File

Copy file `.env.example` menjadi `.env`:
```bash
cp .env.example .env
```

### 2. Fill Environment Variables

Edit file `.env` dan isi dengan API keys Anda:

```env
# Google Maps & Places API
GOOGLE_MAPS_API_KEY=AIzaSyB_YOUR_ACTUAL_API_KEY_HERE

# Google Gemini AI API
GEMINI_API_KEY=AIzaSyC_YOUR_GEMINI_API_KEY_HERE

# App Configuration
APP_NAME=ReLink
APP_VERSION=1.0.0
ENVIRONMENT=development
```

---

## 📦 Dependencies Installation

### 1. Install Flutter Dependencies

```bash
cd relink
flutter pub get
```

### 2. Install Firebase CLI (Optional)

```bash
npm install -g firebase-tools
firebase login
firebase init
```

### 3. Setup Android Build

```bash
cd android
./gradlew clean
cd ..
```

### 4. Setup iOS (Mac only)

```bash
cd ios
pod install
cd ..
```

---

## 🏃 Running the App

### 1. Connect Device / Emulator

```bash
flutter devices
```

### 2. Run App

**Development mode**:
```bash
flutter run
```

**Specific device**:
```bash
flutter run -d <device-id>
```

**Release mode**:
```bash
flutter run --release
```

---

## 🧪 Testing

### Run Tests

```bash
flutter test
flutter analyze
```

---

## 📱 Building for Production

### Android APK

```bash
flutter build apk --release
```

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

### iOS (Mac only)

```bash
flutter build ios --release
```

---

## 🔒 Security Checklist

Before Production:

- [ ] Update Firestore Security Rules ke production mode
- [ ] Update Storage Security Rules ke production mode
- [ ] Restrict Google Maps API key dengan package name & SHA-1
- [ ] Enable Google Cloud billing alerts
- [ ] Remove debug logs dari production build
- [ ] Setup crash reporting (Firebase Crashlytics)
- [ ] Setup analytics (Firebase Analytics)

---

## 🐛 Troubleshooting

### Google Maps tidak muncul
- Cek API key di `.env` sudah benar
- Cek Maps SDK for Android/iOS sudah enabled
- Cek billing sudah active di GCP

### Places API tidak return hasil
- Cek Places API sudah enabled
- Cek billing sudah active
- Cek quota belum exceeded

### Firebase authentication gagal
- Cek `google-services.json` sudah ada di `android/app/`
- Cek package name sama dengan Firebase console

### Build gagal
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📚 Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Google Maps Platform](https://developers.google.com/maps/documentation)
- [Google Gemini AI](https://ai.google.dev/docs)
- [Flutter Documentation](https://docs.flutter.dev/)

---

**Last Updated**: January 2025
**Version**: 1.0.0
**Status**: ✅ Complete
