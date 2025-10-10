import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Trip Planning Integration Tests', () {
    testWidgets('Complete trip creation flow', (WidgetTester tester) async {
      // Test the complete flow of creating a trip from start to finish

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('My Trips')),
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreateTripScreen(),
                        ),
                      );
                    },
                    child: const Text('Create Trip'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Navigate to create trip
      await tester.tap(find.text('Create Trip'));
      await tester.pumpAndSettle();

      // Step 2: Fill trip basic information
      expect(find.text('New Trip'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('trip_name_field')),
        'Bali Adventure 2025',
      );

      await tester.enterText(
        find.byKey(const Key('trip_description_field')),
        'A wonderful trip to explore Bali',
      );

      // Select destination
      await tester.tap(find.byKey(const Key('destination_selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bali, Indonesia'));
      await tester.pumpAndSettle();

      // Step 3: Set dates
      await tester.tap(find.byKey(const Key('start_date_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('end_date_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('22'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Step 4: Set budget
      await tester.enterText(
        find.byKey(const Key('budget_field')),
        '5000000',
      );
      await tester.pumpAndSettle();

      // Step 5: Add travelers
      await tester.tap(find.byKey(const Key('add_traveler_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('traveler_name_field')),
        'Jane Doe',
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Step 6: Create trip
      await tester.tap(find.text('Create Trip'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify trip created
      expect(find.text('Trip Created Successfully'), findsOneWidget);

      // Step 7: View trip details
      await tester.tap(find.text('View Trip'));
      await tester.pumpAndSettle();

      expect(find.text('Bali Adventure 2025'), findsOneWidget);
      expect(find.text('A wonderful trip to explore Bali'), findsOneWidget);
    });

    testWidgets('Add itinerary items to trip', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TripDetailScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to itinerary tab
      await tester.tap(find.text('Itinerary'));
      await tester.pumpAndSettle();

      // Add new itinerary item
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill itinerary details
      await tester.enterText(
        find.byKey(const Key('activity_title_field')),
        'Visit Tanah Lot Temple',
      );

      await tester.enterText(
        find.byKey(const Key('activity_description_field')),
        'Iconic sea temple at sunset',
      );

      // Select time
      await tester.tap(find.byKey(const Key('activity_time_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('17'));
      await tester.tap(find.text('00'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Set duration
      await tester.enterText(
        find.byKey(const Key('duration_field')),
        '2',
      );
      await tester.pumpAndSettle();

      // Save itinerary item
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify item added
      expect(find.text('Visit Tanah Lot Temple'), findsOneWidget);
    });

    testWidgets('Add expenses to trip budget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TripDetailScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to budget tab
      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();

      // Add new expense
      await tester.tap(find.text('Add Expense'));
      await tester.pumpAndSettle();

      // Fill expense details
      await tester.enterText(
        find.byKey(const Key('expense_title_field')),
        'Hotel Accommodation',
      );

      await tester.enterText(
        find.byKey(const Key('expense_amount_field')),
        '2500000',
      );

      // Select category
      await tester.tap(find.byKey(const Key('category_selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accommodation'));
      await tester.pumpAndSettle();

      // Save expense
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify expense added and budget updated
      expect(find.text('Hotel Accommodation'), findsOneWidget);
      expect(find.textContaining('2,500,000'), findsOneWidget);
    });

    testWidgets('AI itinerary generation flow', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TripDetailScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to itinerary
      await tester.tap(find.text('Itinerary'));
      await tester.pumpAndSettle();

      // Tap AI generate button
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();

      // Verify AI generator screen
      expect(find.text('AI Itinerary Generator'), findsOneWidget);

      // Set preferences
      await tester.tap(find.text('Culture'));
      await tester.tap(find.text('Adventure'));
      await tester.pumpAndSettle();

      // Set pace
      await tester.tap(find.text('Moderate'));
      await tester.pumpAndSettle();

      // Generate itinerary
      await tester.tap(find.text('Generate'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify generated itinerary
      expect(find.byType(Card), findsWidgets);

      // Accept generated itinerary
      await tester.tap(find.text('Accept Itinerary'));
      await tester.pumpAndSettle();

      // Verify itinerary added to trip
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('Trip sharing flow', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TripDetailScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap share button
      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();

      // Verify share options
      expect(find.text('Share Trip'), findsOneWidget);
      expect(find.text('Share Link'), findsOneWidget);
      expect(find.text('Invite Collaborators'), findsOneWidget);

      // Test invite collaborators
      await tester.tap(find.text('Invite Collaborators'));
      await tester.pumpAndSettle();

      // Enter email
      await tester.enterText(
        find.byKey(const Key('collaborator_email_field')),
        'friend@example.com',
      );
      await tester.pumpAndSettle();

      // Send invitation
      await tester.tap(find.text('Send Invite'));
      await tester.pumpAndSettle();

      // Verify invite sent
      expect(find.text('Invitation Sent'), findsOneWidget);
    });

    testWidgets('Edit trip details', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TripDetailScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap edit button
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Update trip name
      await tester.enterText(
        find.byKey(const Key('trip_name_field')),
        'Bali Adventure 2025 - Updated',
      );
      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Verify updated
      expect(find.text('Bali Adventure 2025 - Updated'), findsOneWidget);
    });

    testWidgets('Delete trip flow', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TripDetailScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap more options
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.text('Delete Trip'));
      await tester.pumpAndSettle();

      // Confirm deletion
      expect(find.text('Delete Trip?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify trip deleted
      expect(find.text('Trip Deleted'), findsOneWidget);
    });
  });
}

// Mock screens
class CreateTripScreen extends StatelessWidget {
  const CreateTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Trip')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const TextField(key: Key('trip_name_field')),
            const TextField(key: Key('trip_description_field')),
            TextButton(
              key: const Key('destination_selector'),
              onPressed: () {},
              child: const Text('Select Destination'),
            ),
            const TextField(key: Key('start_date_field')),
            const TextField(key: Key('end_date_field')),
            const TextField(key: Key('budget_field')),
            ElevatedButton(
              key: const Key('add_traveler_button'),
              onPressed: () {},
              child: const Text('Add Traveler'),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Create Trip'),
            ),
          ],
        ),
      ),
    );
  }
}

class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          const Text('Itinerary'),
          const Text('Budget'),
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
          IconButton(icon: const Icon(Icons.auto_awesome), onPressed: () {}),
        ],
      ),
    );
  }
}
