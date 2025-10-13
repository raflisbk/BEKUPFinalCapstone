# 🆕 ReLink - Fresh Start Guide

Complete guide untuk mulai setup Firebase/GCP dari awal (from scratch).

---

## 🎯 Overview

Guide ini untuk:
- ✅ Reset semua konfigurasi Firebase/GCP
- ✅ Mulai setup dari 0
- ✅ Setup dengan benar step-by-step
- ✅ Gunakan free tier services
- ✅ Alternatif untuk Firebase Storage (gratis)

---

## 📦 Part 1: Clean Up Existing Configuration

### **Step 1.1: Backup Current Files (Already Done)**

```bash
# Backup sudah dibuat di: backup_configs/
# Includes:
# - google-services.json
# - .firebaserc
# - firebase.json
```

### **Step 1.2: Remove Firebase Configuration Files**

```bash
# Remove Android Firebase config
rm android/app/google-services.json
rm android/app/google-services.json.backup

# Remove Firebase CLI config
rm .firebaserc

# Remove Firebase project config (keep hosting config)
# We'll recreate firebase.json later
```

### **Step 1.3: Clean Environment Variables**

Edit `.env` file and remove Firebase-related variables:

```env
# Remove these lines:
# FIREBASE_WEB_API_KEY=...
# FIREBASE_WEB_PROJECT_ID=...
# FIREBASE_WEB_MESSAGING_SENDER_ID=...
# etc.
```

### **Step 1.4: Clean Flutter Build**

```bash
flutter clean
rm -rf build/
rm -rf android/.gradle/
rm -rf android/app/build/
```

---

## 🔥 Part 2: Create NEW Firebase Project (From Scratch)

### **Step 2.1: Create Firebase Project**

1. **Go to Firebase Console**
   ```
   https://console.firebase.google.com/
   ```

2. **Create Project**
   - Click: **"Add project"** atau **"Create a project"**

3. **Project Name**
   - Enter: `ReLink` (atau nama yang Anda inginkan)
   - Project ID akan auto-generate: `relink-xxxxx`
   - ⚠️ **CATAT Project ID ini!**
   - Click: **Continue**

4. **Google Analytics**
   - Enable Google Analytics: **Yes** (recommended)
   - Select Analytics account atau create new
   - Click: **Create project**

5. **Wait for Creation**
   - Process takes 30-60 seconds
   - Click: **Continue** when done

6. **Welcome Screen**
   - You'll see Firebase project dashboard
   - Note your Project ID (top of page)

### **Step 2.2: Add Android App**

1. **Click Android Icon**
   - In project overview
   - Or: Project Settings → Your apps → Add app → Android

2. **Register Android App**
   - **Android package name:** `com.example.relink`
     - ⚠️ **CRITICAL:** Must match `build.gradle.kts`
     - Check: `android/app/build.gradle.kts` → `applicationId`

   - **App nickname:** `ReLink Android`

   - **Debug SHA-1 certificate:**
     ```bash
     cd android
     ./gradlew signingReport
     # Copy SHA-1 fingerprint
     # Example: AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:00:AA:BB:CC:DD
     ```
     - Paste SHA-1 in Firebase Console

   - Click: **Register app**

3. **Download google-services.json**
   - Click: **Download google-services.json**
   - Save file

4. **Add to Project**
   ```bash
   # Copy to android/app/
   copy %USERPROFILE%\Downloads\google-services.json android\app\google-services.json

   # Verify
   cat android/app/google-services.json | grep "project_id"
   ```

5. **Skip Remaining Steps**
   - Click: **Next** → **Next** → **Continue to console**
   - SDK already configured in your project

---

## ☁️ Part 3: Setup Google Cloud Platform

### **Step 3.1: Access GCP Console**

Your Firebase project automatically creates a GCP project.

1. **Go to GCP Console**
   ```
   https://console.cloud.google.com/
   ```

2. **Select Project**
   - Top bar → Project dropdown
   - Select your new Firebase project
   - Should match Project ID from Firebase

### **Step 3.2: Enable Billing (Required for APIs)**

⚠️ **IMPORTANT:** Google Maps requires billing enabled, BUT you get **$200 free credit per month**.

1. **Go to Billing**
   ```
   https://console.cloud.google.com/billing
   ```

2. **Link Billing Account**
   - Click: **Link a billing account**
   - If you don't have one: **Create billing account**

3. **Add Payment Method**
   - **Country:** Indonesia
   - **Payment method:** Credit/Debit card
   - Add card details
   - Accept terms
   - Click: **Start my free trial** atau **Submit and enable billing**

4. **Verify Billing**
   - Billing should now be active
   - You get **$300 free trial credit** (90 days)
   - After trial: **$200/month free credit** for Maps

