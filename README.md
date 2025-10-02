# ReLink - Travel Companion & Local Guide App

**Aplikasi mobile travel untuk menemukan teman perjalanan dan local guide**

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
</div>

## About ReLink

ReLink adalah aplikasi mobile berbasis Flutter yang menghubungkan wisatawan dengan local guide terverifikasi dan sesama pelancong di sekitar lokasi mereka. Aplikasi ini dirancang untuk memberikan pengalaman wisata yang lebih autentik dan personal sambil memberdayakan masyarakat lokal.

### Key Features

- **Solo Traveler Matching** - Temukan teman perjalanan terdekat menggunakan geolocation
- **Local Guide Marketplace** - Akses guide lokal terverifikasi dengan berbagai keahlian
- **Smart Recommendations** - Rekomendasi destinasi sesuai minat dan lokasi
- **Budget Planner** - Rencanakan dan tracking budget perjalanan
- **UMKM Tour Packages** - Paket wisata berbasis UMKM lokal
- **Guest Mode** - Jelajah aplikasi tanpa perlu akun

## Design Philosophy

ReLink mengadopsi desain **minimalis black & white** yang terinspirasi dari OpenAI dengan prinsip:

- Pure black & white color scheme
- Generous white space untuk breathing room
- Large typography dengan negative letter-spacing
- Subtle borders, minimal shadows
- Smooth animations untuk delightful UX

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

3. **Setup Firebase** (lihat SETUP.md untuk detail lengkap)
   - Buat project di Firebase Console
   - Download `google-services.json` (Android)
   - Enable Authentication, Firestore, Storage

4. **Setup Google Maps**
   - Dapatkan API key dari Google Cloud Console
   - Tambahkan ke `AndroidManifest.xml` dan `AppDelegate.swift`

5. **Run app**
```bash
flutter run
```

## Project Structure

```
lib/
├── core/
│   ├── theme/              # Design system (colors, typography, theme)
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
│   └── config/             # Firebase & app configuration
│       └── firebase_config.dart
├── services/
│   └── location_service.dart   # Location & geocoding utilities
├── presentation/
│   ├── splash/             # Splash screen
│   │   └── splash_screen.dart
│   ├── onboarding/         # Onboarding flow (3 pages)
│   │   └── onboarding_screen.dart
│   ├── auth/               # Authentication screens
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── guest_screen.dart
│   ├── main/               # Main screen with bottom navigation
│   │   └── main_screen.dart
│   ├── home/               # Home page
│   │   └── home_screen.dart
│   ├── explore/            # Map & nearby travelers
│   │   └── explore_screen.dart
│   ├── guides/             # Local guides list & detail
│   │   ├── guides_screen.dart
│   │   └── guide_detail_screen.dart
│   ├── destinations/       # Destination detail
│   │   └── destination_detail_screen.dart
│   ├── search/             # Search functionality
│   │   └── search_screen.dart
│   └── profile/            # User profile
│       └── profile_screen.dart
└── main.dart               # App entry point

android/
└── app/src/main/
    └── AndroidManifest.xml     # Android permissions & API keys

ios/
└── Runner/
    ├── Info.plist              # iOS permissions
    └── AppDelegate.swift       # iOS configuration
```

## Tech Stack

| Category | Technology |
|----------|-----------|
| **Framework** | Flutter 3.9.2+ |
| **Language** | Dart |
| **State Management** | Provider |
| **Backend** | Firebase (Auth, Firestore, Storage) |
| **Maps** | Google Maps Flutter |
| **Location** | Geolocator, Geocoding |
| **UI/UX** | Material Design 3, Animate Do |
| **Storage** | Shared Preferences |

## Dependencies

### Production
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
- `google_sign_in` - Google authentication
- `google_maps_flutter` - Maps integration
- `geolocator`, `geocoding` - Location services
- `provider` - State management
- `animate_do` - Smooth animations
- `cached_network_image` - Image caching

### Development
- `flutter_lints` - Code quality

