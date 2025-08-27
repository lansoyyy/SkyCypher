# Voice Assistant Feature Documentation

## Overview

The voice assistant feature allows users to navigate to the voice inspection screen using voice commands. When the user speaks the word "inspection", the app will automatically navigate to the voice inspection screen while maintaining the voice assistant dialog for continuous voice control.

## How to Use

1. **Access the Voice Assistant**
   - On the home screen, tap the microphone floating action button (FAB) located at the bottom right corner
   - A voice assistant dialog will appear

2. **Using Voice Commands**
   - Press and hold the microphone button to start listening
   - Speak the word "inspection" to navigate to the voice inspection screen
   - Release the button to stop listening and process the command

3. **During Voice Inspection**
   - The voice assistant dialog remains active even after navigation
   - You can continue to use voice commands on the voice inspection screen
   - Press and hold the microphone button again for additional commands

## Technical Implementation

### Components

1. **Voice Assistant Manager** (`lib/services/voice_assistant_manager.dart`)
   - Singleton class that manages the voice assistant state
   - Handles speech recognition using the `speech_to_text` package
   - Manages the persistent dialog overlay
   - Processes voice commands and handles navigation

2. **Voice Assistant Dialog** (`lib/services/voice_assistant_manager.dart`)
   - Custom dialog widget that appears as an overlay
   - Features a microphone button with visual feedback
   - Displays recognized text and status messages
   - Remains visible across screen navigations

3. **Home Screen Integration** (`lib/screens/home_screen.dart`)
   - Floating action button that triggers the voice assistant
   - Integration with the VoiceAssistantManager singleton

### Dependencies

- `speech_to_text`: For speech recognition capabilities
- `flutter`: Core Flutter framework

### Architecture

The voice assistant uses an overlay approach to maintain its context across screen navigations:

1. When the FAB is pressed, the VoiceAssistantManager creates an OverlayEntry
2. The overlay is inserted into the current context's overlay
3. Speech recognition is initialized and started when the user presses the microphone
4. When "inspection" is recognized, the app navigates to the voice inspection screen
5. The overlay remains active during navigation, allowing continued voice interaction

## Customization

### Changing Voice Commands

To modify the voice commands that trigger navigation:

1. Open `lib/services/voice_assistant_manager.dart`
2. Locate the `_processCommand` method
3. Modify the condition in the if statement:
   ```dart
   if (lowerCommand.contains('your-new-command')) {
     _navigateToVoiceInspection();
   }
   ```

### Customizing the Dialog

To modify the appearance of the voice assistant dialog:

1. Open `lib/services/voice_assistant_manager.dart`
2. Locate the `VoiceAssistantDialog` widget
3. Modify the UI elements as needed

## Troubleshooting

### Voice Recognition Not Working

1. Ensure the app has microphone permissions
2. Check that the device has a working microphone
3. Verify that the speech_to_text package is properly installed

### Dialog Not Appearing

1. Ensure the VoiceAssistantManager is properly initialized
2. Check that the overlay is being inserted correctly
3. Verify there are no context-related issues

## Future Enhancements

Possible improvements to the voice assistant feature:

1. Add support for more voice commands
2. Implement confidence-based command processing
3. Add voice command history
4. Improve error handling and user feedback
5. Add support for continuous listening mode