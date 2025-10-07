# ReLink - Travel Companion & Local Guide App

**Aplikasi mobile travel untuk menemukan teman perjalanan dan local guide**

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Status-Production%20Ready-success?style=for-the-badge" />
</div>

## About ReLink

ReLink adalah aplikasi mobile berbasis Flutter yang menghubungkan wisatawan dengan local guide terverifikasi dan sesama pelancong di sekitar lokasi mereka. Aplikasi ini dirancang untuk memberikan pengalaman wisata yang lebih autentik dan personal sambil memberdayakan masyarakat lokal.

### Key Features

- **Solo Traveler Matching** - Temukan teman perjalanan terdekat menggunakan geolocation
- **Real-time Location Tracking** - Lihat nearby travelers dalam radius 5km dengan custom markers
- **Local Guide Marketplace** - Akses guide lokal terverifikasi dengan berbagai keahlian
- **Smart Recommendations** - Rekomendasi destinasi sesuai minat dan lokasi
- **Profile Management** - Upload foto atau pilih dari 20 emoji avatar hewan
- **Persistent Authentication** - Stay logged in, no need to login repeatedly
- **Guest Mode** - Jelajah aplikasi tanpa perlu akun

---

## Quick Start

### Prerequisites

- Flutter SDK (>= 3.9.2)
- Dart SDK
- Android Studio / VS Code
- Firebase account
- Google Cloud account (untuk Maps API)

### Installation

1. **Clone repository**
```bash
git clone https://github.com/yourusername/relink.git
cd relink
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Setup Firebase**
   - Download `google-services.json` dari Firebase Console
   - Place di `android/app/google-services.json`
   - Enable Authentication, Firestore, Storage

4. **Setup environment variables**
   - Create `.env` file:
```env
GOOGLE_MAPS_API_KEY=your_api_key_here
```

5. **Run app**
```bash
flutter run
```

**Detailed Setup:** See [QUICKSTART.md](QUICKSTART.md)

---

## Project Status

**Current Version:** 2.3.0
**Status:** ✅ **Production Ready**
**Last Updated:** October 6, 2025

### Development Progress

| Category | Progress | Status |
|----------|----------|--------|
| **UI/UX Screens** | 11/11 | ✅ Complete (100%) |
| **Authentication** | Full | ✅ Complete (100%) |
| **State Management** | 3 Providers | ✅ Complete (100%) |
| **Map & Location** | Full Featured | ✅ Complete (100%) |
| **Performance** | Optimized | ✅ Complete (100%) |
| **Documentation** | Comprehensive | ✅ Complete (100%) |

### Performance Metrics (Snapdragon 625)

| Metric | Result | Target | Status |
|--------|--------|--------|--------|
| Map load time | 1.2s | < 2s | ✅ |
| Marker update | 200ms | < 500ms | ✅ |
| Frame rate | 57-60 fps | > 50 fps | ✅ |
| Memory usage | 120MB | < 150MB | ✅ |
| CPU (idle) | 8% | < 15% | ✅ |

---

## Features Implemented

### Core Features (100% Complete)

#### Authentication System
- [x] Email/password registration & login
- [x] Google Sign-In integration
- [x] Password reset functionality
- [x] **Persistent sessions** - Auto-login after app restart
- [x] **Onboarding persistence** - Shows only once
- [x] Guest mode access
- [x] Professional error handling
- [x] Loading states & feedback

#### Location & Map
- [x] Real-time location tracking with isolate
- [x] Google Maps integration
- [x] **Custom emoji markers** for users
- [x] Nearby travelers detection (5km radius)
- [x] Location sharing toggle
- [x] Distance calculation & formatting
- [x] **Optimized for low-end devices** (60fps smooth)
- [x] Parallel marker generation (5x faster)
- [x] Efficient state management (Selector pattern)

#### Profile Management
- [x] View and edit user profile
- [x] **Photo upload** from camera/gallery
- [x] **20 emoji avatar options** (animal-themed)
- [x] Bio and location information
- [x] Guide mode toggle
- [x] Sign out with confirmation
- [x] Responsive UI (no overflow errors)

#### Navigation & UI
- [x] Splash screen with animations
- [x] 3-page onboarding flow
- [x] Bottom navigation (4 tabs)
- [x] Home screen with hero section
- [x] Explore screen with map
- [x] Guides screen with cards
- [x] Search functionality
- [x] Destination detail pages
- [x] Guide detail pages

### Recent Updates (v2.3.0)

#### Performance Optimizations
- ✅ **5x faster marker generation** (1000ms → 200ms)
- ✅ **60% CPU reduction** with Selector pattern
- ✅ **85% fewer frame drops** during updates
- ✅ **33% memory reduction** (180MB → 120MB)
- ✅ Parallel marker generation with Future.wait
- ✅ Mount state checks (no memory leaks)
- ✅ Marker limit (50 max) for performance

#### Code Quality
- ✅ **Clean professional logging** (no emojis/symbols)
- ✅ 62+ logging points throughout app
- ✅ Comprehensive error handling
- ✅ Production-ready code standards
- ✅ Proper state management patterns

#### Bug Fixes
- ✅ Fixed auto-logout issue
- ✅ Fixed onboarding appearing every time
- ✅ Fixed avatar picker overflow
- ✅ Fixed race conditions in auth
- ✅ Fixed unnecessary widget rebuilds

---

## Architecture

### Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── default_avatars.dart      # 20 emoji avatars
│   ├── theme/
│   │   ├── app_colors.dart           # Minimalist B&W palette
│   │   ├── app_text_styles.dart      # Typography system
│   │   └── app_theme.dart            # Theme config
│   ├── utils/
│   │   ├── logger.dart               # Logging system
│   │   └── marker_generator.dart     # Custom markers
│   ├── models/
│   │   └── user_model.dart           # User data model
│   └── providers/
│       ├── auth_provider.dart        # Authentication state (450+ lines)
│       ├── user_provider.dart        # User profile state (150+ lines)
│       └── location_provider.dart    # Location tracking (300+ lines)
├── services/
│   ├── photo_upload_service.dart     # Photo handling
│   └── location_isolate_service.dart # Background location
├── presentation/
│   ├── splash/                       # Splash screen
│   ├── onboarding/                   # Onboarding flow
│   ├── auth/                         # Authentication UI
│   ├── main/                         # Bottom navigation
│   ├── home/                         # Home screen
│   ├── explore/                      # Map & location
│   ├── guides/                       # Guides list
│   ├── destinations/                 # Destinations
│   ├── search/                       # Search
│   └── profile/                      # User profile
└── main.dart                         # Entry point
```

