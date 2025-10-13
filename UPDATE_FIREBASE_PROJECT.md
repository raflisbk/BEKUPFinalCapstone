# 🔄 Update Firebase Project - Complete Guide

Guide lengkap untuk update dari `relink-app-a96f3` ke `relink-f4647`.

---

## 🎯 Current Situation

**Your Current Config:**
- google-services.json: `relink-app-a96f3` (Project Number: 809876881035)
- Firebase CLI: Using `relink-app-a96f3`

**Available Projects:**
- ✅ `relink-f4647` - Available in GCP Console (Project Number: 888790734949)
- ⚠️ `relink-app-a96f3` - Not visible in GCP (might not have billing enabled)

**Problem:**
Your app is configured for `relink-app-a96f3` but you only have access to `relink-f4647` in GCP.

---

## ✅ SOLUTION 1: Switch to relink-f4647 (RECOMMENDED)

Update your app to use the project that exists in GCP.

### **Step 1: Download New google-services.json**

1. **Go to Firebase Console**
   ```
   https://console.firebase.google.com/project/relink-f4647
   ```

2. **Click Gear Icon ⚙️ → Project Settings**

3. **Scroll to "Your apps" Section**

4. **Check if Android App Exists:**

   **If Android App EXISTS:**
   - Look for package: `com.example.relink`
   - Click **download google-services.json**
   - Skip to Step 2

   **If Android App DOES NOT EXIST:**
   - Continue to add Android app below

5. **Add Android App (if needed):**
   - Click **"Add app"** → Select **Android** icon
   - **Android package name:** `com.example.relink`
     - ⚠️ **IMPORTANT:** Must match your `build.gradle.kts`
   - **App nickname (optional):** ReLink Android
   - **Debug signing certificate SHA-1 (optional):**
     ```bash
     cd android
     ./gradlew signingReport
     # Copy SHA-1 from output
     ```
   - Click **"Register app"**

6. **Download google-services.json**
   - Click **"Download google-services.json"**
   - Save the file

### **Step 2: Replace google-services.json**

```bash
# Backup old file (optional)
cp android/app/google-services.json android/app/google-services.json.backup

# Replace with new file
# Copy downloaded file to: android/app/google-services.json
```

**Or using command:**
```bash
# If downloaded to Downloads folder
cp ~/Downloads/google-services.json android/app/google-services.json

# Windows
copy "%USERPROFILE%\Downloads\google-services.json" android\app\google-services.json
```

### **Step 3: Verify New google-services.json**

```bash
# Check project ID
cat android/app/google-services.json | grep "project_id"
# Should show: "project_id": "relink-f4647"

# Check project number
cat android/app/google-services.json | grep "project_number"
# Should show: "project_number": "888790734949"

# Check package name
cat android/app/google-services.json | grep "package_name"
# Should show: "package_name": "com.example.relink"
```

### **Step 4: Update Firebase CLI Configuration**

```bash
# Switch to relink-f4647 project
firebase use relink-f4647

# Verify
firebase use
# Should show: Active project: relink-f4647
```

### **Step 5: Update .firebaserc**

```bash
# Edit .firebaserc
cat > .firebaserc << 'EOF'
{
  "projects": {
    "default": "relink-f4647"
  }
}
EOF
```

### **Step 6: Update firebase.json**

Update project references in `firebase.json`:

```json
{
  "flutter": {
    "platforms": {
      "android": {
        "default": {
          "projectId": "relink-f4647",
          "appId": "1:888790734949:android:YOUR_APP_ID",
          "fileOutput": "android/app/google-services.json"
        }
      }
    }
  },
  "hosting": {
    "public": "build/web"
    // ... rest of config
  }
}
```

### **Step 7: Update Web Configuration (if using web)**

Update `web/index.html` Firebase config:

```javascript
const firebaseConfig = {
  apiKey: "YOUR_NEW_API_KEY",  // From new google-services.json
  authDomain: "relink-f4647.firebaseapp.com",
  projectId: "relink-f4647",
  storageBucket: "relink-f4647.firebasestorage.app",
  messagingSenderId: "888790734949",
  appId: "1:888790734949:web:YOUR_WEB_APP_ID",
  measurementId: "G-YOUR_MEASUREMENT_ID"
};
```

