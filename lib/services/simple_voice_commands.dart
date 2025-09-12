import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:skycypher/screens/aircraft_selection_screen.dart';
import 'package:skycypher/screens/maintenance_log_screen.dart';
import 'package:skycypher/screens/aircraft_status_screen.dart';

class SimpleVoiceCommands {
  static void listenForCommands(BuildContext context) async {
    // Show a simple dialog to indicate we're listening
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ListeningDialog();
      },
    );

    final speech = SpeechToText();

    // Initialize speech recognition
    bool available = false;
    try {
      print('Initializing speech recognition...');
      available = await speech.initialize(
        onError: (error) {
          print('Speech error: $error');
          Navigator.of(context, rootNavigator: true).pop(); // Close the dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Speech recognition error: $error')),
          );
        },
        onStatus: (status) {
          print('Speech status: $status');
        },
      );
      print('Speech recognition available: $available');
    } catch (e) {
      print('Exception during speech initialization: $e');
      Navigator.of(context, rootNavigator: true).pop(); // Close the dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition initialization failed: $e')),
      );
      return;
    }

    if (!available) {
      print('Speech recognition not available');
      Navigator.of(context, rootNavigator: true).pop(); // Close the dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Speech recognition not available on this device')),
      );
      return;
    }

    // Start listening
    print('Starting to listen for speech...');
    try {
      speech.listen(
        onResult: (result) {
          final command = result.recognizedWords.toLowerCase();
          final confidence = result.confidence;
          print('Heard: "$command" with confidence: $confidence');
          print('Is final result: ${result.finalResult}');

          // Only process the command if it's a final result (user has finished speaking)
          if (result.finalResult) {
            print('Processing final result...');

            // Stop listening immediately
            speech.stop();

            // Close the dialog
            Navigator.of(context, rootNavigator: true).pop();

            // Process the command only if confidence is reasonable
            if (confidence > 0.3) {
              // Lowered confidence threshold
              if (command.contains('inspection')) {
                print('Navigating to AircraftSelectionScreen');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AircraftSelectionScreen(),
                  ),
                );
              } else if (command.contains('maintenance')) {
                print('Navigating to MaintenanceLogScreen');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MaintenanceLogScreen(),
                  ),
                );
              } else if (command.contains('status')) {
                print('Navigating to AircraftStatusScreen');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AircraftStatusScreen(),
                  ),
                );
              } else {
                // Show a message if the command is not recognized
                print('Command not recognized: $command');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Command not recognized: "$command"')),
                );
              }
            } else {
              print('Low confidence result: $confidence');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Unable to recognize command clearly. Please try again.')),
              );
            }
          } else {
            print('Intermediate result, waiting for final result...');
          }
        },
        listenFor: const Duration(seconds: 20), // Increased listening time
        pauseFor: const Duration(
            seconds: 5), // Time to wait before considering speech ended
        localeId: 'en_US',
      );
      print('Started listening for speech');
    } catch (e) {
      print('Exception during speech listening: $e');
      Navigator.of(context, rootNavigator: true).pop(); // Close the dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition failed: $e')),
      );
    }
  }
}

class ListeningDialog extends StatefulWidget {
  @override
  _ListeningDialogState createState() => _ListeningDialogState();
}

class _ListeningDialogState extends State<ListeningDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Listening for Commands',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing microphone icon
          ScaleTransition(
            scale: _animation,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: Icon(
                Icons.mic,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Say "inspection", "maintenance", or "status"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Take your time to speak clearly...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Progress indicator
          const LinearProgressIndicator(),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
