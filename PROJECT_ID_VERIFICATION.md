# 🔍 ReLink - Project ID Verification Guide

Panduan lengkap untuk identify dan verify project ID yang benar antara Firebase dan GCP.

---

## 📋 Your Current Project IDs

Based on your configuration files:

| Source | Project ID | Project Number | Status |
|--------|-----------|----------------|--------|
| **google-services.json** | `relink-app-a96f3` | `809876881035` | ✅ Active |
| **.firebaserc** | `relink-app-a96f3` | - | ✅ Configured |
| **firebase.json** | `relink-app-a96f3` | - | ✅ Configured |
| **Package Name** | - | - | `com.example.relink` |

**✅ Your correct project is: `relink-app-a96f3`**

---

## 🔎 How to Identify Correct Project ID

### **Method 1: Check Your Configuration Files** ⭐

#### **1. Android: google-services.json**

```bash
# Check project ID in google-services.json
cat android/app/google-services.json | grep "project_id"
```

**Your Output:**
```json
"project_id": "relink-app-a96f3",
```

#### **2. Firebase CLI: .firebaserc**

```bash
# Check Firebase project
cat .firebaserc
```

**Your Output:**
```json
{
  "projects": {
    "default": "relink-app-a96f3"
  }
}
```

#### **3. Web: index.html**

Check `web/index.html` for Firebase config:

```javascript
const firebaseConfig = {
  projectId: "relink-app-a96f3",  // ← This is your project ID
  // ...
};
```

---

### **Method 2: Firebase Console** 🔥

**Step-by-Step:**

1. **Go to Firebase Console**
   - URL: https://console.firebase.google.com/

2. **View Your Projects**
   - You'll see all Firebase projects you have access to
   - Look for project with name containing "relink"

3. **Identify by Package Name**
   - Click each "ReLink" project
   - Go to: **Project Settings** (⚙️ gear icon)
   - Scroll to **Your apps** section
   - Check Android app
   - **Match Package Name:** `com.example.relink`

4. **Verify Project ID**
   - In Project Settings
   - Section: **General**
   - Look for: **Project ID**: `relink-app-a96f3`
   - Look for: **Project number**: `809876881035`

**Screenshot Flow:**
```
Firebase Console
└── Select Project
    └── ⚙️ Project Settings
        └── General Tab
            ├── Project name: ReLink (or similar)
            ├── Project ID: relink-app-a96f3 ✅
            ├── Project number: 809876881035
            └── Your apps
                └── Android app
                    └── Package name: com.example.relink ✅
```

---

### **Method 3: Google Cloud Console** ☁️

**Step-by-Step:**

1. **Go to GCP Console**
   - URL: https://console.cloud.google.com/

2. **View Project List**
   - Click project dropdown at top
   - You'll see all GCP projects

3. **Identify by Project Number**
   - Each project shows:
     - Project name
     - Project ID
     - Project number
   - **Match Project Number:** `809876881035`

4. **Verify in Project Dashboard**
   - Select the project
   - Dashboard shows:
     - Project ID: `relink-app-a96f3`
     - Project number: `809876881035`

**Screenshot Flow:**
```
GCP Console
└── Project Dropdown (top bar)
    └── List of Projects
        └── Find project with number: 809876881035
            ├── Project name: relink-app-a96f3
            ├── Project ID: relink-app-a96f3 ✅
            └── Project number: 809876881035 ✅
```

---

### **Method 4: Firebase CLI** 💻

**List All Projects:**

```bash
# Login first (if not logged in)
firebase login

# List all projects you have access to
firebase projects:list
```

**Output Example:**
```
┌──────────────────────┬────────────────────┬────────────────────┬──────────────────────┐
│ Project Display Name │ Project ID         │ Project Number     │ Resource Location ID │
├──────────────────────┼────────────────────┼────────────────────┼──────────────────────┤
│ ReLink               │ relink-app-a96f3   │ 809876881035       │ asia-southeast2      │
│ ReLink Old           │ relink-f4647       │ 888790734949       │ [Not specified]      │
└──────────────────────┴────────────────────┴────────────────────┴──────────────────────┘
```

**Identify Correct One:**
- Match **Project Number**: `809876881035`
- Check **Resource Location**: `asia-southeast2`
- Your correct project: `relink-app-a96f3` ✅

---

### **Method 5: Check API Requests** 🌐

**Test with Flutter App:**

```bash
# Run app with verbose logging
flutter run --verbose 2>&1 | grep -i "project"
```

Look for Firebase initialization logs showing project ID.

**Or Check Network Requests:**
1. Run app
2. Open Chrome DevTools (if web)
3. Network tab
4. Filter: "firestore" or "firebase"
5. Check request URLs - will contain project ID

Example URL:
```
https://firestore.googleapis.com/v1/projects/relink-app-a96f3/databases/(default)/documents/...
                                          ^^^^^^^^^^^^^^^^
                                          Your Project ID
```

---

## 🆔 Understanding Firebase/GCP Project Identifiers

### **Project ID vs Project Number vs Project Name**

