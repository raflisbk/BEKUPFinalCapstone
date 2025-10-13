# 🚨 ReLink - Disaster Recovery Guide

Complete guide untuk recovery jika accidentally delete Firebase/GCP project.

---

## 🆘 Emergency Recovery Procedures

### **Scenario 1: Project Deleted < 30 Days Ago** ⏰

**GOOD NEWS: You can restore it!**

#### **Quick Restore Steps:**

```bash
# 1. Go to GCP Console
# URL: https://console.cloud.google.com/cloud-resource-manager

# 2. Enable "Show deleted projects"
# 3. Find: relink-app-a96f3
# 4. Click ⋮ → Restore
# 5. Wait 5-10 minutes
# 6. Verify restoration
```

#### **Detailed Recovery Process:**

**Step 1: Access GCP Console**
1. Open: https://console.cloud.google.com/
2. Login with Google Account yang memiliki project

**Step 2: Navigate to Manage Resources**
- Click hamburger menu (☰)
- Go to: **IAM & Admin** → **Manage Resources**
- Direct link: https://console.cloud.google.com/cloud-resource-manager

**Step 3: Show Deleted Projects**
- Look for filter/dropdown at top
- Enable: ☑️ **"Include deleted projects"**
- Or select: **"ALL"** to show active + deleted

**Step 4: Find Your Project**
- Project ID: `relink-app-a96f3`
- Status: **Pending deletion** or **Scheduled for deletion**
- Deletion date shown (30 days from when deleted)

**Step 5: Restore Project**
- Click **three dots** (⋮) next to project
- Select: **"Restore"**
- Confirm in dialog: **"Restore project"**

**Step 6: Wait for Restoration**
- Restoration takes: 5-10 minutes
- Status changes: Pending → Active
- All services automatically restored

**Step 7: Verify Restoration**

```bash
# Check Firebase projects
firebase projects:list

# Should show:
# Project Display Name: relink-app-a96f3
# Project ID: relink-app-a96f3
# Resource Location: asia-southeast2
```

**Step 8: Test App**
```bash
# Run Flutter app
flutter run

# Test:
# ✅ Authentication works
# ✅ Firestore read/write
# ✅ Storage upload/download
# ✅ FCM notifications
```

**Step 9: Check All Services**

Firebase Console: https://console.firebase.google.com/project/relink-app-a96f3

Verify:
- ✅ **Authentication**: Users still exist
- ✅ **Firestore**: Collections and documents intact
- ✅ **Storage**: Files still accessible
- ✅ **Hosting**: Web app still deployed
- ✅ **Cloud Messaging**: FCM still working

---

### **Scenario 2: Project Deleted > 30 Days Ago** 💀

**BAD NEWS: Project is permanently deleted. NO RECOVERY POSSIBLE.**

You must **recreate everything from scratch**.

---

## 🔨 Complete Rebuild Guide (If No Recovery)

### **Phase 1: Create New Firebase Project**

**Step 1: Create Project**
1. Go to: https://console.firebase.google.com/
2. Click: **"Create a project"**
3. Project name: `relink-app-v2` (or similar)
4. Project ID: Will auto-generate (e.g., `relink-app-v2-abc123`)
5. Enable Google Analytics: Yes
6. Click: **"Create project"**

**Step 2: Add Android App**
1. Click Android icon
2. Package name: `com.example.relink` ⚠️ **MUST MATCH**
3. App nickname: `ReLink Android`
4. SHA-1: Get from `cd android && ./gradlew signingReport`
5. Download: `google-services.json`
6. Replace: `android/app/google-services.json`

**Step 3: Add Web App**
1. Click Web icon (</> symbol)
2. App nickname: `ReLink Web`
3. Enable Firebase Hosting: Yes
4. Copy web config (apiKey, authDomain, etc.)
5. Update: `web/index.html` with new config

---

### **Phase 2: Enable Firebase Services**

**Authentication:**
```
Firebase Console → Authentication → Get Started

Enable sign-in methods:
- ✅ Email/Password
- ✅ Google Sign-In
- ✅ Anonymous
```

**Firestore Database:**
```
Firebase Console → Firestore Database → Create database

Settings:
- Mode: Production mode
- Location: asia-southeast2 (Jakarta)
- Click: Enable

Deploy rules:
firebase deploy --only firestore:rules
```

