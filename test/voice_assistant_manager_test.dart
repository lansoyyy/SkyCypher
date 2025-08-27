import 'package:flutter_test/flutter_test.dart';
import 'package:skycypher/services/voice_assistant_manager.dart';

void main() {
  group('VoiceAssistantManager', () {
    late VoiceAssistantManager manager;

    setUp(() {
      manager = VoiceAssistantManager.getInstance();
    });

    test('singleton instance', () {
      final instance1 = VoiceAssistantManager.getInstance();
      final instance2 = VoiceAssistantManager.getInstance();
      expect(instance1, equals(instance2));
    });

    test('initial state', () {
      expect(manager.isListening, false);
      expect(manager.isProcessing, false);
      expect(manager.recognizedText, '');
      expect(manager.statusMessage, 'Ready to listen');
      expect(manager.isDialogVisible, false);
    });

    test('voice command model', () {
      final now = DateTime.now();
      final command = VoiceCommand(
        text: 'Test command',
        confidence: 0.8,
        timestamp: now,
      );

      expect(command.text, 'Test command');
      expect(command.confidence, 0.8);
      expect(command.timestamp, now);
    });
  });
}