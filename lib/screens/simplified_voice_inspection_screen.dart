import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skycypher/utils/colors.dart' as app_colors;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:skycypher/services/auth_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class SimplifiedVoiceInspectionScreen extends StatefulWidget {
  final String aircraftModel;
  final String rpNumber;

  const SimplifiedVoiceInspectionScreen({
    super.key,
    required this.aircraftModel,
    required this.rpNumber,
  });

  @override
  State<SimplifiedVoiceInspectionScreen> createState() =>
      _SimplifiedVoiceInspectionScreenState();
}

class _SimplifiedVoiceInspectionScreenState
    extends State<SimplifiedVoiceInspectionScreen> {
  // Speech to text implementation
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isIntentionallyStopping = false; // Flag to track intentional stops
  String _lastRecognizedText = 'Initializing...';
  String? _userType;

  // Inspection type for mechanics
  String _inspectionType = 'Pre Flight';
  final List<String> _inspectionTypes = ['Pre Flight', 'Maintenance'];

  // Text to speech implementation
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;

  // Inspection checklists for different user types
  List<InspectionItem> _pilotInspectionItems = [];
  List<InspectionItem> _mechanicInspectionItems = [];

  // Current task tracking
  int _currentTaskIndex = 0;

  // Flag to prevent duplicate processing
  bool _taskCompleted = false;

  // Get the current inspection items based on user type and inspection type
  List<InspectionItem> get _currentInspectionItems {
    if (_userType == 'Mechanic') {
      return _mechanicInspectionItems;
    } else {
      return _pilotInspectionItems;
    }
  }

  @override
  void initState() {
    super.initState();

    // Check permissions and initialize
    _checkPermissionsAndInitialize();
  }

  Future<void> _checkPermissionsAndInitialize() async {
    // Check microphone permission
    var status = await Permission.microphone.request();

    if (status.isGranted) {
      // Permission granted, proceed with initialization
      _initializeSystems();
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied, show a message
      if (mounted) {
        setState(() {
          _lastRecognizedText =
              'Microphone permission is required for speech recognition. Please enable it in settings.';
        });

        // Show a dialog to guide the user to settings
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPermissionDialog();
        });
      }
    } else {
      // Permission denied
      if (mounted) {
        setState(() {
          _lastRecognizedText =
              'Microphone permission is required for speech recognition.';
        });
      }
    }
  }

  void _initializeSystems() {
    // Fetch user data to determine user type
    _fetchUserData();

    // Initialize speech to text
    _speech = stt.SpeechToText();
    _initializeSpeechRecognition();

    // Initialize text to speech
    _flutterTts = FlutterTts();
    _initializeTextToSpeech().then((_) {
      // After TTS is initialized, initialize inspection items and read the first task
      _initializeInspectionItems();
      // Read the first task after a short delay to ensure everything is initialized
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _readCurrentTask();
        }
      });
    });
  }

  void _showPermissionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: app_colors.primary,
          title: const Text('Permission Required',
              style: TextStyle(color: Colors.white)),
          content: const Text(
            'Microphone permission is required for speech recognition. Please enable it in your device settings.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child:
                  const Text('Settings', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchUserData() async {
    try {
      final userData = await AuthService.getUserData();
      if (userData != null && userData['userType'] != null) {
        // Check if widget is still mounted before updating state
        if (!mounted) return;
        setState(() {
          _userType = userData['userType'] as String;
        });
      }
      // Initialize inspection items after user type is determined
      _initializeInspectionItems();
    } catch (e) {
      print('Error fetching user data: $e');
      // Initialize with default items if user data fetch fails
      _initializeInspectionItems();
    }
  }

  void _initializeInspectionItems() {
    // Pilot inspection items
    _pilotInspectionItems = [
      InspectionItem(
        id: 'fuel_tank_quality',
        title: 'Fuel Tank Quality',
        description:
            'Check fuel tank for contamination, proper fuel level and quality',
      ),
      InspectionItem(
        id: 'sump_drain',
        title: 'Sump Drain',
        description:
            'Drain sump and check for water, sediment or other contaminants',
      ),
      InspectionItem(
        id: 'leading_edge',
        title: 'Leading Edge',
        description: 'Inspect leading edge for damage, dents or wear',
      ),
      InspectionItem(
        id: 'aileron',
        title: 'Aileron',
        description:
            'Check aileron hinges, control surfaces and attachment points',
      ),
      InspectionItem(
        id: 'flap',
        title: 'Flap',
        description:
            'Inspect flaps for damage, proper operation and attachment',
      ),
      InspectionItem(
        id: 'tire',
        title: 'Tire',
        description: 'Check tire condition, pressure and tread wear',
      ),
      InspectionItem(
        id: 'brake',
        title: 'Brake',
        description: 'Inspect brake pads, discs and hydraulic connections',
      ),
      InspectionItem(
        id: 'fuselage_tail',
        title: 'Fuselage / Tail Inspection',
        description:
            'Fuselage surface, stabilizer, elevator, rudder, tail tie-down',
      ),
      InspectionItem(
        id: 'nose_section',
        title: 'Nose Section Inspection',
        description:
            'Windshield, oil level, belly sump, propeller, spinner, static port',
      ),
      InspectionItem(
        id: 'right_wing',
        title: 'Right Wing / Fuselage Inspection',
        description: 'Repeat inspections from left side',
      ),
      InspectionItem(
        id: 'final_walkaround',
        title: 'Final Walk-Around Pass',
        description: 'Panels, caps, chocks, covers secured',
      ),
      InspectionItem(
        id: 'cockpit_before_start',
        title: 'Cockpit / Before Start',
        description:
            'Seats, doors, avionics, master switch, flaps, control lock',
      ),
    ];

    _mechanicInspectionItems = [
      // Pre Flight Category
      InspectionItem(
        id: 'fuel_tank_quality',
        title: 'Fuel Tank Quality',
        description:
            'Check fuel tank for contamination, proper fuel level and quality',
      ),
      InspectionItem(
        id: 'sump_drain',
        title: 'Sump Drain',
        description:
            'Drain sump and check for water, sediment or other contaminants',
      ),
      InspectionItem(
        id: 'leading_edge',
        title: 'Leading Edge',
        description: 'Inspect leading edge for damage, dents or wear',
      ),
      InspectionItem(
        id: 'aileron',
        title: 'Aileron',
        description:
            'Check aileron hinges, control surfaces and attachment points',
      ),
      InspectionItem(
        id: 'flap',
        title: 'Flap',
        description:
            'Inspect flaps for damage, proper operation and attachment',
      ),
      InspectionItem(
        id: 'tire',
        title: 'Tire',
        description: 'Check tire condition, pressure and tread wear',
      ),
      InspectionItem(
        id: 'brake',
        title: 'Brake',
        description: 'Inspect brake pads, discs and hydraulic connections',
      ),
      InspectionItem(
        id: 'fuselage_tail',
        title: 'Fuselage / Tail Inspection',
        description:
            'Fuselage surface, stabilizer, elevator, rudder, tail tie-down',
      ),
      InspectionItem(
        id: 'nose_section',
        title: 'Nose Section Inspection',
        description:
            'Windshield, oil level, belly sump, propeller, spinner, static port',
      ),
      InspectionItem(
        id: 'right_wing',
        title: 'Right Wing / Fuselage Inspection',
        description: 'Repeat inspections from left side',
      ),
      InspectionItem(
        id: 'final_walkaround',
        title: 'Final Walk-Around Pass',
        description: 'Panels, caps, chocks, covers secured',
      ),
      InspectionItem(
        id: 'cockpit_before_start',
        title: 'Cockpit / Before Start',
        description:
            'Seats, doors, avionics, master switch, flaps, control lock',
      ),
    ];

    // Note: We don't automatically read the first task here anymore
    // That's now handled in initState after TTS initialization
  }

  Future<void> _initializeSpeechRecognition() async {
    // Check if widget is still mounted before updating state
    if (!mounted) return;

    setState(() {
      _lastRecognizedText = 'Initializing speech recognition...';
    });

    try {
      bool available = await _speech.initialize(
        onError: (error) => _onSpeechError(error),
        onStatus: (status) => _onSpeechStatus(status),
      );

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      if (available) {
        setState(() {
          _lastRecognizedText = _userType != null
              ? 'Ready to listen. Say commands for ${_userType!.toLowerCase()} inspection'
              : 'Ready to listen. Say inspection commands';
        });

        // Start listening automatically after initialization
        _startListening();
      } else {
        setState(() {
          _lastRecognizedText = 'Speech recognition not available';
        });
      }
    } catch (e) {
      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _lastRecognizedText = 'Error initializing speech recognition: $e';
      });
    }
  }

  Future<void> _initializeTextToSpeech() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        // Check if widget is still mounted before updating state
        if (!mounted) return;

        setState(() {
          _isSpeaking = true;
        });
      });

      _flutterTts.setCompletionHandler(() {
        // Check if widget is still mounted before updating state
        if (!mounted) return;

        setState(() {
          _isSpeaking = false;
        });

        // After speaking a task, ensure we're listening for user response
        Future.delayed(const Duration(milliseconds: 300), () {
          // Check if widget is still mounted
          if (!mounted) return;

          if (!_isListening) {
            _startListening();
          }
        });
      });

      _flutterTts.setCancelHandler(() {
        // Check if widget is still mounted before updating state
        if (!mounted) return;

        setState(() {
          _isSpeaking = false;
        });
      });

      _flutterTts.setErrorHandler((msg) {
        // Check if widget is still mounted before updating state
        if (!mounted) return;

        setState(() {
          _isSpeaking = false;
          _lastRecognizedText = 'TTS Error: $msg';
        });
      });
    } catch (e) {
      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _lastRecognizedText = 'Error initializing TTS: $e';
      });
    }
  }

  void _onSpeechError(dynamic error) {
    print('Speech recognition error: $error');

    // Check if widget is still mounted before updating state
    if (!mounted) return;

    setState(() {
      _lastRecognizedText = 'Speech recognition error: $error';
      _isListening = false;
    });

    // Check if this is an intentional stop
    if (_isIntentionallyStopping) {
      _isIntentionallyStopping = false; // Reset the flag
      return;
    }

    // Handle different types of errors
    String errorMsg = error.toString().toLowerCase();

    // For timeout errors, inform user and restart patiently
    if (errorMsg.contains('timeout')) {
      _lastRecognizedText =
          'I\'m ready to listen. Please speak when you\'re ready.';
      print('Timeout error - informing user and restarting');

      // Show a visual indication that we're ready to listen
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _lastRecognizedText = 'Listening... Please speak your command.';
        });
      });

      // Restart with a reasonable delay to give user time to speak
      Future.delayed(const Duration(seconds: 1), () {
        // Check if widget is still mounted
        if (!mounted) return;
        _startListening();
      });
    }
    // For permission errors
    else if (errorMsg.contains('permission') || errorMsg.contains('denied')) {
      _lastRecognizedText =
          'Microphone permission is required. Please check app permissions.';
      print('Permission error - showing permission dialog');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPermissionDialog();
      });
    }
    // For client errors (often occur after timeouts), restart with a delay
    else if (errorMsg.contains('client')) {
      _lastRecognizedText = 'Preparing to listen again...';
      print('Client error - restarting with delay');
      Future.delayed(const Duration(seconds: 2), () {
        // Check if widget is still mounted
        if (!mounted) return;
        _startListening();
      });
    }
    // For permanent errors, show a message but don't restart rapidly
    else if (errorMsg.contains('permanent')) {
      _lastRecognizedText =
          'Speech recognition temporarily unavailable. Retrying...';
      print('Permanent error - restarting with longer delay');
      Future.delayed(const Duration(seconds: 3), () {
        // Check if widget is still mounted
        if (!mounted) return;
        _startListening();
      });
    }
    // For other errors, restart with a normal delay
    else {
      print('Other error - restarting with normal delay');
      Future.delayed(const Duration(seconds: 2), () {
        // Check if widget is still mounted
        if (!mounted) return;
        _startListening();
      });
    }
  }

  void _onSpeechStatus(String status) {
    print('Speech recognition status: $status');

    // Restart listening if it stops unexpectedly (but not if we intentionally stopped it)
    if (status == 'notListening' && !_isIntentionallyStopping) {
      Future.delayed(const Duration(milliseconds: 500), () {
        // Check if widget is still mounted
        if (!mounted) return;

        if (!_isSpeaking) {
          _startListening();
        }
      });
    }
  }

  @override
  void dispose() {
    // Set the intentional stopping flag to prevent restart loops
    _isIntentionallyStopping = true;

    // Stop speech recognition
    try {
      _speech.stop();
    } catch (e) {
      print('Error stopping speech recognition: $e');
    }

    // Stop text to speech
    try {
      _flutterTts.stop();
    } catch (e) {
      print('Error stopping TTS: $e');
    }

    super.dispose();
  }

  void _startListening() {
    // Check if widget is still mounted
    if (!mounted) return;

    if (_isListening) return;

    setState(() {
      _isListening = true;
      _lastRecognizedText = 'Listening... Please speak your command.';
    });

    try {
      _speech.listen(
        onResult: (result) {
          // Check if widget is still mounted before updating state
          if (!mounted) return;

          setState(() {
            _lastRecognizedText = 'Recognized: "${result.recognizedWords}"';
          });

          // Process the command immediately
          _processCommand(result.recognizedWords);
        },
        // Even more tolerant parameters
        listenFor: const Duration(seconds: 120), // Increased to 2 minutes
        pauseFor: const Duration(seconds: 15), // Increased to 15 seconds
        localeId: 'en_US',
      );
    } catch (e) {
      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _isListening = false;
        _lastRecognizedText = 'Error starting speech recognition: $e';
      });

      // Retry listening after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        // Check if widget is still mounted
        if (!mounted) return;

        _startListening();
      });
    }
  }

  void _stopListening() {
    // Check if widget is still mounted
    if (!mounted) return;

    if (!_isListening) return;

    // Set the intentional stopping flag
    _isIntentionallyStopping = true;

    setState(() {
      _isListening = false;
    });

    try {
      _speech.stop();
    } catch (e) {
      print('Error stopping speech recognition: $e');
    }
  }

  void _processCommand(String command) {
    // Check if widget is still mounted
    if (!mounted) return;

    final lowerCommand = command.toLowerCase().trim();

    // Handle specific commands for task completion
    if (_currentTaskIndex < _currentInspectionItems.length) {
      // Prevent duplicate processing
      if (_taskCompleted) return;

      // Check for completion commands
      if (lowerCommand == 'done' ||
          lowerCommand == 'check' ||
          lowerCommand == 'finish' ||
          lowerCommand == 'complete') {
        setState(() {
          _currentInspectionItems[_currentTaskIndex].isCompleted = true;
          _taskCompleted = true; // Mark task as explicitly completed
        });
        HapticFeedback.lightImpact();

        // Move to next task after a delay to allow user to hear confirmation
        Future.delayed(const Duration(seconds: 2), () {
          // Check if widget is still mounted
          if (!mounted) return;

          _nextTask();
        });
        return;
      }

      // Check for incomplete commands
      if (lowerCommand == 'skip' ||
          lowerCommand == 'not complete' ||
          lowerCommand == 'problem') {
        setState(() {
          _currentInspectionItems[_currentTaskIndex].isCompleted = false;
          _taskCompleted = true; // Mark task as explicitly completed
        });
        HapticFeedback.mediumImpact();

        // Move to next task after a delay to allow user to hear confirmation
        Future.delayed(const Duration(seconds: 2), () {
          // Check if widget is still mounted
          if (!mounted) return;

          _nextTask();
        });
        return;
      }
    }

    // If we get here, the command wasn't recognized
    setState(() {
      _lastRecognizedText =
          'Command not recognized. Please say "done" when finished or "problem" if there is an issue.';
    });

    // Ensure we're still listening
    if (!_isListening) {
      Future.delayed(const Duration(milliseconds: 500), () {
        // Check if widget is still mounted
        if (!mounted) return;

        _startListening();
      });
    }
  }

  // Method to move to the next task
  void _nextTask() {
    // Check if widget is still mounted
    if (!mounted) return;

    // Reset task completion flag for next task
    _taskCompleted = false;

    // Move to next task
    _currentTaskIndex++;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if widget is still mounted
      if (!mounted) return;

      _readCurrentTask();
    });
  }

  Future<void> _readCurrentTask() async {
    // Check if widget is still mounted
    if (!mounted) return;

    if (_currentTaskIndex < _currentInspectionItems.length) {
      final currentItem = _currentInspectionItems[_currentTaskIndex];
      final textToSpeak =
          'Please check the ${currentItem.title.toLowerCase()}. Say "done" when completed or "problem" if there is an issue.';

      setState(() {
        _lastRecognizedText = 'Reading task: $textToSpeak';
      });

      try {
        // Speak the task
        await _flutterTts.speak(textToSpeak);
      } catch (e) {
        // Check if widget is still mounted before updating state
        if (!mounted) return;

        setState(() {
          _lastRecognizedText = 'Error reading task: $e';
        });
        return;
      }
    } else {
      // All tasks completed, show summary
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    // Check if widget is still mounted
    if (!mounted) return;

    final completedItems =
        _currentInspectionItems.where((item) => item.isCompleted).toList();
    final uncompletedItems =
        _currentInspectionItems.where((item) => !item.isCompleted).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: app_colors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Inspection Summary',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                'Aircraft: ${widget.aircraftModel}',
                style: TextStyle(color: Colors.white.withOpacity(0.9)),
              ),
              Text(
                'RP Number: ${widget.rpNumber}',
                style: TextStyle(color: Colors.white.withOpacity(0.9)),
              ),
              Text(
                'User Type: ${_userType ?? "Unknown"}',
                style: TextStyle(color: Colors.white.withOpacity(0.9)),
              ),
              if (_userType == 'Mechanic') ...[
                const SizedBox(height: 8),
                Text(
                  'Inspection Type: $_inspectionType',
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Completed Tasks:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...completedItems.map((item) => Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                    child: Text(
                      '• ${item.title}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
              const Text(
                'Uncompleted Tasks:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...uncompletedItems.map((item) => Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                    child: Text(
                      '• ${item.title}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                      ),
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Check if widget is still mounted
              if (!mounted) return;

              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: app_colors.secondary,
            ),
            child: const Text('Finish Inspection'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.primary,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  app_colors.primary,
                  app_colors.primary.withOpacity(0.9),
                  app_colors.darkPrimary,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildVoiceInterface(),
                        const SizedBox(height: 32),
                        _buildInspectionChecklist(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  _stopListening();
                  // Check if widget is still mounted
                  if (!mounted) return;

                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.aircraftModel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'RP: ${widget.rpNumber}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  if (_userType != null) ...[
                    Text(
                      '${_userType} Inspection',
                      style: TextStyle(
                        color: app_colors.secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Simplified Voice Inspection',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _userType != null
                ? 'Hands-free ${_userType!.toLowerCase()} inspection in progress'
                : 'Hands-free inspection in progress',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          // Add dropdown for mechanics to select inspection type
          if (_userType == 'Mechanic') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Inspection Type:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _inspectionType,
                    items: _inspectionTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          type,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        // Check if widget is still mounted before updating state
                        if (!mounted) return;

                        setState(() {
                          _inspectionType = newValue;
                          _currentTaskIndex =
                              0; // Reset to first task when changing inspection type
                          _taskCompleted = false; // Reset task completion flag
                        });
                        // Restart the inspection with the new type
                        Future.delayed(const Duration(milliseconds: 300), () {
                          // Check if widget is still mounted
                          if (!mounted) return;

                          _readCurrentTask();
                        });
                      }
                    },
                    dropdownColor: app_colors.primary,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    underline: Container(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceInterface() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Voice indicator
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? app_colors.secondary.withOpacity(0.8)
                      : app_colors.secondary,
                  boxShadow: _isListening
                      ? [
                          BoxShadow(
                            color: app_colors.secondary.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: app_colors.secondary.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: Icon(
                  _isListening
                      ? Icons.mic
                      : _isSpeaking
                          ? Icons.hourglass_empty
                          : Icons.mic_none,
                  size: 48,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // Status text
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  _lastRecognizedText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                _isListening
                    ? 'I\'m listening. Speak naturally and clearly.'
                    : 'Tap the microphone or wait for instructions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInspectionChecklist() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: app_colors.secondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Inspection Checklist',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 20),
              ...(_currentInspectionItems
                  .map((item) => _buildChecklistItem(item))
                  .toList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(InspectionItem item) {
    // Determine the background color based on state
    Color backgroundColor;
    Color borderColor;
    IconData iconData;
    Color iconColor;

    if (item.isCompleted) {
      backgroundColor = Colors.green.withOpacity(0.1);
      borderColor = Colors.green.withOpacity(0.3);
      iconData = Icons.check;
      iconColor = Colors.green;
    } else {
      backgroundColor = Colors.white.withOpacity(0.05);
      borderColor = Colors.white.withOpacity(0.1);
      iconData = Icons.circle_outlined;
      iconColor = Colors.white.withOpacity(0.7);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  item.isCompleted ? iconColor : Colors.white.withOpacity(0.2),
              border: Border.all(
                color: item.isCompleted
                    ? iconColor
                    : Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              iconData,
              color: item.isCompleted
                  ? Colors.white
                  : Colors.white.withOpacity(0.7),
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration:
                        item.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InspectionItem {
  final String id;
  final String title;
  final String description;
  bool isCompleted;

  InspectionItem({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
  });
}
