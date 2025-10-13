# 🚀 ReLink - Firebase Hosting Deployment Guide

Complete step-by-step guide untuk deploy ReLink web app ke Firebase Hosting.

---

## 📋 Prerequisites

Sebelum deploy, pastikan Anda sudah:

- ✅ Firebase CLI installed: `firebase --version`
- ✅ Logged in to Firebase: `firebase login`
- ✅ Project configured: `.firebaserc` dan `firebase.json` exist
- ✅ Flutter web build working: `flutter build web`

---

## 🔐 Step 1: Login to Firebase

### First Time Setup

```bash
# Login to Firebase
firebase login

# Browser akan terbuka
# Login dengan Google Account yang memiliki akses ke project relink-app-a96f3
# Allow Firebase CLI access
```

### Verify Login

```bash
# Check if logged in
firebase projects:list

# You should see: relink-app-a96f3
```

### Select Project

```bash
# Use the correct project
firebase use relink-app-a96f3

# Or set as default
firebase use --add
# Select: relink-app-a96f3
# Alias: default
```

---

## 🏗️ Step 2: Build Flutter Web App

### Clean Build (Recommended)

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for web (release mode)
flutter build web --release
```

### Build Output

Build output akan berada di: `build/web/`

Files yang akan di-deploy:
```
build/web/
├── index.html
├── flutter_bootstrap.js
├── assets/
├── canvaskit/
├── icons/
└── ...
```

### Verify Build

```bash
# Check build directory
ls build/web

# You should see:
# - index.html
# - flutter_bootstrap.js
# - assets/
# - icons/
```

---

## 🚀 Step 3: Deploy to Firebase Hosting

### Deploy Hosting

```bash
# Deploy only hosting
firebase deploy --only hosting
```

### Deploy Output

Anda akan melihat:
```
=== Deploying to 'relink-app-a96f3'...

i  deploying hosting
i  hosting[relink-app-a96f3]: beginning deploy...
i  hosting[relink-app-a96f3]: found X files in build/web
✔  hosting[relink-app-a96f3]: file upload complete
i  hosting[relink-app-a96f3]: finalizing version...
✔  hosting[relink-app-a96f3]: version finalized
i  hosting[relink-app-a96f3]: releasing new version...
✔  hosting[relink-app-a96f3]: release complete

✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/relink-app-a96f3/overview
Hosting URL: https://relink-app-a96f3.web.app
```

### Access Your Web App

Setelah deploy, akses app di:
- **Primary URL:** https://relink-app-a96f3.web.app
- **Alternative URL:** https://relink-app-a96f3.firebaseapp.com

---

## ⚡ Quick Deployment (Using Script)

### Windows

Gunakan deployment script yang sudah disediakan:

```batch
# Run deployment script
deploy.bat
```

Script akan otomatis:
1. Clean build
2. Get dependencies
3. Build web (release)
4. Deploy to Firebase Hosting
5. Show deployment URLs

### Linux/Mac

Buat script serupa atau gunakan commands manual:

```bash
# One-line deployment
flutter clean && flutter pub get && flutter build web --release && firebase deploy --only hosting
```

---

## 🔄 Update Deployment

### Deploy Update

Setiap kali ada perubahan code:

```bash
# Build new version
flutter build web --release

# Deploy update
firebase deploy --only hosting
```

### Version History

Firebase Hosting menyimpan version history:

```bash
# View hosting history
firebase hosting:releases:list

# Rollback to previous version
firebase hosting:rollback
```

---

## 🔧 Advanced Deployment Options

### Deploy Preview Channel

Test deployment tanpa affect production:

```bash
# Create preview channel
firebase hosting:channel:deploy preview

# Access preview URL
# https://relink-app-a96f3--preview-XXXX.web.app
```

### Deploy with Message

```bash
# Deploy with version message
firebase deploy --only hosting -m "Version 1.0.0 - Initial release"
```

### Deploy Specific Target

Jika ada multiple hosting sites:

```bash
# Deploy to specific target
firebase deploy --only hosting:relink-app-a96f3
```

---

## 📊 Post-Deployment Checklist

### 1. Test Web App

- [ ] Open https://relink-app-a96f3.web.app
- [ ] Test authentication (email/password, Google)
- [ ] Test Firestore read/write
- [ ] Test image upload to Storage
- [ ] Test on multiple browsers (Chrome, Firefox, Safari, Edge)
- [ ] Test on mobile browsers
- [ ] Test PWA installation

### 2. Verify Firebase Console

- [ ] Check hosting metrics
- [ ] Verify analytics events
- [ ] Check error logs in Firebase Console

### 3. Performance Testing

```bash
# Run Lighthouse audit
# Chrome DevTools → Lighthouse → Generate report

# Or use CLI
npm install -g lighthouse
lighthouse https://relink-app-a96f3.web.app
```

### 4. Security Check

- [ ] API keys restricted properly
- [ ] Authorized domains configured
- [ ] Firestore rules in production mode
- [ ] Storage rules configured correctly

---

## 🐛 Troubleshooting

### Problem: "Firebase command not found"

**Solution:**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Verify installation
firebase --version
```

### Problem: "Not logged in"

**Solution:**
```bash
# Login to Firebase
firebase login

# If login fails in browser, use token
firebase login:ci
```

### Problem: "Permission denied"

**Solution:**
```bash
# Check if you have access to project
firebase projects:list

# If not listed, ask project owner to add you:
# Firebase Console → Project Settings → Users and permissions
```