5. **Set Budget Alert (IMPORTANT!)**
   ```
   Billing → Budgets & alerts → Create budget

   Settings:
   - Name: Monthly Budget
   - Amount: $50 (or your preference)
   - Threshold rules:
     - 50% = $25
     - 90% = $45
     - 100% = $50
   - Email notifications: Your email
   - Click: Finish
   ```

### **Step 3.3: Enable Required APIs**

1. **Go to APIs Library**
   ```
   https://console.cloud.google.com/apis/library
   ```

2. **Enable APIs One by One:**

   **For Google Maps:**
   - Search: `Maps SDK for Android` → Enable
   - Search: `Places API` → Enable
   - Search: `Places API (New)` → Enable
   - Search: `Geocoding API` → Enable
   - Search: `Geolocation API` → Enable
   - Search: `Directions API` → Enable
   - Search: `Distance Matrix API` → Enable

   **For Gemini AI:**
   - Search: `Generative Language API` → Enable

3. **Wait for APIs to Enable**
   - Each takes 10-30 seconds

### **Step 3.4: Create API Keys**

#### **Google Maps API Key:**

1. **Go to Credentials**
   ```
   https://console.cloud.google.com/apis/credentials
   ```

2. **Create API Key**
   - Click: **+ CREATE CREDENTIALS**
   - Select: **API key**
   - API key will be generated
   - **COPY THIS KEY** → Save to notepad

3. **Restrict API Key (IMPORTANT for Security)**
   - Click: **Edit API key** (pencil icon)
   - Name: `Google Maps API Key`

   **Application restrictions:**
   - Select: **Android apps**
   - Click: **+ ADD AN ITEM**
   - Package name: `com.example.relink`
   - SHA-1: (paste your SHA-1 from earlier)
   - Click: **Done**

   **API restrictions:**
   - Select: **Restrict key**
   - Select APIs:
     - ✅ Maps SDK for Android
     - ✅ Places API
     - ✅ Places API (New)
     - ✅ Geocoding API
     - ✅ Geolocation API
     - ✅ Directions API
     - ✅ Distance Matrix API

   - Click: **Save**

4. **Add to AndroidManifest.xml**
   ```xml
   <!-- android/app/src/main/AndroidManifest.xml -->
   <application>
       <!-- Add this inside <application> tag -->
       <meta-data
           android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
   </application>
   ```

#### **Gemini AI API Key:**

1. **Go to Google AI Studio**
   ```
   https://aistudio.google.com/app/apikey
   ```

2. **Create API Key**
   - Click: **Create API key**
   - Select: **Create API key in existing project**
   - Choose your Firebase project
   - Click: **Create**
   - **COPY THIS KEY**

---

## 🔐 Part 4: Enable Firebase Services (FREE)

### **Step 4.1: Firebase Authentication (FREE)**

1. **Go to Authentication**
   ```
   Firebase Console → Authentication
   ```

2. **Get Started**
   - Click: **Get started**

3. **Enable Sign-in Methods**

   **Email/Password:**
   - Click: **Email/Password**
   - Toggle: **Enable**
   - Click: **Save**

   **Google Sign-In:**
   - Click: **Google**
   - Toggle: **Enable**
   - Project support email: Your email
   - Click: **Save**

   **Anonymous:**
   - Click: **Anonymous**
   - Toggle: **Enable**
   - Click: **Save**

**✅ Authentication is 100% FREE** (unlimited users)

### **Step 4.2: Cloud Firestore (FREE Tier)**

1. **Go to Firestore Database**
   ```
   Firebase Console → Firestore Database
   ```

2. **Create Database**
   - Click: **Create database**

3. **Select Mode**
   - For testing: **Start in test mode**
   - For production: **Start in production mode**
   - Click: **Next**

4. **Select Location**
   - **Firestore location:** `asia-southeast2 (Jakarta)`
   - ⚠️ **Cannot be changed later!**
   - Click: **Enable**

5. **Wait for Creation**
   - Takes 30-60 seconds

6. **Firestore Pricing (FREE Tier):**
   ```
   ✅ FREE per day:
   - 50,000 document reads
   - 20,000 document writes
   - 20,000 document deletes
   - 1 GB storage

   Enough for small-medium apps!
   ```

### **Step 4.3: Firebase Storage - FREE ALTERNATIVES** ⭐

**❌ Firebase Storage is NOT truly free:**
```
Free tier:
- 5 GB storage
- 1 GB/day download
- 20,000 uploads/day

BUT AFTER FREE TIER:
- $0.026 per GB storage/month
- $0.12 per GB downloaded
- CAN BE EXPENSIVE!
```

