# 🇮🇩 Indonesia Tourism API Integration Guide

## Overview

ReLink app sekarang dilengkapi dengan **Indonesia Tourism Service** yang mengintegrasikan data wisata real dari seluruh Indonesia menggunakan **Google Places API**.

## ✨ Fitur

### 1. **Data Wisata Real Indonesia**
- ✅ Destinasi wisata dari **Google Places API** dengan foto real
- ✅ Rating dan review dari pengguna Google Maps
- ✅ Deskripsi lengkap destinasi
- ✅ Lokasi GPS akurat
- ✅ Fallback ke curated data jika API tidak tersedia

### 2. **Filter Berdasarkan Provinsi**
Pilih destinasi berdasarkan 13 provinsi populer:
- 🌴 Bali
- 🏛️ D.I. Yogyakarta
- 🏙️ DKI Jakarta
- 🌊 Jawa Barat
- ⛰️ Jawa Timur
- 🏞️ Jawa Tengah
- 🏔️ Sumatera Utara
- 🌿 Sumatera Barat
- 🌺 Sulawesi Selatan
- 🏖️ Nusa Tenggara Barat (Lombok)
- 🗻 Nusa Tenggara Timur
- 🌴 Kalimantan
- 🦜 Papua

### 3. **Filter Berdasarkan Kategori**
10 kategori wisata:
- 🏖️ **Pantai** - Beach tourism
- ⛰️ **Gunung** - Mountain & hiking
- 🎭 **Budaya** - Cultural sites & museums
- 🍜 **Kuliner** - Culinary experiences
- 🌿 **Alam** - Nature & parks
- 🏛️ **Sejarah** - Historical landmarks
- 🕌 **Religi** - Religious sites
- 🚵 **Petualangan** - Adventure activities
- 🏙️ **Perkotaan** - Urban tourism
- 🌾 **Pedesaan** - Rural tourism

### 4. **Curated Destinations**
Data curated untuk destinasi populer:

#### Bali
- Tanah Lot Temple
- Uluwatu Temple
- Tegallalang Rice Terrace
- Kuta Beach
- Mount Batur

#### Yogyakarta
- Borobudur Temple (UNESCO)
- Prambanan Temple
- Malioboro Street
- Taman Sari Water Castle
- Mount Merapi

#### Jakarta
- National Monument (Monas)
- Kota Tua Jakarta
- Ancol Dreamland
- Thousand Islands

#### Dan masih banyak lagi...

## 🔧 Setup Google Places API

### Step 1: Enable Google Places API

1. **Buka Google Cloud Console**
   - Go to: https://console.cloud.google.com/

2. **Pilih Project Anda**
   - Pilih project yang sama dengan Google Maps API

3. **Enable Places API**
   ```
   APIs & Services > Library > Search "Places API"
   ```
   - Enable **Places API**
   - Enable **Places API (New)** (opsional, untuk fitur terbaru)

### Step 2: Konfigurasi API Key

API Key yang sama dengan Google Maps bisa digunakan untuk Places API.

#### Tambahkan Restrictions (Recommended):

1. **API Restrictions**:
   ```
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Geocoding API
   - Geolocation API
   ```

2. **Application Restrictions**:
   - **Android**: Tambahkan package name + SHA-1 fingerprint
   - **iOS**: Tambahkan bundle identifier

### Step 3: Verify .env Configuration

File `.env` sudah ter-configure dengan:
```env
# Google Maps & Places API (Same key)
GOOGLE_MAPS_API_KEY=AIzaSyB_YOUR_ACTUAL_API_KEY_HERE
```

**IMPORTANT**: Pastikan API key sudah diganti dari placeholder!

## 📱 Menggunakan Indonesia Tourism Screen

### Akses dari Aplikasi

Ada beberapa cara mengakses Indonesia Tourism:

#### Option 1: Dari Explore Screen
```dart
// Add button to explore_screen.dart
FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IndonesiaTourismScreen(),
      ),
    );
  },
  child: const Icon(Icons.tour),
)
```

#### Option 2: Dari Main Navigation
Add to main navigation bottom bar:
```dart
{
  'icon': Icons.explore,
  'label': 'Wisata 🇮🇩',
  'screen': IndonesiaTourismScreen(),
}
```

### Penggunaan

1. **Search Bar**: Ketik nama destinasi atau tempat
2. **Filter Provinsi**: Pilih provinsi untuk melihat destinasi di provinsi tersebut
3. **Filter Kategori**: Filter berdasarkan jenis wisata
4. **Pull to Refresh**: Tarik ke bawah untuk reload data
5. **Tap Card**: Klik destinasi untuk melihat detail lengkap

