# 🗑️ Delete Firebase & GCP Projects - Complete Guide

Complete step-by-step guide untuk menghapus projects lama dan mulai fresh.

---

## ⚠️ IMPORTANT WARNING

**SEBELUM DELETE:**
- ✅ Backup sudah dibuat di `backup_configs/`
- ✅ Yakin tidak ada data penting yang perlu disimpan
- ✅ Users akan hilang (jika ada)
- ✅ Firestore data akan hilang
- ✅ Storage files akan hilang
- ⏰ **Ada 30 hari grace period** untuk restore jika berubah pikiran

**AFTER DELETE:**
- ❌ Semua data HILANG setelah 30 hari
- ❌ Users harus re-register
- ❌ App tidak akan berfungsi sampai setup baru

---

## 📋 Projects yang Akan Dihapus

Berdasarkan Firebase CLI:

```
Projects:
1. relink-app-a96f3 (Project Number: 809876881035)
2. relink-f4647 (Project Number: 888790734949)
```

---

## 🔥 Part 1: Delete Firebase Projects

### **Project 1: Delete relink-app-a96f3**

#### **Step 1.1: Open Firebase Console**
```
https://console.firebase.google.com/project/relink-app-a96f3
```

#### **Step 1.2: Go to Project Settings**
- Click **Gear Icon** ⚙️ (top left)
- Select: **Project Settings**

#### **Step 1.3: Delete Project**
- Scroll to bottom
- Section: **Danger Zone** (red box)
- Click: **Delete project**

#### **Step 1.4: Confirm Deletion**
1. Dialog akan muncul dengan warnings
2. **Type project ID to confirm:** `relink-app-a96f3`
3. Checkboxes:
   - ☑️ I understand that deleting this project will also delete:
   - ☑️ All apps and data
   - ☑️ All integrations
   - ☑️ All billing associations
4. Click: **Delete project**

#### **Step 1.5: Final Confirmation**
- Akan diminta login ulang untuk security
- Enter password
- Confirm deletion

#### **Step 1.6: Wait for Deletion**
- Process takes 10-30 seconds
- You'll be redirected to Firebase Console home
- Project akan hilang dari list

---

### **Project 2: Delete relink-f4647**

**Repeat same steps:**

#### **Step 2.1: Open Firebase Console**
```
https://console.firebase.google.com/project/relink-f4647
```

#### **Step 2.2: Go to Project Settings**
- Gear Icon ⚙️ → Project Settings

#### **Step 2.3: Delete Project**
- Scroll to bottom
- Click: **Delete project**

#### **Step 2.4: Confirm Deletion**
- Type: `relink-f4647`
- Check all boxes
- Click: **Delete project**

#### **Step 2.5: Verify Deletion**
- Check Firebase Console home
- Both projects should be gone
- List should be empty or show other projects only

---

## ☁️ Part 2: Delete GCP Projects

Firebase projects are automatically GCP projects, so they should already be deleted. But let's verify:

### **Step 2.1: Open GCP Console**
```
https://console.cloud.google.com/
```

### **Step 2.2: Check Project List**
- Click project dropdown (top bar)
- Look for:
  - `relink-app-a96f3`
  - `relink-f4647`

### **Step 2.3: If Projects Still Show**

**Enable "Show Deleted Projects":**
- Project dropdown → Manage resources
- Or go to: https://console.cloud.google.com/cloud-resource-manager
- Enable: ☑️ **Include deleted projects**
- You should see projects with "Pending deletion" status

**If Projects Still Active (Not Deleted):**

For each project:

1. **Select Project**
   - Click on project name

2. **Go to IAM & Admin**
   - Sidebar → IAM & Admin → Settings
   - Or: https://console.cloud.google.com/iam-admin/settings

3. **Shut Down Project**
   - Scroll to bottom
   - Section: **Shut down**
   - Click: **SHUT DOWN**

4. **Confirm Shut Down**
   - Type project ID
   - Click: **SHUT DOWN**

### **Step 2.4: Verify All Deleted**

1. **Go to Project Dropdown**
   - Should show no ReLink projects
   - Or show as "Pending deletion"

