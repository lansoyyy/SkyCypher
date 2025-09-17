// import 'package:flutter/material.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;

// class VoiceInspectionScreen extends StatefulWidget {
//   final String userRole;

//   const VoiceInspectionScreen({
//     super.key,
//     required this.userRole,
//   });

//   @override
//   State<VoiceInspectionScreen> createState() => _VoiceInspectionScreenState();
// }

// class _VoiceInspectionScreenState extends State<VoiceInspectionScreen> {
//   late stt.SpeechToText _speech;
//   late FlutterTts _tts;

//   List<String> tasks = [];
//   List<String> completedTasks = [];
//   List<String> uncompletedTasks = [];
//   int currentTaskIndex = 0;
//   bool _isListening = false;
//   String? selectedCategory;
//   String _lastError = '';
//   bool _hasError = false;

//   // Sample task lists
//   static const List<String> _pilotInspectionItems = [
//     'Check the fuel level.',
//     'Inspect the wings for damage.',
//     'Verify the control surfaces.',
//   ];

//   static const List<String> _mechanicPreFlightItems = [
//     'Inspect engine oil.',
//     'Check battery connections.',
//     'Examine tires for wear.',
//   ];

//   static const List<String> _mechanicMaintenanceItems = [
//     'Lubricate moving parts.',
//     'Tighten all bolts and nuts.',
//     'Test electrical systems.',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _speech = stt.SpeechToText();
//     _tts = FlutterTts();
//     _initTts();
//     _initializeSpeech();
//     _loadTasks();
//     if (widget.userRole == 'Pilot' && tasks.isNotEmpty) {
//       // Auto-start for Pilot
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _startInspection();
//       });
//     }
//   }

//   void _initTts() {
//     _tts.setCompletionHandler(() {
//       // Check if the widget is still mounted before calling methods
//       if (mounted) {
//         _startListening();
//       }
//     });
//     _tts.setErrorHandler((msg) {
//       print('TTS Error: $msg');
//       // Check if the widget is still mounted before calling setState
//       if (mounted) {
//         setState(() {
//           _hasError = true;
//           _lastError = 'TTS Error: $msg';
//         });
//       }
//     });
//   }

//   Future<void> _initializeSpeech() async {
//     bool available = await _speech.initialize(
//       onStatus: (status) => print('Speech Status: $status'),
//       onError: (dynamic error) => _onSpeechError(error),
//     );
//     // Check if the widget is still mounted before calling setState
//     if (mounted) {
//       if (!available) {
//         print('Speech recognition not available');
//         setState(() {
//           _hasError = true;
//           _lastError = 'Speech recognition not available';
//         });
//       }
//     }
//   }

//   void _onSpeechError(dynamic error) {
//     print('Speech recognition error: $error');
//     // Check if the widget is still mounted before calling setState
//     if (mounted) {
//       setState(() {
//         _isListening = false;
//         _hasError = true;
//         _lastError = error.toString();
//       });
//     }

//     // Don't automatically restart, let user decide with restart button
//   }

//   void _loadTasks() {
//     if (widget.userRole == 'Pilot') {
//       tasks = List.from(_pilotInspectionItems);
//     } else if (widget.userRole == 'Mechanic') {
//       tasks = [];
//     }
//   }

//   void _startInspection() {
//     if (tasks.isNotEmpty && currentTaskIndex < tasks.length) {
//       _startCurrentTask();
//     }
//   }

//   Future<void> _startCurrentTask() async {
//     if (currentTaskIndex < tasks.length) {
//       await _tts.speak(tasks[currentTaskIndex]);
//     }
//   }

//   Future<void> _startListening() async {
//     if (_isListening) return;
//     // Check if the widget is still mounted before calling setState
//     if (mounted) {
//       setState(() {
//         _isListening = true;
//         _hasError = false; // Clear error when restarting
//         _lastError = '';
//       });
//     }
//     await _speech.listen(
//       onResult: _onSpeechResult,
//       listenFor:
//           const Duration(seconds: 60), // Long duration for indefinite wait
//       pauseFor: const Duration(seconds: 5),
//       partialResults: false,
//       localeId: 'en_US',
//     );
//   }

//   void _stopListening() {
//     _speech.stop();
//     // Check if the widget is still mounted before calling setState
//     if (mounted) {
//       setState(() {
//         _isListening = false;
//       });
//     }
//   }

//   void _restartListening() {
//     _stopListening();
//     // Add a small delay before restarting
//     Future.delayed(const Duration(milliseconds: 500), () {
//       _startListening();
//     });
//   }