## Development Timeline

| Week | Focus | Status |
|------|-------|--------|
| **Week 1** (12-18 Sep) | UI/UX Design, Theme Setup, Basic Screens | COMPLETED |
| **Week 2** (19-25 Sep) | Map Integration, Location Features, Detail Pages | COMPLETED |
| **Week 3** (26 Sep-2 Oct) | Firebase Integration, Authentication, Real Data | IN PROGRESS |
| **Week 4** (3-9 Oct) | Booking System, UMKM Packages, Testing | PLANNED |
| **Week 5** (10-16 Oct) | Bug Fixes, Performance, Demo Video | PLANNED |

## Development Progress

### Week 1 - UI/UX Foundation (100% Complete)

#### Design System
- [x] Minimalist black/white theme configuration
- [x] Color palette (Pure black, white, grey scale)
- [x] Typography system (Display, Headline, Body, Label)
- [x] Theme configuration (buttons, inputs, cards)

#### Core Screens
- [x] Splash screen dengan animasi
- [x] 3-page onboarding flow
- [x] Authentication screens (Login/Register/Guest)
- [x] Main screen dengan bottom navigation (4 tabs)
- [x] Home screen dengan hero section & search
- [x] Explore screen (basic layout)
- [x] Guides screen dengan guide cards
- [x] Profile screen dengan menu items

#### Documentation
- [x] Firebase structure documentation
- [x] Setup guide & README
- [x] Project structure organized

### Week 2 - Advanced Features (100% Complete)

#### Google Maps & Location
- [x] Location service implementation (singleton pattern)
- [x] Google Maps integration di Explore screen
- [x] Current location marker (blue)
- [x] Nearby travelers markers (red - dummy data)
- [x] My Location button dengan camera control
- [x] Android permissions setup (AndroidManifest.xml)
- [x] iOS permissions setup (Info.plist)
- [x] Location permission request flow
- [x] Reverse geocoding (coordinates to address)
- [x] Forward geocoding (address to coordinates)
- [x] Calculate distance between points
- [x] Real-time location stream

#### Detail Pages
- [x] **Destination Detail Screen**
  - [x] Hero image header dengan gradient
  - [x] Expandable SliverAppBar
  - [x] Stats cards (Rating, Guides, Visitors)
  - [x] About section
  - [x] Available guides list preview
  - [x] Bottom CTA "Book a Guide"
  - [x] Smooth animations (FadeIn)

- [x] **Guide Detail Screen**
  - [x] Profile header dengan avatar
  - [x] Rating & reviews count badge
  - [x] Stats (Tours, Languages, Years)
  - [x] About me section
  - [x] Languages chips (3 languages)
  - [x] Specializations chips (4 items)
  - [x] Reviews preview (2 cards)
  - [x] Bottom bar dengan price display
  - [x] Booking dialog implementation
  - [x] Confirmation flow

#### Search Feature
- [x] **Search Screen**
  - [x] Search bar dengan auto-focus
  - [x] Real-time search filtering
  - [x] Clear button (X icon)
  - [x] Filter chips (All, Destinations, Guides)
  - [x] Search results for destinations
  - [x] Search results for guides
  - [x] Case-insensitive search
  - [x] Empty state UI
  - [x] Recent searches section
  - [x] Navigation to detail pages

#### Navigation
- [x] Home to Destination Detail (tap card)
- [x] Home to Search Screen (tap search bar)
- [x] Guides to Guide Detail (tap card)
- [x] Search to Destination/Guide Detail
- [x] All back navigation working
- [x] Smooth page transitions

### Week 3 - Backend Integration (In Progress)

#### Firebase Setup
- [ ] Create Firebase project
- [ ] Add google-services.json (Android)
- [ ] Add GoogleService-Info.plist (iOS)
- [ ] Initialize Firebase in app
- [ ] Setup Authentication (Email & Google Sign-in)
- [ ] Setup Firestore database
- [ ] Setup Firebase Storage

