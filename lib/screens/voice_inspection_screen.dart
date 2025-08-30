import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skycypher/utils/colors.dart' as app_colors;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:skycypher/services/auth_service.dart';

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
  String _currentCommand = '';
  String _lastRecognizedText = 'Initializing...';
  String? _userType;

  // Inspection checklists for different user types
  List<InspectionItem> _pilotInspectionItems = [];
  List<InspectionItem> _mechanicInspectionItems = [];

  // Get the current inspection items based on user type
  List<InspectionItem> get _currentInspectionItems {
    if (_userType == 'Mechanic') {
      return _mechanicInspectionItems;
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
    // Mechanic inspection items (number 1 & 2 in your PDF)
    _pilotInspectionItems = [
      InspectionItem(
        id: 'exterior_left_wing',
        title: 'Left Wing / Fuselage Inspection',
        description:
            'Fuel tank quality, sump drain, leading edge, aileron, flap, tire, brake',
        commands: [
          'left wing inspection',
          'check left wing',
          'inspect left wing'
        ],
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

    _mechanicInspectionItems = [
      InspectionItem(
        id: 'exterior_left_wing',
        title: 'Left Wing / Fuselage Inspection',
        description:
            'Fuel tank quality, sump drain, leading edge, aileron, flap, tire, brake',
        commands: [
          'left wing inspection',
          'check left wing',
          'inspect left wing'
        ],
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
    super.dispose();
  }

  void _startListening() async {
    if (_isListening) return;

    setState(() {
      _isListening = true;
      _currentCommand = '';
      _lastRecognizedText = 'Listening...';
    });

    HapticFeedback.heavyImpact();
    _pulseController.repeat(reverse: true);
    _waveController.repeat();

    // Start listening for speech
    _speech.listen(
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

  void _processCommand(String command) {
    final lowerCommand = command.toLowerCase();

    for (var item in _currentInspectionItems) {
      for (var cmd in item.commands) {
        if (lowerCommand.contains(cmd.toLowerCase())) {
          setState(() {
            item.isCompleted = true;
            item.completedAt = DateTime.now();
          });
          HapticFeedback.lightImpact();
          // Provide audio feedback
          _lastRecognizedText = 'Completed: ${item.title}';
          break;
        }
      }
    }

    if (lowerCommand.contains('complete') ||
        lowerCommand.contains('finish') ||
        lowerCommand.contains('inspection complete')) {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final completedItems =
        _currentInspectionItems.where((item) => item.isCompleted).length;
    final totalItems = _currentInspectionItems.length;

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
            const SizedBox(height: 16),
            Text(
              'Completed: $completedItems/$totalItems items',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.isCompleted
            ? Colors.green.withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isCompleted
              ? Colors.green.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
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
              color: item.isCompleted
                  ? Colors.green
                  : Colors.white.withOpacity(0.2),
              border: Border.all(
                color: item.isCompleted
                    ? Colors.green
                    : Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              item.isCompleted ? Icons.check : Icons.circle_outlined,
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

  InspectionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.commands,
    this.isCompleted = false,
    this.completedAt,
  });
}