**Storage:**
```
Firebase Console → Storage → Get Started

Settings:
- Mode: Production mode
- Location: asia-southeast2
- Click: Done

Deploy rules:
firebase deploy --only storage
```

**Cloud Messaging:**
```
Firebase Console → Cloud Messaging

- Already enabled by default
- No additional setup needed
```

---

### **Phase 3: Setup Google Cloud Platform**

**Step 1: Enable Billing**
1. Go to: https://console.cloud.google.com/billing
2. Link billing account
3. Add credit/debit card
4. Set budget alert: $50/month

**Step 2: Enable APIs**

Go to: https://console.cloud.google.com/apis/library

Enable:
- ✅ Maps SDK for Android
- ✅ Maps SDK for iOS (if needed)
- ✅ Places API
- ✅ Places API (New)
- ✅ Geocoding API
- ✅ Geolocation API
- ✅ Directions API
- ✅ Distance Matrix API
- ✅ Generative Language API (for Gemini)

**Step 3: Create API Keys**

**Google Maps API Key:**
```
APIs & Services → Credentials → Create Credentials → API key

Restrictions:
- Application restrictions: Android apps
  - Package name: com.example.relink
  - SHA-1: [Your SHA-1]
- API restrictions: Select above APIs
- Save
```

**Gemini AI Key:**
```
Go to: https://aistudio.google.com/app/apikey
Click: Create API key
Select: relink-app-v2 project
Copy key
```

---

### **Phase 4: Update Project Configuration**

**Update Environment Variables (.env):**

```env
# OLD (akan error)
FIREBASE_WEB_API_KEY=AIzaSyBugpuZTTIJKRBLejc1Tb9o7BMdIuEaKmM
FIREBASE_WEB_PROJECT_ID=relink-app-a96f3

# NEW (dari project baru)
FIREBASE_WEB_API_KEY=AIzaSyC_NEW_KEY_HERE
FIREBASE_WEB_PROJECT_ID=relink-app-v2-abc123

GOOGLE_MAPS_API_KEY=AIzaSyB_NEW_MAPS_KEY
GEMINI_API_KEY=AIzaSyD_NEW_GEMINI_KEY
```

**Update firebase.json:**

```json
{
  "flutter": {
    "platforms": {
      "android": {
        "default": {
          "projectId": "relink-app-v2-abc123",
          "appId": "1:NEW_APP_ID:android:NEW_HASH",
          "fileOutput": "android/app/google-services.json"
        }
      }
    }
  }
}
```

**Update .firebaserc:**

```json
{
  "projects": {
    "default": "relink-app-v2-abc123"
  }
}
```

**Update web/index.html:**

Replace Firebase config:
```javascript
const firebaseConfig = {
  apiKey: "AIzaSyC_NEW_API_KEY",
  authDomain: "relink-app-v2-abc123.firebaseapp.com",
  projectId: "relink-app-v2-abc123",
  storageBucket: "relink-app-v2-abc123.firebasestorage.app",
  messagingSenderId: "NEW_SENDER_ID",
  appId: "1:NEW_SENDER_ID:web:NEW_HASH",
  measurementId: "G-NEW_MEASUREMENT_ID"
};
```

**Update AndroidManifest.xml:**

Replace Google Maps API key:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyB_NEW_MAPS_KEY"/>
```

---

### **Phase 5: Data Migration (If You Have Backup)**

**If you have backups of Firestore data:**

**Option A: Manual Re-upload**
```bash
# Export from old project (if still accessible)
gcloud firestore export gs://relink-app-a96f3-backup/

# Import to new project
gcloud firestore import gs://relink-app-a96f3-backup/
```

**Option B: Use Scripts**
- Write scripts to re-populate Firestore
- Add destinations data
- Re-create user profiles (users need to re-register)

**If NO backups:**
- ⚠️ **All data is lost permanently**
- Users must re-register
- Destinations must be re-added
- Photos/reviews lost

---

### **Phase 6: Testing New Setup**

**Test Checklist:**

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

Test:
- [ ] App launches successfully
- [ ] Email/password registration works
- [ ] Google Sign-In works
- [ ] Firestore read/write works
- [ ] Image upload to Storage works
- [ ] Google Maps loads
- [ ] Places search works
- [ ] Gemini AI responses work
- [ ] Push notifications work (FCM)

---

### **Phase 7: Redeploy Web App**

```bash
# Build Flutter web
flutter build web --release

