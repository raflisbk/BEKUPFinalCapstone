# ReLink - Travel Companion & Local Guide App

**Aplikasi mobile travel untuk menemukan teman perjalanan dan local guide**

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
</div>

## 📱 About ReLink

ReLink adalah aplikasi mobile berbasis Flutter yang menghubungkan wisatawan dengan local guide terverifikasi dan sesama pelancong di sekitar lokasi mereka. Aplikasi ini dirancang untuk memberikan pengalaman wisata yang lebih autentik dan personal sambil memberdayakan masyarakat lokal.

### ✨ Key Features

- 🧳 **Solo Traveler Matching** - Temukan teman perjalanan terdekat menggunakan geolocation
- 🗺️ **Local Guide Marketplace** - Akses guide lokal terverifikasi dengan berbagai keahlian
- 🎯 **Smart Recommendations** - Rekomendasi destinasi sesuai minat dan lokasi
- 💰 **Budget Planner** - Rencanakan dan tracking budget perjalanan
- 📦 **UMKM Tour Packages** - Paket wisata berbasis UMKM lokal
- 👥 **Guest Mode** - Jelajah aplikasi tanpa perlu akun

## 🎨 Design Philosophy

ReLink mengadopsi desain **minimalis black & white** yang terinspirasi dari OpenAI dengan prinsip:

- ⚫ Pure black & white color scheme
- 📐 Generous white space untuk breathing room
- 🔤 Large typography dengan negative letter-spacing
- 🖼️ Subtle borders, minimal shadows
- ✨ Smooth animations untuk delightful UX

## 🚀 Quick Start

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

3. **Setup Firebase** (lihat [SETUP.md](SETUP.md) untuk detail lengkap)
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

## 📂 Project Structure

```
lib/
├── core/
│   ├── theme/              # Design system (colors, typography, theme)
│   └── config/             # Firebase & app configuration
├── presentation/
│   ├── splash/             # Splash screen
│   ├── onboarding/         # Onboarding flow
│   ├── auth/               # Authentication (login/register)
│   ├── main/               # Main screen with bottom nav
│   ├── home/               # Home page
│   ├── explore/            # Map & nearby travelers
│   ├── guides/             # Local guides list
│   └── profile/            # User profile
└── main.dart               # App entry point
```

## 🛠️ Tech Stack

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

## 📦 Dependencies

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

## 🗓️ Development Timeline

| Week | Focus | Status |
|------|-------|--------|
| **Week 1** (12-18 Sep) | UI/UX Design, Theme Setup, Basic Screens | ✅ Completed |
| **Week 2** (19-25 Sep) | Map Integration, Location Features | 🔄 In Progress |
| **Week 3** (26 Sep-2 Oct) | Guide Matching, Firebase Integration | ⏳ Planned |
| **Week 4** (3-9 Oct) | Bug Fixes, Performance Optimization | ⏳ Planned |
| **Week 5** (10-16 Oct) | Demo Video, Documentation | ⏳ Planned |

## 🎯 Week 1 Deliverables ✅

- [x] Minimalist black/white theme configuration
- [x] Splash screen dengan animasi
- [x] 3-page onboarding flow
- [x] Authentication screens (Login/Register/Guest)
- [x] Main screen dengan bottom navigation
- [x] Home screen dengan hero section
- [x] Basic Explore, Guides, Profile screens
- [x] Firebase structure documentation
- [x] Setup guide & README

## 📸 Screenshots

> Screenshots akan ditambahkan setelah implementasi UI selesai

## 🔐 Firebase Structure

### Collections

- **users** - User profiles & preferences
- **guides** - Local guide information
- **destinations** - Tourist destinations data
- **tourPackages** - UMKM tour packages
- **bookings** - Booking transactions
- **reviews** - User reviews & ratings

Lihat [firebase_config.dart](lib/core/config/firebase_config.dart) untuk detail struktur.

## 🎨 Design System

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

## 👥 Team

- **BC25B066** - Mohamad Rafli Agung Subekti
- **BC25B067** - Lulu Shafira

**Learning Path**: Flutter
**Tema**: Inovasi Teknologi untuk Digitalisasi Wisata Nusantara

## 📄 License

This project is created for BEKUP Create: Upskilling Bootcamp 2025

## 🙏 Acknowledgments

- Design inspiration: [OpenAI](https://openai.com)
- BEKUP Team for guidance and support
- Flutter & Firebase communities

---

**Made with ❤️ for Indonesian Tourism**