**✅ BETTER FREE ALTERNATIVES:**

---

## 💾 FREE Storage Alternatives (Better than Firebase Storage)

### **Option 1: Cloudinary (RECOMMENDED)** ⭐⭐⭐

**Pricing:**
```
FREE TIER:
✅ 25 GB storage
✅ 25 GB bandwidth/month
✅ Unlimited transformations
✅ Image optimization
✅ CDN included
✅ Forever free!
```

**Setup Cloudinary:**

1. **Sign Up**
   ```
   https://cloudinary.com/users/register/free
   ```

2. **Get Credentials**
   - Dashboard → Account Details
   - Copy:
     - Cloud name
     - API Key
     - API Secret

3. **Add to Flutter**
   ```yaml
   # pubspec.yaml
   dependencies:
     cloudinary_public: ^0.21.0
   ```

4. **Usage Example**
   ```dart
   import 'package:cloudinary_public/cloudinary_public.dart';

   final cloudinary = CloudinaryPublic('YOUR_CLOUD_NAME', 'YOUR_UPLOAD_PRESET');

   // Upload image
   CloudinaryResponse response = await cloudinary.uploadFile(
     CloudinaryFile.fromFile(imagePath),
   );

   print(response.secureUrl); // Image URL
   ```

**Pros:**
- ✅ 25 GB storage (vs Firebase 5 GB)
- ✅ Automatic image optimization
- ✅ CDN (fast loading)
- ✅ Image transformations (resize, crop, etc.)
- ✅ Forever free
- ✅ Easy to use

**Cons:**
- ❌ Requires separate account
- ❌ Different from Firebase ecosystem

---

### **Option 2: Supabase Storage** ⭐⭐

**Pricing:**
```
FREE TIER:
✅ 1 GB storage
✅ 2 GB bandwidth
✅ Unlimited files
✅ Forever free
```

**Setup Supabase:**

1. **Sign Up**
   ```
   https://supabase.com/
   ```

2. **Create Project**
   - Free tier
   - Select region (Singapore)

3. **Add to Flutter**
   ```yaml
   dependencies:
     supabase_flutter: ^2.0.0
   ```

4. **Usage**
   ```dart
   import 'package:supabase_flutter/supabase_flutter.dart';

   // Upload
   await Supabase.instance.client.storage
     .from('avatars')
     .upload('user1.jpg', imageFile);

   // Get URL
   final url = Supabase.instance.client.storage
     .from('avatars')
     .getPublicUrl('user1.jpg');
   ```

**Pros:**
- ✅ Easy integration
- ✅ Similar to Firebase
- ✅ Forever free
- ✅ PostgreSQL database included

**Cons:**
- ❌ Only 1 GB storage
- ❌ Separate account needed

---

### **Option 3: Imgur** ⭐

**Pricing:**
```
FREE TIER:
✅ Unlimited storage
✅ 1250 uploads/day
✅ Free forever
```

**Setup:**

1. **Register App**
   ```
   https://api.imgur.com/oauth2/addclient
   ```

2. **Add to Flutter**
   ```yaml
   dependencies:
     http: ^1.2.2
   ```

3. **Upload**
   ```dart
   final response = await http.post(
     Uri.parse('https://api.imgur.com/3/upload'),
     headers: {
       'Authorization': 'Client-ID YOUR_CLIENT_ID',
     },
     body: {
       'image': base64Image,
     },
   );
   ```

**Pros:**
- ✅ Unlimited storage
- ✅ Free forever
- ✅ Simple API

**Cons:**
- ❌ Images are public
- ❌ Not ideal for private photos

---

### **Option 4: ImageKit** ⭐⭐

**Pricing:**
```
FREE TIER:
✅ 20 GB storage
✅ 20 GB bandwidth/month
✅ Image optimization
✅ CDN included
```

**Similar to Cloudinary, slightly less generous free tier.**

---

### **Option 5: Keep Firebase Storage (With Limits)**

If you want to use Firebase Storage but avoid charges:

**Set Storage Rules to Limit Uploads:**

```javascript
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      // Max file size: 5 MB
      allow write: if request.resource.size < 5 * 1024 * 1024;

      // Only authenticated users
      allow write: if request.auth != null;

      // Limit uploads per user
      allow create: if request.auth != null;
    }
  }
}
```

**Monitor Usage:**
```
Firebase Console → Storage → Usage
Set up budget alerts in GCP
```

---

## 🎯 RECOMMENDED SETUP for ReLink

### **For Images (Photos, Avatars):**

**Use Cloudinary** ⭐
- 25 GB free storage
- Automatic optimization
- CDN for fast loading
- Image transformations