# Login to Firebase
firebase login

# Use new project
firebase use relink-app-v2-abc123

# Deploy
firebase deploy --only hosting
```

New web URLs:
- https://relink-app-v2-abc123.web.app
- https://relink-app-v2-abc123.firebaseapp.com

---

### **Phase 8: Update Documentation**

Update all docs with new project ID:
- README.md
- SETUP_MANUAL.md
- WEB_SETUP.md
- DEPLOYMENT_GUIDE.md
- .env.example

Search and replace:
- `relink-app-a96f3` → `relink-app-v2-abc123`

---

## 🛡️ Prevention: Backup Strategy

### **To Prevent Future Disasters:**

**1. Enable Daily Firestore Backups**

```bash
# Setup scheduled backups (Cloud Functions)
gcloud firestore export gs://relink-firestore-backup/$(date +%Y%m%d)
```

**2. Enable Storage Versioning**
```
Firebase Console → Storage → Rules → Enable versioning
```

**3. Export Authentication Users**
```bash
# Export users list
firebase auth:export users.json --format=JSON
```

**4. Keep Local Backups**
- Backup `.env` file (encrypted)
- Save `google-services.json`
- Export Firestore data monthly
- Save API keys in password manager

**5. Use Version Control**
- ✅ All code in Git
- ✅ Configuration files tracked
- ✅ Regular commits

**6. Multiple Admin Accounts**
- Add multiple owners to Firebase project
- Use organization account (not personal)
- Enable 2FA on all accounts

**7. Project Billing Alerts**
- Set alerts before hitting limits
- Prevents accidental service shutdown

**8. Documentation**
- Keep SETUP_MANUAL.md updated
- Document all API keys (encrypted)
- Save SHA-1 fingerprints

---

## 📞 Contact Support (If Needed)

### **Firebase Support:**

**Free Plan:**
- Community support: Stack Overflow
- Firebase Community: https://firebase.google.com/support

**Paid Plans (Blaze):**
- Email support
- Priority support ticket
- Response: 24-48 hours

**To contact support:**
1. Firebase Console → ? icon → Contact Support
2. Select issue type: Project Recovery
3. Provide:
   - Project ID: relink-app-a96f3
   - Deletion date
   - Business justification
   - Impact description

**Note:** Support CANNOT restore projects deleted > 30 days.

---

## ✅ Prevention Checklist

To avoid accidental deletion:

- [ ] Enable billing alerts
- [ ] Add multiple project owners
- [ ] Enable 2FA on all accounts
- [ ] Setup automated Firestore backups
- [ ] Export users monthly
- [ ] Keep local backup of configs
- [ ] Document all API keys
- [ ] Version control everything
- [ ] Test restore procedure quarterly
- [ ] Have disaster recovery plan documented

---

## 🚨 Emergency Contact Info

**Save these for emergencies:**

**Firebase Console:**
- https://console.firebase.google.com/

**GCP Console:**
- https://console.cloud.google.com/

**Project Recovery:**
- https://console.cloud.google.com/cloud-resource-manager

**Firebase Support:**
- https://firebase.google.com/support

**Your Project Info:**
- Project ID: `relink-app-a96f3`
- Location: `asia-southeast2`
- Package Name: `com.example.relink`

---

## 🎯 Summary

### **If Deleted < 30 Days:**
1. ✅ Go to GCP Cloud Resource Manager
2. ✅ Enable "Show deleted projects"
3. ✅ Find project → Restore
4. ✅ Wait 5-10 minutes
5. ✅ Test everything works

### **If Deleted > 30 Days:**
1. ❌ No recovery possible
2. 🔨 Create new Firebase project
3. 🔨 Re-enable all services
4. 🔨 Update all configurations
5. 🔨 Re-deploy app
6. 😭 Lost all data (unless you have backups)

---

## 💡 Key Takeaway

**PREVENTION > RECOVERY**

Always:
- ✅ Enable automated backups
- ✅ Multiple admin accounts
- ✅ Document everything
- ✅ Version control configs
- ✅ Test restore procedures

**Never:**
- ❌ Delete projects without confirmation
- ❌ Work with single admin account
- ❌ Skip backups
- ❌ Ignore backup testing

---

**Last Updated:** January 2025
**Status:** Emergency Procedures Documented
**Next Review:** Quarterly

---

**Remember: 30 days is your window to restore. After that, it's gone forever!** ⏰