2. **Check Cloud Resource Manager**
   ```
   https://console.cloud.google.com/cloud-resource-manager
   ```
   - Enable: ☑️ Include deleted projects
   - Both projects should show status: **Pending deletion**
   - Delete date: 30 days from now

---

## 🧹 Part 3: Clean Up Billing

### **Step 3.1: Check Billing Accounts**

```
https://console.cloud.google.com/billing
```

1. **My Billing Accounts**
   - Check if any billing accounts exist

2. **For Each Billing Account:**
   - Click account name
   - Go to: **My Projects**
   - Verify no "ReLink" projects linked
   - If linked, they'll auto-unlink when deleted

### **Step 3.2: Check for Active Charges**

- Go to: **Billing** → **Reports**
- Check last month charges
- Should be $0 or minimal (within free tier)

### **Step 3.3: Cancel Billing (Optional)**

**Only if you don't plan to use Google Cloud again:**

1. Go to billing account
2. Click: **⋮** (three dots)
3. Select: **Close billing account**
4. Confirm

**⚠️ Warning:** This will prevent creating new projects until you re-enable billing.

**Recommended:** Keep billing account active for new project.

---

## 🔑 Part 4: Revoke API Keys (Security)

### **Step 4.1: List API Keys**

For each OLD project, revoke API keys to prevent unauthorized use:

```
https://console.cloud.google.com/apis/credentials
```

**If you can still access old projects:**

1. Select old project (relink-app-a96f3 or relink-f4647)
2. Go to: **APIs & Services** → **Credentials**
3. For each API key:
   - Click **⋮** (three dots)
   - Select: **Delete**
   - Confirm deletion

**If projects already deleted:**
- API keys automatically invalidated
- No action needed ✅

---

## 📱 Part 5: Verify Cleanup Complete

### **Checklist:**

**Firebase Console:**
- [ ] Open: https://console.firebase.google.com/
- [ ] No ReLink projects visible
- [ ] List is empty or shows other projects only

**GCP Console:**
- [ ] Open: https://console.cloud.google.com/
- [ ] Project dropdown shows no ReLink projects
- [ ] Or shows "Pending deletion" status

**Local Files:**
- [ ] `android/app/google-services.json` - Removed ✅
- [ ] `.firebaserc` - Contains template only ✅
- [ ] `build/` - Removed ✅
- [ ] Backup in `backup_configs/` - Exists ✅

**Firebase CLI:**
```bash
firebase projects:list
```
- [ ] No ReLink projects in list
- [ ] Or shows error (no projects found)

---

## 🆕 Part 6: Start Fresh Setup

Now you're ready to create everything from scratch!

### **Follow: FRESH_START_GUIDE.md**

**Complete workflow:**

```
1. Create NEW Firebase Project
   ↓
2. Add Android App
   ↓
3. Download google-services.json
   ↓
4. Setup GCP (Enable Billing)
   ↓
5. Enable APIs (Maps, Places, Gemini)
   ↓
6. Create NEW API Keys
   ↓
7. Enable Firebase Services
   - Authentication
   - Firestore
   - (Skip Storage - use Cloudinary!)
   ↓
8. Setup Cloudinary (FREE 25 GB)
   ↓
9. Configure .env file
   ↓
10. Test everything
```

**Estimated time:** 75 minutes

**Cost:** $0 (all free tier) ✅

---

## ⏰ Recovery Window (30 Days)

### **If You Change Your Mind:**

Projects can be restored within 30 days!

**How to Restore:**

1. **Go to GCP Cloud Resource Manager**
   ```
   https://console.cloud.google.com/cloud-resource-manager
   ```

2. **Enable "Include deleted projects"**
   - Checkbox at top

3. **Find Your Project**
   - Look for: relink-app-a96f3 or relink-f4647
   - Status: **Pending deletion**

4. **Restore Project**
   - Click **⋮** (three dots)
   - Select: **Restore**
   - Confirm restoration

5. **Wait 5-10 Minutes**
   - Project will be active again
   - All data restored

**After 30 days:** ❌ Permanent deletion, no recovery possible!

---

## 📊 What Gets Deleted

### **Permanently Lost (After 30 days):**