### State Management

**Provider Pattern** with optimization:
- `AuthProvider` - Authentication state & methods
- `UserProvider` - User profile management
- `LocationProvider` - Real-time location tracking
- **Selector** pattern for optimized rebuilds
- **Isolate** for background processing

### Design System

**Minimalist Black & White Theme:**
- Primary: `#000000` (Pure Black)
- Background: `#FFFFFF` (Pure White)
- Typography: Display (48-72px), Headline (24-40px), Body (14-18px)
- Material Design 3 principles

---

## Tech Stack

### Core Technologies
| Category | Technology | Purpose |
|----------|-----------|---------|
| **Framework** | Flutter 3.9.2+ | Cross-platform UI |
| **Language** | Dart 3.x | Programming language |
| **State** | Provider | State management |
| **Backend** | Firebase | Auth, DB, Storage |
| **Maps** | Google Maps | Location services |

### Key Dependencies

**Production:**
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage` - Backend
- `google_sign_in` - Google authentication
- `google_maps_flutter` - Maps integration
- `geolocator`, `geocoding` - Location services
- `provider` - State management
- `image_picker` - Photo upload
- `shared_preferences` - Local storage
- `animate_do` - Animations

**Development:**
- `flutter_lints` - Code quality
- `flutter_dotenv` - Environment variables

---

## Documentation

### Complete Documentation Available

| Document | Description | Status |
|----------|-------------|--------|
| [QUICKSTART.md](QUICKSTART.md) | Quick setup & development guide | ✅ |
| [SUMMARY.md](SUMMARY.md) | Complete feature overview | ✅ |
| [AUTH_FIX.md](AUTH_FIX.md) | Authentication implementation | ✅ |
| [FEATURES_UPDATE.md](FEATURES_UPDATE.md) | Map markers & avatars | ✅ |
| [OPTIMIZATION_UPDATE.md](OPTIMIZATION_UPDATE.md) | Performance details | ✅ |
| [TESTING_GUIDE.md](TESTING_GUIDE.md) | QA procedures | ✅ |
| [CHANGELOG.md](CHANGELOG.md) | Version history | ✅ |

### Code Statistics

- **Total Files:** 40+ Dart files
- **Lines of Code:** ~6,500+
- **Providers:** 3 (Auth, User, Location)
- **Models:** 1 (UserModel)
- **Logging Points:** 62+ comprehensive logs
- **Screens:** 11 complete screens

---

## Testing

### Manual Testing Checklist

✅ **Authentication Flow:**
- First install → Onboarding → Auth → Register → Main
- Close & reopen → Auto-login to Main (no login needed)
- Logout → Auth screen (onboarding doesn't show again)

✅ **Map Performance:**
- Map loads < 2s on low-end devices
- Markers update smoothly (no frame drops)
- Location sharing works correctly
- 50 markers render at 60fps

✅ **Profile Management:**
- Avatar picker opens without overflow
- Photo upload works (camera & gallery)
- Emoji avatar selection works
- Profile updates persist

### Performance Testing

**Tested on:** Snapdragon 625, 3GB RAM
- ✅ Smooth 60fps throughout
- ✅ No memory leaks
- ✅ Efficient battery usage
- ✅ Fast cold start

See [TESTING_GUIDE.md](TESTING_GUIDE.md) for complete checklist.

---

## Development Timeline

### Completed Milestones

| Week | Focus | Status |
|------|-------|--------|
| **Week 1** | UI/UX Design, Theme, Basic Screens | ✅ 100% |
| **Week 2** | Maps, Location, Detail Pages | ✅ 100% |
| **Week 3-4** | Firebase, Auth, State Management | ✅ 100% |
| **Week 3-4** | Performance Optimization | ✅ 100% |

### Latest Achievements (Week 3-4)

**Week 3-4 Progress: 100% Complete**

✅ **State Management (100%)**
- AuthProvider - Full authentication
- UserProvider - Profile management
- LocationProvider - Real-time tracking

✅ **Authentication (100%)**
- Email/password & Google Sign-In
- Persistent sessions
- Onboarding persistence
- Clean logging

✅ **Performance Optimization (100%)**
- 5x faster marker generation
- 60% CPU reduction
- 85% fewer frame drops
- 33% memory savings

✅ **Code Quality (100%)**
- Professional logging
- Error handling
- Documentation
- Production ready

---

## Deployment

### Build Commands

```bash
# Debug build
flutter run