#### State Management
- [ ] AuthProvider implementation
- [ ] LocationProvider implementation
- [ ] DestinationProvider implementation
- [ ] GuideProvider implementation
- [ ] BookingProvider implementation
- [ ] Integrate providers dengan screens

#### Real Data Integration
- [ ] Replace dummy destinations dengan Firestore
- [ ] Replace dummy guides dengan Firestore
- [ ] Real-time updates implementation
- [ ] User-specific data (bookings, favorites)
- [ ] Image uploads untuk profiles
- [ ] Reviews & ratings system

## Current Milestone

**Status:** Week 2 Completed - Week 3 Starting

**Completed Screens:** 11/11 (100%)
- Splash Screen
- Onboarding (3 pages)
- Auth Screens (Login/Register/Guest)
- Main Screen (Bottom Nav)
- Home Screen
- Explore Screen (with Google Maps)
- Guides Screen
- Profile Screen
- Destination Detail Screen
- Guide Detail Screen
- Search Screen

**Next Focus:** Firebase integration & real data implementation

## Screenshots

> Screenshots akan ditambahkan setelah implementasi UI selesai

## Features Implemented

### Core Features
- **Authentication Flow** - Login, Register, Guest mode
- **Bottom Navigation** - 4 tabs navigation system
- **Home Screen** - Hero section, search bar, quick actions, featured destinations
- **Search** - Real-time search dengan filters (All/Destinations/Guides)
- **Google Maps** - Current location, nearby travelers markers, camera controls
- **Detail Pages** - Destination detail & Guide detail dengan booking flow
- **Location Services** - Geolocation, geocoding, distance calculation

### In Development
- Firebase Authentication
- Real-time data from Firestore
- State management with Provider
- Booking system backend
- User profile editing
- Reviews & ratings

### Planned Features
- UMKM tour packages
- Budget planner
- Travel itinerary
- Chat between travelers
- Payment integration
- Notifications

## Firebase Structure

### Collections

- **users** - User profiles & preferences
- **guides** - Local guide information
- **destinations** - Tourist destinations data
- **tourPackages** - UMKM tour packages
- **bookings** - Booking transactions
- **reviews** - User reviews & ratings

Lihat [firebase_config.dart](lib/core/config/firebase_config.dart) untuk detail struktur.

## Design System

### Colors
- **Primary**: `#000000` (Pure Black)
- **Background**: `#FFFFFF` (Pure White)
- **Text Primary**: `#000000`
- **Text Secondary**: `#616161`
- **Border**: `#E0E0E0`

### Typography
- **Display**: 48-72px, Weight 700, Letter Spacing -2
- **Headline**: 24-40px, Weight 600, Letter Spacing -1
- **Body**: 14-18px, Weight 400, Line Height 1.6

## Team

- **BC25B066** - Mohamad Rafli Agung Subekti
- **BC25B067** - Lulu Shafira

**Learning Path**: Flutter
**Tema**: Inovasi Teknologi untuk Digitalisasi Wisata Nusantara

## License

This project is created for BEKUP Create: Upskilling Bootcamp 2025

## Acknowledgments
- BEKUP Team for guidance and support
- Flutter & Firebase communities

---

## Project Statistics

### Development Progress
- **Overall Progress:** 40% (Week 1-2 Complete)
- **Screens Completed:** 11/11 (100%)
- **Core Features:** 7/15 (46%)
- **Backend Integration:** 0/6 (0%)

### Code Metrics
- **Total Files:** 30+ Dart files
- **Lines of Code:** ~4,000+
- **Components Created:** 35+

### Week-by-Week
| Week | Tasks | Completion |
|------|-------|------------|
| Week 1 | UI/UX Foundation | 100% |
| Week 2 | Maps & Features | 100% |
| Week 3 | Firebase Backend | 0% |
| Week 4 | Advanced Features | 0% |
| Week 5 | Polish & Demo | 0% |

---

**Made with care for Indonesian Tourism**