### **Step 8: Update Environment Variables**

Update `.env` file:

```env
# OLD
FIREBASE_WEB_PROJECT_ID=relink-app-a96f3
FIREBASE_WEB_MESSAGING_SENDER_ID=809876881035

# NEW
FIREBASE_WEB_PROJECT_ID=relink-f4647
FIREBASE_WEB_MESSAGING_SENDER_ID=888790734949
```

### **Step 9: Clean Build and Test**

```bash
# Clean build
flutter clean
flutter pub get

# Delete old build cache
rm -rf build/
rm -rf android/.gradle/
rm -rf android/app/build/

# Run app
flutter run
```

### **Step 10: Test All Features**

Test checklist:
- [ ] App launches successfully
- [ ] Authentication works (sign in/sign up)
- [ ] Firestore read/write works
- [ ] Storage upload works
- [ ] Google Maps loads
- [ ] Push notifications work (if enabled)

### **Step 11: Verify in Firebase Console**

```
https://console.firebase.google.com/project/relink-f4647

Check:
- Authentication → Users (should be empty if new project)
- Firestore → Data (should be empty if new project)
- Storage → Files (should be empty if new project)
```

---

## 🚀 SOLUTION 2: Setup GCP for relink-app-a96f3

If you want to keep using `relink-app-a96f3`, you need to setup GCP access.

### **Why relink-app-a96f3 Not in GCP?**

Possible reasons:
1. **Billing not enabled** - Firebase project exists but GCP not activated
2. **No GCP access** - You don't have permission in GCP
3. **Project not linked** - Firebase and GCP not properly linked

### **Step 1: Check GCP Project Exists**

1. **Go to GCP Console**
   ```
   https://console.cloud.google.com/cloud-resource-manager
   ```

2. **Enable "Show all projects"** or "Include deleted projects"

3. **Search for:** `relink-app-a96f3`

4. **If Found:**
   - Check status (Active/Deleted)
   - Check your access level
   - Continue to Step 2

5. **If NOT Found:**
   - Project might be in different Google Account
   - Or project was never created in GCP
   - **Recommended:** Use Solution 1 instead

### **Step 2: Enable Billing (if needed)**

1. **In GCP Console → Billing**
   ```
   https://console.cloud.google.com/billing
   ```

2. **Link Billing Account**
   - Add credit/debit card
   - Accept terms
   - Enable billing for `relink-app-a96f3`

### **Step 3: Enable Required APIs**

Go to: `https://console.cloud.google.com/apis/library?project=relink-app-a96f3`

Enable:
- ✅ Maps SDK for Android
- ✅ Places API
- ✅ Geocoding API
- ✅ Directions API
- ✅ Generative Language API (Gemini)

### **Step 4: Create API Keys**

Create new API keys in GCP for this project.

---

## 📊 Comparison: Which Solution?

| Aspect | Solution 1: Use relink-f4647 | Solution 2: Setup relink-app-a96f3 |
|--------|------------------------------|-------------------------------------|
| **Difficulty** | ⭐ Easy | ⭐⭐⭐ Complex |
| **Time** | 15 minutes | 1-2 hours |
| **Cost** | $0 | $0 (but need billing setup) |
| **Data Migration** | Need to migrate if you have data | Keep existing data |
| **GCP Access** | ✅ Already have | Need to setup |
| **Recommended** | ✅ YES | ❌ Only if you have existing data |

---

## ⚠️ Important Notes

### **About Data Migration**

**If you switch projects, you'll need to:**
- ❌ **Lose all existing data** (users, Firestore, Storage)
- ✅ **OR migrate data** between projects

**If you have existing users/data in `relink-app-a96f3`:**
1. Export Firestore data
2. Export Authentication users
3. Import to `relink-f4647`

**If this is a NEW app with NO users yet:**
- ✅ Safe to switch projects
- No data to migrate

### **About Package Name**

**IMPORTANT:** Package name must stay `com.example.relink`
- Do NOT change package name
- Must match in both:
  - `build.gradle.kts`
  - Firebase Console Android app

