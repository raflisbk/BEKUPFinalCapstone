# ⚡ Quick Deploy Reference

Fast reference untuk deploy ReLink ke Firebase Hosting.

---

## 🚀 One-Command Deploy

### Windows (Recommended)

```batch
deploy.bat
```

### Manual Command

```bash
flutter build web --release && firebase deploy --only hosting
```

---

## 📋 First Time Setup

```bash
# 1. Install Firebase CLI
npm install -g firebase-tools

# 2. Login to Firebase
firebase login

# 3. Verify project
firebase use relink-app-a96f3
```

---

## 🔄 Regular Deploy (After Code Changes)

```bash
# Build and deploy
flutter build web --release
firebase deploy --only hosting
```

---

## 🌐 Access Your App

After deployment:
- **Primary:** https://relink-app-a96f3.web.app
- **Alternative:** https://relink-app-a96f3.firebaseapp.com

---

## 🧪 Test Locally Before Deploy

```bash
# Build for web
flutter build web --release

# Serve locally
firebase serve --only hosting

# Access: http://localhost:5000
```

---

## 📊 Check Deployment Status

```bash
# View recent deployments
firebase hosting:releases:list

# View hosting sites
firebase hosting:sites:list
```

---

## ⏮️ Rollback (If Needed)

```bash
# Rollback to previous version
firebase hosting:rollback
```

---

## 🔍 Troubleshooting

### Not logged in?
```bash
firebase login
```

### Wrong project?
```bash
firebase use relink-app-a96f3
```

### Build failed?
```bash
flutter clean
flutter pub get
flutter build web --release
```

### Old version showing?
- Clear browser cache (Ctrl+Shift+R)
- Check deployment: `firebase hosting:releases:list`

---

## ✅ Quick Checklist

Before deploying:
- [ ] Code changes committed
- [ ] Tests passing
- [ ] Build successful locally
- [ ] Logged in to Firebase

After deploying:
- [ ] Check web.app URL
- [ ] Test authentication
- [ ] Verify features working
- [ ] Check Firebase Console

---

## 📞 Quick Links

- **Firebase Console:** https://console.firebase.google.com/project/relink-app-a96f3
- **Hosting Dashboard:** https://console.firebase.google.com/project/relink-app-a96f3/hosting
- **Analytics:** https://console.firebase.google.com/project/relink-app-a96f3/analytics

---

**For detailed guide, see:** [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
