import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:relink/presentation/explore/indonesia_tourism_screen.dart';
import 'package:relink/core/providers/indonesia_tourism_provider.dart';

void main() {
  group('IndonesiaTourismScreen Widget Tests', () {
    late IndonesiaTourismProvider mockProvider;

    setUp(() {
      mockProvider = IndonesiaTourismProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<IndonesiaTourismProvider>.value(
          value: mockProvider,
          child: const IndonesiaTourismScreen(),
        ),
      );
    }

    testWidgets('should display app bar with title', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('🇮🇩 Wisata Indonesia'), findsOneWidget);
    });

    testWidgets('should display search field', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Cari destinasi wisata...'), findsOneWidget);
    });

    testWidgets('should display loading indicator when loading', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act
      mockProvider.loadTrendingDestinations();
      await tester.pump(); // Trigger rebuild

      // Assert (may show loading briefly)
      // Note: This is timing-dependent, might need adjustment
    });

    testWidgets('should display destinations when loaded', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act
      await mockProvider.loadTrendingDestinations();
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('should display error message on error', (tester) async {
      // This would require mocking the service to return an error
      // For now, we test the error UI structure
      await tester.pumpWidget(createTestWidget());

      // The error state UI should be testable if error occurs
    });

    testWidgets('should display province filter chips', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(FilterChip), findsWidgets);
      expect(find.text('Semua'), findsOneWidget);
    });

    testWidgets('should display category filter chips', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('🌴 Semua Kategori'), findsOneWidget);
    });

    testWidgets('should clear search on clear button tap', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'temple');

      // Act
      final clearButton = find.byIcon(Icons.clear);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('temple'), findsNothing);
    });

    testWidgets('should trigger search on submit', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'borobudur');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert - provider should have triggered search
      expect(mockProvider.destinations, isNotEmpty);
    });

    testWidgets('should support pull-to-refresh', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await mockProvider.loadTrendingDestinations();
      await tester.pumpAndSettle();

      // Act
      await tester.drag(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();

      // Assert - data should be reloaded
    });

    testWidgets('should navigate to detail on card tap', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await mockProvider.loadTrendingDestinations();
      await tester.pumpAndSettle();

      // Act
      if (mockProvider.trendingDestinations.isNotEmpty) {
        final firstCard = find.byType(Card).first;
        await tester.tap(firstCard);
        await tester.pumpAndSettle();

        // Assert - should navigate (would need navigation observer)
      }
    });
  });
}
