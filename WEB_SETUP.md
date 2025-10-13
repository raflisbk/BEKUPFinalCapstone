# 🌐 ReLink - Firebase Web Setup Guide

Complete guide untuk setup Firebase Web App untuk ReLink.

---

## 📋 Overview

ReLink sekarang support **Web App** dengan Firebase Web SDK. Web app dapat diakses melalui browser dan memiliki semua fitur yang sama dengan mobile app.

### Web App Details

- **Firebase Project:** relink-app-a96f3
- **Auth Domain:** relink-app-a96f3.firebaseapp.com
- **Hosting URL:** relink-app-a96f3.web.app (setelah deploy)

---

## 🔧 Setup Firebase Web SDK

### 1. Firebase Configuration

Firebase Web SDK sudah dikonfigurasi di `web/index.html` menggunakan CDN:

```html
<script type="module">
  import { initializeApp } from 'https://www.gstatic.com/firebasejs/11.1.0/firebase-app.js';
  import { getAnalytics } from 'https://www.gstatic.com/firebasejs/11.1.0/firebase-analytics.js';
  // ... more imports

  const firebaseConfig = {
    apiKey: "AIzaSyBugpuZTTIJKRBLejc1Tb9o7BMdIuEaKmM",
    authDomain: "relink-app-a96f3.firebaseapp.com",
    projectId: "relink-app-a96f3",
    storageBucket: "relink-app-a96f3.firebasestorage.app",
    messagingSenderId: "809876881035",
    appId: "1:809876881035:web:f2c5f579fca42bc8955e8e",
    measurementId: "G-VYJGMVWC92"
  };

  // Initialize Firebase
  const app = initializeApp(firebaseConfig);
</script>
```

### 2. Environment Variables

Update `.env` file dengan web configuration:

```env
# Firebase Web Configuration
FIREBASE_WEB_API_KEY=AIzaSyBugpuZTTIJKRBLejc1Tb9o7BMdIuEaKmM
FIREBASE_WEB_APP_ID=1:809876881035:web:f2c5f579fca42bc8955e8e
FIREBASE_WEB_MESSAGING_SENDER_ID=809876881035
FIREBASE_WEB_PROJECT_ID=relink-app-a96f3
FIREBASE_WEB_AUTH_DOMAIN=relink-app-a96f3.firebaseapp.com
FIREBASE_WEB_STORAGE_BUCKET=relink-app-a96f3.firebasestorage.app
FIREBASE_WEB_MEASUREMENT_ID=G-VYJGMVWC92
```

---

## 📦 Files Created

### 1. `web/index.html`
- Updated dengan Firebase Web SDK
- Menggunakan CDN dari gstatic.com
- Firebase initialized dan available globally

### 2. `web/firebase-config.js`
- Module JavaScript untuk Firebase configuration
- Export Firebase services (auth, db, storage, analytics)
- Dapat digunakan jika Anda butuh import manual

### 3. `web/firebase-messaging-sw.js`
- Service Worker untuk Firebase Cloud Messaging
- Handle background notifications
- Handle notification clicks

---

## 🚀 Running Web App

### Development Mode

```bash
# Run Flutter web app
flutter run -d chrome

# Or run on specific port
flutter run -d chrome --web-port 8080

# Run on all devices (mobile simulator + web)
flutter run -d all
```

### Build for Production

```bash
# Build web app
flutter build web

# Output will be in: build/web/
```

---

## 🌐 Deploy to Firebase Hosting

### Step 1: Install Firebase CLI

```bash
npm install -g firebase-tools
```

### Step 2: Login to Firebase

```bash
firebase login
```

### Step 3: Initialize Firebase Hosting

```bash
firebase init hosting
```

Configuration:
- **Project:** Select `relink-app-a96f3`
- **Public directory:** `build/web`
- **Single-page app:** Yes
- **Automatic builds with GitHub:** No (optional)

### Step 4: Build Flutter Web

```bash
flutter build web --release
```

### Step 5: Deploy to Firebase Hosting