## 🔌 API Integration Details

### Google Places Text Search API

**Endpoint**:
```
GET https://maps.googleapis.com/maps/api/place/textsearch/json
```

**Parameters**:
```
?query={destination_name}+{province}+{category}
&key={GOOGLE_MAPS_API_KEY}
&language=id
&region=id
```

**Example Request**:
```
https://maps.googleapis.com/maps/api/place/textsearch/json
?query=Borobudur+Yogyakarta+Indonesia
&key=AIzaSyB_YOUR_API_KEY
&language=id
&region=id
```

**Response Fields Used**:
- `name` - Nama destinasi
- `formatted_address` - Alamat lengkap
- `rating` - Rating (0-5)
- `user_ratings_total` - Jumlah review
- `geometry.location` - Koordinat GPS (lat, lng)
- `photos[].photo_reference` - Reference untuk foto
- `types[]` - Kategori tempat

### Google Place Photos API

**Endpoint**:
```
GET https://maps.googleapis.com/maps/api/place/photo
```

**Parameters**:
```
?maxwidth=800
&photo_reference={PHOTO_REFERENCE}
&key={GOOGLE_MAPS_API_KEY}
```

**Example**:
```
https://maps.googleapis.com/maps/api/place/photo
?maxwidth=800
&photo_reference=Aap_uEDg7L43...
&key=AIzaSyB_YOUR_API_KEY
```

### Google Place Details API

**Endpoint**:
```
GET https://maps.googleapis.com/maps/api/place/details/json
```

**Parameters**:
```
?place_id={PLACE_ID}
&fields=editorial_summary
&key={GOOGLE_MAPS_API_KEY}
&language=id
```

Used for getting detailed descriptions.

## 💰 Pricing & Quota

### Google Places API Pricing (as of 2025)

| API Call | Free Tier/Month | Price After Free Tier |
|----------|----------------|---------------------|
| Text Search | $0 for first $200 | $32 per 1000 requests |
| Place Details | $0 for first $200 | $17 per 1000 requests |
| Place Photos | Free | Free |

**Monthly Free Credit**: $200/month from Google Cloud

**Estimated Usage**:
- Text Search: ~100 calls/day = ~$10/month (covered by free tier)
- Place Details: ~50 calls/day = ~$5/month (covered by free tier)
- Photos: Unlimited free

**Optimization**:
- Service uses caching untuk reduce API calls
- Fallback ke curated data jika quota habis
- Client-side filtering untuk category/province

## 🗂️ Code Structure

```
lib/
├── services/
│   └── indonesia_tourism_service.dart      # Main service
├── core/
│   └── providers/
│       └── indonesia_tourism_provider.dart  # State management
└── presentation/
    └── explore/
        └── indonesia_tourism_screen.dart    # UI Screen
```

### Key Classes

#### 1. `IndonesiaTourismService`
Main service untuk fetch data wisata.

**Methods**:
```dart
// Search destinations
Future<List<Destination>> searchIndonesianDestinations({
  IndonesianProvince? province,
  TourismCategory? category,
  String? keyword,
  int limit = 20,
})

// Get by province
Future<List<Destination>> getPopularDestinationsByProvince(
  IndonesianProvince province,
)

// Get by category
Future<List<Destination>> getDestinationsByCategory(
  TourismCategory category,
)

// Get trending
Future<List<Destination>> getTrendingDestinations()

// Search by keyword
Future<List<Destination>> searchByKeyword(String keyword)
```

#### 2. `IndonesiaTourismProvider`
Provider untuk state management.

**Properties**:
```dart
List<Destination> destinations
List<Destination> trendingDestinations
bool isLoading
String? error
IndonesianProvince? selectedProvince
TourismCategory? selectedCategory
```

**Methods**:
```dart
Future<void> loadTrendingDestinations()
Future<void> searchByProvince(IndonesianProvince province)
Future<void> searchByCategory(TourismCategory category)
Future<void> searchByKeyword(String keyword)
void clearFilters()
Future<void> reload()
```

#### 3. `IndonesiaTourismScreen`
UI Screen dengan search, filter, dan display.

**Features**:
- Search bar dengan autocomplete
- Horizontal scroll province filter
- Horizontal scroll category filter
- Card list dengan foto, rating, tags
- Pull to refresh
- Error handling & retry
- Loading states

## 📊 Data Model

### Enums

