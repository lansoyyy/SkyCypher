import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skycypher/utils/colors.dart' as app_colors;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:skycypher/services/auth_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceInspectionScreen extends StatefulWidget {
  final String aircraftModel;
  final String rpNumber;

  const VoiceInspectionScreen({
    super.key,
    required this.aircraftModel,
    required this.rpNumber,
  });

  @override
  State<VoiceInspectionScreen> createState() => _VoiceInspectionScreenState();
}

class _VoiceInspectionScreenState extends State<VoiceInspectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  // Speech to text implementation
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isCommandProcessed =
      false; // Flag to prevent multiple command processing
  String _currentCommand = '';
  String _lastRecognizedText = 'Initializing...';
  String? _userType;
  String _mechanicCategory = 'Preflight'; // New: Category for mechanics

  // Text to speech implementation
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;

  // Inspection checklists for different user types
  List<InspectionItem> _pilotInspectionItems = [];
  List<InspectionItem> _mechanicPreflightItems = [];
  List<InspectionItem> _mechanicMaintenanceItems = [];

  // Current task tracking
  int _currentTaskIndex = 0;

  // Get the current inspection items based on user type and category
  List<InspectionItem> get _currentInspectionItems {
    if (_userType == 'Mechanic') {
      return _mechanicCategory == 'Preflight'
          ? _mechanicPreflightItems
          : _mechanicMaintenanceItems;
    } else {
      // Default to pilot items for Pilot user type or if user type is not set
      return _pilotInspectionItems;
    }
  }

  @override
  void initState() {
    super.initState();

    // Fetch user data to determine user type
    _fetchUserData();

    // Initialize speech to text
    _speech = stt.SpeechToText();
    _initializeSpeechRecognition();

    // Initialize text to speech
    _flutterTts = FlutterTts();
    _initializeTextToSpeech().then((_) {
      print('TTS initialization completed');
    });

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _fetchUserData() async {
    try {
      final userData = await AuthService.getUserData();
      if (userData != null && userData['userType'] != null) {
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
        commands: ['fuel tank quality', 'check fuel tank', 'inspect fuel tank'],
      ),
      InspectionItem(
        id: 'sump_drain',
        title: 'Sump Drain',
        description:
            'Drain sump and check for water, sediment or other contaminants',
        commands: ['sump drain', 'check sump', 'inspect sump drain'],
      ),
      InspectionItem(
        id: 'leading_edge',
        title: 'Leading Edge',
        description: 'Inspect leading edge for damage, dents or wear',
        commands: [
          'leading edge',
          'check leading edge',
          'inspect leading edge'
        ],
      ),
      InspectionItem(
        id: 'aileron',
        title: 'Aileron',
        description:
            'Check aileron hinges, control surfaces and attachment points',
        commands: ['aileron', 'check aileron', 'inspect aileron'],
      ),
      InspectionItem(
        id: 'flap',
        title: 'Flap',
        description:
            'Inspect flaps for damage, proper operation and attachment',
        commands: ['flap', 'check flap', 'inspect flap'],
      ),
      InspectionItem(
        id: 'tire',
        title: 'Tire',
        description: 'Check tire condition, pressure and tread wear',
        commands: ['tire', 'check tire', 'inspect tire'],
      ),
      InspectionItem(
        id: 'brake',
        title: 'Brake',
        description: 'Inspect brake pads, discs and hydraulic connections',
        commands: ['brake', 'check brake', 'inspect brake'],
      ),
      InspectionItem(
        id: 'fuselage_tail',
        title: 'Fuselage / Tail Inspection',
        description:
            'Fuselage surface, stabilizer, elevator, rudder, tail tie-down',
        commands: [
          'fuselage inspection',
          'check fuselage',
          'inspect fuselage and tail'
        ],
      ),
      InspectionItem(
        id: 'nose_section',
        title: 'Nose Section Inspection',
        description:
            'Windshield, oil level, belly sump, propeller, spinner, static port',
        commands: ['nose inspection', 'check nose section', 'inspect nose'],
      ),
      InspectionItem(
        id: 'right_wing',
        title: 'Right Wing / Fuselage Inspection',
        description: 'Repeat inspections from left side',
        commands: [
          'right wing inspection',
          'check right wing',
          'inspect right wing'
        ],
      ),
      InspectionItem(
        id: 'final_walkaround',
        title: 'Final Walk-Around Pass',
        description: 'Panels, caps, chocks, covers secured',
        commands: [
          'final walkaround',
          'final inspection',
          'complete walkaround'
        ],
      ),
      InspectionItem(
        id: 'cockpit_before_start',
        title: 'Cockpit / Before Start',
        description:
            'Seats, doors, avionics, master switch, flaps, control lock',
        commands: ['cockpit check', 'check cockpit', 'cockpit inspection'],
      ),
    ];

    // Mechanic preflight items
    _mechanicPreflightItems = [
      InspectionItem(
        id: 'fuel_tank_quality',
        title: 'Fuel Tank Quality',
        description:
            'Check fuel tank for contamination, proper fuel level and quality',
        commands: ['fuel tank quality', 'check fuel tank', 'inspect fuel tank'],
      ),
      InspectionItem(
        id: 'sump_drain',
        title: 'Sump Drain',
        description:
            'Drain sump and check for water, sediment or other contaminants',
        commands: ['sump drain', 'check sump', 'inspect sump drain'],
      ),
      InspectionItem(
        id: 'leading_edge',
        title: 'Leading Edge',
        description: 'Inspect leading edge for damage, dents or wear',
        commands: [
          'leading edge',
          'check leading edge',
          'inspect leading edge'
        ],
      ),
      InspectionItem(
        id: 'aileron',
        title: 'Aileron',
        description:
            'Check aileron hinges, control surfaces and attachment points',
        commands: ['aileron', 'check aileron', 'inspect aileron'],
      ),
      InspectionItem(
        id: 'flap',
        title: 'Flap',
        description:
            'Inspect flaps for damage, proper operation and attachment',
        commands: ['flap', 'check flap', 'inspect flap'],
      ),
      InspectionItem(
        id: 'tire',
        title: 'Tire',
        description: 'Check tire condition, pressure and tread wear',
        commands: ['tire', 'check tire', 'inspect tire'],
      ),
      InspectionItem(
        id: 'brake',
        title: 'Brake',
        description: 'Inspect brake pads, discs and hydraulic connections',
        commands: ['brake', 'check brake', 'inspect brake'],
      ),
      InspectionItem(
        id: 'fuselage_tail',
        title: 'Fuselage / Tail Inspection',
        description:
            'Fuselage surface, stabilizer, elevator, rudder, tail tie-down',
        commands: [
          'fuselage inspection',
          'check fuselage',
          'inspect fuselage and tail'
        ],
      ),
      InspectionItem(
        id: 'nose_section',
        title: 'Nose Section Inspection',
        description:
            'Windshield, oil level, belly sump, propeller, spinner, static port',
        commands: ['nose inspection', 'check nose section', 'inspect nose'],
      ),
      InspectionItem(
        id: 'right_wing',
        title: 'Right Wing / Fuselage Inspection',
        description: 'Repeat inspections from left side',
        commands: [
          'right wing inspection',
          'check right wing',
          'inspect right wing'
        ],
      ),
      InspectionItem(
        id: 'final_walkaround',
        title: 'Final Walk-Around Pass',
        description: 'Panels, caps, chocks, covers secured',
        commands: [
          'final walkaround',
          'final inspection',
          'complete walkaround'
        ],
      ),
      InspectionItem(
        id: 'cockpit_before_start',
        title: 'Cockpit / Before Start',
        description:
            'Seats, doors, avionics, master switch, flaps, control lock',
        commands: ['cockpit check', 'check cockpit', 'cockpit inspection'],
      ),
    ];

    // Mechanic maintenance items
    _mechanicMaintenanceItems = [
      InspectionItem(
        id: 'airframe_structural',
        title: 'Airframe / Structural Inspection',
        description: 'Fuselage, wings, tail surfaces, rivets, skin integrity',
        commands: ['airframe inspection', 'check airframe', 'inspect airframe'],
      ),
      InspectionItem(
        id: 'cabin_cockpit',
        title: 'Cabin / Cockpit Inspection',
        description: 'Seats, safety belts, windows, flight controls',
        commands: ['cabin inspection', 'check cabin', 'inspect cabin'],
      ),
      InspectionItem(
        id: 'engine_nacelle',
        title: 'Engine / Nacelle Inspection',
        description: 'Leaks, mounting, cables, hoses, exhaust, cleanliness',
        commands: ['engine inspection', 'check engine', 'inspect engine'],
      ),
      InspectionItem(
        id: 'landing_gear',
        title: 'Landing Gear / Wheels Inspection',
        description: 'Gear assemblies, tires, brakes, shock strut',
        commands: [
          'landing gear inspection',
          'check landing gear',
          'inspect landing gear'
        ],
      ),
      InspectionItem(
        id: 'propeller_spinner',
        title: 'Propeller / Spinner Inspection',
        description: 'Blades, cracks, nicks, spinner, mounting bolts',
        commands: [
          'propeller inspection',
          'check propeller',
          'inspect propeller'
        ],
      ),
      InspectionItem(
        id: 'electrical_avionics',
        title: 'Electrical / Avionics Inspection',
        description: 'Wiring, conduits, antennas, secure installation',
        commands: [
          'electrical inspection',
          'check electrical',
          'inspect electrical'
        ],
      ),
    ];

    // Start reading the first task after a short delay to ensure everything is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_currentInspectionItems.isNotEmpty) {
          _readCurrentTask();
        }
      });
    });
  }

  Future<void> _initializeSpeechRecognition() async {
    setState(() {
      _lastRecognizedText = 'Initializing speech recognition...';
    });

    try {
      bool available = await _speech.initialize(
        onError: (error) => _onSpeechError(error),
        onStatus: (status) => _onSpeechStatus(status),
      );

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

      print('TTS initialized successfully');

      _flutterTts.setStartHandler(() {
        print('TTS started speaking');
        setState(() {
          _isSpeaking = true;
        });
      });

      _flutterTts.setCompletionHandler(() {
        print('TTS finished speaking');
        setState(() {
          _isSpeaking = false;
        });

        // After speaking a task, listen for user response after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          _startListening();
        });
      });

      _flutterTts.setErrorHandler((msg) {
        print('TTS Error: $msg');
        setState(() {
          _isSpeaking = false;
          _lastRecognizedText = 'TTS Error: $msg';
        });
        // Resume listening even if TTS fails after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          _startListening();
        });
      });

      // Test TTS with a simple phrase to ensure it's working
      await Future.delayed(const Duration(milliseconds: 1000));
      print('Testing TTS with sample phrase');
      // await _flutterTts.speak("Text to speech is ready");
    } catch (e) {
      print('Error initializing TTS: $e');
      setState(() {
        _lastRecognizedText = 'Error initializing TTS: $e';
      });
    }
  }

  void _onSpeechError(dynamic error) {
    setState(() {
      _lastRecognizedText = 'Speech recognition error: $error';
      _isListening = false;
      _isProcessing = false;
    });
    _pulseController.stop();
    _waveController.stop();
  }

  void _onSpeechStatus(String status) {
    // Handle speech recognition status changes if needed
  }

  @override
  void dispose() {
    _stopListening(); // Stop listening when screen is disposed
    _pulseController.dispose();
    _waveController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _startListening() async {
    if (_isListening) return;

    setState(() {
      _isListening = true;
      _currentCommand = '';
      _isCommandProcessed = false; // Reset the command processed flag
      _lastRecognizedText = 'Listening...';
    });

    HapticFeedback.heavyImpact();
    _pulseController.repeat(reverse: true);
    _waveController.repeat();

    // Start listening for speech
    _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        partialResults: false, // Changed to false to only process final results
        listenMode: stt.ListenMode.confirmation,
      ),
      onResult: (result) {
        setState(() {
          _currentCommand = result.recognizedWords;
          _lastRecognizedText = 'Recognized: "$_currentCommand"';
        });

        // Process the command immediately
        _processCommand(_currentCommand);
      },
    );
  }

  void _stopListening() {
    if (!_isListening) return;

    setState(() {
      _isListening = false;
      _isProcessing = true;
    });

    _speech.stop();
    _pulseController.stop();
    _waveController.stop();

    // Process any final command
    if (_currentCommand.isNotEmpty) {
      _processCommand(_currentCommand);
    }

    setState(() {
      _isProcessing = false;
    });
  }

  void _refreshSpeechRecognition() {
    // Stop any current listening
    _stopListening();

    // Reset speech recognition
    setState(() {
      _lastRecognizedText =
          'Refreshing speech recognition... Your progress is saved.';
      _isCommandProcessed = false;
      _currentCommand = '';
    });

    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    // Re-initialize speech recognition
    _initializeSpeechRecognition().then((_) {
      // If we have a current task, restart the process
      if (_currentTaskIndex < _currentInspectionItems.length) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _readCurrentTask();
          }
        });
      }
    });
  }

  void _processCommand(String command) {
    // Check if a command has already been processed
    if (_isCommandProcessed) return;

    final lowerCommand = command.toLowerCase().trim();

    // Handle specific commands for task completion
    if (_currentTaskIndex < _currentInspectionItems.length) {
      final currentItem = _currentInspectionItems[_currentTaskIndex];

      // Check for completion commands
      if (lowerCommand.contains('done') ||
          lowerCommand.contains('completed') ||
          lowerCommand.contains('complete')) {
        // Mark command as processed to prevent multiple processing
        _isCommandProcessed = true;

        // Stop listening to prevent multiple processing
        _stopListening();

        setState(() {
          currentItem.isCompleted = true;
          currentItem.completedAt = DateTime.now();
          currentItem.hasWarning = false; // Clear any warning
        });
        HapticFeedback.lightImpact();
        _lastRecognizedText = 'Task completed: ${currentItem.title}';

        // Move to next task after a short delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _currentTaskIndex++;
            _readCurrentTask();
          }
        });
        return;
      }

      // Check for warning commands
      if (lowerCommand.contains('not completed') ||
          lowerCommand.contains('problem') ||
          lowerCommand.contains('issue') ||
          lowerCommand.contains('not complete')) {
        // Mark command as processed to prevent multiple processing
        _isCommandProcessed = true;

        // Stop listening to prevent multiple processing
        _stopListening();

        setState(() {
          currentItem.isCompleted = false;
          currentItem.hasWarning = true;
          currentItem.warningAt = DateTime.now();
        });
        HapticFeedback.mediumImpact();
        _lastRecognizedText = 'Task has issue: ${currentItem.title}';

        // Move to next task after a short delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _currentTaskIndex++;
            _readCurrentTask();
          }
        });
        return;
      }
    }

    // Handle general completion command
    if (lowerCommand.contains('complete') ||
        lowerCommand.contains('finish') ||
        lowerCommand.contains('inspection complete')) {
      // Mark command as processed to prevent multiple processing
      _isCommandProcessed = true;

      // Stop listening to prevent multiple processing
      _stopListening();
      _showCompletionDialog();
    }
  }

  Future<void> _readCurrentTask() async {
    if (_currentTaskIndex < _currentInspectionItems.length) {
      final currentItem = _currentInspectionItems[_currentTaskIndex];
      final textToSpeak = currentItem.title;

      print('Reading task: $textToSpeak'); // Debug log

      setState(() {
        _lastRecognizedText = 'Reading task: $textToSpeak';
        _isCommandProcessed =
            false; // Reset the command processed flag for new task
      });

      // Stop listening while speaking
      _stopListening();

      try {
        // Add a small delay to ensure TTS is ready
        await Future.delayed(const Duration(milliseconds: 100));

        if (textToSpeak == 'Final Walk-Around Pass') {
          await _flutterTts.speak(textToSpeak);
        } else {
          await _flutterTts.speak('Please inspect $textToSpeak');
        }

        // Speak the task
      } catch (e) {
        print('Error speaking task: $e');
        setState(() {
          _lastRecognizedText = 'Error reading task: $e';
        });
        // Continue to next task even if speaking fails
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _startListening();
          }
        });
      }
    } else {
      // All tasks completed, show summary
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final completedItems =
        _currentInspectionItems.where((item) => item.isCompleted).length;
    final warningItems =
        _currentInspectionItems.where((item) => item.hasWarning).length;
    final totalItems = _currentInspectionItems.length;
    final pendingItems = totalItems - completedItems - warningItems;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: app_colors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Inspection Summary',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
              Text(
                'Category: $_mechanicCategory',
                style: TextStyle(color: Colors.white.withOpacity(0.9)),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Completed: $completedItems/$totalItems items',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (warningItems > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Warnings: $warningItems items with issues',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (pendingItems > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Pending: $pendingItems items not addressed',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () {
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

  // New method to handle mechanic category change
  void _onMechanicCategoryChanged(String? newValue) {
    if (newValue != null && newValue != _mechanicCategory) {
      setState(() {
        _mechanicCategory = newValue;
        _currentTaskIndex = 0; // Reset to first task when category changes
      });

      // Read the first task of the new category
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_currentInspectionItems.isNotEmpty) {
            _readCurrentTask();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.primary,
      body: Stack(
        children: [
          // Enhanced background gradient
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

          // Background logo
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.center,
                child: Opacity(
                  opacity: 0.03,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 500,
                    fit: BoxFit.contain,
                  ),
                ),
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
                  _stopListening(); // Stop listening before navigating away
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
              // Refresh button for speech-to-text
              GestureDetector(
                onTap: () {
                  _refreshSpeechRecognition();
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
                    Icons.refresh,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                    // Show category dropdown for Mechanics
                    if (_userType == 'Mechanic') ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: app_colors.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: app_colors.secondary.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: _mechanicCategory,
                          items: const [
                            DropdownMenuItem(
                              value: 'Preflight',
                              child: Text(
                                'Preflight',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Maintenance',
                              child: Text(
                                'Maintenance',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          onChanged: _onMechanicCategoryChanged,
                          underline: const SizedBox(),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Voice-Controlled Inspection',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                // Voice indicator (no button needed for hands-free)
                AnimatedBuilder(
                  animation:
                      Listenable.merge([_pulseAnimation, _waveAnimation]),
                  builder: (context, child) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? app_colors.secondary.withOpacity(0.8)
                            : app_colors.secondary,
                        boxShadow: _isListening
                            ? [
                                BoxShadow(
                                  color: app_colors.secondary.withOpacity(0.4),
                                  blurRadius: 20 * _pulseAnimation.value,
                                  spreadRadius: 5 * _pulseAnimation.value,
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
                      child: Transform.scale(
                        scale: _isListening ? _pulseAnimation.value : 1.0,
                        child: Icon(
                          _isListening
                              ? Icons.mic
                              : _isProcessing
                                  ? Icons.hourglass_empty
                                  : Icons.mic_none,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
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
                      ? 'Listening... Speak commands naturally'
                      : 'Initializing hands-free inspection',
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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                    _buildProgressIndicator(),
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
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final completed =
        _currentInspectionItems.where((item) => item.isCompleted).length;
    final total = _currentInspectionItems.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        '$completed/$total',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
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
    } else if (item.hasWarning) {
      backgroundColor = Colors.orange.withOpacity(0.1);
      borderColor = Colors.orange.withOpacity(0.3);
      iconData = Icons.warning;
      iconColor = Colors.orange;
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
              color: item.isCompleted || item.hasWarning
                  ? iconColor
                  : Colors.white.withOpacity(0.2),
              border: Border.all(
                color: item.isCompleted || item.hasWarning
                    ? iconColor
                    : Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              iconData,
              color: item.isCompleted || item.hasWarning
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
                if (item.isCompleted && item.completedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Completed at ${item.completedAt!.hour.toString().padLeft(2, '0')}:${item.completedAt!.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.green.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (item.hasWarning && item.warningAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Warning at ${item.warningAt!.hour.toString().padLeft(2, '0')}:${item.warningAt!.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.orange.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
  final List<String> commands;
  bool isCompleted;
  DateTime? completedAt;
  bool hasWarning; // New field for warning state
  DateTime? warningAt; // New field for warning timestamp

  InspectionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.commands,
    this.isCompleted = false,
    this.completedAt,
    this.hasWarning = false, // Initialize warning state
    this.warningAt,
  });
}