| Identifier | Format | Example | Changeable? | Where Used |
|------------|--------|---------|-------------|------------|
| **Project Name** | Display name | "ReLink" | ✅ Yes | UI only |
| **Project ID** | Unique string | `relink-app-a96f3` | ❌ No | APIs, configs |
| **Project Number** | Numeric | `809876881035` | ❌ No | Internal APIs |

#### **1. Project Name (Display Name)**
- **Example:** "ReLink", "ReLink App", "ReLink Production"
- **Purpose:** Human-readable name shown in Firebase/GCP Console
- **Changeable:** ✅ Yes, can be changed anytime
- **Used in:** UI display only
- **Problem:** You can have multiple projects with same name!

#### **2. Project ID** ⭐ **Most Important**
- **Example:** `relink-app-a96f3`
- **Format:** Lowercase letters, numbers, hyphens
- **Purpose:** Unique identifier for project
- **Changeable:** ❌ NO, permanent after creation
- **Used in:**
  - Firebase configs
  - API URLs
  - Cloud Storage buckets
  - Firestore paths
  - Authentication domains

#### **3. Project Number**
- **Example:** `809876881035`
- **Format:** Numeric only
- **Purpose:** Internal Google identifier
- **Changeable:** ❌ NO, assigned at creation
- **Used in:**
  - Some GCP APIs
  - Service account keys
  - Internal tracking

---

## 🔍 How to Find ALL Your ReLink Projects

### **Scenario: Multiple Projects with "ReLink" Name**

You might have:
- `ReLink` (old/test project)
- `ReLink` (production)
- `ReLink App` (another project)
- `relink-test` (development)

**How to identify which is active?**

---

### **Step-by-Step Identification:**

#### **Step 1: Check Your google-services.json**

```bash
cat android/app/google-services.json | grep -A 2 "project_info"
```

**Output:**
```json
"project_info": {
  "project_number": "809876881035",
  "project_id": "relink-app-a96f3",
```

**This is your ACTIVE Android project!** ✅

---

#### **Step 2: List All Projects in Firebase**

```bash
firebase projects:list
```

**Example Output:**
```
┌──────────────────────┬────────────────────┬────────────────────┐
│ Display Name         │ Project ID         │ Project Number     │
├──────────────────────┼────────────────────┼────────────────────┤
│ ReLink               │ relink-app-a96f3   │ 809876881035       │ ← ACTIVE
│ ReLink               │ relink-f4647       │ 888790734949       │ ← OLD
│ ReLink Test          │ relink-test-abc    │ 123456789012       │ ← DEV
└──────────────────────┴────────────────────┴────────────────────┘
```

**Match Project Number:** `809876881035` → **`relink-app-a96f3`** ✅

---

#### **Step 3: Check Each Project in Firebase Console**

For each "ReLink" project:

1. **Open Project Settings**
   - Firebase Console → Select Project → ⚙️ Settings

2. **Check Your Apps Section**
   - Look for Android app
   - **Check Package Name:** `com.example.relink`
   - If package name matches, this is your project! ✅

3. **Check Project Details**
   ```
   General tab:
   - Project name: ReLink
   - Project ID: relink-app-a96f3 ✅
   - Project number: 809876881035 ✅
   ```

4. **Check Android App Configuration**
   ```
   Your apps → Android:
   - Package name: com.example.relink ✅
   - App ID: 1:809876881035:android:0c37a7f474cd966f955e8e
   - SHA-1: (your debug/release fingerprints)
   ```

**If all match → This is your correct project!**

---

#### **Step 4: Check GCP Console**

1. **Open GCP Console**
   - https://console.cloud.google.com/

2. **Click Project Dropdown** (top bar)
   - Shows all GCP projects

3. **Look for Each "ReLink" Project**
   - Check project number: `809876881035`
   - This matches → **`relink-app-a96f3`** ✅

4. **Verify APIs Enabled**
   - Go to: APIs & Services → Dashboard
   - Check if Maps SDK, Firestore, etc. are enabled
   - Active project will have APIs enabled

---

## 🎯 Your Correct Project Identification

Based on your configuration:

### **✅ Active Project:**

```
Project Name: ReLink (or similar display name)
Project ID: relink-app-a96f3
Project Number: 809876881035
Package Name: com.example.relink
Location: asia-southeast2
```

### **How We Know:**

1. ✅ `google-services.json` contains: `relink-app-a96f3`
2. ✅ `.firebaserc` configured with: `relink-app-a96f3`
3. ✅ `firebase.json` references: `relink-app-a96f3`
4. ✅ Package name matches: `com.example.relink`
5. ✅ Project number matches: `809876881035`

---

## 🗂️ Organizing Multiple Projects

### **If You Have Multiple ReLink Projects:**

#### **Recommended Naming Convention:**

| Project | Display Name | Project ID | Purpose |
|---------|-------------|------------|---------|
| **Production** | ReLink Production | `relink-app-a96f3` | Live app |
| **Development** | ReLink Dev | `relink-dev-xyz` | Testing |
| **Staging** | ReLink Staging | `relink-stage-xyz` | Pre-production |