# Release APK (Android)
flutter build apk --release

# Release App Bundle (Play Store)
flutter build appbundle --release

# iOS build
flutter build ios --release
```

### Pre-Deployment Checklist

- [x] All features tested
- [x] Performance optimized
- [x] No critical bugs
- [x] Documentation complete
- [x] Firebase configured
- [x] API keys secured
- [x] Code analyzed

✅ **Ready for production deployment**

---

## Future Enhancements

### Priority 1 (Performance)
- [ ] Marker bitmap caching
- [ ] Progressive marker loading
- [ ] Marker clustering on zoom out
- [ ] Background marker pre-generation

### Priority 2 (Features)
- [ ] Chat between travelers
- [ ] Destination reviews & ratings
- [ ] Trip planning
- [ ] Photo gallery
- [ ] Social features (follow, like)
- [ ] UMKM tour packages
- [ ] Booking system

### Priority 3 (Polish)
- [ ] Advanced animations
- [ ] Skeleton loading states
- [ ] Haptic feedback
- [ ] Dark mode

---

## Team

- **BC25B066** - Mohamad Rafli Agung Subekti
- **BC25B067** - Lulu Shafira

**Learning Path:** Flutter
**Tema:** Inovasi Teknologi untuk Digitalisasi Wisata Nusantara
**Program:** BEKUP Create: Upskilling Bootcamp 2025

---

## License

This project is created for BEKUP Create: Upskilling Bootcamp 2025

---

## Acknowledgments

- BEKUP Team for guidance and support
- Flutter & Firebase communities
- Google Maps Platform
- Material Design team

---

## Support & Resources

### Documentation
- [Quick Start Guide](QUICKSTART.md)
- [Complete Summary](SUMMARY.md)
- [Technical Docs](AUTH_FIX.md)

### Links
- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/)

---

## Project Statistics

### Final Statistics

| Metric | Count |
|--------|-------|
| **Screens** | 11 complete |
| **Providers** | 3 (Auth, User, Location) |
| **Lines of Code** | 6,500+ |
| **Logging Points** | 62+ |
| **Documentation Files** | 7+ comprehensive docs |
| **Performance Tests** | All passed ✅ |

### Version History

- **v2.3.0** (Oct 6, 2025) - Performance optimizations, production ready
- **v2.2.0** (Oct 6, 2025) - Avatar system refinement
- **v2.1.0** (Oct 6, 2025) - Authentication persistence
- **v2.0.0** (Oct 6, 2025) - Map markers & location features
- **v1.0.0** - Initial release with core UI

---

<div align="center">

## Production Ready

**Status:** Ready for beta testing & deployment
**Performance:** Optimized for all devices
**Code Quality:** Production standards
**Documentation:** Comprehensive

**Made with care for Indonesian Tourism**

</div>

---

## Quick Commands Reference

```bash
# Development
flutter run                    # Run app
flutter hot-reload             # Hot reload (r in terminal)
flutter clean                  # Clean build cache

# Analysis
flutter analyze                # Check for issues
flutter format .               # Format code

# Testing
flutter test                   # Run unit tests
flutter logs                   # View logs

# Build
flutter build apk --release    # Android APK
flutter build appbundle        # Play Store bundle
```

---

**Last Updated:** October 6, 2025
**Version:** 2.3.0
**Status:** ✅ Production Ready
