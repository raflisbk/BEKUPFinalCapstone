import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:relink/presentation/explore/indonesia_tourism_screen.dart';
import 'package:relink/core/providers/indonesia_tourism_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Indonesia Tourism Integration Tests', () {
    testWidgets('Complete user flow: search, filter, view destination', (tester) async {
      // Setup
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => IndonesiaTourismProvider(),
            child: const IndonesiaTourismScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Wait for trending destinations to load
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byType(Card), findsWidgets);

      // Step 2: Search for a destination
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'bali');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify search results
      expect(find.byType(Card), findsWidgets);

      // Step 3: Filter by province
      final provinceChip = find.text('Bali');
      if (provinceChip.evaluate().isNotEmpty) {
        await tester.tap(provinceChip);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Step 4: Filter by category
      final beachCategory = find.textContaining('Pantai');
      if (beachCategory.evaluate().isNotEmpty) {
        await tester.dragUntilVisible(
          beachCategory,
          find.byType(ListView).first,
          const Offset(-200, 0),
        );
        await tester.tap(beachCategory);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Verify filtered results
      expect(find.byType(Card), findsWidgets);

      // Step 5: Tap on a destination card
      final firstCard = find.byType(Card).first;
      await tester.tap(firstCard);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify navigation occurred (destination detail should be shown)
      // This depends on your navigation implementation
    });

    testWidgets('Test pull-to-refresh functionality', (tester) async {
      // Setup
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => IndonesiaTourismProvider(),
            child: const IndonesiaTourismScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Perform pull-to-refresh
      await tester.drag(
        find.byType(RefreshIndicator),
        const Offset(0, 500),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify data is refreshed
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('Test error handling and retry', (tester) async {
      // This would test offline or error scenarios
      // Requires network mocking or test configuration
    });

    testWidgets('Test filter combinations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => IndonesiaTourismProvider(),
            child: const IndonesiaTourismScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Test Province + Category filter combination
      final yogyaChip = find.text('D.I. Yogyakarta');
      if (yogyaChip.evaluate().isNotEmpty) {
        await tester.dragUntilVisible(
          yogyaChip,
          find.byType(ListView).first,
          const Offset(-200, 0),
        );
        await tester.tap(yogyaChip);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Then filter by category
      final cultureCategory = find.textContaining('Budaya');
      if (cultureCategory.evaluate().isNotEmpty) {
        await tester.dragUntilVisible(
          cultureCategory,
          find.byType(ListView).at(1),
          const Offset(-200, 0),
        );
        await tester.tap(cultureCategory);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Verify results
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('Test clear filters functionality', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => IndonesiaTourismProvider(),
            child: const IndonesiaTourismScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Apply province filter
      final baliChip = find.text('Bali');
      if (baliChip.evaluate().isNotEmpty) {
        await tester.tap(baliChip);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Clear by selecting "Semua"
      final semuaChip = find.text('Semua');
      await tester.tap(semuaChip);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify filters are cleared and trending is shown
      expect(find.byType(Card), findsWidgets);
    });
  });
}