### **For Documents (PDFs, Receipts):**

**Use Firebase Storage**
- Small files only
- Monitor usage carefully
- Set file size limits

### **Cost Comparison:**

| Service | Storage | Bandwidth | Best For |
|---------|---------|-----------|----------|
| **Cloudinary** | 25 GB | 25 GB/mo | ✅ Images |
| **Firebase Storage** | 5 GB | 1 GB/day | ❌ Expensive |
| **Supabase** | 1 GB | 2 GB/mo | Small apps |
| **Imgur** | Unlimited | Unlimited | Public images |

---

## 📝 Part 5: Update Configuration Files

### **Step 5.1: Create .env File**

```env
# Firebase Configuration
FIREBASE_PROJECT_ID=your-new-project-id
FIREBASE_API_KEY=your-firebase-api-key
FIREBASE_MESSAGING_SENDER_ID=your-sender-id

# Google Maps & Places
GOOGLE_MAPS_API_KEY=your-google-maps-key

# Gemini AI
GEMINI_API_KEY=your-gemini-key

# Cloudinary (if using)
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-cloudinary-key
CLOUDINARY_API_SECRET=your-cloudinary-secret
CLOUDINARY_UPLOAD_PRESET=your-preset
```

### **Step 5.2: Update .firebaserc**

```json
{
  "projects": {
    "default": "your-new-project-id"
  }
}
```

### **Step 5.3: Update firebase.json**

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  },
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  }
}
```

**Note:** No storage rules if using Cloudinary!

---

## 🧪 Part 6: Test Everything

### **Step 6.1: Build and Run**

```bash
# Get dependencies
flutter pub get

# Run app
flutter run
```

### **Step 6.2: Test Features**

**Authentication:**
- [ ] Email/password registration
- [ ] Email/password login
- [ ] Google Sign-In
- [ ] Logout

**Firestore:**
- [ ] Write data
- [ ] Read data
- [ ] Real-time listeners

**Maps:**
- [ ] Map loads
- [ ] Current location shows
- [ ] Places search works

**Image Upload (Cloudinary):**
- [ ] Upload photo
- [ ] Get image URL
- [ ] Display in app

---

## ✅ Complete Setup Checklist

### **Firebase/GCP:**
- [ ] Firebase project created
- [ ] Android app added
- [ ] google-services.json downloaded and placed
- [ ] GCP billing enabled
- [ ] Required APIs enabled
- [ ] API keys created and restricted
- [ ] Firebase Authentication enabled
- [ ] Firestore database created

### **Configuration:**
- [ ] .env file created with all keys
- [ ] .firebaserc updated
- [ ] firebase.json configured
- [ ] AndroidManifest.xml has Maps API key
- [ ] SHA-1 added to Firebase

### **Storage:**
- [ ] Cloudinary account created (or alternative chosen)
- [ ] Cloudinary credentials added to .env
- [ ] Flutter package added (cloudinary_public)
- [ ] Upload tested

### **Testing:**
- [ ] App builds successfully
- [ ] Authentication works
- [ ] Firestore works
- [ ] Maps displays
- [ ] Image upload works
- [ ] No console errors

---

## 💰 Cost Summary

### **With Firebase Storage:**
```
Monthly cost if you exceed free tier:
- 10 GB storage: $0.26
- 10 GB download: $1.20
- Total: ~$1.50/month

For 100 users uploading photos: $10-50/month
```

### **With Cloudinary:**
```
Monthly cost:
- 25 GB storage: $0 (free)
- 25 GB bandwidth: $0 (free)
- Total: $0/month ✅

For 100 users uploading photos: $0/month ✅
```

**Cloudinary saves you ~$10-50/month!**

---

## 📚 Documentation

After fresh setup, update these docs:
- README.md (with new project ID)
- SETUP_MANUAL.md (if needed)
- .env.example (with new variables)

---

## 🎯 Summary

### **What You Get:**

**100% FREE Services:**
- ✅ Firebase Authentication (unlimited)
- ✅ Cloud Firestore (50K reads/day)
- ✅ Google Maps ($200 credit/month)
- ✅ Gemini AI (60 req/min)
- ✅ Cloudinary Storage (25 GB)
- ✅ Firebase Hosting (10 GB)

**Total Monthly Cost:** $0 for small-medium apps! 🎉

### **Next Steps:**

1. Follow this guide step-by-step
2. Choose Cloudinary for images
3. Use Firebase for everything else
4. Monitor usage in Firebase/GCP Console
5. Set budget alerts
6. Enjoy free tier! 🚀

---

**Last Updated:** January 2025
**Cost Optimized:** Yes ✅
**Storage Solution:** Cloudinary (FREE 25 GB)