#### **Clean Up Unused Projects:**

**Step 1: Identify Unused Projects**
```bash
firebase projects:list
```

**Step 2: Check Last Activity**
- Firebase Console → Project → Usage tab
- Check last activity date
- If no activity > 3 months → probably unused

**Step 3: Backup Before Delete**
```bash
# Export Firestore data
gcloud firestore export gs://backup-bucket/
```

**Step 4: Delete Unused Project**
- Firebase Console → Project Settings → General
- Scroll down → "Delete project"
- Type project ID to confirm
- ⚠️ **Remember:** 30-day recovery window

---

## 📝 Quick Reference Commands

### **Check Your Current Configuration:**

```bash
# Project ID in google-services.json
cat android/app/google-services.json | grep "project_id"
# Output: "project_id": "relink-app-a96f3"

# Project in Firebase CLI
cat .firebaserc
# Output: "default": "relink-app-a96f3"

# List all Firebase projects
firebase projects:list

# Check which project Firebase CLI is using
firebase use
# Output: Active project: relink-app-a96f3

# Switch to different project (if needed)
firebase use <project-id>
```

---

## ✅ Verification Checklist

Use this checklist to verify correct project:

### **Firebase Console:**
- [ ] Open: https://console.firebase.google.com/
- [ ] Select project: **ReLink** (or your display name)
- [ ] Project Settings → General
- [ ] Verify Project ID: `relink-app-a96f3` ✅
- [ ] Verify Project Number: `809876881035` ✅
- [ ] Check Your apps → Android
- [ ] Verify Package name: `com.example.relink` ✅

### **GCP Console:**
- [ ] Open: https://console.cloud.google.com/
- [ ] Project dropdown → Select project
- [ ] Verify Project ID: `relink-app-a96f3` ✅
- [ ] Verify Project Number: `809876881035` ✅
- [ ] Check APIs enabled (Maps, Firestore, etc.)

### **Configuration Files:**
- [ ] `android/app/google-services.json`: `relink-app-a96f3` ✅
- [ ] `.firebaserc`: `relink-app-a96f3` ✅
- [ ] `firebase.json`: `relink-app-a96f3` ✅
- [ ] `web/index.html`: `relink-app-a96f3` ✅

### **Testing:**
- [ ] Run app: `flutter run`
- [ ] Test authentication (sign in/up)
- [ ] Test Firestore read/write
- [ ] Test Storage upload
- [ ] Check console logs for project ID

**If all ✅ → You're using the correct project!**

---

## 🚨 Common Issues

### **Issue 1: Multiple Projects with Same Name**

**Problem:** You see 3 "ReLink" projects in Firebase Console

**Solution:**
1. Check Project ID (unique identifier)
2. Match with `google-services.json`
3. Check package name in each project
4. One that matches `com.example.relink` is correct

### **Issue 2: Different Project IDs in Different Files**

**Problem:**
- `google-services.json`: `relink-app-a96f3`
- `.firebaserc`: `relink-f4647`

**Solution:**
```bash
# Update .firebaserc to match google-services.json
firebase use relink-app-a96f3

# Or regenerate google-services.json from Firebase Console
```

### **Issue 3: App Not Connecting to Firebase**

**Problem:** App can't authenticate or access Firestore

**Solution:**
1. Verify all config files have same Project ID
2. Check package name matches in Firebase Console
3. Verify `google-services.json` is up to date
4. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

## 📞 Need Help Identifying?

### **If Still Confused:**

**Option 1: Check Firebase Console**
- Easiest way to see all your projects
- Visual interface
- Shows package names

**Option 2: Use Firebase CLI**
```bash
firebase projects:list
```
- Shows all projects you have access to
- Match Project Number with google-services.json

**Option 3: Contact Firebase Support**
- Firebase Console → ? icon → Contact Support
- Provide:
  - Package name: `com.example.relink`
  - Project number: `809876881035`
  - Ask: "Which project ID matches this package?"

---

## 🎯 Summary

### **Your Correct Project:**

```yaml
Display Name: ReLink
Project ID: relink-app-a96f3
Project Number: 809876881035
Package Name: com.example.relink
Region: asia-southeast2

Firebase Console:
  https://console.firebase.google.com/project/relink-app-a96f3

GCP Console:
  https://console.cloud.google.com/home/dashboard?project=relink-app-a96f3
```

### **Key Identifiers:**
- **Project ID:** `relink-app-a96f3` (use this everywhere)
- **Project Number:** `809876881035` (for matching)
- **Package Name:** `com.example.relink` (for verification)

### **Where to Find:**
1. **google-services.json** - Most reliable source
2. **.firebaserc** - Current Firebase CLI config
3. **Firebase Console** - Visual verification
4. **GCP Console** - Cross-verification

**Remember:** Project ID is permanent and unique. Match it across all configs!

---

**Last Updated:** January 2025
**Your Active Project:** `relink-app-a96f3` ✅