```dart
enum IndonesianProvince {
  bali, yogyakarta, jakarta, jawaBarat, jawaTimur,
  jawaTengah, sumateraUtara, sumateraBarat,
  sulawesiSelatan, ntb, ntt, kalimantan, papua
}

enum TourismCategory {
  beach, mountain, culture, culinary, nature,
  historical, religious, adventure, urban, rural
}
```

### Destination Model

Already using existing `Destination` model:
```dart
class Destination {
  final String id;           // Google Place ID
  final String name;
  final String description;
  final String location;
  final double latitude;
  final double longitude;
  final String category;
  final List<String> imageUrls;  // Google Photos URLs
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final DateTime createdAt;
}
```

## 🧪 Testing

### Manual Testing Checklist

- [ ] Search destinasi dengan keyword
- [ ] Filter by province (test 3-5 provinsi)
- [ ] Filter by category (test 3-5 kategori)
- [ ] Kombinasi province + category filter
- [ ] Pull to refresh
- [ ] Click destinasi card -> navigate to detail
- [ ] Test dengan API key valid
- [ ] Test dengan API key invalid (fallback to curated)
- [ ] Test offline mode
- [ ] Test dengan slow internet

### Unit Testing

```dart
// test/services/indonesia_tourism_service_test.dart
void main() {
  group('IndonesiaTourismService', () {
    test('search by province returns destinations', () async {
      final service = IndonesiaTourismService();
      final results = await service.getPopularDestinationsByProvince(
        IndonesianProvince.bali,
      );
      expect(results, isNotEmpty);
      expect(results.first.location, contains('Bali'));
    });

    test('search by category returns correct type', () async {
      final service = IndonesiaTourismService();
      final results = await service.getDestinationsByCategory(
        TourismCategory.beach,
      );
      expect(results, isNotEmpty);
      expect(results.first.category, equals('beach'));
    });
  });
}
```

## ❗ Troubleshooting

### Issue 1: "No destinations found"

**Possible Causes**:
1. API key tidak valid
2. Places API tidak di-enable
3. Quota habis
4. Network error

**Solutions**:
1. Verify API key di Google Cloud Console
2. Enable Places API di Google Cloud
3. Check quota usage
4. System akan fallback ke curated data automatically

### Issue 2: "Photos not loading"

**Possible Causes**:
1. Photo reference invalid
2. Network slow
3. Image cache issue

**Solutions**:
1. Photos akan show placeholder grey box
2. CachedNetworkImage akan auto retry
3. Clear app cache

### Issue 3: "Descriptions are generic"

**Explanation**:
- Google Places API tidak selalu punya editorial summary
- Fallback ke "Destinasi wisata populer di Indonesia"

**Solution**:
- Maintain curated descriptions dalam service
- Atau integrate dengan Wikipedia API untuk descriptions

### Issue 4: "Wrong category detection"

**Explanation**:
- Category detection based on Google Place `types`
- Tidak selalu 100% akurat

**Solution**:
- Manually curate popular destinations dengan category yang benar
- Override detection untuk known places

## 🚀 Future Enhancements

### Phase 1: Enhanced Data
- [ ] Add Wikipedia API untuk detailed descriptions
- [ ] Integrate dengan Instagram API untuk user photos
- [ ] Add weather data per destination
- [ ] Add best time to visit recommendations

### Phase 2: Social Features
- [ ] User-generated reviews dalam bahasa Indonesia
- [ ] Photo uploads dari users
- [ ] "Been there" check-ins
- [ ] Share destinasi ke social media

### Phase 3: Trip Planning
- [ ] Auto-generate itinerary untuk province
- [ ] Calculate travel time antar destinasi
- [ ] Recommend nearby destinations
- [ ] Budget estimation per destination

### Phase 4: Offline Support
- [ ] Cache popular destinations
- [ ] Download province data offline
- [ ] Offline maps per province
- [ ] Sync bookmarks & favorites

## 📚 Additional Resources

- **Google Places API Docs**: https://developers.google.com/maps/documentation/places/web-service
- **Google Cloud Console**: https://console.cloud.google.com/
- **Indonesia Tourism Data**: https://www.indonesia.travel/
- **UNESCO Sites in Indonesia**: https://whc.unesco.org/en/statesparties/id

## 📞 Support

Jika ada pertanyaan atau issues:
1. Check troubleshooting section di atas
2. Verify API key configuration
3. Check Google Cloud Console quota
4. Review logs dengan AppLogger

## 📄 License

Indonesia Tourism Service menggunakan:
- **Google Places API**: Subject to Google's Terms of Service
- **Curated Data**: Open source, free to use
- **Photos**: Google Photos API (free tier)

---

**Selamat Menjelajahi Indonesia! 🇮🇩✨**
