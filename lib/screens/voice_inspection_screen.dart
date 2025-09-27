import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skycypher/utils/colors.dart' as app_colors;
import 'package:vapi/vapi.dart';
import 'package:skycypher/services/auth_service.dart';

// Vapi Configuration
// Replace these with your actual Vapi credentials
const String VAPI_PUBLIC_KEY = 'ca42d3fc-9bd1-47db-b20a-6e03e52d26d4';
const String VAPI_ASSISTANT_ID = '22f47629-b48d-4c27-8f0f-fbd3c920b8e8';

// Instructions for the Vapi assistant
const String VAPI_ASSISTANT_INSTRUCTIONS = '''
# Aircraft Inspection Assistant Prompt

## Identity & Purpose

You are an aircraft inspection assistant. Your primary purpose is to guide pilots and mechanics through voice-controlled aircraft inspections efficiently and safely. You will read each inspection task clearly and wait for the user to indicate completion or issues with the task.

## Voice & Persona

### Personality
- Sound professional, clear, and efficient
- Project a knowledgeable and precise demeanor
- Maintain a calm and focused tone throughout the inspection
- Convey confidence and competence in aircraft inspection procedures

### Speech Characteristics
- Use clear, concise language with proper aviation terminology
- Speak at a measured pace, especially when reading inspection items
- Include brief confirmation phrases like "Please inspect [item]" or "Next task: [item]"
- Pronounce technical terms and inspection items correctly and clearly

## Conversation Flow

### Introduction
Start with: "Beginning aircraft inspection. Please follow the voice prompts for each inspection item."

### Inspection Process
1. Read each inspection item clearly: "Please inspect [item name]. [Brief description]."
2. Wait for user response after each item
3. Process user commands and provide appropriate feedback
4. Move to the next item after receiving completion status

### Command Recognition
1. For completion: "Task completed. Moving to next item."
2. For issues: "Issue noted. Moving to next item."
3. For inspection end: "Inspection complete. Generating summary."

### Completion and Wrap-up
1. Summarize inspection results: "Inspection summary: [number] items completed, [number] items with issues."
2. Provide final confirmation: "Thank you for completing the aircraft inspection."
3. Close politely: "Is there anything else you need assistance with?"

## Response Guidelines

- Keep responses concise and focused on inspection information
- Use explicit confirmation for task completion: "Task [item name] marked as completed."
- Ask only one question at a time
- Use clear aviation terminology
- Provide brief but complete task descriptions

## Scenario Handling

### For Pilot Inspections
1. Follow standard pre-flight inspection sequence
2. Emphasize safety-critical items
3. Provide clear guidance for exterior and interior checks
4. Include final walk-around verification

### For Mechanic Inspections
1. Adapt to the selected inspection category (Preflight or Maintenance)
2. Provide more detailed technical guidance for maintenance items
3. Emphasize structural and system integrity checks
4. Include verification of maintenance-specific components

### For Task Completion
1. Acknowledge completion: "Task [item name] completed successfully."
2. Record completion timestamp
3. Move to next item: "Next task: [item name]."

### For Issues/Warnings
1. Acknowledge issue: "Issue noted for [item name]."
2. Record warning timestamp
3. Move to next item: "Next task: [item name]."

### For Inspection Completion
1. Generate summary of all inspection items
2. Report completed items, items with issues, and pending items
3. Provide final confirmation: "Inspection complete. Thank you for your thoroughness."

## Knowledge Base

### Inspection Categories
- Pilot Pre-flight: Standard external and internal checks before flight
- Mechanic Preflight: Detailed technical inspection before flight
- Mechanic Maintenance: Comprehensive inspection of aircraft systems and components

### Inspection Items
- Fuel System: Fuel tank quality, sump drain checks
- Flight Controls: Ailerons, flaps, control surfaces inspection
- Landing Gear: Tire condition, brake system checks
- Airframe: Fuselage, wings, tail surfaces inspection
- Engine: Engine compartment, propeller, spinner checks
- Electrical: Wiring, avionics, antenna checks

### Safety Considerations
- Emphasize safety-critical inspection items
- Remind user to follow proper inspection procedures
- Encourage thoroughness in all inspection areas
- Note any items requiring special attention

## Response Refinement

- When reading inspection items: "Please inspect [item name]. [Brief description]."
- For task completion: "Task completed. Moving to next item."
- For issues: "Issue noted. Moving to next item."
- For complex items: "Please carefully inspect [item name]. Pay special attention to [specific aspect]."

## Call Management

- If multiple commands are detected: "Processing command: [command]."
- If unclear command: "Please repeat your command."
- If user needs help: "Say 'done' to complete a task, 'problem' for issues, or 'inspection complete' to finish."

Remember that your ultimate goal is to guide the user through a thorough and efficient aircraft inspection while ensuring all safety-critical items are properly checked. Accuracy in inspection guidance is your top priority, followed by clear communication of each inspection item.
''';

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

  // Vapi implementation
  VapiClient? _vapiClient;
  VapiCall? _currentCall;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isCommandProcessed =
      false; // Flag to prevent multiple command processing
  String _currentCommand = '';
  String _lastRecognizedText = 'Initializing...';
  String? _userType;
  String _mechanicCategory = 'Preflight'; // New: Category for mechanics
  bool _isCallActive = false;

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

    // Initialize animation controllers
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

    // Fetch user data to determine user type
    _fetchUserData();

    // Initialize Vapi client
    _initializeVapiClient();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start the voice inspection automatically after the widget is built
    // We use a post-frame callback to ensure the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a small delay to ensure everything is initialized
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isCallActive &&
            _vapiClient != null &&
            _currentInspectionItems.isNotEmpty) {
          _startListening();
        }
      });
    });
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
  }

  Future<void> _initializeVapiClient() async {
    setState(() {
      _lastRecognizedText = 'Initializing voice assistant...';
    });

    try {
      // Check if we have valid configuration
      if (VAPI_PUBLIC_KEY == 'your-public-key-here' ||
          VAPI_ASSISTANT_ID == 'your-assistant-id-here') {
        // Show configuration dialog if credentials are not set
        _showConfigurationDialog();
        return;
      }

      // Initialize Vapi client with the configured public key
      _vapiClient = VapiClient(VAPI_PUBLIC_KEY);

      setState(() {
        _lastRecognizedText = _userType != null
            ? 'Ready to listen. Say commands for ${_userType!.toLowerCase()} inspection'
            : 'Ready to listen. Say inspection commands';
      });
    } catch (e) {
      setState(() {
        _lastRecognizedText = 'Error initializing voice assistant: $e';
      });
    }
  }

  void _showConfigurationDialog() {
    final publicKeyController = TextEditingController(text: VAPI_PUBLIC_KEY);
    final assistantIdController =
        TextEditingController(text: VAPI_ASSISTANT_ID);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: app_colors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Vapi Configuration',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter your Vapi credentials to enable voice features:',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: publicKeyController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Public Key',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: app_colors.secondary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: assistantIdController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Assistant ID',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: app_colors.secondary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Continue without voice features
              setState(() {
                _lastRecognizedText =
                    'Voice features disabled. Configure Vapi to enable.';
              });
            },
            child: const Text('Continue Without Voice'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // In a real implementation, you would save these credentials
              // For now, we'll just update the state and continue
              setState(() {
                _lastRecognizedText =
                    'Vapi configured. Restarting voice assistant...';
              });

              // Initialize with the new credentials
              _vapiClient = VapiClient(publicKeyController.text);
              _startVapiCall();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: app_colors.secondary,
            ),
            child: const Text('Save & Continue'),
          ),
        ],
      ),
    );
  }

  void _handleVapiEvent(VapiEvent event) {
    switch (event.label) {
      case "call-start":
        _handleCallStart();
        break;
      case "call-end":
        _handleCallEnd();
        break;
      case "message":
        _handleMessage(event);
        break;
    }
  }

  void _handleCallStart() {
    setState(() {
      _isCallActive = true;
      _isListening = true;
      _lastRecognizedText = 'Voice assistant active. Listening for commands...';
    });
    debugPrint('Vapi call started');

    // The first message will be handled by the assistant's firstMessage parameter
    // No need to call _readCurrentTask here as the assistant will handle the flow
  }

  void _handleCallEnd() {
    setState(() {
      _isCallActive = false;
      _isListening = false;
      _currentCall = null;
      _lastRecognizedText = 'Voice assistant disconnected';
    });
    debugPrint('Vapi call ended');
  }

  void _handleMessage(VapiEvent event) {
    // Process messages from Vapi
    try {
      debugPrint('Handling Vapi message: ${event.value}');

      if (event.value is Map<String, dynamic>) {
        final message = event.value as Map<String, dynamic>;
        debugPrint('Message type: ${message['type']}');

        // Handle transcript messages (user speech)
        if (message['type'] == 'transcript') {
          final transcript = message['transcript'] as String?;
          final role = message['role'] as String?;

          // Only process user transcripts, not assistant transcripts
          if (transcript != null && transcript.isNotEmpty && role == 'user') {
            debugPrint('User transcript received: $transcript');
            setState(() {
              _currentCommand = transcript;
              _lastRecognizedText = 'Recognized: "$_currentCommand"';
            });

            // Process the command
            _processCommand(_currentCommand);
          }
        }

        // Handle conversation update messages (assistant speech)
        if (message['type'] == 'conversation-update') {
          final conversation = message['conversation'];
          if (conversation is Map<String, dynamic>) {
            final messages = conversation['messages'] as List?;
            if (messages != null && messages.isNotEmpty) {
              // Check if the last message is a Map before casting
              final lastMessage = messages.last;
              if (lastMessage is Map<String, dynamic>) {
                if (lastMessage['role'] == 'assistant') {
                  final content = lastMessage['content'] as String?;
                  if (content != null && content.isNotEmpty) {
                    debugPrint('Assistant message: $content');
                    setState(() {
                      _lastRecognizedText = 'Assistant: $content';
                    });

                    // Update the current task index based on the assistant's message
                    _updateCurrentTaskIndexFromMessage(content);

                    // If the assistant says "task completed", mark the current task as completed
                    if (content.contains('task completed') ||
                        content.contains('Task completed')) {
                      if (_currentTaskIndex < _currentInspectionItems.length) {
                        final currentItem =
                            _currentInspectionItems[_currentTaskIndex];
                        if (!currentItem.isCompleted) {
                          _markTaskCompleted(currentItem);
                          debugPrint(
                              'Task marked as completed from assistant message: ${currentItem.title}');
                        }
                      }
                    }

                    // If the assistant says "issue noted", mark the current task as having an issue
                    if (content.contains('issue noted') ||
                        content.contains('Issue noted')) {
                      if (_currentTaskIndex < _currentInspectionItems.length) {
                        final currentItem =
                            _currentInspectionItems[_currentTaskIndex];
                        if (!currentItem.hasWarning) {
                          _markTaskWithIssue(currentItem);
                          debugPrint(
                              'Task marked with issue from assistant message: ${currentItem.title}');
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing Vapi message: $e');
    }
  }

  Future<void> _startVapiCall() async {
    if (_vapiClient == null || _isCallActive) return;

    try {
      setState(() {
        _isProcessing = true;
        _lastRecognizedText = 'Starting voice assistant...';
      });

      // Start a new call using the configured assistant ID
      final call = await _vapiClient!.start(
        assistantId: VAPI_ASSISTANT_ID,
        assistantOverrides: {
          'firstMessage':
              'Beginning aircraft inspection for ${widget.aircraftModel}. I will guide you through each inspection item. Please respond with "done" when you complete an item or "problem" if you find an issue. Let\'s start with the first item: ${_currentInspectionItems.isNotEmpty ? _currentInspectionItems[0].title : "Fuel Tank Quality"}.',
          'name': 'Aircraft Inspection Assistant',
          'model': {
            'model': 'gpt-4o',
            'provider': 'openai',
            'temperature': 0.5,
            'messages': [
              {
                'role': 'system',
                'content': '''
You are an aircraft inspection assistant. Your task is to guide the user through a series of inspection items.

Here is the list of inspection items for this ${_userType ?? 'Pilot'} inspection:
${_currentInspectionItems.map((item) => '- ${item.title}: ${item.description}').join('\n')}

Your conversation flow should be:
1. Start with the first inspection item
2. Wait for the user to respond with "done" (completed) or "problem" (issue found)
3. When the user responds, acknowledge their response and move to the next item
4. Continue this process for all inspection items
5. When all items are complete, provide a summary and end the conversation

For each item, say: "Please inspect [item name]. [Brief description]."

When the user says "done", respond: "Task completed. Next item: [next item name]."

When the user says "problem", respond: "Issue noted. Next item: [next item name]."

If the user says "inspection complete" at any time, provide a summary of completed items and end the conversation.

Keep your responses concise and focused on the inspection process.
'''
              }
            ],
          },
          'voice': {'voiceId': 'Elliot', 'provider': 'vapi'},
          'transcriber': {
            'model': 'nova-3',
            'language': 'en',
            'provider': 'deepgram',
            'endpointing': 150
          },
          'endCallMessage':
              'Thank you for completing the aircraft inspection. Your inspection has been recorded. Have a safe flight.',
        },
      );

      _currentCall = call;
      call.onEvent.listen(_handleVapiEvent);

      // Start animations
      _pulseController.repeat(reverse: true);
      _waveController.repeat();

      HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('Error starting Vapi call: $e');
      setState(() {
        _isProcessing = false;
        _lastRecognizedText = 'Error starting voice assistant: $e';
      });
    }
  }

  Future<void> _stopVapiCall() async {
    if (!_isCallActive || _currentCall == null) return;

    try {
      setState(() {
        _isProcessing = true;
        _isListening = false;
      });

      await _currentCall?.stop();

      // Stop animations
      _pulseController.stop();
      _waveController.stop();

      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint('Error stopping Vapi call: $e');
      setState(() {
        _isProcessing = false;
        _lastRecognizedText = 'Error stopping voice assistant: $e';
      });
    }
  }

  @override
  void dispose() {
    _stopVapiCall(); // Stop Vapi call when screen is disposed
    _pulseController.dispose();
    _waveController.dispose();
    _currentCall?.dispose();
    _vapiClient?.dispose();
    super.dispose();
  }

  void _startListening() async {
    if (_isCallActive) return;

    setState(() {
      _currentCommand = '';
      _isCommandProcessed = false; // Reset the command processed flag
    });

    // Start Vapi call for listening
    _startVapiCall();
  }

  void _stopListening() {
    if (!_isCallActive) return;

    setState(() {
      _isProcessing = true;
    });

    _stopVapiCall();

    // Process any final command
    if (_currentCommand.isNotEmpty) {
      _processCommand(_currentCommand);
    }

    setState(() {
      _isProcessing = false;
    });
  }

  void _processCommand(String command) {
    // Check if a command has already been processed
    if (_isCommandProcessed) return;

    final lowerCommand = command.toLowerCase().trim();
    debugPrint('Processing command: $command');

    // Handle specific commands for task completion
    if (_currentTaskIndex < _currentInspectionItems.length) {
      final currentItem = _currentInspectionItems[_currentTaskIndex];
      debugPrint(
          'Current task: ${currentItem.title} (index: $_currentTaskIndex)');

      // Check for completion commands
      if (lowerCommand.contains('done') ||
          lowerCommand.contains('completed') ||
          lowerCommand.contains('complete')) {
        // Only mark the current task as completed
        _markTaskCompleted(currentItem);

        // Mark the command as processed after marking the task
        _markCommandProcessed();

        debugPrint('Task marked as completed: ${currentItem.title}');
        return;
      }

      // Check for warning commands
      if (lowerCommand.contains('not completed') ||
          lowerCommand.contains('problem') ||
          lowerCommand.contains('issue') ||
          lowerCommand.contains('not complete')) {
        // Only mark the current task as having an issue
        _markTaskWithIssue(currentItem);

        // Mark the command as processed after marking the task
        _markCommandProcessed();

        debugPrint('Task marked with issue: ${currentItem.title}');
        return;
      }
    }

    // Handle general completion command
    if (lowerCommand.contains('complete') ||
        lowerCommand.contains('finish') ||
        lowerCommand.contains('inspection complete')) {
      _markCommandProcessed();
      _showCompletionDialog();
    }
  }

  void _markCommandProcessed() {
    debugPrint('Marking command as processed');
    _isCommandProcessed = true;
    // Don't stop listening here since Vapi will handle the continuous conversation

    // Reset the command processed flag after a shorter delay to allow processing of new commands
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isCommandProcessed = false;
        debugPrint('Command processed flag reset');
      });
    });
  }

  void _markTaskCompleted(InspectionItem item) {
    setState(() {
      item.isCompleted = true;
      item.completedAt = DateTime.now();
      item.hasWarning = false; // Clear any warning
    });
    HapticFeedback.lightImpact();
    _lastRecognizedText = 'Task completed: ${item.title}';

    // Vapi will handle the conversation flow, so we don't need to move to the next task here
    debugPrint('Task marked as completed: ${item.title}');

    // Force a UI update to ensure the task list is refreshed
    setState(() {});
  }

  void _markTaskWithIssue(InspectionItem item) {
    setState(() {
      item.isCompleted = false;
      item.hasWarning = true;
      item.warningAt = DateTime.now();
    });
    HapticFeedback.mediumImpact();
    _lastRecognizedText = 'Task has issue: ${item.title}';

    // Vapi will handle the conversation flow, so we don't need to move to the next task here
    debugPrint('Task marked with issue: ${item.title}');

    // Force a UI update to ensure the task list is refreshed
    setState(() {});
  }

  void _updateCurrentTaskFromMessage(String message) {
    debugPrint('Updating current task from message: $message');

    // Check if the message indicates task completion
    if (message.contains('task completed') ||
        message.contains('Task completed')) {
      // Mark the current task as completed
      if (_currentTaskIndex < _currentInspectionItems.length) {
        final currentItem = _currentInspectionItems[_currentTaskIndex];
        if (!currentItem.isCompleted) {
          setState(() {
            currentItem.isCompleted = true;
            currentItem.completedAt = DateTime.now();
            currentItem.hasWarning = false;
            debugPrint(
                'Current task marked as completed: ${currentItem.title}');
          });
        }
      }
    }

    // Check if the message indicates a task issue
    if (message.contains('issue noted') || message.contains('Issue noted')) {
      // Mark the current task as having an issue
      if (_currentTaskIndex < _currentInspectionItems.length) {
        final currentItem = _currentInspectionItems[_currentTaskIndex];
        if (!currentItem.hasWarning) {
          setState(() {
            currentItem.isCompleted = false;
            currentItem.hasWarning = true;
            currentItem.warningAt = DateTime.now();
            debugPrint('Current task marked with issue: ${currentItem.title}');
          });
        }
      }
    }

    // Try to find which task is being mentioned in the message
    for (int i = 0; i < _currentInspectionItems.length; i++) {
      final item = _currentInspectionItems[i];
      if (message.contains(item.title)) {
        // Update the current task index
        if (_currentTaskIndex != i) {
          setState(() {
            _currentTaskIndex = i;
            debugPrint(
                'Current task index updated to: $_currentTaskIndex (${item.title})');
          });
        }
        return;
      }
    }

    // If no specific task is found, look for keywords like "next item" or "task completed"
    if (message.contains('next item') || message.contains('Next item')) {
      // Move to the next task if not at the end
      if (_currentTaskIndex < _currentInspectionItems.length - 1) {
        setState(() {
          _currentTaskIndex++;
          debugPrint(
              'Current task index incremented to: $_currentTaskIndex (${_currentInspectionItems[_currentTaskIndex].title})');
        });
      }
    }

    // Force a UI update to ensure the task list is refreshed
    setState(() {});
  }

  // Update only the current task index based on the assistant's message
  // Don't mark tasks as completed or with issues based on assistant messages
  void _updateCurrentTaskIndexFromMessage(String message) {
    debugPrint('Updating current task index from message: $message');

    // Try to find which task is being mentioned in the message
    for (int i = 0; i < _currentInspectionItems.length; i++) {
      final item = _currentInspectionItems[i];
      if (message.contains(item.title)) {
        // Update the current task index
        if (_currentTaskIndex != i) {
          setState(() {
            _currentTaskIndex = i;
            debugPrint(
                'Current task index updated to: $_currentTaskIndex (${item.title})');
          });
        }
        return;
      }
    }

    // If no specific task is found, look for keywords like "next item"
    if (message.contains('next item') || message.contains('Next item')) {
      // Move to the next task if not at the end
      if (_currentTaskIndex < _currentInspectionItems.length - 1) {
        setState(() {
          _currentTaskIndex++;
          debugPrint(
              'Current task index incremented to: $_currentTaskIndex (${_currentInspectionItems[_currentTaskIndex].title})');
        });
      }
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
                        // _buildInspectionChecklist(),
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
                // Voice indicator
                AnimatedBuilder(
                  animation:
                      Listenable.merge([_pulseAnimation, _waveAnimation]),
                  builder: (context, child) {
                    return GestureDetector(
                      onTap: _isCallActive ? _stopListening : _startListening,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isCallActive
                              ? app_colors.secondary.withOpacity(0.8)
                              : app_colors.secondary,
                          boxShadow: _isCallActive
                              ? [
                                  BoxShadow(
                                    color:
                                        app_colors.secondary.withOpacity(0.4),
                                    blurRadius: 20 * _pulseAnimation.value,
                                    spreadRadius: 5 * _pulseAnimation.value,
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color:
                                        app_colors.secondary.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                        ),
                        child: Transform.scale(
                          scale: _isCallActive ? _pulseAnimation.value : 1.0,
                          child: Icon(
                            _isCallActive
                                ? Icons.mic
                                : _isProcessing
                                    ? Icons.hourglass_empty
                                    : Icons.mic_none,
                            size: 48,
                            color: Colors.white,
                          ),
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
                  _isCallActive
                      ? 'Listening... Speak commands naturally'
                      : 'Voice assistant starting automatically...',
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