### **About API Keys**

After switching projects:
- ✅ Update Google Maps API key (get from new GCP project)
- ✅ Update Gemini API key (if using different project)
- ✅ Update all API keys in `.env` file

---

## 🧪 Testing After Update

### **Quick Test Script:**

```bash
# 1. Clean build
flutter clean
flutter pub get

# 2. Run app
flutter run

# 3. Test features
# - Register new user
# - Sign in
# - Create a trip
# - Upload a photo
# - Send a message
```

### **Verify Project is Correct:**

```bash
# Check google-services.json
cat android/app/google-services.json | grep "project_id"

# Check Firebase CLI
firebase use

# Check if app connects
flutter run
# Look for Firebase initialization logs
```

---

## ✅ Verification Checklist

After update, verify:

**Configuration Files:**
- [ ] `android/app/google-services.json` - Updated to new project
- [ ] `.firebaserc` - Points to new project
- [ ] `firebase.json` - Updated project ID
- [ ] `web/index.html` - Updated Firebase config (if using web)
- [ ] `.env` - Updated environment variables

**Firebase Console:**
- [ ] Can access: `https://console.firebase.google.com/project/relink-f4647`
- [ ] Android app registered with `com.example.relink`
- [ ] Authentication enabled
- [ ] Firestore created
- [ ] Storage enabled

**GCP Console:**
- [ ] Can access: `https://console.cloud.google.com/home/dashboard?project=relink-f4647`
- [ ] Billing enabled
- [ ] Required APIs enabled (Maps, Places, etc.)
- [ ] API keys created

**App Testing:**
- [ ] App builds successfully
- [ ] Authentication works
- [ ] Firestore read/write works
- [ ] Storage upload works
- [ ] Google Maps displays
- [ ] No console errors

---

## 🆘 Troubleshooting

### **Problem: google-services.json not working**

**Solution:**
```bash
# Verify file is correct
cat android/app/google-services.json | grep "project_id"

# Should match the project you want to use
# If not, re-download from Firebase Console
```

### **Problem: "Default FirebaseApp is not initialized"**

**Solution:**
```bash
# Clean build
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

### **Problem: Package name mismatch**

**Solution:**
1. Check `build.gradle.kts`: `applicationId = "com.example.relink"`
2. Check Firebase Console → Android app → Package name
3. Must be EXACTLY the same
4. If different, add new Android app with correct package name

### **Problem: Authentication not working after switch**

**Solution:**
1. Enable authentication methods in new Firebase project:
   - Firebase Console → Authentication → Sign-in method
   - Enable: Email/Password, Google, Anonymous
2. For Google Sign-In, add SHA-1:
   ```bash
   cd android
   ./gradlew signingReport
   # Add SHA-1 to Firebase Console
   ```

### **Problem: Firestore/Storage empty**

**This is NORMAL if you switched projects.**
- New project = empty database
- You need to re-populate data
- OR migrate data from old project

---

## 📝 Summary

### **Recommended Steps:**

1. ✅ **Use Solution 1** (switch to `relink-f4647`)
2. ✅ Download new `google-services.json`
3. ✅ Replace file in `android/app/`
4. ✅ Update `.firebaserc` and `firebase.json`
5. ✅ Clean build and test
6. ✅ Verify all features work

### **Why Solution 1?**
- ✅ Project already exists in GCP
- ✅ No billing setup needed
- ✅ Quick and easy (15 minutes)
- ✅ Can use GCP APIs immediately

### **Time Estimate:**
- Download new file: 2 minutes
- Replace and update configs: 5 minutes
- Clean build: 3 minutes
- Testing: 5 minutes
- **Total: ~15 minutes**

---

## 📞 Need Help?

If you encounter issues:

1. **Check Firebase Status:** https://status.firebase.google.com/
2. **Firebase Documentation:** https://firebase.google.com/docs/android/setup
3. **Stack Overflow:** Tag [firebase-android]

---

**Last Updated:** January 2025
**Current Project:** relink-app-a96f3
**Target Project:** relink-f4647
**Status:** Migration Guide Complete
