import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skycypher/screens/simplified_voice_inspection_screen.dart';

void main() {
  testWidgets('SimplifiedVoiceInspectionScreen renders correctly',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        home: const SimplifiedVoiceInspectionScreen(
          aircraftModel: 'Cessna 152',
          rpNumber: 'RP-C152-001',
        ),
      ),
    );

    // Verify that the screen renders
    expect(find.text('Simplified Voice Inspection'), findsOneWidget);
    expect(find.text('Cessna 152'), findsOneWidget);
    expect(find.text('RP: RP-C152-001'), findsOneWidget);
  });
}