### Problem: "Build failed"

**Solution:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build web --release --verbose

# Check for errors in output
```

### Problem: "Deploy failed - quota exceeded"

**Solution:**
- Check Firebase Hosting quota in Firebase Console
- Free tier: 10 GB/month storage, 360 MB/day transfer
- Upgrade to Blaze plan if needed

### Problem: "404 errors after deployment"

**Solution:**
- Check `firebase.json` rewrites configuration
- Should have:
  ```json
  "rewrites": [
    {
      "source": "**",
      "destination": "/index.html"
    }
  ]
  ```
- Redeploy after fixing

### Problem: "Old version still showing"

**Solution:**
```bash
# Clear browser cache
# Or force reload: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)

# Check deployment version
firebase hosting:releases:list

# If wrong version deployed, rollback
firebase hosting:rollback
```

---

## 📈 Monitoring & Analytics

### View Hosting Metrics

```bash
# List recent releases
firebase hosting:releases:list

# View hosting sites
firebase hosting:sites:list
```

### Firebase Console

Monitor deployment:
1. Go to https://console.firebase.google.com/
2. Select project: relink-app-a96f3
3. Navigate to **Hosting**
4. View:
   - Release history
   - Traffic metrics
   - Request counts
   - Bandwidth usage

### Google Analytics

Track user behavior:
1. Firebase Console → Analytics
2. View:
   - Active users
   - Page views
   - User retention
   - Custom events

---

## 🔒 Production Deployment Best Practices

### Before Production Deploy:

1. **Test Locally First**
   ```bash
   # Serve locally to test
   firebase serve --only hosting
   # Access: http://localhost:5000
   ```

2. **Use Preview Channels**
   ```bash
   # Test on preview channel first
   firebase hosting:channel:deploy staging
   ```

3. **Version Your Releases**
   ```bash
   # Deploy with version tag
   firebase deploy --only hosting -m "v1.0.0"
   ```

4. **Backup Current Version**
   - Firebase keeps version history automatically
   - You can rollback anytime

5. **Monitor After Deploy**
   - Check Firebase Console for errors
   - Monitor Analytics for user behavior
   - Check Performance metrics

---

## 🌐 Custom Domain Setup (Optional)

### Add Custom Domain

1. **Firebase Console → Hosting → Add custom domain**
2. **Enter your domain:** example.com
3. **Verify ownership:** Add TXT record to DNS
4. **Add A/CNAME records** provided by Firebase
5. **Wait for SSL provisioning** (can take 24 hours)

### Example DNS Configuration

```
# Root domain (example.com)
A     @     151.101.1.195
A     @     151.101.65.195

# Subdomain (www.example.com)
CNAME www   relink-app-a96f3.web.app
```

---

## 📝 Deployment Commands Reference

### Essential Commands

```bash
# Login
firebase login

# List projects
firebase projects:list

# Use project
firebase use relink-app-a96f3

# Build web
flutter build web --release

# Deploy
firebase deploy --only hosting

# Deploy with message
firebase deploy --only hosting -m "Version 1.0"

# Serve locally
firebase serve --only hosting

# View releases
firebase hosting:releases:list

# Rollback
firebase hosting:rollback
```

### Preview Channels

```bash
# Create preview
firebase hosting:channel:deploy CHANNEL_NAME

# List channels
firebase hosting:channel:list

# Delete channel
firebase hosting:channel:delete CHANNEL_NAME
```

---

## ✅ Final Checklist

Before considering deployment complete:

### Technical
- [ ] Flutter web build successful (no errors)
- [ ] Firebase CLI installed and logged in
- [ ] firebase.json configured correctly
- [ ] .firebaserc has correct project ID
- [ ] Deployment completed successfully
- [ ] Both URLs accessible (web.app and firebaseapp.com)

### Testing
- [ ] App loads correctly on web
- [ ] Authentication working
- [ ] Firestore read/write working
- [ ] Image upload working
- [ ] Tested on Chrome
- [ ] Tested on Firefox
- [ ] Tested on Safari
- [ ] Tested on mobile browsers
- [ ] PWA installable

### Security
- [ ] API keys restricted
- [ ] Authorized domains configured
- [ ] Firestore rules in production mode
- [ ] Storage rules configured
- [ ] CORS configured if needed

### Performance
- [ ] Lighthouse score > 90
- [ ] First Contentful Paint < 2s
- [ ] Time to Interactive < 5s
- [ ] Images optimized
- [ ] Caching headers configured

### Monitoring
- [ ] Firebase Analytics enabled
- [ ] Error logging configured
- [ ] Performance monitoring active
- [ ] Hosting metrics accessible

---

## 🎯 Success!

Jika semua checklist ✅, deployment Anda sukses! 🎉

**Your ReLink web app is now live at:**
- https://relink-app-a96f3.web.app
- https://relink-app-a96f3.firebaseapp.com

**Next Steps:**
1. Share URLs dengan team atau users
2. Monitor analytics dan performance
3. Iterate based on user feedback
4. Deploy updates regularly

---

## 📞 Support

Jika ada masalah:
1. Check Firebase Status: https://status.firebase.google.com/
2. Firebase Documentation: https://firebase.google.com/docs/hosting
3. Flutter Web Docs: https://docs.flutter.dev/platform-integration/web
4. Community Support: Stack Overflow (tag: firebase-hosting)

---

**Last Updated:** January 2025
**Firebase Hosting Version:** Latest
**Flutter Version:** 3.9.2+

Happy Deploying! 🚀
