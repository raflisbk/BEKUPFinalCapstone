# ReLink - Travel Companion App

**Mobile travel app connecting travelers with local guides**

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
</div>

## About

ReLink is a Flutter-based mobile app that connects travelers with verified local guides and fellow travelers. Designed to provide authentic and personalized travel experiences while empowering local communities.

### Key Features

- **AI Travel Assistant** - AI-powered travel companion using Google Gemini Pro
- **AI Route Planning** - Smart route optimization with real-time suggestions
- **Analytics Dashboard** - AI-powered insights into travel patterns
- **Smart Budget Planning** - AI-optimized budget recommendations
- **Offline Mode** - 95% app functionality available without internet
- **Real-time Chat** - Messaging with read receipts and online status
- **Social Network** - Follow users, activity feed, profiles
- **Trip Planning** - Complete itinerary and budget management
- **Photo Gallery** - Upload, like, and comment on photos
- **Reviews & Ratings** - Comprehensive review system
- **Location Tracking** - See nearby travelers
- **Dark Mode** - Complete dark theme support

---

## Tech Stack

| Category | Technology |
|----------|-----------|
| **Framework** | Flutter 3.9.2+ |
| **Language** | Dart 3.x |
| **State Management** | Provider |
| **Backend** | Firebase (Auth, Firestore, Storage) |
| **Maps** | Google Maps Flutter |
| **AI** | Google Gemini Pro |

---

## Installation

### Prerequisites

- Flutter SDK (>= 3.9.2)
- Dart SDK
- Firebase account
- Google Cloud account (Maps & Gemini API)

### Setup

1. **Clone repository**
```bash
git clone https://github.com/yourusername/relink.git
cd relink
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Firebase Configuration**
   - Create Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Download `google-services.json` and place in `android/app/`
   - Enable: Authentication, Firestore, Storage

4. **API Keys**
   - Get Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
   - Get Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)

   Create `.env` file:
```env
GOOGLE_MAPS_API_KEY=your_maps_api_key_here
GEMINI_API_KEY=your_gemini_api_key_here
```

5. **Run app**
```bash
flutter run
```

---

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   ├── models/
│   ├── providers/
│   └── widgets/
├── services/
│   ├── ai/
│   ├── cache/
│   ├── sync/
│   └── core/
├── presentation/
│   ├── auth/
│   ├── chat/
│   ├── gallery/
│   ├── trips/
│   └── main/
└── main.dart
```

---

## Development Commands

```bash
# Run app
flutter run

# Check for issues
flutter analyze

# Format code
flutter format .

# Build release
flutter build apk --release
```

---

## Team

- **BC25B066** - Mohamad Rafli Agung Subekti
- **BC25B067** - Lulu Shafira

**Learning Path:** Flutter
**Program:** BEKUP Create: Upskilling Bootcamp 2025
**Theme:** Technology Innovation for Indonesian Tourism Digitalization

---

## License

This project is created for BEKUP Create: Upskilling Bootcamp 2025

---

<div align="center">

**Made with care for Indonesian Tourism**

</div>