//   void _onSpeechResult(result) async {
//     await _speech.stop();
//     // Check if the widget is still mounted before calling setState
//     if (mounted) {
//       setState(() {
//         _isListening = false;
//       });
//     }
//     final String recognized = result.recognizedWords.toLowerCase().trim();
//     _processCommand(recognized);
//   }

//   void _processCommand(String command) {
//     final bool isComplete = ['done', 'check', 'finish', 'complete']
//         .any((word) => command.contains(word));
//     final bool isIncomplete = ['skip', 'not complete', 'problem']
//         .any((word) => command.contains(word));

//     final String task = tasks[currentTaskIndex];
//     if (isComplete) {
//       completedTasks.add(task);
//     } else if (isIncomplete) {
//       uncompletedTasks.add(task);
//     } else {
//       // Default to incomplete for invalid responses
//       uncompletedTasks.add(task);
//     }

//     currentTaskIndex++;
//     if (currentTaskIndex < tasks.length) {
//       _startCurrentTask();
//     } else {
//       _showSummary();
//     }
//   }

//   void _showSummary() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Inspection Summary'),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Completed Tasks:',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               ...completedTasks.map((task) => Text('• $task')),
//               const SizedBox(height: 16),
//               const Text(
//                 'Uncompleted Tasks:',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               ...uncompletedTasks.map((task) => Text('• $task')),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _tts.stop();
//     _speech.stop();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Voice Inspection Screen'),
//         actions: [
//           if (_hasError)
//             IconButton(
//               icon: const Icon(Icons.refresh),
//               onPressed: _restartListening,
//               tooltip: 'Restart Speech Recognition',
//             ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (_hasError) ...[
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 margin: const EdgeInsets.only(bottom: 16),
//                 decoration: BoxDecoration(
//                   color: Colors.red.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.red),
//                 ),
//                 child: Column(
//                   children: [
//                     const Text(
//                       'Speech Recognition Error',
//                       style: TextStyle(
//                         color: Colors.red,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       _lastError,
//                       style: const TextStyle(color: Colors.red),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 12),
//                     ElevatedButton(
//                       onPressed: _restartListening,
//                       child: const Text('Restart Speech Recognition'),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//             if (widget.userRole == 'Mechanic' && tasks.isEmpty)
//               Column(
//                 children: [
//                   const Text('Select Category:'),
//                   DropdownButton<String>(
//                     value: selectedCategory,
//                     hint: const Text('Choose a category'),
//                     items: const [
//                       DropdownMenuItem(
//                         value: 'Pre Flight',
//                         child: Text('Pre Flight Category'),
//                       ),
//                       DropdownMenuItem(
//                         value: 'Maintenance',
//                         child: Text('Maintenance Category'),
//                       ),
//                     ],
//                     onChanged: (value) {
//                       setState(() {
//                         selectedCategory = value;
//                         if (value == 'Pre Flight') {
//                           tasks = List.from(_mechanicPreFlightItems);
//                         } else if (value == 'Maintenance') {
//                           tasks = List.from(_mechanicMaintenanceItems);
//                         }
//                         currentTaskIndex = 0;
//                         completedTasks.clear();
//                         uncompletedTasks.clear();
//                       });
//                       _startInspection();
//                     },
//                   ),
//                 ],
//               )
//             else if (currentTaskIndex < tasks.length)
//               Column(
//                 children: [
//                   Text(
//                     'Current Task ${currentTaskIndex + 1}/${tasks.length}:',
//                     style: const TextStyle(
//                         fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     tasks[currentTaskIndex],
//                     style: const TextStyle(fontSize: 16),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 16),
//                   if (_isListening)
//                     const Column(
//                       children: [
//                         Icon(Icons.mic, color: Colors.red, size: 48),
//                         Text('Listening... Speak now!'),
//                       ],
//                     )
//                   else
//                     ElevatedButton(
//                       onPressed: _startCurrentTask,
//                       child: const Text('Start Task (Speak to Begin)'),
//                     ),
//                   const SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       ElevatedButton(
//                         onPressed: _startListening,
//                         child: const Text('Start Listening'),
//                       ),
//                       ElevatedButton(
//                         onPressed: _stopListening,
//                         child: const Text('Stop Listening'),
//                       ),
//                     ],
//                   ),
//                 ],
//               )
//             else
//               const Center(
//                 child: Text('All tasks completed. Summary will appear.'),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