**Firebase:**
- ❌ All users (authentication data)
- ❌ Firestore database (all collections)
- ❌ Storage files (all images/documents)
- ❌ Hosting deployments
- ❌ Cloud Functions (if any)
- ❌ Analytics data
- ❌ Crash reports

**GCP:**
- ❌ API keys
- ❌ Service accounts
- ❌ Billing history
- ❌ API usage statistics

**App Impact:**
- ❌ App will crash on launch (no Firebase connection)
- ❌ Users can't login
- ❌ No data will load
- ❌ Need fresh setup to work again

---

## 🆘 Troubleshooting

### **Problem: Can't find "Delete project" button**

**Solution:**
- You must be **Owner** of project
- Check your role: Project Settings → Users and permissions
- If not Owner, ask project creator to add you as Owner

### **Problem: "This project has active resources"**

**Solution:**
1. Go to each Firebase service:
   - Firestore: Delete database
   - Storage: Empty all buckets
   - Functions: Delete all functions
2. Wait 5 minutes
3. Try delete again

### **Problem: "Project is part of an organization"**

**Solution:**
- Contact organization admin
- They need to approve deletion
- Or remove project from organization first

### **Problem: "Billing account has charges"**

**Solution:**
- Check billing: https://console.cloud.google.com/billing
- Pay any outstanding charges
- Then try delete again

### **Problem: Project still shows after deletion**

**Solution:**
- Wait 5-10 minutes (deletion takes time)
- Refresh browser
- Clear browser cache
- Check "Pending deletion" status in GCP

---

## ✅ Final Verification Script

Run this to verify everything is clean:

```bash
# Check local files
echo "=== Local Files ==="
ls android/app/google-services.json 2>/dev/null && echo "❌ google-services.json still exists" || echo "✅ google-services.json removed"
cat .firebaserc | grep "YOUR_NEW_PROJECT_ID_HERE" && echo "✅ .firebaserc is template" || echo "❌ .firebaserc not updated"

# Check Firebase projects
echo ""
echo "=== Firebase Projects ==="
firebase projects:list

# If shows no projects or only other projects = ✅ Success
```

Expected output:
```
=== Local Files ===
✅ google-services.json removed
✅ .firebaserc is template

=== Firebase Projects ===
No projects found (or other projects only)
```

---

## 🎯 Summary

### **What You Did:**

1. ✅ Cleaned local Firebase configs
2. ✅ Backed up old files
3. 🔜 Will delete relink-app-a96f3 from Firebase
4. 🔜 Will delete relink-f4647 from Firebase
5. 🔜 Will verify GCP projects deleted
6. 🔜 Will revoke old API keys

### **What's Next:**

1. **Delete projects in Firebase Console** (5 min)
   - relink-app-a96f3
   - relink-f4647

2. **Verify deletion in GCP Console** (2 min)
   - Check projects are "Pending deletion"

3. **Follow FRESH_START_GUIDE.md** (75 min)
   - Create new project
   - Setup all services
   - Use Cloudinary for storage (FREE)

### **Recovery Window:**

- ⏰ **30 days** to restore if needed
- After 30 days: ❌ Permanent deletion

### **Cost:**

```
Old setup: $30-360/year (Firebase Storage)
New setup: $0/year (Cloudinary) ✅

SAVE: $30-360/year!
```

---

## 📚 Next Steps

After deleting projects:

1. **Read FRESH_START_GUIDE.md** (complete setup guide)
2. **Read STORAGE_ALTERNATIVES.md** (why use Cloudinary)
3. **Create new Firebase project** (follow guide)
4. **Setup Cloudinary** (25 GB free!)
5. **Build and test** (verify everything works)

**Time to complete fresh setup:** ~75 minutes
**Cost:** $0 (all free tier)

---

## 🎊 Ready for Fresh Start!

Your local config is cleaned! ✅

**Now:**
1. Go to Firebase Console
2. Delete both projects
3. Verify in GCP
4. Follow FRESH_START_GUIDE.md

**Good luck with your fresh start!** 🚀

---

**Last Updated:** January 2025
**Status:** Local cleanup complete ✅
**Next:** Delete projects in Firebase Console
