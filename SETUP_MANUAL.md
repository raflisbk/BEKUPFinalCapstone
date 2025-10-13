# 🚀 ReLink - Complete Setup Manual

Panduan lengkap setup ReLink dari nol sampai production-ready. Ikuti step-by-step dengan teliti.

> **Estimasi Waktu:** 60-90 menit
> **Biaya:** $0 (semua menggunakan free tier)

---

## 📑 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Part 1: Firebase Setup](#part-1-firebase-setup)
3. [Part 2: Google Cloud Platform (GCP) Setup](#part-2-google-cloud-platform-gcp-setup)
4. [Part 3: Google Gemini AI Setup](#part-3-google-gemini-ai-setup)
5. [Part 4: Indonesia Tourism API Setup](#part-4-indonesia-tourism-api-setup)
6. [Part 5: Environment Configuration](#part-5-environment-configuration)
7. [Part 6: Android Configuration](#part-6-android-configuration)
8. [Part 7: iOS Configuration (Optional)](#part-7-ios-configuration-optional)
9. [Part 8: Testing Setup](#part-8-testing-setup)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Sebelum memulai, pastikan Anda sudah memiliki:

### Software Requirements
- ✅ **Flutter SDK** versi 3.9.2 atau lebih baru
- ✅ **Dart SDK** versi 3.0 atau lebih baru
- ✅ **Android Studio** atau **VS Code** dengan Flutter extension
- ✅ **Git** untuk version control
- ✅ **Node.js** (untuk Firebase CLI - opsional tapi direkomendasikan)

### Accounts Requirements
- ✅ **Google Account** (untuk Firebase, GCP, dan Gemini)
- ✅ **Credit/Debit Card** (untuk verifikasi GCP - tidak akan dicharge di free tier)

### Verify Installation

```bash
# Check Flutter
flutter --version
# Output: Flutter 3.9.2 or newer

# Check Dart
dart --version
# Output: Dart 3.x.x

# Check Git
git --version
# Output: git version 2.x.x

# Check devices
flutter doctor -v
# Pastikan tidak ada error critical
```

---

## Part 1: Firebase Setup

Firebase adalah backend utama aplikasi ReLink untuk Authentication, Database (Firestore), dan Storage.

### Step 1.1: Create Firebase Project

1. **Buka Firebase Console**
   - URL: https://console.firebase.google.com/
   - Login dengan Google Account Anda

2. **Create New Project**
   - Klik tombol **"Create a project"** atau **"Add project"**
   - Project name: `relink-app` (atau nama sesuai keinginan)
   - Project ID akan otomatis generate, contoh: `relink-app-a1b2c`
   - Klik **"Continue"**

3. **Google Analytics (Optional)**
   - Enable Google Analytics: **Recommended** (pilih Yes)
   - Jika enable, pilih atau create Analytics account
   - Klik **"Create project"**
   - Tunggu proses pembuatan project (30-60 detik)

4. **Project Created**
   - Klik **"Continue"** setelah project ready
   - Anda akan diarahkan ke Firebase Console Dashboard

### Step 1.2: Add Android App to Firebase

1. **Add Android App**
   - Di Firebase Console, klik icon **Android** (robot hijau)
   - Atau klik gear icon (⚙️) → Project settings → Scroll down → Click "Add app" → Select Android

2. **Register App**
   - **Android package name:** `com.relink.app`
     > ⚠️ **IMPORTANT:** Package name harus sama dengan `applicationId` di `android/app/build.gradle`
     > Buka file tersebut dan cari `applicationId`, gunakan value yang sama

   - **App nickname (optional):** `ReLink Android`
   - **Debug signing certificate SHA-1 (optional):** Kosongkan dulu, kita akan tambahkan nanti
   - Klik **"Register app"**

3. **Download Configuration File**
   - Download file **`google-services.json`**
   - File ini berisi konfigurasi Firebase untuk Android app Anda
   - **Simpan file ini** di lokasi yang aman

4. **Add google-services.json to Project**
   ```bash
   # Copy file ke folder android/app/
   # Path lengkap: D:\Subek\project\Draft\flutter\FinalCapstone\relink\android\app\google-services.json
   ```
   - Pastikan file `google-services.json` berada di `android/app/` (BUKAN di `android/`)

5. **Skip the Next Steps**
   - Firebase akan menunjukkan step untuk add Firebase SDK
   - Skip step ini karena sudah ada di project
   - Klik **"Next"** → **"Continue to console"**

### Step 1.3: Add iOS App to Firebase (Optional)

> ⚠️ **Skip step ini jika Anda tidak develop untuk iOS**

1. **Add iOS App**
   - Di Firebase Console, klik icon **iOS** (🍎)
   - iOS bundle ID: `com.relink.app` (sama dengan Android)
   - App nickname: `ReLink iOS`
   - App Store ID: Kosongkan

2. **Download GoogleService-Info.plist**
   - Download file konfigurasi iOS
   - Copy ke folder `ios/Runner/`

3. **Skip remaining steps** dan klik "Continue to console"

### Step 1.4: Enable Firebase Authentication

1. **Go to Authentication**
   - Di sidebar, klik **"Authentication"**
   - Klik **"Get started"** (jika pertama kali)

2. **Enable Sign-in Methods**

   **a. Email/Password:**
   - Tab **"Sign-in method"**
   - Klik **"Email/Password"**
   - Toggle **"Enable"**
   - **Email link (passwordless sign-in):** Tidak perlu diaktifkan
   - Klik **"Save"**

   **b. Google Sign-In:**
   - Masih di tab "Sign-in method"
   - Klik **"Google"**
   - Toggle **"Enable"**
   - **Project support email:** Pilih email Anda
   - Klik **"Save"**

   **c. Anonymous Sign-In:**
   - Klik **"Anonymous"**
   - Toggle **"Enable"**
   - Klik **"Save"**

3. **Verify Sign-in Methods**
   - Pastikan ada 3 methods yang enabled:
     - ✅ Email/Password
     - ✅ Google
     - ✅ Anonymous

### Step 1.5: Create Firestore Database

Firestore adalah NoSQL database untuk menyimpan data aplikasi.

1. **Go to Firestore Database**
   - Di sidebar, klik **"Firestore Database"**
   - Klik **"Create database"**

2. **Select Location**
   - **Production mode** atau **Test mode:** Pilih **"Test mode"** untuk development
   - Klik **"Next"**

3. **Choose Location**
   - **Firestore location:** Pilih **`asia-southeast2 (Jakarta)`** atau terdekat
   - ⚠️ **IMPORTANT:** Location tidak bisa diubah setelah dibuat
   - Klik **"Enable"**
   - Tunggu proses pembuatan (30-60 detik)

4. **Firestore Rules (Test Mode)**
   - Default rules untuk test mode:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.time < timestamp.date(2025, 12, 31);
       }
     }
   }
   ```
   - ⚠️ **WARNING:** Rules ini allow semua orang read/write sampai Dec 31, 2025
   - Untuk production, Anda harus update rules (lihat bagian Production Rules)

5. **Start Collection (Optional)**
   - Klik **"Start collection"**
   - Collection ID: `users`
   - Klik **"Next"**
   - Add first document:
     - Document ID: Auto-ID
     - Field: `test` | Type: `string` | Value: `hello`
   - Klik **"Save"**
   - Document ini hanya untuk testing, bisa dihapus nanti

### Step 1.6: Setup Firebase Storage

Firebase Storage untuk menyimpan images (profile photos, travel photos, chat images).

1. **Go to Storage**
   - Di sidebar, klik **"Storage"**
   - Klik **"Get started"**

2. **Security Rules**
   - Pilih **"Start in test mode"** untuk development
   - Rules default:
   ```javascript
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /{allPaths=**} {
         allow read, write: if request.time < timestamp.date(2025, 12, 31);
       }
     }
   }
   ```
   - Klik **"Next"**

3. **Select Location**
   - Pilih **`asia-southeast2 (Jakarta)`** (sama dengan Firestore)
   - Klik **"Done"**
   - Tunggu proses setup (30 detik)

4. **Verify Storage**
   - Anda akan lihat empty storage bucket
   - Bucket name format: `relink-app-a1b2c.appspot.com`

### Step 1.7: Enable Firebase Cloud Messaging (FCM)

FCM untuk push notifications (sudah enabled by default).

1. **Go to Cloud Messaging**
   - Di sidebar, klik **"Cloud Messaging"**
   - FCM sudah enabled secara default

2. **Get Server Key (Optional - untuk advanced features)**
   - Klik gear icon (⚙️) → **"Project settings"**
   - Tab **"Cloud Messaging"**
   - **Cloud Messaging API (Legacy):** Note the server key jika diperlukan
   - Untuk aplikasi ini, kita akan menggunakan FCM v1 API (tidak perlu server key manual)

### Step 1.8: Get Firebase Configuration Values

Kita perlu beberapa values dari Firebase untuk environment configuration.

1. **Go to Project Settings**
   - Klik gear icon (⚙️) → **"Project settings"**

2. **Your Apps Section**
   - Scroll down ke section **"Your apps"**
   - Pilih Android app yang sudah dibuat

3. **SDK Setup and Configuration**
   - Copy values berikut:
   ```
   apiKey: "AIzaSy..."
   authDomain: "relink-app-a1b2c.firebaseapp.com"
   projectId: "relink-app-a1b2c"
   storageBucket: "relink-app-a1b2c.appspot.com"
   messagingSenderId: "123456789012"
   appId: "1:123456789012:android:abcdef123456"
   ```
   - **Save these values**, kita akan gunakan nanti

### Step 1.9: Firebase CLI Setup (Optional but Recommended)

Firebase CLI berguna untuk deploy rules, functions, dan management.

1. **Install Firebase CLI**
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**
   ```bash
   firebase login
   ```
   - Browser akan terbuka
   - Login dengan Google Account yang sama
   - Allow Firebase CLI access

3. **Initialize Firebase in Project**
   ```bash
   cd D:\Subek\project\Draft\flutter\FinalCapstone\relink
   firebase init
   ```
   - Select features:
     - ✅ Firestore: Deploy rules and create indexes
     - ✅ Storage: Deploy storage rules
   - Select existing project: `relink-app-a1b2c`
   - Firestore rules file: `firestore.rules` (default)
   - Firestore indexes file: `firestore.indexes.json` (default)
   - Storage rules file: `storage.rules` (default)
   - Press Enter untuk finish

### Step 1.10: Production-Ready Firestore Rules

⚠️ **IMPORTANT:** Sebelum production, update Firestore rules!

1. **Edit firestore.rules**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {

       // Users collection
       match /users/{userId} {
         allow read: if true; // Public profiles
         allow create: if request.auth.uid == userId;
         allow update, delete: if request.auth.uid == userId;
       }

       // Conversations - only participants
       match /conversations/{conversationId} {
         allow read: if request.auth.uid in resource.data.participantIds;
         allow create: if request.auth.uid in request.resource.data.participantIds;
         allow update: if request.auth.uid in resource.data.participantIds;
         allow delete: if request.auth.uid in resource.data.participantIds;
       }

       // Messages - only participants of conversation
       match /messages/{messageId} {
         allow read: if request.auth.uid != null;
         allow create: if request.auth.uid == request.resource.data.senderId;
         allow update: if request.auth.uid == resource.data.senderId;
         allow delete: if request.auth.uid == resource.data.senderId;
       }

       // Trips
       match /trips/{tripId} {
         allow read: if resource.data.isPublic == true ||
                        request.auth.uid == resource.data.createdBy ||
                        request.auth.uid in resource.data.participantIds;
         allow create: if request.auth.uid == request.resource.data.createdBy;
         allow update, delete: if request.auth.uid == resource.data.createdBy;
       }

       // Photos
       match /photos/{photoId} {
         allow read: if resource.data.isPublic == true ||
                        request.auth.uid == resource.data.userId;
         allow create: if request.auth.uid == request.resource.data.userId;
         allow update, delete: if request.auth.uid == resource.data.userId;
       }

       // Reviews
       match /reviews/{reviewId} {
         allow read: if true;
         allow create: if request.auth.uid == request.resource.data.userId;
         allow update, delete: if request.auth.uid == resource.data.userId;
       }

       // Destinations - public read, authenticated write
       match /destinations/{destinationId} {
         allow read: if true;
         allow create: if request.auth.uid != null;
         allow update, delete: if request.auth.uid == resource.data.createdBy;
       }

       // Social connections
       match /social_connections/{userId} {
         allow read: if true;
         allow write: if request.auth.uid == userId;
       }

       // Activities feed
       match /activities/{activityId} {
         allow read: if true;
         allow create: if request.auth.uid == request.resource.data.userId;
         allow update, delete: if request.auth.uid == resource.data.userId;
       }

       // User bookmarks
       match /user_bookmarks/{userId} {
         allow read, write: if request.auth.uid == userId;
       }

       // Blocked users
       match /blocked_users/{userId} {
         allow read, write: if request.auth.uid == userId;
       }

       // User reports
       match /user_reports/{reportId} {
         allow read: if false; // Admin only via console
         allow create: if request.auth.uid == request.resource.data.reporterId;
       }
     }
   }
   ```

2. **Deploy Rules**
   ```bash
   firebase deploy --only firestore:rules
   ```

### Step 1.11: Production-Ready Storage Rules

1. **Edit storage.rules**
   ```javascript
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {

       // Profile photos
       match /profile_photos/{userId}/{fileName} {
         allow read: if true; // Public
         allow write: if request.auth.uid == userId &&
                        request.resource.size < 5 * 1024 * 1024 && // Max 5MB
                        request.resource.contentType.matches('image/.*');
       }

       // Travel photos
       match /travel_photos/{userId}/{fileName} {
         allow read: if true;
         allow write: if request.auth.uid == userId &&
                        request.resource.size < 10 * 1024 * 1024 && // Max 10MB
                        request.resource.contentType.matches('image/.*');
       }

       // Chat images
       match /chat_images/{conversationId}/{fileName} {
         allow read: if request.auth != null;
         allow write: if request.auth != null &&
                        request.resource.size < 5 * 1024 * 1024 &&
                        request.resource.contentType.matches('image/.*');
       }

       // Destination images (for guides/admins)
       match /destination_images/{destinationId}/{fileName} {
         allow read: if true;
         allow write: if request.auth != null &&
                        request.resource.size < 10 * 1024 * 1024 &&
                        request.resource.contentType.matches('image/.*');
       }
     }
   }
   ```

2. **Deploy Storage Rules**
   ```bash
   firebase deploy --only storage
   ```

---

## Part 2: Google Cloud Platform (GCP) Setup

GCP diperlukan untuk Google Maps API, Places API, Directions API, dan Geocoding API.

### Step 2.1: Access Google Cloud Console

1. **Open Google Cloud Console**
   - URL: https://console.cloud.google.com/
   - Login dengan Google Account yang **sama** dengan Firebase

2. **Select Firebase Project**
   - Di top navigation bar, klik project dropdown
   - Pilih project Firebase Anda: `relink-app-a1b2c`
   - Project ini otomatis terintegrasi dengan Firebase

### Step 2.2: Enable Billing

⚠️ **REQUIRED:** Google Maps API memerlukan billing enabled, tapi Anda mendapat $200 free credit per bulan.

1. **Go to Billing**
   - Di sidebar menu (☰), klik **"Billing"**
   - Atau URL: https://console.cloud.google.com/billing

2. **Link Billing Account**
   - Klik **"Link a billing account"**
   - Jika belum punya billing account, klik **"Create billing account"**

3. **Create Billing Account**
   - **Account type:** Individual atau Business
   - **Country:** Indonesia
   - **Payment method:** Add Credit/Debit Card
   - Fill card details:
     - Card number
     - Expiry date
     - CVV
     - Billing address
   - ⚠️ **Note:** Card akan di-verify dengan charge kecil (~$1) yang akan di-refund

4. **Accept Terms**
   - Read and accept Google Cloud Terms of Service
   - Klik **"Start my free trial"** atau **"Enable billing"**

5. **Verify Billing**
   - Billing account akan active dalam beberapa menit
   - Anda mendapat **$300 free trial credit** (untuk 90 hari)
   - Setelah trial, Anda mendapat **$200 per bulan** untuk Google Maps Platform

6. **Set Budget Alert (Recommended)**
   - Go to **"Billing"** → **"Budgets & alerts"**
   - Click **"Create budget"**
   - Budget name: `Monthly Budget`
   - Budget amount: $50 (atau sesuai kebutuhan)
   - Set alert thresholds: 50%, 90%, 100%
   - Add email notification
   - Click **"Finish"**

### Step 2.3: Enable Required APIs

Kita perlu enable beberapa APIs untuk Maps, Places, dan Location services.

1. **Go to APIs & Services**
   - Di sidebar, klik **"APIs & Services"** → **"Library"**
   - Atau URL: https://console.cloud.google.com/apis/library

2. **Enable Maps SDK for Android**
   - Search: `Maps SDK for Android`
   - Klik **"Maps SDK for Android"**
   - Klik **"Enable"**
   - Tunggu proses enable (30 detik)

3. **Enable Maps SDK for iOS** (jika develop untuk iOS)
   - Search: `Maps SDK for iOS`
   - Klik dan **"Enable"**

4. **Enable Places API**
   - Search: `Places API`
   - Klik **"Places API"**
   - Klik **"Enable"**

5. **Enable Places API (New)**
   - Search: `Places API (New)`
   - Klik dan **"Enable"**
   - API ini lebih efisien dan recommended

6. **Enable Geocoding API**
   - Search: `Geocoding API`
   - Klik dan **"Enable"**
   - Untuk convert address ke coordinates

7. **Enable Geolocation API**
   - Search: `Geolocation API`
   - Klik dan **"Enable"**
   - Untuk device location based on WiFi/cell towers

8. **Enable Directions API**
   - Search: `Directions API`
   - Klik dan **"Enable"**
   - Untuk route planning dan navigation

9. **Enable Distance Matrix API**
   - Search: `Distance Matrix API`
   - Klik dan **"Enable"**
   - Untuk calculate distance between multiple points

10. **Enable Roads API** (Optional)
    - Search: `Roads API`
    - Untuk snap to roads feature

### Step 2.4: Create API Key

Sekarang kita create API key untuk access Google Maps services.

1. **Go to Credentials**
   - Sidebar: **"APIs & Services"** → **"Credentials"**
   - Atau URL: https://console.cloud.google.com/apis/credentials

2. **Create Credentials**
   - Klik **"+ CREATE CREDENTIALS"**
   - Pilih **"API key"**
   - API key akan otomatis di-generate

3. **Copy API Key**
   - Copy API key yang muncul
   - Format: `AIzaSyB_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
   - **SAVE THIS KEY** - Anda akan perlu untuk environment configuration

4. **Rename API Key (Optional)**
   - Klik **"Edit API key"** (icon pensil)
   - Name: `ReLink Maps & Places API Key`

### Step 2.5: Restrict API Key (HIGHLY RECOMMENDED)

Unrestricted API key sangat berbahaya! Anyone could use your key and drain your quota.

#### Method 1: Restrict by Android App (Recommended for Production)

1. **Go to API Key Settings**
   - Di Credentials page, klik API key yang baru dibuat
   - Atau klik icon pensil (✏️)

2. **Application Restrictions**
   - Section **"Application restrictions"**
   - Select **"Android apps"**
   - Klik **"+ ADD AN ITEM"**

3. **Get SHA-1 Certificate Fingerprint**

   **For Debug Build (Development):**
   ```bash
   cd android
   ./gradlew signingReport
   ```
   - Output akan menampilkan SHA-1 untuk debug keystore
   - Copy SHA-1, format: `AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD`

   **For Release Build (Production):**
   ```bash
   keytool -list -v -keystore /path/to/your/release-keystore.jks -alias your-alias
   ```
   - Masukkan keystore password
   - Copy SHA-1 certificate fingerprint

4. **Add Package Name and SHA-1**
   - **Package name:** `com.relink.app` (sesuaikan dengan applicationId)
   - **SHA-1 certificate fingerprint:** Paste SHA-1 yang sudah dicopy
   - Klik **"Done"**
   - Untuk support debug + release, tambahkan 2 items:
     - Item 1: Package name + Debug SHA-1
     - Item 2: Package name + Release SHA-1

#### Method 2: Restrict by API (Alternative)

Jika Anda kesulitan dengan SHA-1, gunakan API restrictions dulu:

1. **API Restrictions**
   - Section **"API restrictions"**
   - Select **"Restrict key"**
   - Select APIs:
     - ✅ Maps SDK for Android
     - ✅ Maps SDK for iOS
     - ✅ Places API
     - ✅ Places API (New)
     - ✅ Geocoding API
     - ✅ Geolocation API
     - ✅ Directions API
     - ✅ Distance Matrix API

2. **Save**
   - Klik **"Save"** di bottom
   - API key sekarang restricted

⚠️ **IMPORTANT:**
- Untuk development, bisa gunakan unrestricted key dulu
- Untuk production, **WAJIB** restrict by Android app + SHA-1
- Jangan commit API key ke git!

### Step 2.6: Add SHA-1 to Firebase (for Google Sign-In)

Google Sign-In memerlukan SHA-1 fingerprint di Firebase.

1. **Go to Firebase Console**
   - URL: https://console.firebase.google.com/
   - Select project: `relink-app-a1b2c`

2. **Go to Project Settings**
   - Klik gear icon (⚙️) → **"Project settings"**

3. **Your Apps Section**
   - Scroll down ke **"Your apps"**
   - Pilih Android app

4. **Add SHA-1 Fingerprint**
   - Klik **"Add fingerprint"**
   - Paste **Debug SHA-1** (untuk development)
   - Klik **"Save"**
   - Klik **"Add fingerprint"** lagi
   - Paste **Release SHA-1** (untuk production)
   - Klik **"Save"**

5. **Download Updated google-services.json**
   - Setelah add SHA-1, download ulang `google-services.json`
   - Replace file lama di `android/app/google-services.json`

### Step 2.7: Monitor API Usage

Setup monitoring untuk track API usage dan avoid unexpected charges.

1. **Go to APIs & Services Dashboard**
   - Sidebar: **"APIs & Services"** → **"Dashboard"**
   - Atau URL: https://console.cloud.google.com/apis/dashboard

2. **View Metrics**
   - Anda akan lihat charts untuk:
     - Traffic (requests per day)
     - Errors
     - Latency
   - Monitor regularly untuk ensure tidak ada unusual usage

3. **Set Quota Limits (Optional)**
   - Go to **"APIs & Services"** → **"Quotas"**
   - Set daily quotas untuk each API
   - Contoh: Limit 1000 requests/day untuk development

---

## Part 3: Google Gemini AI Setup

Google Gemini adalah AI model untuk chat assistant, itinerary generation, dan recommendations.

### Step 3.1: Access Google AI Studio

1. **Go to Google AI Studio**
   - URL: https://makersuite.google.com/app/apikey
   - Atau: https://aistudio.google.com/app/apikey
   - Login dengan Google Account yang sama

2. **Accept Terms of Service**
   - Jika pertama kali, accept terms and conditions
   - Read privacy policy

### Step 3.2: Create API Key

1. **Create API Key**
   - Klik **"Get API Key"** atau **"Create API Key"**
   - Dialog akan muncul

2. **Select Project**
   - **Create API key in new project:** JANGAN pilih ini
   - **Create API key in existing project:** Pilih ini
   - Select project: `relink-app-a1b2c` (project Firebase Anda)
   - Klik **"Create API key in existing project"**

3. **Copy API Key**
   - API key akan di-generate
   - Format: `AIzaSyC_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
   - Klik **"Copy"** atau copy manual
   - **SAVE THIS KEY**

4. **Note the Restrictions**
   - By default, Gemini API key tidak restricted
   - Untuk production, Anda bisa restrict by IP atau referrer

### Step 3.3: Enable Generative Language API

API ini diperlukan untuk Gemini Pro model.

1. **Go to Google Cloud Console**
   - URL: https://console.cloud.google.com/
   - Select project: `relink-app-a1b2c`

2. **Enable API**
   - Go to **"APIs & Services"** → **"Library"**
   - Search: `Generative Language API`
   - Klik **"Generative Language API"**
   - Klik **"Enable"**

3. **Verify API**
   - Go to **"APIs & Services"** → **"Enabled APIs & services"**
   - Pastikan **"Generative Language API"** ada di list

### Step 3.4: Test Gemini API (Optional)

Test API key untuk ensure it's working.

1. **Using curl (Command Line)**
   ```bash
   curl \
     -H 'Content-Type: application/json' \
     -d '{"contents":[{"parts":[{"text":"Hello, Gemini!"}]}]}' \
     -X POST 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=YOUR_API_KEY'
   ```
   - Replace `YOUR_API_KEY` dengan API key Anda
   - Jika success, akan return JSON dengan response dari Gemini

2. **Using Google AI Studio Playground**
   - Go to: https://aistudio.google.com/
   - Click **"Create new"** → **"Chat prompt"**
   - Type: "Hello, Gemini!"
   - Click **"Run"**
   - Jika working, Gemini akan respond

### Step 3.5: Understand Gemini Pricing

**Free Tier (untuk development dan testing):**
- 60 requests per minute
- 1,500 requests per day
- Free forever

**Paid Tier (jika exceed free tier):**
- Pay-as-you-go
- ~$0.00025 per 1000 characters (Gemini Pro)
- Very affordable untuk small-medium apps

**Tips:**
- Use caching untuk reduce API calls
- Implement rate limiting di app
- Monitor usage di Google Cloud Console

### Step 3.6: Restrict Gemini API Key (Optional)

1. **Go to GCP Credentials**
   - Console: https://console.cloud.google.com/apis/credentials
   - Find Gemini API key

2. **Restrict by Application**
   - Klik API key → Edit
   - **Application restrictions:** Android apps (sama dengan Maps API)
   - Add package name + SHA-1

3. **Restrict by API**
   - **API restrictions:** Restrict key
   - Select: ✅ Generative Language API
   - Click **"Save"**

---

## Part 4: Indonesia Tourism API Setup

Untuk mendapatkan data destinasi wisata Indonesia yang real dan up-to-date.

### Option 1: Indonesia Tourism API (Kemenparekraf)

**API Resmi dari Kementerian Pariwisata dan Ekonomi Kreatif**

⚠️ **Note:** API ini kadang tidak stabil atau memerlukan approval khusus.

1. **Visit Website**
   - URL: http://api.pariwisata.com/ (jika tersedia)
   - Atau: https://data.go.id (Portal Data Terbuka Indonesia)

2. **Register Account**
   - Create account di portal
   - Verify email

3. **Request API Access**
   - Apply for API key
   - Tunggu approval (bisa beberapa hari)

4. **Get API Key**
   - Setelah approved, get API key
   - Documentation: Check API docs untuk endpoints

### Option 2: Indonesia Travel API (Third-Party)

**API populer untuk data wisata Indonesia:**

#### A. RapidAPI - Indonesia Tourism

1. **Go to RapidAPI**
   - URL: https://rapidapi.com/
   - Search: "Indonesia Tourism" or "Indonesia Travel"

2. **Subscribe to API**
   - Pilih API yang sesuai, contoh:
     - **Indonesia Travel Destinations API**
     - **Wonderful Indonesia API**
   - Click **"Subscribe to Test"**
   - Pilih plan:
     - **Free Plan:** 100-500 requests/month (good untuk testing)
     - **Basic Plan:** ~$5-10/month (untuk production)

3. **Get API Key**
   - Setelah subscribe, Anda akan dapat:
     - **RapidAPI Key:** `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
     - **API Host:** `indonesia-tourism.p.rapidapi.com`
   - Save kedua values ini

4. **Test API**
   ```bash
   curl --request GET \
     --url 'https://indonesia-tourism.p.rapidapi.com/api/v1/destinations' \
     --header 'X-RapidAPI-Host: indonesia-tourism.p.rapidapi.com' \
     --header 'X-RapidAPI-Key: YOUR_RAPIDAPI_KEY'
   ```

#### B. The Kulturasi API

1. **Website**
   - URL: https://kulturasi.com/api (example)
   - Free API untuk wisata & budaya Indonesia

2. **No Registration Required (untuk public endpoints)**
   - Some endpoints free tanpa API key
   - Rate limit: 100 requests/hour

3. **Endpoints**
   ```
   GET https://kulturasi.com/api/destinations
   GET https://kulturasi.com/api/destinations/{id}
   GET https://kulturasi.com/api/destinations?province=Bali
   ```

### Option 3: Web Scraping (Advanced)

Jika tidak ada API yang suitable, scrape data dari websites.

**Sources:**
- Indonesia.travel (official tourism website)
- TripAdvisor Indonesia
- Google Places API (dengan filter Indonesia)

⚠️ **Legal Notice:** Check terms of service sebelum scraping. Some websites melarang scraping.

**Example: Using Google Places API untuk Indonesia Tourism**

Google Places API bisa digunakan untuk get real data about tourist places di Indonesia.

1. **Already Have Access** (dari Part 2)
   - Anda sudah enable Places API di GCP
   - API key sudah dibuat

2. **Search Tourism Places**
   ```bash
   curl "https://maps.googleapis.com/maps/api/place/textsearch/json?query=tourist+attractions+in+Bali+Indonesia&key=YOUR_GOOGLE_MAPS_KEY"
   ```

3. **Get Place Details**
   ```bash
   curl "https://maps.googleapis.com/maps/api/place/details/json?place_id=PLACE_ID&fields=name,rating,formatted_address,photos,reviews&key=YOUR_GOOGLE_MAPS_KEY"
   ```

4. **Integration in App**
   - App sudah menggunakan Google Places untuk search destinations
   - Anda bisa fokus ke places di Indonesia dengan add filters

### Option 4: Custom Firebase Database

**Recommended untuk ReLink:** Populate Firestore dengan data wisata Indonesia sendiri.

1. **Collect Data**
   - Research destinasi wisata populer di Indonesia
   - Categories: Beaches, Mountains, Cultural Sites, National Parks, etc.

2. **Create Firestore Collection**
   - Collection name: `destinations`
   - Document structure:
   ```javascript
   {
     id: "dest_001",
     name: "Tanah Lot",
     description: "Iconic Hindu temple on rock formation...",
     category: "cultural",
     province: "Bali",
     city: "Tabanan",
     latitude: -8.6211,
     longitude: 115.0866,
     rating: 4.5,
     priceRange: 2, // 1-5 scale
     images: ["url1", "url2"],
     facilities: ["parking", "restaurant", "toilet"],
     activities: ["photography", "sunset viewing"],
     openingHours: "06:00-19:00",
     bestTimeToVisit: "April-October",
     entryFee: {
       domestic: 20000,
       foreign: 60000
     },
     createdAt: timestamp,
     updatedAt: timestamp
   }
   ```

3. **Populate Data**
   - Manually add destinations via Firebase Console
   - Or create script untuk batch import
   - Start dengan ~50-100 popular destinations

4. **Data Sources for Indonesia Tourism**
   - **Indonesia.travel** - Official tourism portal
   - **Wikipedia** - Info about destinations
   - **Google Maps** - Reviews, photos, coordinates
   - **TripAdvisor** - Ratings and reviews
   - **Kompas Travel** - Indonesian travel articles

### Recommended Destinations to Add (Examples)

**Bali:**
- Tanah Lot, Uluwatu Temple, Tegallalang Rice Terrace, Mount Batur, Ubud Monkey Forest

**Java:**
- Borobudur, Prambanan, Mount Bromo, Kawah Ijen, Taman Mini Indonesia Indah

**Lombok:**
- Mount Rinjani, Pink Beach, Gili Islands

**Sulawesi:**
- Bunaken National Park, Tana Toraja, Wakatobi

**Sumatra:**
- Lake Toba, Bukit Lawang (Orangutan), Ngarai Sianok

**Kalimantan:**
- Tanjung Puting (Orangutan), Derawan Islands

**Papua:**
- Raja Ampat, Baliem Valley

### Create Initialization Script (Optional)

Create Dart script untuk initialize destinations data:

```dart
// lib/scripts/init_destinations.dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> initializeDestinations() async {
  final destinations = [
    {
      'id': 'dest_bali_tanah_lot',
      'name': 'Tanah Lot',
      'description': 'Iconic Hindu temple on a rock formation...',
      'category': 'cultural',
      'province': 'Bali',
      'city': 'Tabanan',
      'latitude': -8.6211,
      'longitude': 115.0866,
      'rating': 4.5,
      'priceRange': 2,
      // ... more fields
    },
    // Add more destinations
  ];

  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  for (var dest in destinations) {
    final docRef = firestore.collection('destinations').doc(dest['id']);
    batch.set(docRef, dest);
  }

  await batch.commit();
  print('Destinations initialized!');
}
```

---

## Part 5: Environment Configuration

Setup environment variables untuk menyimpan API keys dengan aman.

### Step 5.1: Create .env File

1. **Check if .env.example exists**
   ```bash
   ls -la | grep .env
   ```

2. **Copy .env.example to .env**
   ```bash
   cp .env.example .env
   ```

   Jika `.env.example` tidak ada, create `.env` baru:
   ```bash
   touch .env
   ```

### Step 5.2: Fill Environment Variables

Edit file `.env` dengan text editor:

```env
# ========================================
# Firebase Configuration
# ========================================
FIREBASE_API_KEY=AIzaSy...  # From Firebase Project Settings
FIREBASE_AUTH_DOMAIN=relink-app-a1b2c.firebaseapp.com
FIREBASE_PROJECT_ID=relink-app-a1b2c
FIREBASE_STORAGE_BUCKET=relink-app-a1b2c.appspot.com
FIREBASE_MESSAGING_SENDER_ID=123456789012
FIREBASE_APP_ID=1:123456789012:android:abcdef123456

# ========================================
# Google Cloud Platform - Maps & Places
# ========================================
GOOGLE_MAPS_API_KEY=AIzaSyB_...  # From GCP Credentials

# ========================================
# Google Gemini AI
# ========================================
GEMINI_API_KEY=AIzaSyC_...  # From Google AI Studio

# ========================================
# Indonesia Tourism API (Optional)
# ========================================
INDONESIA_TOURISM_API_KEY=your_tourism_api_key_here
INDONESIA_TOURISM_BASE_URL=https://api.pariwisata.com/v1

# Or if using RapidAPI:
RAPIDAPI_KEY=your_rapidapi_key_here
RAPIDAPI_HOST=indonesia-tourism.p.rapidapi.com

# ========================================
# App Configuration
# ========================================
APP_NAME=ReLink
APP_VERSION=4.1.0
ENVIRONMENT=development  # development, staging, production

# ========================================
# Optional: Other Services
# ========================================
# Weather API (OpenWeatherMap)
OPENWEATHER_API_KEY=your_openweather_key_here

# Sentry (Error tracking)
SENTRY_DSN=your_sentry_dsn_here

# Analytics
GOOGLE_ANALYTICS_ID=UA-XXXXXXXXX-X
```

### Step 5.3: Load Environment Variables in Flutter

App sudah menggunakan `flutter_dotenv` package untuk load environment variables.

1. **Verify pubspec.yaml**
   ```yaml
   dependencies:
     flutter_dotenv: ^5.1.0

   flutter:
     assets:
       - .env
   ```

2. **Load in main.dart**
   - Check `lib/main.dart`:
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';

   Future<void> main() async {
     WidgetsFlutterBinding.ensureInitialized();

     // Load environment variables
     await dotenv.load(fileName: ".env");

     // Rest of initialization...
   }
   ```

3. **Access Environment Variables**
   ```dart
   // Anywhere in the app:
   final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
   final geminiKey = dotenv.env['GEMINI_API_KEY'];
   ```

### Step 5.4: Secure .env File

⚠️ **CRITICAL SECURITY:**

1. **Add .env to .gitignore**
   ```bash
   # Check .gitignore
   cat .gitignore | grep .env
   ```

   Jika belum ada, tambahkan:
   ```bash
   echo ".env" >> .gitignore
   ```

2. **Verify .env NOT in Git**
   ```bash
   git status
   ```
   - `.env` should NOT appear in untracked files (jika sudah ada di .gitignore)

3. **Never Commit API Keys**
   - JANGAN commit `.env` ke git
   - JANGAN hardcode API keys di code
   - JANGAN share API keys di chat/email

4. **Create .env.example for Team**
   - Create template tanpa real values:
   ```bash
   cp .env .env.example
   ```

   - Edit `.env.example` dan replace values dengan placeholders:
   ```env
   GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
   GEMINI_API_KEY=your_gemini_api_key_here
   # etc...
   ```

   - Commit `.env.example` (ini aman):
   ```bash
   git add .env.example
   git commit -m "Add environment template"
   ```

---

## Part 6: Android Configuration

Configure Android app untuk integrate dengan Firebase dan Google services.

### Step 6.1: Verify google-services.json

```bash
# Check if file exists
ls -la android/app/google-services.json
```

- File harus ada di `android/app/google-services.json`
- Jika tidak ada, download lagi dari Firebase Console

### Step 6.2: Check build.gradle Configuration

1. **Project-level build.gradle** (`android/build.gradle.kts`)

   Open file dan verify:
   ```kotlin
   buildscript {
       dependencies {
           // Google Services plugin
           classpath("com.google.gms:google-services:4.4.0")
       }
   }
   ```

2. **App-level build.gradle** (`android/app/build.gradle.kts`)

   Verify:
   ```kotlin
   plugins {
       id("com.android.application")
       id("kotlin-android")
       id("com.google.gms.google-services")  // IMPORTANT!
   }

   android {
       defaultConfig {
           applicationId = "com.relink.app"  // Must match Firebase
           minSdk = 21
           targetSdk = 34
           // ...
       }
   }

   dependencies {
       // Firebase
       implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
       implementation("com.google.firebase:firebase-auth")
       implementation("com.google.firebase:firebase-firestore")
       implementation("com.google.firebase:firebase-storage")
       implementation("com.google.firebase:firebase-messaging")

       // Google Play Services
       implementation("com.google.android.gms:play-services-auth:20.7.0")
       implementation("com.google.android.gms:play-services-maps:18.2.0")
   }
   ```

### Step 6.3: Add Google Maps API Key to Android

1. **Open AndroidManifest.xml**
   - Path: `android/app/src/main/AndroidManifest.xml`

2. **Add API Key**
   ```xml
   <manifest>
       <application>
           <!-- Google Maps API Key -->
           <meta-data
               android:name="com.google.android.geo.API_KEY"
               android:value="YOUR_GOOGLE_MAPS_API_KEY"/>

           <!-- Other configurations... -->
       </application>
   </manifest>
   ```

   - Replace `YOUR_GOOGLE_MAPS_API_KEY` dengan actual API key
   - Or better, use build config untuk load dari .env (advanced)

### Step 6.4: Set Permissions

Verify permissions di `AndroidManifest.xml`:

```xml
<manifest>
    <!-- Internet -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <!-- Location -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

    <!-- Camera (for photo upload) -->
    <uses-permission android:name="android.permission.CAMERA" />

    <!-- Storage (for image picker) -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
                     android:maxSdkVersion="32" />

    <!-- Notifications -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application>
        <!-- ... -->
    </application>
</manifest>
```

### Step 6.5: Generate Release Keystore (for Production)

For production builds, Anda perlu release keystore.

1. **Generate Keystore**
   ```bash
   keytool -genkey -v -keystore ~/relink-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias relink
   ```

   Akan prompt untuk:
   - Keystore password (SAVE THIS!)
   - Key password (SAVE THIS!)
   - Name, Organization, City, State, Country

2. **Save Keystore Securely**
   - Move keystore ke safe location (JANGAN commit ke git!)
   - Backup keystore (jika hilang, tidak bisa update app!)

3. **Create key.properties**
   - Create file: `android/key.properties`
   ```properties
   storePassword=your_keystore_password
   keyPassword=your_key_password
   keyAlias=relink
   storeFile=/path/to/relink-release-key.jks
   ```

   - Add to `.gitignore`:
   ```bash
   echo "android/key.properties" >> .gitignore
   ```

4. **Update app/build.gradle.kts**
   ```kotlin
   // Load keystore
   val keystoreProperties = Properties()
   val keystorePropertiesFile = rootProject.file("key.properties")
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(FileInputStream(keystorePropertiesFile))
   }

   android {
       signingConfigs {
           create("release") {
               keyAlias = keystoreProperties["keyAlias"] as String
               keyPassword = keystoreProperties["keyPassword"] as String
               storeFile = file(keystoreProperties["storeFile"] as String)
               storePassword = keystoreProperties["storePassword"] as String
           }
       }

       buildTypes {
           release {
               signingConfig = signingConfigs.getByName("release")
               // ...
           }
       }
   }
   ```

5. **Get Release SHA-1**
   ```bash
   keytool -list -v -keystore ~/relink-release-key.jks -alias relink
   ```
   - Copy SHA-1 fingerprint
   - Add ke Firebase Project Settings (seperti debug SHA-1)
   - Add ke GCP API Key restrictions

### Step 6.6: Build & Test Android

1. **Clean Build**
   ```bash
   flutter clean
   flutter pub get
   cd android
   ./gradlew clean
   cd ..
   ```

2. **Build Debug APK**
   ```bash
   flutter build apk --debug
   ```
   - APK location: `build/app/outputs/flutter-apk/app-debug.apk`

3. **Install on Device**
   ```bash
   flutter install
   ```

4. **Or Run Directly**
   ```bash
   flutter run
   ```

5. **Build Release APK** (when ready)
   ```bash
   flutter build apk --release
   ```

---

## Part 7: iOS Configuration (Optional)

Skip jika tidak develop untuk iOS.

### Step 7.1: Verify GoogleService-Info.plist

```bash
ls -la ios/Runner/GoogleService-Info.plist
```

- File harus ada di `ios/Runner/`
- Jika tidak, download dari Firebase Console

### Step 7.2: Open Xcode

```bash
cd ios
open Runner.xcworkspace
```

⚠️ **Note:** Buka `Runner.xcworkspace`, BUKAN `Runner.xcodeproj`!

### Step 7.3: Configure Bundle ID

1. In Xcode:
   - Select **Runner** project
   - Select **Runner** target
   - Tab **"General"**
   - **Bundle Identifier:** `com.relink.app` (must match Firebase)

### Step 7.4: Add Google Maps API Key

1. **Open AppDelegate.swift**
   - Path: `ios/Runner/AppDelegate.swift`

2. **Add Import**
   ```swift
   import GoogleMaps
   ```

3. **Add API Key in didFinishLaunchingWithOptions**
   ```swift
   override func application(
     _ application: UIApplication,
     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
   ) -> Bool {
     GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
     GeneratedPluginRegistrant.register(with: self)
     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
   }
   ```

### Step 7.5: Update Info.plist

Add required permissions:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>ReLink needs your location to show nearby travelers and destinations</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>ReLink needs your location for real-time tracking</string>

<key>NSCameraUsageDescription</key>
<string>ReLink needs camera access to upload photos</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>ReLink needs photo library access to upload images</string>
```

### Step 7.6: Install Pods

```bash
cd ios
pod install
cd ..
```

### Step 7.7: Build iOS

```bash
flutter build ios --release
```

---

## Part 8: Testing Setup

### Step 8.1: Test Firebase Connection

1. **Run App**
   ```bash
   flutter run
   ```

2. **Test Authentication**
   - Try register with email/password
   - Check Firebase Console → Authentication → Users
   - New user should appear

3. **Test Firestore**
   - Complete registration (creates user document)
   - Check Firebase Console → Firestore → users collection
   - User document should exist

4. **Test Storage**
   - Upload profile photo
   - Check Firebase Console → Storage
   - File should be uploaded

### Step 8.2: Test Google Maps

1. **Open Explore Screen**
   - App should show Google Map
   - If blank map → Check API key and enabled APIs

2. **Test Location**
   - Enable location permission
   - Map should center on current location
   - Blue dot should appear

3. **Test Places Search**
   - Search for "Bali"
   - Results should appear

### Step 8.3: Test Gemini AI

1. **Open AI Chat**
   - Navigate to AI chat screen
   - Send message: "Hello"
   - Gemini should respond

2. **Test AI Features**
   - Try AI itinerary generator
   - Try AI budget optimizer
   - All should work

### Step 8.4: Test Complete Flow

1. **Registration → Login → Logout → Login**
2. **Create Trip → Add Destination → Add Participant**
3. **Upload Photo → Like → Comment**
4. **Send Message → Receive Message**
5. **Follow User → View Activity Feed**
6. **Write Review → Edit → Delete**

### Step 8.5: Test Offline Mode

1. **Enable Airplane Mode**
2. **Open App**
3. **Navigate Screens**
   - Cached data should load
   - Can add expenses, messages (queued)
4. **Disable Airplane Mode**
   - Background sync should start
   - Queued operations should complete

---

## Troubleshooting

### Problem: Google Maps Not Showing

**Solutions:**
1. Check API key in `AndroidManifest.xml` or `AppDelegate.swift`
2. Verify Maps SDK enabled in GCP
3. Check billing enabled in GCP
4. Clear app data and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Problem: Google Sign-In Not Working

**Solutions:**
1. Verify SHA-1 fingerprint added to Firebase
2. Download updated `google-services.json`
3. Check package name matches Firebase
4. Verify Google Sign-In enabled in Firebase Auth

### Problem: Firebase Error "Default FirebaseApp not initialized"

**Solutions:**
1. Check `google-services.json` in correct location
2. Verify `com.google.gms.google-services` plugin in build.gradle
3. Clean and rebuild:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter run
   ```

### Problem: Places API Returns No Results

**Solutions:**
1. Verify Places API enabled in GCP
2. Check API key has Places API in restrictions
3. Verify billing enabled
4. Check quota not exceeded in GCP Console

### Problem: Gemini API Error "API key not valid"

**Solutions:**
1. Check API key in `.env` file
2. Verify Generative Language API enabled in GCP
3. Check API key restrictions (if any)
4. Try regenerate API key in AI Studio

### Problem: Build Failed - Dependency Issues

**Solutions:**
```bash
# Clear Flutter cache
flutter clean
flutter pub cache repair
flutter pub get

# Clear Android cache
cd android
./gradlew clean
./gradlew --stop
cd ..

# Rebuild
flutter run
```

### Problem: API Quota Exceeded

**Solutions:**
1. Check usage in GCP Console → APIs & Services → Dashboard
2. Increase quota limits
3. Optimize API calls (caching, rate limiting)
4. Consider upgrading to paid tier

### Problem: Can't Upload Images to Firebase Storage

**Solutions:**
1. Verify Storage enabled in Firebase
2. Check Storage rules (test mode allows all)
3. Check file size (ensure < 10MB after compression)
4. Verify storage quota not exceeded

---

## Environment Variables Checklist

Make sure `.env` file contains all required keys:

```
✅ FIREBASE_API_KEY
✅ FIREBASE_PROJECT_ID
✅ FIREBASE_STORAGE_BUCKET
✅ FIREBASE_MESSAGING_SENDER_ID
✅ FIREBASE_APP_ID
✅ GOOGLE_MAPS_API_KEY
✅ GEMINI_API_KEY
⬜ INDONESIA_TOURISM_API_KEY (optional)
⬜ RAPIDAPI_KEY (optional)
```

---

## Production Checklist

Before deploying to production:

### Security
- [ ] Firestore rules set to production mode
- [ ] Storage rules set to production mode
- [ ] API keys restricted (Android app + SHA-1)
- [ ] `.env` file in `.gitignore`
- [ ] No API keys hardcoded in code

### Firebase
- [ ] Authentication methods tested
- [ ] Firestore indexes created (for complex queries)
- [ ] Storage buckets configured
- [ ] Firebase Analytics enabled (optional)
- [ ] Crashlytics enabled (optional)

### Google Cloud
- [ ] All required APIs enabled
- [ ] Billing account active with alerts
- [ ] API quotas monitored
- [ ] Release SHA-1 added to all services

### App Configuration
- [ ] Release keystore created and backed up
- [ ] App signed with release key
- [ ] ProGuard rules added (if using)
- [ ] App version incremented
- [ ] Change ENVIRONMENT to "production" in .env

### Testing
- [ ] All features tested on real devices
- [ ] Tested with slow network
- [ ] Tested offline mode
- [ ] Tested on different Android versions
- [ ] No console errors or warnings

---

## Quick Reference

### Important URLs

- **Firebase Console:** https://console.firebase.google.com/
- **Google Cloud Console:** https://console.cloud.google.com/
- **Google AI Studio:** https://aistudio.google.com/
- **RapidAPI:** https://rapidapi.com/

### Common Commands

```bash
# Clean & rebuild
flutter clean && flutter pub get && flutter run

# Get SHA-1 (debug)
cd android && ./gradlew signingReport

# Get SHA-1 (release)
keytool -list -v -keystore path/to/keystore.jks -alias alias_name

# Build release APK
flutter build apk --release

# Build app bundle
flutter build appbundle --release

# Check Flutter issues
flutter doctor -v

# Analyze code
flutter analyze
```

---

## Support & Resources

### Documentation
- **Flutter Docs:** https://docs.flutter.dev/
- **Firebase Docs:** https://firebase.google.com/docs
- **Google Maps Flutter:** https://pub.dev/packages/google_maps_flutter
- **Google Gemini AI:** https://ai.google.dev/docs

### Community
- **Flutter Discord:** https://discord.gg/flutter
- **Firebase Discord:** https://discord.gg/firebase
- **Stack Overflow:** Tag [flutter] [firebase]

---

**Setup Complete! 🎉**

Jika semua steps diikuti dengan benar, aplikasi ReLink Anda seharusnya sudah fully configured dan ready untuk development/production.

**Next Steps:**
1. Run app: `flutter run`
2. Test all features
3. Fix any issues menggunakan Troubleshooting section
4. Start developing!

**Questions?**
- Review documentation di links above
- Check troubleshooting section
- Ask in Flutter/Firebase communities

---

**Last Updated:** January 2025
**Version:** 1.0.0
**Maintained by:** ReLink Development Team
