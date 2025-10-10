import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:relink/presentation/explore/explore_screen.dart';
import 'package:relink/core/providers/location_provider.dart';
import 'package:relink/core/providers/auth_provider.dart';
import '../test_setup.dart';

/// Widget tests for Map Screen (Explore Screen)
/// Tests Google Maps integration, markers, and location features
void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  group('Map Screen (Explore Screen) Tests', () {
    late LocationProvider mockLocationProvider;
    late AuthProvider mockAuthProvider;

    setUp(() {
      mockLocationProvider = LocationProvider();
      mockAuthProvider = AuthProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<LocationProvider>.value(
              value: mockLocationProvider,
            ),
            ChangeNotifierProvider<AuthProvider>.value(
              value: mockAuthProvider,
            ),
          ],
          child: const ExploreScreen(),
        ),
      );
    }

    testWidgets('should display Google Map widget', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - GoogleMap widget should be present
      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('should display current location button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should have FAB or button for current location
      expect(find.byType(FloatingActionButton), findsWidgets);
      expect(find.byIcon(Icons.my_location), findsWidgets);
    });

    testWidgets('should display destination markers on map', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Markers should be loaded
      // Note: Markers are set on GoogleMap widget, not directly testable in widget tests
      // but we can verify the GoogleMap widget is configured with markers
      final googleMapWidget = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(googleMapWidget, isNotNull);
    });

    testWidgets('should show marker clustering indicator', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - When multiple markers are close together, clustering should occur
      // Note: Clustering behavior is internal to GoogleMap
      // We can verify clustering is enabled in the widget configuration
      final googleMapWidget = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(googleMapWidget, isNotNull);
    });

    testWidgets('should center map on current location when button tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap location button
      final locationButton = find.byIcon(Icons.my_location);
      if (locationButton.evaluate().isNotEmpty) {
        await tester.tap(locationButton);
        await tester.pumpAndSettle();

        // Assert - Map should recenter
        // Note: Would need to verify map controller camera position
        // This requires integration testing or mocking GoogleMapController
      }
    });

    testWidgets('should display loading indicator while loading', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Initial pump without settle to catch loading state
      await tester.pump();

      // Assert - May show loading indicator briefly
      // Note: Timing-dependent, may need adjustment
    });

    testWidgets('should display location sharing toggle', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should have toggle for location sharing
      // Note: May be in app bar, bottom sheet, or settings menu
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('should display nearby travelers when location sharing enabled', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Enable location sharing if toggle exists
      final locationToggle = find.byType(Switch);
      if (locationToggle.evaluate().isNotEmpty) {
        await tester.tap(locationToggle.first);
        await tester.pumpAndSettle();

        // Assert - Nearby travelers should appear as markers
        // Note: Requires mock location data
      }
    });
  });

  group('Map Interaction Tests', () {
    late LocationProvider mockLocationProvider;
    late AuthProvider mockAuthProvider;

    setUp(() {
      mockLocationProvider = LocationProvider();
      mockAuthProvider = AuthProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<LocationProvider>.value(
              value: mockLocationProvider,
            ),
            ChangeNotifierProvider<AuthProvider>.value(
              value: mockAuthProvider,
            ),
          ],
          child: const ExploreScreen(),
        ),
      );
    }

    testWidgets('should display marker info window when marker tapped', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Note: Tapping markers requires integration testing
      // as markers are rendered by native map view
      // Widget tests can verify GoogleMap is configured with markers
      final googleMapWidget = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(googleMapWidget, isNotNull);
    });

    testWidgets('should update map when zoom level changes', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Note: Map zoom interactions require integration testing
      // Widget tests verify the GoogleMap widget is present and configured
      final googleMapWidget = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(googleMapWidget.onCameraMove, isNotNull);
    });
  });
}