```bash
firebase deploy --only hosting
```

### Step 6: Access Your Web App

After deployment, your app will be available at:
- **Production:** https://relink-app-a96f3.web.app
- **Alternative:** https://relink-app-a96f3.firebaseapp.com

---

## 🔐 Security Configuration

### 1. Authorized Domains

Di Firebase Console, add authorized domains:

1. Go to **Authentication** → **Settings** → **Authorized domains**
2. Add domains:
   - `localhost` (for development)
   - `relink-app-a96f3.web.app`
   - `relink-app-a96f3.firebaseapp.com`
   - Your custom domain (if any)

### 2. CORS Configuration for Storage

If you have CORS issues with Firebase Storage, add CORS rules:

Create `cors.json`:
```json
[
  {
    "origin": ["*"],
    "method": ["GET", "POST", "PUT", "DELETE"],
    "maxAgeSeconds": 3600
  }
]
```

Apply CORS:
```bash
gsutil cors set cors.json gs://relink-app-a96f3.firebasestorage.app
```

### 3. API Key Restrictions

⚠️ **IMPORTANT:** Restrict your Web API key!

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services** → **Credentials**
3. Find Web API key: `AIzaSyBugpuZTTIJKRBLejc1Tb9o7BMdIuEaKmM`
4. Click Edit
5. **Application restrictions:**
   - Select **HTTP referrers (web sites)**
   - Add referrers:
     - `http://localhost:*`
     - `https://relink-app-a96f3.web.app/*`
     - `https://relink-app-a96f3.firebaseapp.com/*`
6. **API restrictions:**
   - Select **Restrict key**
   - Enable:
     - Firebase Authentication API
     - Cloud Firestore API
     - Firebase Storage API
     - Google Analytics API
     - Cloud Messaging API
7. Click **Save**

---

## 🔔 Push Notifications Setup (Web)

### 1. Generate VAPID Key

```bash
# Using Firebase Console
# Go to Project Settings → Cloud Messaging → Web configuration
# Click "Generate key pair" under Web Push certificates
```

### 2. Add VAPID Key to Code

Update your Firebase messaging initialization:

```javascript
import { getMessaging, getToken } from "firebase/messaging";

const messaging = getMessaging(app);

// Get FCM token
getToken(messaging, {
  vapidKey: 'YOUR_VAPID_KEY_HERE'
}).then((currentToken) => {
  if (currentToken) {
    console.log('FCM Token:', currentToken);
    // Send token to your server
  }
}).catch((err) => {
  console.log('Error getting token:', err);
});
```

### 3. Request Notification Permission

```javascript
// Request permission for notifications
Notification.requestPermission().then((permission) => {
  if (permission === 'granted') {
    console.log('Notification permission granted.');
    // Get FCM token
  }
});
```

---

## 🧪 Testing Web App

### 1. Test Authentication

- Email/Password login
- Google Sign-In
- Anonymous login
- Test on different browsers (Chrome, Firefox, Safari, Edge)

### 2. Test Firestore

- Read/write data
- Real-time listeners
- Offline persistence

### 3. Test Storage

- Upload images
- Download files
- Check CORS configuration

### 4. Test Notifications

- Request permission
- Receive foreground notifications
- Receive background notifications (with service worker)

---

## 🛠️ Troubleshooting

### Problem: Firebase not initialized

**Solution:**
- Check browser console for errors
- Verify Firebase config in `index.html`
- Check internet connection
- Clear browser cache

### Problem: CORS errors when uploading images

**Solution:**
```bash
# Set CORS for Firebase Storage
gsutil cors set cors.json gs://relink-app-a96f3.firebasestorage.app
```

### Problem: Google Sign-In not working

**Solutions:**
1. Check authorized domains in Firebase Console
2. Verify OAuth client ID
3. Check if third-party cookies enabled in browser
4. Test in incognito mode

### Problem: Service Worker not registering

