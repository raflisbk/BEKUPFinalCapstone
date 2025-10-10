import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Booking Flow Integration Tests', () {
    testWidgets('Complete hotel booking flow', (WidgetTester tester) async {
      // This integration test simulates the complete hotel booking user journey
      // from search to payment confirmation

      // Step 1: Navigate to booking screen
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Booking')),
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BookingSearchScreen(),
                        ),
                      );
                    },
                    child: const Text('Book a Hotel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap book hotel button
      await tester.tap(find.text('Book a Hotel'));
      await tester.pumpAndSettle();

      // Step 2: Search for hotels
      expect(find.text('Search Hotels'), findsOneWidget);

      // Enter destination
      await tester.enterText(
        find.byKey(const Key('destination_field')),
        'Bali',
      );
      await tester.pumpAndSettle();

      // Select check-in date
      await tester.tap(find.byKey(const Key('checkin_date_field')));
      await tester.pumpAndSettle();
      // Tap on a date in the calendar
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Select check-out date
      await tester.tap(find.byKey(const Key('checkout_date_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Enter number of guests
      await tester.enterText(
        find.byKey(const Key('guests_field')),
        '2',
      );
      await tester.pumpAndSettle();

      // Tap search button
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 3: View search results
      expect(find.byType(Card), findsWidgets);

      // Step 4: Select a hotel
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      // Step 5: View hotel details
      expect(find.text('Hotel Details'), findsOneWidget);

      // Step 6: Proceed to booking
      await tester.tap(find.text('Book Now'));
      await tester.pumpAndSettle();

      // Step 7: Fill guest information
      expect(find.text('Guest Information'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('guest_name_field')),
        'John Doe',
      );
      await tester.enterText(
        find.byKey(const Key('guest_email_field')),
        'john@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('guest_phone_field')),
        '+6281234567890',
      );
      await tester.pumpAndSettle();

      // Step 8: Proceed to payment
      await tester.tap(find.text('Continue to Payment'));
      await tester.pumpAndSettle();

      // Step 9: Select payment method
      expect(find.text('Payment Method'), findsOneWidget);

      await tester.tap(find.text('Credit Card'));
      await tester.pumpAndSettle();

      // Step 10: Enter payment details
      await tester.enterText(
        find.byKey(const Key('card_number_field')),
        '4242424242424242',
      );
      await tester.enterText(
        find.byKey(const Key('card_expiry_field')),
        '12/25',
      );
      await tester.enterText(
        find.byKey(const Key('card_cvv_field')),
        '123',
      );
      await tester.pumpAndSettle();

      // Step 11: Confirm payment
      await tester.tap(find.text('Confirm Payment'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Step 12: Verify booking confirmation
      expect(find.text('Booking Confirmed'), findsOneWidget);
      expect(find.textContaining('Confirmation Code:'), findsOneWidget);

      // Step 13: View booking details
      expect(find.text('View Booking'), findsOneWidget);
    });

    testWidgets('Flight booking flow', (WidgetTester tester) async {
      // Simplified flight booking flow test
      await tester.pumpWidget(
        const MaterialApp(
          home: FlightBookingScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Search for flights
      await tester.enterText(find.byKey(const Key('origin_field')), 'Jakarta');
      await tester.enterText(
        find.byKey(const Key('destination_field')),
        'Bali',
      );

      await tester.tap(find.text('Search Flights'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Select a flight
      expect(find.byType(Card), findsWidgets);
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      // Verify flight details displayed
      expect(find.text('Flight Details'), findsOneWidget);
    });

    testWidgets('Activity booking flow', (WidgetTester tester) async {
      // Activity booking flow test
      await tester.pumpWidget(
        const MaterialApp(
          home: ActivityBookingScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Search for activities
      await tester.enterText(
        find.byKey(const Key('activity_destination_field')),
        'Ubud',
      );

      await tester.tap(find.text('Search Activities'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Browse activity categories
      expect(find.text('Culture'), findsOneWidget);
      expect(find.text('Adventure'), findsOneWidget);

      // Filter by category
      await tester.tap(find.text('Culture'));
      await tester.pumpAndSettle();

      // Select an activity
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      // Verify activity details
      expect(find.text('Activity Details'), findsOneWidget);
    });

    testWidgets('Booking cancellation flow', (WidgetTester tester) async {
      // Test booking cancellation
      await tester.pumpWidget(
        const MaterialApp(
          home: MyBookingsScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // View bookings list
      expect(find.byType(ListTile), findsWidgets);

      // Tap on a booking
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // Tap cancel button
      await tester.tap(find.text('Cancel Booking'));
      await tester.pumpAndSettle();

      // Confirm cancellation in dialog
      expect(find.text('Cancel Booking?'), findsOneWidget);
      expect(find.text('This action cannot be undone'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('cancellation_reason_field')),
        'Change of plans',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm Cancellation'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify cancellation success
      expect(find.text('Booking Cancelled'), findsOneWidget);
    });

    testWidgets('Booking history and details view', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyBookingsScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify bookings are displayed
      expect(find.byType(ListTile), findsWidgets);

      // Filter by booking type
      await tester.tap(find.text('Hotels'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsWidgets);

      await tester.tap(find.text('Flights'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Activities'));
      await tester.pumpAndSettle();

      // View booking details
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // Verify details screen
      expect(find.textContaining('Booking ID:'), findsOneWidget);
      expect(find.textContaining('Status:'), findsOneWidget);
      expect(find.textContaining('Total Price:'), findsOneWidget);
    });
  });
}

// Mock screens for integration testing
class BookingSearchScreen extends StatelessWidget {
  const BookingSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Hotels')),
      body: Column(
        children: [
          const TextField(key: Key('destination_field')),
          const TextField(key: Key('checkin_date_field')),
          const TextField(key: Key('checkout_date_field')),
          const TextField(key: Key('guests_field')),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}

class FlightBookingScreen extends StatelessWidget {
  const FlightBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Flight')),
      body: Column(
        children: [
          const TextField(key: Key('origin_field')),
          const TextField(key: Key('destination_field')),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Search Flights'),
          ),
        ],
      ),
    );
  }
}

class ActivityBookingScreen extends StatelessWidget {
  const ActivityBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Activity')),
      body: Column(
        children: [
          const TextField(key: Key('activity_destination_field')),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Search Activities'),
          ),
          const Text('Culture'),
          const Text('Adventure'),
        ],
      ),
    );
  }
}

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: Column(
        children: [
          const Text('Hotels'),
          const Text('Flights'),
          const Text('Activities'),
          ListTile(
            title: const Text('Sample Booking'),
            subtitle: const Text('Hotel in Bali'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
