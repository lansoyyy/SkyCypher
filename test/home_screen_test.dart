import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skycypher/screens/home_screen.dart';

void main() {
  testWidgets('Home screen has voice assistant FAB', (WidgetTester tester) async {
    // Build the home screen
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    // Verify that the voice assistant FAB is present
    expect(find.byIcon(Icons.mic), findsOneWidget);
    
    // Verify that the FAB has the correct background color
    final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
    expect(fab.backgroundColor, const Color(0xFF6366F1)); // app_colors.secondary
  });
}