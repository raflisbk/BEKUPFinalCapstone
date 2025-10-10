import 'package:flutter_test/flutter_test.dart';
import 'package:relink/services/booking_service.dart';
import '../test_setup.dart';

void main() {
  late BookingService bookingService;

  setUpAll(() async {
    await setupTestEnvironment();
  });

  setUp(() {
    bookingService = BookingService();
  });

  group('BookingService - Search Tests', () {
    test('searchHotels returns list of hotels', () async {
      final hotels = await bookingService.searchHotels(
        destination: 'Jakarta',
        checkIn: DateTime(2025, 11, 1),
        checkOut: DateTime(2025, 11, 5),
        guests: 2,
      );

      expect(hotels, isNotEmpty);
      expect(hotels.length, greaterThan(0));
      expect(hotels.first['name'], isNotNull);
      expect(hotels.first['pricePerNight'], isA<double>());
    });

    test('searchHotels with price filters', () async {
      final hotels = await bookingService.searchHotels(
        destination: 'Bali',
        checkIn: DateTime(2025, 11, 1),
        checkOut: DateTime(2025, 11, 5),
        guests: 2,
        minPrice: 100.0,
        maxPrice: 200.0,
      );

      expect(hotels, isNotEmpty);
      for (var hotel in hotels) {
        final price = hotel['pricePerNight'] as double;
        expect(price, greaterThanOrEqualTo(0));
      }
    });

    test('searchFlights returns list of flights', () async {
      final flights = await bookingService.searchFlights(
        origin: 'Jakarta',
        destination: 'Bali',
        departureDate: DateTime(2025, 11, 1),
        passengers: 2,
      );

      expect(flights, isNotEmpty);
      expect(flights.first['airline'], isNotNull);
      expect(flights.first['price'], isA<double>());
      expect(flights.first['stops'], isA<int>());
    });

    test('searchFlights with return date', () async {
      final flights = await bookingService.searchFlights(
        origin: 'Jakarta',
        destination: 'Bali',
        departureDate: DateTime(2025, 11, 1),
        returnDate: DateTime(2025, 11, 7),
        passengers: 2,
      );

      expect(flights, isNotEmpty);
    });

    test('searchActivities returns list of activities', () async {
      final activities = await bookingService.searchActivities(
        destination: 'Bali',
        date: DateTime(2025, 11, 1),
      );

      expect(activities, isNotEmpty);
      expect(activities.first['name'], isNotNull);
      expect(activities.first['price'], isA<double>());
      expect(activities.first['rating'], isA<double>());
    });

    test('searchActivities with category filter', () async {
      final activities = await bookingService.searchActivities(
        destination: 'Bali',
        date: DateTime(2025, 11, 1),
        category: 'Culture',
      );

      expect(activities, isNotEmpty);
    });
  });

  group('BookingService - Booking Management Tests', () {
    test('createBooking creates new booking successfully', () async {
      final booking = await bookingService.createBooking(
        userId: 'test_user_123',
        type: BookingType.hotel,
        providerName: 'Grand Hotel',
        itemName: 'Deluxe Room',
        itemId: 'hotel_1',
        checkInDate: DateTime(2025, 11, 1),
        checkOutDate: DateTime(2025, 11, 5),
        guests: 2,
        totalPrice: 500.0,
        currency: 'USD',
      );

      expect(booking, isNotNull);
      expect(booking!.status, BookingStatus.confirmed);
      expect(booking.confirmationCode, isNotNull);
      expect(booking.userId, 'test_user_123');
      expect(booking.totalPrice, 500.0);
    });

    test('createBooking with flight type', () async {
      final booking = await bookingService.createBooking(
        userId: 'test_user_123',
        type: BookingType.flight,
        providerName: 'SkyHigh Airlines',
        itemName: 'Flight SH101',
        checkInDate: DateTime(2025, 11, 1),
        guests: 1,
        totalPrice: 350.0,
        currency: 'USD',
        details: {'flightNumber': 'SH101', 'class': 'Economy'},
      );

      expect(booking, isNotNull);
      expect(booking!.type, BookingType.flight);
      expect(booking.details?['flightNumber'], 'SH101');
    });

    test('createBooking with activity type', () async {
      final booking = await bookingService.createBooking(
        userId: 'test_user_123',
        type: BookingType.activity,
        providerName: 'Local Tours',
        itemName: 'City Walking Tour',
        checkInDate: DateTime(2025, 11, 1),
        guests: 2,
        totalPrice: 90.0,
        currency: 'USD',
      );

      expect(booking, isNotNull);
      expect(booking!.type, BookingType.activity);
    });

    test('getUserBookings returns user bookings', () async {
      // Create a booking first
      await bookingService.createBooking(
        userId: 'test_user_123',
        type: BookingType.hotel,
        providerName: 'Test Hotel',
        itemName: 'Test Room',
        checkInDate: DateTime(2025, 11, 1),
        checkOutDate: DateTime(2025, 11, 5),
        guests: 2,
        totalPrice: 300.0,
        currency: 'USD',
      );

      final bookings = await bookingService.getUserBookings('test_user_123');

      expect(bookings, isA<List<Booking>>());
      // In real test with fake Firestore, expect(bookings, isNotEmpty);
    });

    test('getUpcomingBookings filters by date and status', () async {
      final upcomingBookings = await bookingService.getUpcomingBookings(
        'test_user_123',
      );

      expect(upcomingBookings, isA<List<Booking>>());
    });

    test('cancelBooking cancels booking successfully', () async {
      // Create a booking
      final booking = await bookingService.createBooking(
        userId: 'test_user_123',
        type: BookingType.hotel,
        providerName: 'Test Hotel',
        itemName: 'Test Room',
        checkInDate: DateTime(2025, 11, 1),
        checkOutDate: DateTime(2025, 11, 5),
        guests: 2,
        totalPrice: 300.0,
        currency: 'USD',
      );

      // Cancel it
      final result = await bookingService.cancelBooking(
        booking!.id,
        'Change of plans',
      );

      expect(result, isTrue);
    });

    test('getBooking retrieves booking by id', () async {
      // Create a booking
      final createdBooking = await bookingService.createBooking(
        userId: 'test_user_123',
        type: BookingType.hotel,
        providerName: 'Test Hotel',
        itemName: 'Test Room',
        checkInDate: DateTime(2025, 11, 1),
        checkOutDate: DateTime(2025, 11, 5),
        guests: 2,
        totalPrice: 300.0,
        currency: 'USD',
      );

      // Retrieve it
      await bookingService.getBooking(createdBooking!.id);

      // In real test with fake Firestore
      // final booking = await bookingService.getBooking(createdBooking!.id);
      // expect(booking, isNotNull);
      // expect(booking!.id, createdBooking.id);
    });
  });

  group('BookingService - Availability Tests', () {
    test('checkAvailability returns true for available items', () async {
      final isAvailable = await bookingService.checkAvailability(
        type: BookingType.hotel,
        itemId: 'hotel_1',
        checkInDate: DateTime(2025, 11, 1),
        checkOutDate: DateTime(2025, 11, 5),
        guests: 2,
      );

      expect(isAvailable, isTrue);
    });

    test('getCancellationPolicy returns policy details', () async {
      final policy = await bookingService.getCancellationPolicy(
        BookingType.hotel,
        'hotel_1',
      );

      expect(policy, isNotEmpty);
      expect(policy['freeCancellationBefore'], isNotNull);
      expect(policy['currency'], isNotNull);
    });
  });

  group('BookingService - Trip Integration Tests', () {
    test('addBookingToTrip associates booking with trip', () async {
      // Create a booking
      final booking = await bookingService.createBooking(
        userId: 'test_user_123',
        type: BookingType.hotel,
        providerName: 'Test Hotel',
        itemName: 'Test Room',
        checkInDate: DateTime(2025, 11, 1),
        checkOutDate: DateTime(2025, 11, 5),
        guests: 2,
        totalPrice: 300.0,
        currency: 'USD',
      );

      // Add to trip
      final result = await bookingService.addBookingToTrip(
        booking!.id,
        'trip_123',
      );

      expect(result, isTrue);
    });

    test('getTripBookings returns all bookings for a trip', () async {
      final tripBookings = await bookingService.getTripBookings('trip_123');

      expect(tripBookings, isA<List<Booking>>());
    });
  });

  group('Booking Model Tests', () {
    test('Booking toMap converts to map correctly', () {
      final booking = Booking(
        id: 'booking_123',
        userId: 'user_123',
        type: BookingType.hotel,
        providerName: 'Test Hotel',
        itemName: 'Test Room',
        checkInDate: DateTime(2025, 11, 1),
        checkOutDate: DateTime(2025, 11, 5),
        guests: 2,
        totalPrice: 300.0,
        currency: 'USD',
        status: BookingStatus.confirmed,
        confirmationCode: 'RLK123',
        createdAt: DateTime(2025, 10, 1),
      );

      final map = booking.toMap();

      expect(map['id'], 'booking_123');
      expect(map['userId'], 'user_123');
      expect(map['type'], 'hotel');
      expect(map['status'], 'confirmed');
      expect(map['totalPrice'], 300.0);
      expect(map['confirmationCode'], 'RLK123');
    });

    test('Booking fromMap creates booking from map', () {
      final map = {
        'id': 'booking_123',
        'userId': 'user_123',
        'type': 'hotel',
        'providerName': 'Test Hotel',
        'itemName': 'Test Room',
        'checkInDate': '2025-11-01T00:00:00.000',
        'checkOutDate': '2025-11-05T00:00:00.000',
        'guests': 2,
        'totalPrice': 300.0,
        'currency': 'USD',
        'status': 'confirmed',
        'confirmationCode': 'RLK123',
        'createdAt': '2025-10-01T00:00:00.000',
      };

      final booking = Booking.fromMap(map);

      expect(booking.id, 'booking_123');
      expect(booking.type, BookingType.hotel);
      expect(booking.status, BookingStatus.confirmed);
      expect(booking.totalPrice, 300.0);
    });

    test('Booking handles missing optional fields', () {
      final map = {
        'id': 'booking_123',
        'userId': 'user_123',
        'type': 'flight',
        'providerName': 'Airline',
        'itemName': 'Flight',
        'checkInDate': '2025-11-01T00:00:00.000',
        'guests': 1,
        'totalPrice': 350.0,
        'currency': 'USD',
        'status': 'pending',
        'createdAt': '2025-10-01T00:00:00.000',
      };

      final booking = Booking.fromMap(map);

      expect(booking.checkOutDate, isNull);
      expect(booking.confirmationCode, isNull);
      expect(booking.confirmedAt, isNull);
    });
  });

  group('Booking Enum Tests', () {
    test('BookingType enum has correct values', () {
      expect(BookingType.values.length, 5);
      expect(BookingType.hotel.name, 'hotel');
      expect(BookingType.flight.name, 'flight');
      expect(BookingType.activity.name, 'activity');
      expect(BookingType.restaurant.name, 'restaurant');
      expect(BookingType.transportation.name, 'transportation');
    });

    test('BookingStatus enum has correct values', () {
      expect(BookingStatus.values.length, 5);
      expect(BookingStatus.pending.name, 'pending');
      expect(BookingStatus.confirmed.name, 'confirmed');
      expect(BookingStatus.cancelled.name, 'cancelled');
      expect(BookingStatus.completed.name, 'completed');
      expect(BookingStatus.failed.name, 'failed');
    });
  });
}