**Solutions:**
1. Check if served over HTTPS (or localhost)
2. Verify service worker file path
3. Check browser console for errors
4. Clear service worker cache:
   ```javascript
   navigator.serviceWorker.getRegistrations().then((registrations) => {
     registrations.forEach(r => r.unregister());
   });
   ```

### Problem: Build fails for web

**Solutions:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build web --release

# Check for web-incompatible packages
flutter pub outdated
```

---

## 📊 Performance Optimization

### 1. Enable Caching

Firebase SDK automatically caches data. Enable offline persistence:

```javascript
import { enableIndexedDbPersistence } from "firebase/firestore";

enableIndexedDbPersistence(db).catch((err) => {
  if (err.code == 'failed-precondition') {
    console.log('Multiple tabs open');
  } else if (err.code == 'unimplemented') {
    console.log('Browser not supported');
  }
});
```

### 2. Code Splitting

Flutter web automatically code-splits. Optimize further:

```bash
# Build with specific options
flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=true
```

### 3. Lazy Loading Images

```dart
// Use cached_network_image for web
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

---

## 📱 Progressive Web App (PWA)

### 1. Update manifest.json

File `web/manifest.json` already configured:

```json
{
  "name": "ReLink",
  "short_name": "ReLink",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#FFFFFF",
  "theme_color": "#000000",
  "description": "Travel Companion & Local Guide App",
  "orientation": "portrait-primary",
  "prefer_related_applications": false,
  "icons": [...]
}
```

### 2. Install Prompt

Users can install ReLink as PWA:
- Chrome: "Install App" button in address bar
- Mobile: "Add to Home Screen"
- Desktop: Install icon in browser toolbar

---

## 🌍 Multi-Platform Support

ReLink now supports:
- ✅ **Android** (Firebase SDK via google-services.json)
- ✅ **Web** (Firebase Web SDK via CDN)
- ⚠️ **iOS** (Configure GoogleService-Info.plist)
- ⚠️ **Windows** (Configure firebase_options.dart)
- ⚠️ **macOS** (Configure firebase_options.dart)

---

## 📚 Resources

### Documentation
- [Firebase Web SDK](https://firebase.google.com/docs/web/setup)
- [Flutter Web](https://docs.flutter.dev/platform-integration/web)
- [Firebase Hosting](https://firebase.google.com/docs/hosting)
- [PWA Guide](https://web.dev/progressive-web-apps/)

### Tools
- [Firebase Console](https://console.firebase.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Lighthouse](https://developers.google.com/web/tools/lighthouse) - Web performance testing

---

## ✅ Checklist

Before deploying to production:

- [ ] Firebase Web SDK configured in index.html
- [ ] Environment variables updated with web config
- [ ] Authorized domains added to Firebase
- [ ] API key restricted for web
- [ ] CORS configured for Storage
- [ ] Service worker registered for notifications
- [ ] VAPID key configured for FCM
- [ ] manifest.json configured for PWA
- [ ] Tested authentication on web
- [ ] Tested Firestore read/write
- [ ] Tested image upload to Storage
- [ ] Tested on multiple browsers
- [ ] Performance tested with Lighthouse
- [ ] Built with --release flag
- [ ] Deployed to Firebase Hosting

---

## 🚀 Next Steps

1. **Test Web App Locally:**
   ```bash
   flutter run -d chrome
   ```

2. **Build for Production:**
   ```bash
   flutter build web --release
   ```

3. **Deploy to Firebase Hosting:**
   ```bash
   firebase deploy --only hosting
   ```

4. **Monitor Performance:**
   - Firebase Console → Performance
   - Google Analytics
   - Chrome DevTools

5. **Setup CI/CD:**
   - GitHub Actions for automatic deployment
   - Firebase Hosting preview channels for PR reviews

---

**Setup Complete! 🎉**

Your ReLink web app is now configured and ready to deploy!

**Live URL (after deployment):**
- https://relink-app-a96f3.web.app
- https://relink-app-a96f3.firebaseapp.com

---

**Last Updated:** January 2025
**Firebase SDK Version:** 11.1.0
**Flutter Version:** 3.9.2+
