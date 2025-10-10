import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Common Widget Tests', () {
    testWidgets('Text widget displays correctly', (WidgetTester tester) async {
      const testText = 'Hello, ReLink!';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text(testText),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('Button widget is clickable', (WidgetTester tester) async {
      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                buttonPressed = true;
              },
              child: const Text('Click Me'),
            ),
          ),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(buttonPressed, isTrue);
    });

    testWidgets('TextField accepts input', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: controller,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Test Input');
      await tester.pump();

      expect(controller.text, 'Test Input');
    });

    testWidgets('Card widget displays content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Card Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('ListTile displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('John Doe'),
                  subtitle: Text('john@example.com'),
                  trailing: Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('Checkbox can be toggled', (WidgetTester tester) async {
      var isChecked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Checkbox(
                  value: isChecked,
                  onChanged: (value) {
                    setState(() {
                      isChecked = value!;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(Checkbox), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('Switch can be toggled', (WidgetTester tester) async {
      var isSwitched = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Switch(
                  value: isSwitched,
                  onChanged: (value) {
                    setState(() {
                      isSwitched = value;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(Switch), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pump();

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('Icon displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Icon(
              Icons.star,
              color: Colors.yellow,
              size: 48,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(icon.color, Colors.yellow);
      expect(icon.size, 48);
    });

    testWidgets('AppBar displays title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('ReLink'),
            ),
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('ReLink'), findsOneWidget);
    });

    testWidgets('FloatingActionButton is tappable', (WidgetTester tester) async {
      var fabPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                fabPressed = true;
              },
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(fabPressed, isTrue);
    });

    testWidgets('CircularProgressIndicator displays', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Snackbar displays message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Test Message')),
                    );
                  },
                  child: const Text('Show Snackbar'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Snackbar'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 750)); // Complete animation

      expect(find.text('Test Message'), findsOneWidget);
    });

    testWidgets('AlertDialog displays and can be dismissed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Alert'),
                        content: const Text('This is a test alert'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Alert'), findsOneWidget);
      expect(find.text('This is a test alert'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Alert'), findsNothing);
    });

    testWidgets('ListView scrolls correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 50,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Item $index'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 49'), findsNothing);

      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pump();

      expect(find.text('Item 0'), findsNothing);
      expect(find.text('Item 49'), findsOneWidget);
    });

    testWidgets('Row arranges children horizontally', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Text('Left'),
                Text('Center'),
                Text('Right'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Left'), findsOneWidget);
      expect(find.text('Center'), findsOneWidget);
      expect(find.text('Right'), findsOneWidget);

      final leftPos = tester.getTopLeft(find.text('Left'));
      final centerPos = tester.getTopLeft(find.text('Center'));
      final rightPos = tester.getTopLeft(find.text('Right'));

      expect(leftPos.dx < centerPos.dx, isTrue);
      expect(centerPos.dx < rightPos.dx, isTrue);
    });

    testWidgets('Column arranges children vertically', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Top'),
                Text('Middle'),
                Text('Bottom'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Top'), findsOneWidget);
      expect(find.text('Middle'), findsOneWidget);
      expect(find.text('Bottom'), findsOneWidget);

      final topPos = tester.getTopLeft(find.text('Top'));
      final middlePos = tester.getTopLeft(find.text('Middle'));
      final bottomPos = tester.getTopLeft(find.text('Bottom'));

      expect(topPos.dy < middlePos.dy, isTrue);
      expect(middlePos.dy < bottomPos.dy, isTrue);
    });
  });
}
