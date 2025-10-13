# 🚀 ReLink - Com7. [Part 7: Setup Gemini AI](#part-7-setup-gemini-ai)
8. [Part 8: Setup Cloudinary (Image Storage)](#part-8-setup-cloudinary-image-storage)
9. [Part 9: Testing](#part-9-testing)
10. [Troubleshooting](#troubleshooting)te Setup Guide (Manual)

Panduan lengkap step-by-step untuk setup ReLink app dari awal sampai siap dijalankan.

**Estimasi Waktu:** 2-3 jam (tergantung kecepatan internet)

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Part 1: Create Firebase Project](#part-1-create-firebase-project)
3. [Part 2: Setup Google Cloud Platform (GCP)](#part-2-setup-google-cloud-platform-gcp)
4. [Part 3: Enable Firebase Services](#part-3-enable-firebase-services)
5. [Part 4: Setup Android App in Firebase](#part-4-setup-android-app-in-firebase)
6. [Part 5: Configure Local Project](#part-5-configure-local-project)
7. [Part 6: Setup Google APIs](#part-6-setup-google-apis)
8. [Part 7: Setup Gemini AI](#part-7-setup-gemini-ai)
9. [Part 8: Testing](#part-8-testing)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### ✅ Yang Perlu Anda Miliki:

1. **Google Account** (Gmail)
2. **Flutter SDK** installed (version 3.x atau lebih baru)
3. **Android Studio** installed dengan Android SDK
4. **Git** installed
5. **Internet connection** yang stabil
6. **Text editor** (VS Code recommended)

### ✅ Verifikasi Flutter Installation:

```bash
flutter doctor
```

Pastikan output menunjukkan:
- ✓ Flutter SDK
- ✓ Android toolchain
- ✓ Android Studio
- ✓ VS Code (optional)

**Jika ada masalah, fix terlebih dahulu sebelum lanjut.**

---

## Part 1: Create Firebase Project

**Estimasi: 10 menit**

### Step 1.1: Buka Firebase Console

1. Buka browser
2. Go to: https://console.firebase.google.com/
3. Login dengan Google Account Anda

### Step 1.2: Create New Project

1. Click **"Add project"** atau **"Create a project"**
2. **Project name:**
   - Ketik: `ReLink` (atau nama lain yang Anda inginkan)
   - Firebase akan generate project ID otomatis (contoh: `relink-xxxxx`)
   - **CATAT PROJECT ID INI** - Anda akan butuh nanti
3. Click **Continue**

### Step 1.3: Google Analytics (Optional)

1. **Enable Google Analytics for this project:**
   - **Recommended:** Toggle ON (untuk tracking users)
   - Atau OFF jika tidak perlu analytics
2. Click **Continue**

3. Jika Analytics enabled:
   - **Analytics account:** Pilih "Default Account for Firebase"
   - **Analytics location:** Pilih **Indonesia** atau **Asia Pacific**
   - Accept terms and conditions
   - Click **Create project**

### Step 1.4: Wait for Project Creation

- Loading screen: "Setting up your Firebase project..."
- Tunggu 30-60 detik
- Ketika selesai, click **Continue**

### Step 1.5: You're in Firebase Console!

Anda sekarang berada di Firebase Console dashboard untuk project baru Anda.

**✅ Checkpoint:** Anda sudah punya Firebase project!

---

## Part 2: Setup Google Cloud Platform (GCP)

**Estimasi: 15-20 menit**

Firebase project otomatis membuat GCP project. Sekarang kita perlu setup billing untuk menggunakan Google Maps API dan Gemini AI.

### Step 2.1: Open Google Cloud Console

1. Buka tab baru
2. Go to: https://console.cloud.google.com/
3. Login dengan Google Account yang sama

### Step 2.2: Select Your Project

1. Click project dropdown di top bar
2. Cari project **ReLink** (atau nama yang Anda buat)
3. Click pada project tersebut

### Step 2.3: Enable Billing

**PENTING:** Anda perlu billing untuk Google Maps API, tapi ada $200 free credit!

#### A. Go to Billing

1. Click **☰** (hamburger menu) di top left
2. Scroll ke **"Billing"**
3. Click **"Billing"**

#### B. Create Billing Account

Jika belum punya billing account:

1. Click **"Add billing account"** atau **"Create account"**
2. **Country:** Pilih **Indonesia**
3. Fill form:
   - **Account name:** Bisa pakai nama Anda
   - **Payment method:**
     - **Option 1:** Credit/Debit Card (Visa, Mastercard)
     - **Option 2:** Virtual Account (beberapa bank Indonesia)
4. Accept terms and conditions
5. Click **"Submit and enable billing"**

#### C. Verify Free Credits

Anda akan mendapat:
- ✅ **$300 free credit** (untuk new GCP users)
- ✅ Valid untuk **90 hari**
- ✅ Tidak akan auto-charge setelah habis (kecuali Anda upgrade)

**Setelah $300 habis atau 90 hari, Anda masih dapat:**
- ✅ Firebase Auth: **GRATIS unlimited users**
- ✅ Firebase Firestore: **50,000 reads/day GRATIS**
- ✅ Google Maps: **$200/month free credit** (selamanya)

#### D. Link Billing to Project

1. Go back to GCP Console
2. Select your ReLink project
3. **Billing** → **Account Management**
4. Pastikan billing account linked ke project

**✅ Checkpoint:** Billing account sudah aktif dan linked!

---

## Part 3: Enable Firebase Services

**Estimasi: 10 menit**

Kembali ke Firebase Console untuk enable services yang dibutuhkan.

### Step 3.1: Enable Firebase Authentication

1. Di Firebase Console, sidebar left
2. Click **"Build"** → **"Authentication"**
3. Click **"Get started"**
4. Tab **"Sign-in method"**

#### Enable Google Sign-In:

1. Cari **"Google"** provider
2. Click **"Google"**
3. Toggle **"Enable"**
4. **Project support email:** Pilih email Anda
5. Click **"Save"**

#### Enable Email/Password Sign-In:

1. Cari **"Email/Password"** provider
2. Click **"Email/Password"**
3. Toggle **"Enable"** (yang pertama, bukan Email link)
4. Click **"Save"**

**✅ Checkpoint:** Authentication enabled!

### Step 3.2: Enable Cloud Firestore

1. Sidebar: **"Build"** → **"Firestore Database"**
2. Click **"Create database"**

#### Choose Location:

1. **Start in:** Pilih **"Production mode"** (kita akan setup rules nanti)
2. Click **"Next"**

#### Select Location:

1. **Firestore location:**
   - **Recommended:** `asia-southeast2` (Jakarta, Indonesia) - PALING DEKAT
   - Alternative: `asia-southeast1` (Singapore)
2. Click **"Enable"**

Wait 1-2 menit untuk provisioning.

#### Update Firestore Rules:

1. Tab **"Rules"**
2. Replace default rules dengan:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - user dapat read/write data mereka sendiri
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Destinations - semua user authenticated dapat read, hanya owner yang bisa write
    match /destinations/{destinationId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && resource.data.userId == request.auth.uid;
    }

    // Reviews - authenticated users bisa read semua, create review sendiri
    match /reviews/{reviewId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && resource.data.userId == request.auth.uid;
    }

    // Trips - user hanya bisa akses trip mereka sendiri
    match /trips/{tripId} {
      allow read, write: if request.auth != null && resource.data.userId == request.auth.uid;
    }

    // Bookings - user hanya bisa akses booking mereka sendiri
    match /bookings/{bookingId} {
      allow read, write: if request.auth != null && resource.data.userId == request.auth.uid;
    }
  }
}
```

3. Click **"Publish"**

**✅ Checkpoint:** Firestore database ready!

---

## Part 4: Setup Android App in Firebase

**Estimasi: 10 menit**

### Step 4.1: Register Android App

1. Di Firebase Console, click **⚙️ gear icon** (top left)
2. Click **"Project settings"**
3. Scroll ke **"Your apps"** section
4. Click **Android icon** (robot icon)

### Step 4.2: Fill App Details

1. **Android package name:**
   ```
   com.example.relink
   ```
   **PENTING:** Harus sama persis! Case-sensitive!

2. **App nickname (optional):**
   ```
   ReLink Android
   ```

3. **Debug signing certificate SHA-1 (optional):**
   - **Untuk sekarang:** SKIP (leave empty)
   - Nanti kita akan add untuk Google Sign-In

4. Click **"Register app"**

### Step 4.3: Download google-services.json

1. Click **"Download google-services.json"**
2. File akan ter-download ke folder Downloads Anda
3. **JANGAN CLOSE DIALOG INI DULU**

### Step 4.4: Place google-services.json in Project

1. Open File Explorer / Finder
2. Navigate ke Downloads folder
3. Copy `google-services.json`
4. Paste ke:
   ```
   D:\Subek\project\Draft\flutter\FinalCapstone\relink\android\app\
   ```

   **Path lengkap:**
   ```
   relink/
   └── android/
       └── app/
           └── google-services.json  ← Paste di sini
   ```

### Step 4.5: Continue in Firebase Console

1. Kembali ke browser (Firebase Console)
2. Click **"Next"** (kita sudah add Google services plugin di gradle)
3. Click **"Next"** lagi (dependencies juga sudah ada)
4. Click **"Continue to console"**

**✅ Checkpoint:** Android app registered dan google-services.json sudah di tempat!

---

## Part 5: Configure Local Project

**Estimasi: 15 menit**

Sekarang kita configure local project dengan credentials dari Firebase.

### Step 5.1: Extract Information from google-services.json

1. Open `android/app/google-services.json` dengan text editor
2. Cari dan CATAT informasi berikut:

```json
{
  "project_info": {
    "project_number": "123456789012",        ← CATAT INI
    "project_id": "relink-xxxxx",           ← CATAT INI
    "storage_bucket": "relink-xxxxx.firebasestorage.app"  ← CATAT INI
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789012:android:abcdef1234567890",  ← CATAT INI
        ...
      },
      "api_key": [
        {
          "current_key": "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"  ← CATAT INI
        }
      ]
    }
  ]
}
```

**Informasi yang perlu DICATAT:**
- `project_number` (contoh: 123456789012)
- `project_id` (contoh: relink-xxxxx)
- `storage_bucket` (contoh: relink-xxxxx.firebasestorage.app)
- `mobilesdk_app_id` (contoh: 1:123456789012:android:...)
- `current_key` (API Key) (contoh: AIzaSy...)

### Step 5.2: Get Web App Configuration

Kita juga butuh config untuk Web/Windows/iOS/macOS.

#### A. Add Web App (if not exists)

1. Kembali ke Firebase Console
2. **Project settings** → **Your apps**
3. Click **Web icon** (`</>`)
4. **App nickname:** `ReLink Web`
5. Check **"Also setup Firebase Hosting"** (optional)
6. Click **"Register app"**

#### B. Copy Web Configuration

Anda akan lihat script seperti ini:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
  authDomain: "relink-xxxxx.firebaseapp.com",
  projectId: "relink-xxxxx",
  storageBucket: "relink-xxxxx.firebasestorage.app",
  messagingSenderId: "123456789012",
  appId: "1:123456789012:web:abcdef1234567890",
  measurementId: "G-XXXXXXXXXX"
};
```

**CATAT semua value ini!**

### Step 5.3: Update .env File

1. Open `.env` file di root project Anda
2. Update Firebase variables:

```bash
# -----------------------------------------------
# FIREBASE WEB
# -----------------------------------------------
FIREBASE_WEB_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
FIREBASE_WEB_APP_ID=1:123456789012:web:abcdef1234567890
FIREBASE_WEB_MESSAGING_SENDER_ID=123456789012
FIREBASE_WEB_PROJECT_ID=relink-xxxxx
FIREBASE_WEB_AUTH_DOMAIN=relink-xxxxx.firebaseapp.com
FIREBASE_WEB_STORAGE_BUCKET=relink-xxxxx.firebasestorage.app
FIREBASE_WEB_MEASUREMENT_ID=G-XXXXXXXXXX

# -----------------------------------------------
# FIREBASE ANDROID
# -----------------------------------------------
FIREBASE_ANDROID_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  # dari google-services.json
FIREBASE_ANDROID_APP_ID=1:123456789012:android:abcdef1234567890  # dari google-services.json
FIREBASE_ANDROID_MESSAGING_SENDER_ID=123456789012
FIREBASE_ANDROID_PROJECT_ID=relink-xxxxx
FIREBASE_ANDROID_STORAGE_BUCKET=relink-xxxxx.firebasestorage.app

# -----------------------------------------------
# FIREBASE WINDOWS (use same as Web)
# -----------------------------------------------
FIREBASE_WINDOWS_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
FIREBASE_WINDOWS_APP_ID=1:123456789012:web:abcdef1234567890
FIREBASE_WINDOWS_MESSAGING_SENDER_ID=123456789012
FIREBASE_WINDOWS_PROJECT_ID=relink-xxxxx
FIREBASE_WINDOWS_AUTH_DOMAIN=relink-xxxxx.firebaseapp.com
FIREBASE_WINDOWS_STORAGE_BUCKET=relink-xxxxx.firebasestorage.app
FIREBASE_WINDOWS_MEASUREMENT_ID=G-XXXXXXXXXX
```

**Note:** Untuk iOS dan macOS, biarkan placeholder dulu jika tidak develop untuk platform tersebut.

### Step 5.4: Create firebase_options.dart

1. Create file: `lib/firebase_options.dart`
2. Isi dengan:

```dart
// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_WEB_API_KEY']!,
    appId: dotenv.env['FIREBASE_WEB_APP_ID']!,
    messagingSenderId: dotenv.env['FIREBASE_WEB_MESSAGING_SENDER_ID']!,
    projectId: dotenv.env['FIREBASE_WEB_PROJECT_ID']!,
    authDomain: dotenv.env['FIREBASE_WEB_AUTH_DOMAIN']!,
    storageBucket: dotenv.env['FIREBASE_WEB_STORAGE_BUCKET']!,
    measurementId: dotenv.env['FIREBASE_WEB_MEASUREMENT_ID']!,
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_ANDROID_API_KEY']!,
    appId: dotenv.env['FIREBASE_ANDROID_APP_ID']!,
    messagingSenderId: dotenv.env['FIREBASE_ANDROID_MESSAGING_SENDER_ID']!,
    projectId: dotenv.env['FIREBASE_ANDROID_PROJECT_ID']!,
    storageBucket: dotenv.env['FIREBASE_ANDROID_STORAGE_BUCKET']!,
  );

  static FirebaseOptions get windows => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_WINDOWS_API_KEY']!,
    appId: dotenv.env['FIREBASE_WINDOWS_APP_ID']!,
    messagingSenderId: dotenv.env['FIREBASE_WINDOWS_MESSAGING_SENDER_ID']!,
    projectId: dotenv.env['FIREBASE_WINDOWS_PROJECT_ID']!,
    authDomain: dotenv.env['FIREBASE_WINDOWS_AUTH_DOMAIN']!,
    storageBucket: dotenv.env['FIREBASE_WINDOWS_STORAGE_BUCKET']!,
    measurementId: dotenv.env['FIREBASE_WINDOWS_MEASUREMENT_ID']!,
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_IOS_API_KEY'] ?? '',
    appId: dotenv.env['FIREBASE_IOS_APP_ID'] ?? '',
    messagingSenderId: dotenv.env['FIREBASE_IOS_MESSAGING_SENDER_ID'] ?? '',
    projectId: dotenv.env['FIREBASE_IOS_PROJECT_ID'] ?? '',
    storageBucket: dotenv.env['FIREBASE_IOS_STORAGE_BUCKET'] ?? '',
    androidClientId: dotenv.env['FIREBASE_IOS_ANDROID_CLIENT_ID'],
    iosClientId: dotenv.env['FIREBASE_IOS_CLIENT_ID'],
    iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID'],
  );

  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_MACOS_API_KEY'] ?? '',
    appId: dotenv.env['FIREBASE_MACOS_APP_ID'] ?? '',
    messagingSenderId: dotenv.env['FIREBASE_MACOS_MESSAGING_SENDER_ID'] ?? '',
    projectId: dotenv.env['FIREBASE_MACOS_PROJECT_ID'] ?? '',
    storageBucket: dotenv.env['FIREBASE_MACOS_STORAGE_BUCKET'] ?? '',
    androidClientId: dotenv.env['FIREBASE_MACOS_ANDROID_CLIENT_ID'],
    iosClientId: dotenv.env['FIREBASE_MACOS_CLIENT_ID'],
    iosBundleId: dotenv.env['FIREBASE_MACOS_BUNDLE_ID'],
  );
}
```

**✅ Checkpoint:** Firebase configuration ready!

---

## Part 6: Setup Google APIs

**Estimasi: 20 menit**

### Step 6.1: Enable Google Maps APIs

1. Go to: https://console.cloud.google.com/
2. Select your ReLink project
3. **Navigation menu** (☰) → **APIs & Services** → **Library**

#### Enable These APIs:

Search dan enable satu per satu:

1. **Maps SDK for Android**
   - Search: "Maps SDK for Android"
   - Click on it
   - Click **"Enable"**
   - Wait 1-2 menit

2. **Places API**
   - Search: "Places API"
   - Click on it
   - Click **"Enable"**
   - Wait 1-2 menit

3. **Directions API**
   - Search: "Directions API"
   - Click on it
   - Click **"Enable"**
   - Wait 1-2 menit

4. **Geocoding API**
   - Search: "Geocoding API"
   - Click on it
   - Click **"Enable"**
   - Wait 1-2 menit

### Step 6.2: Create API Key

1. **Navigation menu** (☰) → **APIs & Services** → **Credentials**
2. Click **"+ CREATE CREDENTIALS"**
3. Select **"API key"**
4. API key created! Copy dan **SIMPAN API KEY INI**

### Step 6.3: Restrict API Key (Security)

**PENTING:** Restrict API key agar tidak disalahgunakan!

1. Click **"Edit API key"** (atau click nama API key yang baru dibuat)
2. **API restrictions:**
   - Select **"Restrict key"**
   - Check these APIs:
     - ☑️ Maps SDK for Android
     - ☑️ Places API
     - ☑️ Directions API
     - ☑️ Geocoding API
3. **Application restrictions:**
   - Select **"Android apps"**
   - Click **"+ Add an item"**
   - **Package name:** `com.example.relink`
   - **SHA-1 certificate fingerprint:** (will add later for Google Sign-In)
   - Click **"Done"**
4. Click **"Save"**

### Step 6.4: Get SHA-1 Fingerprint (for Google Sign-In)

Open terminal di root project:

```bash
cd android
./gradlew signingReport
```

**Jika error Java 25:**
```bash
# Use flutter run instead (it uses correct Java version)
cd ..
flutter run  # Will show SHA-1 in logs
```

Atau manual:

**Windows:**
```bash
cd %USERPROFILE%\.android
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**macOS/Linux:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copy **SHA-1 fingerprint** (contoh: `AB:CD:EF:12:34:56...`)

### Step 6.5: Add SHA-1 to Firebase

1. Kembali ke Firebase Console
2. **Project settings** → **Your apps** → **Android app**
3. Scroll ke **"SHA certificate fingerprints"**
4. Click **"Add fingerprint"**
5. Paste SHA-1 yang Anda copy
6. Click **"Save"**

### Step 6.6: Update .env with Google Maps API Key

1. Open `.env`
2. Update:

```bash
GOOGLE_MAPS_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  # Your API key
```

**✅ Checkpoint:** Google Maps APIs ready!

---

## Part 7: Setup Gemini AI

**Estimasi: 10 menit**

### Step 7.1: Go to Google AI Studio

1. Open: https://aistudio.google.com/
2. Login dengan Google Account yang sama
3. Accept Terms of Service (jika diminta)

### Step 7.2: Create API Key

1. Click **"Get API key"** (top right atau sidebar)
2. Select your Firebase project: **ReLink**
3. Click **"Create API key in existing project"**
4. Copy API key yang muncul

### Step 7.3: Update .env

1. Open `.env`
2. Update:

```bash
GEMINI_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  # Your Gemini API key
```

**✅ Checkpoint:** Gemini AI ready!

---

## Part 8: Setup Cloudinary (Image Storage)

**Estimasi: 15 menit**

Cloudinary adalah layanan cloud storage untuk gambar dan video yang lebih cost-effective dibandingkan Firebase Storage. Dengan Cloudinary, Anda mendapat **25GB storage + 25GB bandwidth GRATIS** setiap bulan!

### Step 8.1: Create Cloudinary Account

1. **Go to Cloudinary:**
   - Open: https://cloudinary.com/
   - Click **"Sign Up for Free"**

2. **Fill Registration Form:**
   - **First Name:** Nama depan Anda
   - **Last Name:** Nama belakang Anda
   - **Email:** Email Anda (gunakan email yang sama dengan Firebase)
   - **Company:** Optional, bisa kosong atau isi "Personal"
   - **Password:** Password yang kuat
   - Check **"I agree to the Terms of Use and Privacy Policy"**
   - Click **"Sign Up for Free"**

3. **Email Verification:**
   - Check email Anda untuk verification link
   - Click link di email untuk verify account
   - Login ke Cloudinary Console

### Step 8.2: Get Cloudinary Credentials

Setelah login, Anda akan berada di Cloudinary Dashboard.

1. **Find Dashboard Credentials:**
   - Di halaman utama, Anda akan lihat section **"Account Details"**
   - **CATAT informasi berikut:**

```
Cloud Name: your-cloud-name
API Key: 123456789012345
API Secret: AbCdEfGhIjKlMnOpQrStUvWxYz
```

**PENTING:** Jangan share API Secret dengan siapa pun!

### Step 8.3: Create Upload Preset

Upload preset adalah konfigurasi untuk upload gambar (resize, format, quality, dll).

1. **Go to Settings:**
   - Click **gear icon (⚙️)** di top right
   - Atau go to: https://console.cloudinary.com/settings

2. **Upload Tab:**
   - Click **"Upload"** tab di sidebar kiri
   - Scroll ke **"Upload presets"** section
   - Click **"Add upload preset"**

3. **Configure Upload Preset:**
   - **Upload preset name:** `relink_app_preset` (CATAT INI)
   - **Signing Mode:** Pilih **"Unsigned"** (untuk mobile app)
   - **Access Mode:** **"Public"** (gambar bisa diakses public)

4. **Image Transformations (Optional but Recommended):**
   - **Folder:** `relink` (semua upload akan masuk folder ini)
   - **Format:** **"Auto"** (Cloudinary akan otomatis pilih format terbaik)
   - **Quality:** **"Auto"** (otomatis optimize quality)
   - **Max dimensions:** 
     - **Width:** `1920` (max width)
     - **Height:** `1920` (max height)
   - **Crop mode:** **"Limit"** (tidak akan crop, hanya resize jika terlalu besar)

5. **Click "Save"**

### Step 8.4: Configure Folder Structure

1. **Go to Media Library:**
   - Click **"Media Library"** di sidebar
   - Atau go to: https://console.cloudinary.com/console/media_library

2. **Create Folders:**
   - Click **"Create Folder"** atau **folder icon**
   - Create these folders:
     - `avatars` (untuk profile pictures)
     - `gallery` (untuk photo gallery)
     - `destinations` (untuk destination covers)
     - `chat_images` (untuk chat photos)
     - `review_photos` (untuk review photos)
     - `temp` (untuk temporary uploads)

### Step 8.5: Update .env File

1. **Open `.env` file di root project**
2. **Add Cloudinary Configuration:**

```bash
# -----------------------------------------------
# CLOUDINARY (Image Storage) - FREE 25GB/month
# -----------------------------------------------
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=123456789012345
CLOUDINARY_API_SECRET=AbCdEfGhIjKlMnOpQrStUvWxYz
CLOUDINARY_UPLOAD_PRESET=relink_app_preset

# Optional: Cloudinary settings
CLOUDINARY_SECURE=true
CLOUDINARY_USE_FILENAME=true
CLOUDINARY_UNIQUE_FILENAME=true
```

**Replace dengan credentials Anda yang sebenarnya!**

### Step 8.6: Test Cloudinary Integration

1. **Install Dependencies:**
```bash
flutter pub get
```

2. **Test Upload (Optional):**
   - Run app: `flutter run`
   - Try upload photo di profile atau gallery
   - Check Cloudinary Media Library - foto harus muncul

### Step 8.7: Understand Cloudinary Benefits

#### ✅ **Cost Comparison:**

**Firebase Storage:**
- 1GB storage: $0.026/month
- 1GB bandwidth: $0.12/month
- **10GB = ~$1.46/month**

**Cloudinary FREE Tier:**
- **25GB storage: FREE**
- **25GB bandwidth: FREE** 
- Image optimization: FREE
- Transformations: FREE
- **Total: $0/month!** 💚

#### ✅ **Features You Get FREE:**

1. **Automatic Image Optimization:**
   - WebP/AVIF format conversion
   - Quality optimization
   - Responsive images

2. **On-the-fly Transformations:**
   - Resize, crop, rotate
   - Apply filters and effects
   - Face detection and cropping

3. **CDN (Content Delivery Network):**
   - Global edge locations
   - Fast image delivery worldwide

4. **AI-Powered Features:**
   - Auto-tagging
   - Object detection
   - Background removal

### Step 8.8: Monitor Usage

1. **Check Usage Dashboard:**
   - Go to: https://console.cloudinary.com/console
   - **Usage** tab shows:
     - Storage used
     - Bandwidth used
     - Transformations used
     - Credits remaining

2. **Set Usage Alerts (Recommended):**
   - **Settings** → **Notifications**
   - Set alerts at 80% of free tier limits

**✅ Checkpoint:** Cloudinary storage ready dengan 25GB FREE!

---

## Part 9: Testing

**Estimasi: 10 menit**

### Step 8.1: Install Dependencies

```bash
flutter pub get
```

### Step 8.2: Clean Build

```bash
flutter clean
```

### Step 8.3: Run App

```bash
flutter run
```

**Pilih device:**
- Chrome (for web testing)
- Android Emulator
- Physical Android device

### Step 9.4: Test Features

#### Test 1: Firebase Connection
- App should launch without errors
- Check logs: "Firebase initialized"

#### Test 2: Authentication
- Try **Sign Up** dengan email/password
- Atau **Sign In with Google**
- Check Firebase Console → Authentication → Users (user baru muncul)

#### Test 3: Firestore
- Create profile atau add data
- Check Firebase Console → Firestore Database (data muncul)

#### Test 4: Google Maps
- Navigate ke screen dengan map
- Map harus load dengan benar

#### Test 5: Cloudinary Image Upload
- Go to Profile screen
- Try upload/change profile picture
- Check Cloudinary Media Library - image should appear in `avatars` folder
- Try upload photo to gallery
- Check `gallery` folder in Cloudinary

#### Test 6: Image Optimization
- Upload large image (>5MB)
- Check final uploaded image size - should be optimized
- Try different URL transformations

**✅ SELESAI! App Anda siap digunakan dengan cloud storage yang cost-effective!** 🎉

---

## Troubleshooting

### Problem 1: "google-services.json not found"

**Solution:**
```bash
# Check file location
ls android/app/google-services.json

# If not exists, download again from Firebase Console
```

### Problem 2: "Firebase initialization failed"

**Solution:**
- Check `.env` file - pastikan semua Firebase values terisi
- Check `lib/firebase_options.dart` exists
- Run: `flutter clean && flutter pub get`

### Problem 3: "Google Maps not loading"

**Solution:**
- Check `.env` - pastikan `GOOGLE_MAPS_API_KEY` terisi
- Check GCP Console - pastikan Maps APIs enabled
- Check API key restrictions - pastikan `com.example.relink` allowed

### Problem 4: "Google Sign-In failed"

**Solution:**
- Check SHA-1 fingerprint sudah di-add di Firebase
- Check OAuth client ID di GCP Console
- Re-download `google-services.json` setelah add SHA-1

### Problem 5: Build failed - Java 25 error

**Solution:**
```bash
# Option 1: Use flutter run (uses correct Java)
flutter run

# Option 2: Install Java 17 LTS
# Download from: https://adoptium.net/temurin/releases/?version=17
```

### Problem 6: "Insufficient permissions" di Firestore

**Solution:**
- Check Firestore Rules di Firebase Console
- Update rules sesuai Part 3.2

### Problem 7: "Cloudinary upload failed" 

**Solution:**
```bash
# Check .env file
grep CLOUDINARY .env

# Should show:
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=123456789012345
CLOUDINARY_API_SECRET=secret
CLOUDINARY_UPLOAD_PRESET=relink_app_preset
```

- Check Cloudinary credentials benar
- Check upload preset exists dan unsigned
- Check internet connection

### Problem 8: "Cloudinary image not loading"

**Solution:**
- Check image URL format: should be `https://res.cloudinary.com/...`
- Check image exists di Cloudinary Media Library
- Try different transformation parameters
- Check network connectivity

### Problem 9: "Upload preset not found"

**Solution:**
- Go to Cloudinary Console → Settings → Upload
- Create new upload preset dengan nama `relink_app_preset`
- Set Signing Mode = "Unsigned"
- Update `.env` dengan preset name yang benar

### Problem 10: "Exceeded free tier limits"

**Solution:**
- Check usage di Cloudinary Dashboard
- Optimize images before upload
- Delete old/unused images
- Consider upgrade plan jika perlu

---

## 📚 Additional Resources

### Firebase Documentation:
- https://firebase.google.com/docs/flutter/setup
- https://firebase.google.com/docs/auth
- https://firebase.google.com/docs/firestore

### Google Maps Documentation:
- https://developers.google.com/maps/documentation
- https://pub.dev/packages/google_maps_flutter

### Gemini AI Documentation:
- https://ai.google.dev/docs

---

## 🎯 Summary Checklist

### Firebase Setup:
- [x] Firebase project created
- [x] Authentication enabled (Google + Email/Password)
- [x] Firestore database created with rules
- [x] Android app registered
- [x] `google-services.json` downloaded dan placed

### GCP Setup:
- [x] Billing account created
- [x] Google Maps APIs enabled
- [x] API key created dan restricted
- [x] SHA-1 fingerprint added

### Local Configuration:
- [x] `.env` file updated dengan semua credentials
- [x] `lib/firebase_options.dart` created
- [x] Dependencies installed

### API Keys:
- [x] Google Maps API key
- [x] Gemini AI API key
- [x] Cloudinary credentials

### Cloud Storage:
- [x] Cloudinary account created
- [x] Upload preset configured
- [x] Folder structure created
- [x] Environment variables set

### Testing:
- [x] App runs without errors
- [x] Firebase connection working
- [x] Authentication working
- [x] Firestore working
- [x] Google Maps working
- [x] Cloudinary image upload working

---

**🎉 CONGRATULATIONS!**

ReLink app Anda sekarang sudah fully configured dengan cloud storage yang cost-effective dan siap untuk development!

**Estimated Cost:**
- Firebase: **FREE** (up to 50K Firestore reads/day, unlimited Auth users)
- Google Maps: **FREE** (up to $200/month usage)
- Gemini AI: **FREE** (60 requests/minute)
- Cloudinary: **FREE** (25GB storage + 25GB bandwidth/month)
- **Total: $0/month** untuk usage normal dengan storage yang generous! 💚

### Monthly Free Tier Limits:
- **Firebase Firestore:** 50,000 document reads, 20,000 writes
- **Google Maps:** $200 credit (~28,500 map loads)
- **Gemini AI:** 60 requests/minute, 1500 requests/day
- **Cloudinary:** 25GB storage, 25GB bandwidth, unlimited transformations
- **Total Storage:** 25GB images + unlimited Firestore documents

---

**Last Updated:** October 2024
**Version:** 1.0
