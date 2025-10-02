import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }
}

/// Firebase Collections Structure
///
/// Collection: users
/// - userId (auto-generated)
///   - name: String
///   - email: String
///   - photoUrl: String
///   - phone: String
///   - createdAt: Timestamp
///   - isGuide: bool
///   - location: GeoPoint (for matching nearby travelers)
///
/// Collection: guides
/// - guideId (auto-generated)
///   - userId: String (reference to users collection)
///   - name: String
///   - bio: String
///   - photoUrl: String
///   - expertise: List<String> (e.g., ['history', 'culinary', 'nature'])
///   - rating: double
///   - reviewCount: int
///   - pricePerDay: int
///   - isVerified: bool
///   - location: GeoPoint
///   - languages: List<String>
///   - createdAt: Timestamp
///
/// Collection: destinations
/// - destinationId (auto-generated)
///   - name: String
///   - description: String
///   - location: String
///   - coordinates: GeoPoint
///   - category: String
///   - images: List<String>
///   - rating: double
///   - guidesAvailable: int
///   - createdAt: Timestamp
///
/// Collection: tourPackages
/// - packageId (auto-generated)
///   - guideId: String (reference to guides collection)
///   - name: String
///   - description: String
///   - type: String (e.g., 'culinary', 'cultural', 'workshop')
///   - price: int
///   - duration: String
///   - maxParticipants: int
///   - images: List<String>
///   - includes: List<String>
///   - createdAt: Timestamp
///
/// Collection: bookings
/// - bookingId (auto-generated)
///   - userId: String
///   - guideId: String
///   - packageId: String (optional)
///   - date: Timestamp
///   - status: String (pending, confirmed, completed, cancelled)
///   - totalPrice: int
///   - createdAt: Timestamp
///
/// Collection: reviews
/// - reviewId (auto-generated)
///   - userId: String
///   - guideId: String
///   - rating: double
///   - comment: String
///   - createdAt: Timestamp
