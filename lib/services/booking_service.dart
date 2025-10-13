import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/logger.dart';

/// Booking types
enum BookingType {
  hotel,
  flight,
  activity,
  restaurant,
  transportation,
}

/// Booking status
enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  completed,
  failed,
}

/// Booking model
class Booking {
  final String id;
  final String userId;
  final BookingType type;
  final String providerName;
  final String itemName;
  final String? itemId;
  final DateTime checkInDate;
  final DateTime? checkOutDate;
  final int guests;
  final double totalPrice;
  final String currency;
  final BookingStatus status;
  final String? confirmationCode;
  final Map<String, dynamic>? details;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  const Booking({
    required this.id,
    required this.userId,
    required this.type,
    required this.providerName,
    required this.itemName,
    this.itemId,
    required this.checkInDate,
    this.checkOutDate,
    required this.guests,
    required this.totalPrice,
    required this.currency,
    required this.status,
    this.confirmationCode,
    this.details,
    required this.createdAt,
    this.confirmedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'providerName': providerName,
      'itemName': itemName,
      'itemId': itemId,
      'checkInDate': checkInDate.toIso8601String(),
      'checkOutDate': checkOutDate?.toIso8601String(),
      'guests': guests,
      'totalPrice': totalPrice,
      'currency': currency,
      'status': status.name,
      'confirmationCode': confirmationCode,
      'details': details,
      'createdAt': createdAt.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: BookingType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => BookingType.hotel,
      ),
      providerName: map['providerName'] ?? '',
      itemName: map['itemName'] ?? '',
      itemId: map['itemId'],
      checkInDate: DateTime.parse(map['checkInDate']),
      checkOutDate: map['checkOutDate'] != null ? DateTime.parse(map['checkOutDate']) : null,
      guests: map['guests'] ?? 1,
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.pending,
      ),
      confirmationCode: map['confirmationCode'],
      details: map['details'],
      createdAt: DateTime.parse(map['createdAt']),
      confirmedAt: map['confirmedAt'] != null ? DateTime.parse(map['confirmedAt']) : null,
    );
  }
}

/// Service for booking hotels, flights, and activities
class BookingService {
  static const String _tag = 'BookingService';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Search for hotels
  Future<List<Map<String, dynamic>>> searchHotels({
    required String destination,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      AppLogger.info(_tag, 'Searching hotels', {
        'destination': destination,
        'checkIn': checkIn.toString(),
        'guests': guests,
      });

      // In real implementation, call Booking.com API or similar:
      // final response = await http.get(
      //   Uri.parse('https://api.booking.com/v1/hotels/search'),
      //   headers: {'Authorization': 'Bearer $apiKey'},
      // );

      // Mock hotel results
      return [
        {
          'id': 'hotel_1',
          'name': 'Grand Hotel Central',
          'rating': 4.5,
          'pricePerNight': 120.0,
          'currency': 'USD',
          'imageUrl': 'https://example.com/hotel1.jpg',
          'amenities': ['WiFi', 'Pool', 'Breakfast', 'Gym'],
          'location': destination,
        },
        {
          'id': 'hotel_2',
          'name': 'Seaside Resort',
          'rating': 4.8,
          'pricePerNight': 200.0,
          'currency': 'USD',
          'imageUrl': 'https://example.com/hotel2.jpg',
          'amenities': ['WiFi', 'Pool', 'Beach Access', 'Spa'],
          'location': destination,
        },
      ];
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to search hotels', e, stackTrace);
      return [];
    }
  }

  /// Search for flights
  Future<List<Map<String, dynamic>>> searchFlights({
    required String origin,
    required String destination,
    required DateTime departureDate,
    DateTime? returnDate,
    required int passengers,
  }) async {
    try {
      AppLogger.info(_tag, 'Searching flights', {
        'origin': origin,
        'destination': destination,
        'date': departureDate.toString(),
      });

      // In real implementation, call Skyscanner or similar API

      // Mock flight results
      return [
        {
          'id': 'flight_1',
          'airline': 'SkyHigh Airlines',
          'flightNumber': 'SH101',
          'departureTime': departureDate.add(const Duration(hours: 8)),
          'arrivalTime': departureDate.add(const Duration(hours: 12)),
          'price': 350.0,
          'currency': 'USD',
          'stops': 0,
          'class': 'Economy',
        },
        {
          'id': 'flight_2',
          'airline': 'Global Airways',
          'flightNumber': 'GA202',
          'departureTime': departureDate.add(const Duration(hours: 14)),
          'arrivalTime': departureDate.add(const Duration(hours: 19)),
          'price': 280.0,
          'currency': 'USD',
          'stops': 1,
          'class': 'Economy',
        },
      ];
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to search flights', e, stackTrace);
      return [];
    }
  }

  /// Search for activities
  Future<List<Map<String, dynamic>>> searchActivities({
    required String destination,
    required DateTime date,
    String? category,
  }) async {
    try {
      AppLogger.info(_tag, 'Searching activities', {
        'destination': destination,
        'date': date.toString(),
      });

      // In real implementation, call Viator or GetYourGuide API

      // Mock activity results
      return [
        {
          'id': 'activity_1',
          'name': 'City Walking Tour',
          'provider': 'Local Tours Inc',
          'duration': 3,
          'price': 45.0,
          'currency': 'USD',
          'rating': 4.7,
          'category': 'Culture',
          'imageUrl': 'https://example.com/tour1.jpg',
        },
        {
          'id': 'activity_2',
          'name': 'Sunset Cruise',
          'provider': 'Ocean Adventures',
          'duration': 2,
          'price': 85.0,
          'currency': 'USD',
          'rating': 4.9,
          'category': 'Adventure',
          'imageUrl': 'https://example.com/cruise1.jpg',
        },
      ];
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to search activities', e, stackTrace);
      return [];
    }
  }

  /// Create booking
  Future<Booking?> createBooking({
    required String userId,
    required BookingType type,
    required String providerName,
    required String itemName,
    String? itemId,
    required DateTime checkInDate,
    DateTime? checkOutDate,
    required int guests,
    required double totalPrice,
    required String currency,
    Map<String, dynamic>? details,
  }) async {
    try {
      AppLogger.info(_tag, 'Creating booking', {
        'type': type.name,
        'itemName': itemName,
        'totalPrice': totalPrice,
      });

      final bookingId = DateTime.now().millisecondsSinceEpoch.toString();

      final booking = Booking(
        id: bookingId,
        userId: userId,
        type: type,
        providerName: providerName,
        itemName: itemName,
        itemId: itemId,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        guests: guests,
        totalPrice: totalPrice,
        currency: currency,
        status: BookingStatus.pending,
        details: details,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore.collection('bookings').doc(bookingId).set(booking.toMap());

      // In real implementation:
      // - Call booking API to create reservation
      // - Process payment
      // - Get confirmation code
      // - Update booking status

      // Simulate booking confirmation
      final confirmedBooking = await _confirmBooking(bookingId);

      AppLogger.success(_tag, 'Booking created', {
        'bookingId': bookingId,
      });

      return confirmedBooking;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create booking', e, stackTrace);
      return null;
    }
  }

  /// Confirm booking (internal method)
  Future<Booking?> _confirmBooking(String bookingId) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Generate confirmation code
      final confirmationCode = 'RLK${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // Update booking
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.confirmed.name,
        'confirmationCode': confirmationCode,
        'confirmedAt': FieldValue.serverTimestamp(),
      });

      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      return Booking.fromMap(doc.data()!);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to confirm booking', e, stackTrace);
      return null;
    }
  }

  /// Get user bookings
  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Booking.fromMap(doc.data())).toList();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get user bookings', e, stackTrace);
      return [];
    }
  }

  /// Get upcoming bookings
  Future<List<Booking>> getUpcomingBookings(String userId) async {
    try {
      final now = DateTime.now();

      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('checkInDate', isGreaterThan: now.toIso8601String())
          .where('status', isEqualTo: BookingStatus.confirmed.name)
          .orderBy('checkInDate')
          .get();

      return snapshot.docs.map((doc) => Booking.fromMap(doc.data())).toList();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get upcoming bookings', e, stackTrace);
      return [];
    }
  }

  /// Cancel booking
  Future<bool> cancelBooking(String bookingId, String reason) async {
    try {
      AppLogger.info(_tag, 'Cancelling booking', {
        'bookingId': bookingId,
        'reason': reason,
      });

      // In real implementation:
      // - Call booking API to cancel
      // - Process refund if applicable
      // - Send cancellation confirmation email

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.cancelled.name,
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      AppLogger.success(_tag, 'Booking cancelled');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to cancel booking', e, stackTrace);
      return false;
    }
  }

  /// Get booking details
  Future<Booking?> getBooking(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();

      if (!doc.exists) return null;

      return Booking.fromMap(doc.data()!);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get booking', e, stackTrace);
      return null;
    }
  }

  /// Check booking availability
  Future<bool> checkAvailability({
    required BookingType type,
    required String itemId,
    required DateTime checkInDate,
    DateTime? checkOutDate,
    required int guests,
  }) async {
    try {
      AppLogger.debug(_tag, 'Checking availability', {
        'type': type.name,
        'itemId': itemId,
      });

      // In real implementation, call provider API to check availability

      // Mock: Random availability
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to check availability', e, stackTrace);
      return false;
    }
  }

  /// Get cancellation policy
  Future<Map<String, dynamic>> getCancellationPolicy(
    BookingType type,
    String itemId,
  ) async {
    try {
      // In real implementation, get from provider API

      // Mock cancellation policy
      return {
        'freeCancellationBefore': DateTime.now().add(const Duration(days: 7)),
        'partialRefundBefore': DateTime.now().add(const Duration(days: 3)),
        'noRefundAfter': DateTime.now().add(const Duration(days: 1)),
        'cancellationFee': 0.0,
        'currency': 'USD',
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get cancellation policy', e, stackTrace);
      return {};
    }
  }

  /// Add booking to trip
  Future<bool> addBookingToTrip(String bookingId, String tripId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'tripId': tripId,
      });

      AppLogger.success(_tag, 'Booking added to trip');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add booking to trip', e, stackTrace);
      return false;
    }
  }

  /// Get trip bookings
  Future<List<Booking>> getTripBookings(String tripId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('tripId', isEqualTo: tripId)
          .orderBy('checkInDate')
          .get();

      return snapshot.docs.map((doc) => Booking.fromMap(doc.data())).toList();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get trip bookings', e, stackTrace);
      return [];
    }
  }
}
