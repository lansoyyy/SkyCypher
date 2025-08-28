import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:skycypher/screens/voice_inspection_screen.dart';

class VoiceAssistantManager {
  static final VoiceAssistantManager _instance =
      VoiceAssistantManager._internal();
  factory VoiceAssistantManager() => _instance;
  VoiceAssistantManager._internal();

  stt.SpeechToText? _speech;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isInitialized = false;
  String _recognizedText = '';
  String _statusMessage = 'Initializing...';
  BuildContext? _dialogContext;
  OverlayEntry? _overlayEntry;
  final List<VoiceCommand> _commandHistory = [];

  // Aircraft selection state
  bool _isSelectingAircraft = false;
  bool _isEnteringRpNumber = false;
  String _selectedAircraft = '';
  String _rpNumber = '';

  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  bool get isInitialized => _isInitialized;
  String get recognizedText => _recognizedText;
  String get statusMessage => _statusMessage;
  List<VoiceCommand> get commandHistory => List.unmodifiable(_commandHistory);
  bool get isDialogVisible => _overlayEntry != null;
  bool get isSelectingAircraft => _isSelectingAircraft;
  bool get isEnteringRpNumber => _isEnteringRpNumber;

  /// Show the voice assistant dialog
  Future<void> showDialog(BuildContext context) async {
    if (_overlayEntry != null) return;

    _dialogContext = context;
    _overlayEntry = OverlayEntry(
      builder: (context) => VoiceAssistantDialog(
        manager: this,
        onClose: _dismissDialog,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Dismiss the voice assistant dialog
  void _dismissDialog() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _dialogContext = null;
    _isSelectingAircraft = false;
    _isEnteringRpNumber = false;
    _selectedAircraft = '';
    _rpNumber = '';
  }

  /// Dismiss the dialog externally
  void dismissDialog() {
    _dismissDialog();
  }

  /// Initialize speech recognition
  Future<bool> initialize() async {
    _speech = stt.SpeechToText();
    try {
      bool available = await _speech!.initialize(
        onError: (error) => _onSpeechError(error),
        onStatus: (status) => _onSpeechStatus(status),
      );
      _isInitialized = available;
      _statusMessage =
          available ? 'Ready to listen' : 'Speech service not available';
      _updateDialogState();
      return available;
    } catch (e) {
      _isInitialized = false;
      _statusMessage = 'Initialization failed: $e';
      _updateDialogState();
      return false;
    }
  }

  /// Start listening for speech
  void listen() async {
    if (_isListening || _speech == null || !_isInitialized) {
      // If not initialized, try to initialize first
      if (!_isInitialized) {
        _statusMessage = 'Initializing speech service...';
        _updateDialogState();

        bool initialized = await initialize();
        if (!initialized) {
          _statusMessage = 'Failed to initialize speech service';
          _updateDialogState();
          return;
        }
      }

      // If still not ready, return
      if (!_isInitialized) return;
    }

    _isListening = true;
    _statusMessage = 'Listening...';
    _updateDialogState();

    _speech!.listen(
      onResult: (result) {
        _recognizedText = result.recognizedWords;
        _updateDialogState();

        // Process the command if confidence is high enough
        if (result.confidence > 0.5) {
          _processCommand(_recognizedText);
        }
      },
    );
  }

  /// Stop listening
  void stop() {
    if (!_isListening || _speech == null) return;

    _speech!.stop();
    _isListening = false;
    _statusMessage = 'Processing...';
    _updateDialogState();
  }

  /// Process recognized command
  void _processCommand(String command) {
    final lowerCommand = command.toLowerCase();

    // Add to command history
    _commandHistory.add(VoiceCommand(
      text: command,
      confidence: 0.8, // Placeholder value
      timestamp: DateTime.now(),
    ));

    // Handle aircraft selection flow
    if (_isSelectingAircraft) {
      _handleAircraftSelection(command);
      return;
    }

    // Handle RP number entry flow
    if (_isEnteringRpNumber) {
      _handleRpNumberEntry(command);
      return;
    }

    // Check if command contains "inspection"
    if (lowerCommand.contains('inspection')) {
      // Start aircraft selection process
      _startAircraftSelection();
    }
  }

  /// Start the aircraft selection process
  void _startAircraftSelection() {
    _isSelectingAircraft = true;
    _statusMessage = 'Please say "Cessna 152" or "Cessna 150"';
    _updateDialogState();
  }

  /// Handle aircraft selection
  void _handleAircraftSelection(String command) {
    final lowerCommand = command.toLowerCase();

    if (lowerCommand.contains('cessna 152')) {
      _selectedAircraft = 'Cessna 152';
      _isSelectingAircraft = false;
      _isEnteringRpNumber = true;
      _statusMessage = 'Please say the RP number';
      _updateDialogState();
    } else if (lowerCommand.contains('cessna 150')) {
      _selectedAircraft = 'Cessna 150';
      _isSelectingAircraft = false;
      _isEnteringRpNumber = true;
      _statusMessage = 'Please say the RP number';
      _updateDialogState();
    }
  }

  /// Handle RP number entry
  void _handleRpNumberEntry(String command) {
    // For simplicity, we'll use the recognized text as the RP number
    _rpNumber = command.toUpperCase();
    _isEnteringRpNumber = false;

    // Navigate to voice inspection screen with selected aircraft and RP number
    _navigateToVoiceInspection();
  }

  /// Navigate to voice inspection screen while maintaining dialog
  void _navigateToVoiceInspection() {
    if (_dialogContext == null) return;

    // Dismiss the voice assistant dialog before navigating
    _dismissDialog();

    // Navigate to voice inspection screen
    Navigator.push(
      _dialogContext!,
      MaterialPageRoute(
        builder: (context) => VoiceInspectionScreen(
          aircraftModel: _selectedAircraft,
          rpNumber: _rpNumber,
        ),
      ),
    );
  }

  /// Handle speech recognition errors
  void _onSpeechError(dynamic error) {
    _statusMessage = 'Error: $error';
    _isListening = false;
    _updateDialogState();
  }

  /// Handle speech recognition status changes
  void _onSpeechStatus(String status) {
    // Update status message based on recognition status
    switch (status) {
      case 'listening':
        _statusMessage = 'Listening...';
        break;
      case 'notListening':
        _statusMessage = 'Not listening';
        break;
      case 'done':
        _statusMessage = 'Done processing';
        break;
    }
    _updateDialogState();
  }

  /// Update dialog state
  void _updateDialogState() {
    // Rebuild the dialog to reflect state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_overlayEntry != null) {
        _overlayEntry!.markNeedsBuild();
      }
    });
  }

  /// Get singleton instance
  static VoiceAssistantManager getInstance() {
    return _instance;
  }
}

class VoiceCommand {
  final String text;
  final double confidence;
  final DateTime timestamp;

  VoiceCommand({
    required this.text,
    required this.confidence,
    required this.timestamp,
  });
}

class VoiceAssistantDialog extends StatefulWidget {
  final VoiceAssistantManager manager;
  final VoidCallback onClose;

  const VoiceAssistantDialog({
    super.key,
    required this.manager,
    required this.onClose,
  });

  @override
  State<VoiceAssistantDialog> createState() => _VoiceAssistantDialogState();
}

class _VoiceAssistantDialogState extends State<VoiceAssistantDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);

    // Initialize and start listening when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Ensure the manager is initialized before listening
      if (!widget.manager.isInitialized) {
        await widget.manager.initialize();
      }
      widget.manager.listen();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Voice Assistant',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Microphone button with animation (now just for visual feedback)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.manager.isListening
                            ? Colors.blue.withOpacity(0.8)
                            : Colors.blue,
                        boxShadow: [
                          BoxShadow(
                            color: widget.manager.isListening
                                ? Colors.blue.withOpacity(0.5)
                                : Colors.blue.withOpacity(0.3),
                            blurRadius: widget.manager.isListening
                                ? 20 * _pulseAnimation.value
                                : 15,
                            spreadRadius: widget.manager.isListening
                                ? 5 * _pulseAnimation.value
                                : 3,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Transform.scale(
                        scale: widget.manager.isListening
                            ? _pulseAnimation.value
                            : 1.0,
                        child: Icon(
                          widget.manager.isListening
                              ? Icons.mic
                              : widget.manager.isProcessing
                                  ? Icons.hourglass_empty
                                  : widget.manager.isInitialized
                                      ? Icons.mic_none
                                      : Icons.hourglass_bottom,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Status message
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.manager.statusMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Recognized text
                    if (widget.manager.recognizedText.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '"${widget.manager.recognizedText}"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Instructions based on current state
                    Text(
                      _getInstructions(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getInstructions() {
    if (!widget.manager.isInitialized) {
      return 'Initializing speech service...';
    } else if (widget.manager.isSelectingAircraft) {
      return 'Say "Cessna 152" or "Cessna 150"';
    } else if (widget.manager.isEnteringRpNumber) {
      return 'Please say the RP number';
    } else {
      return 'Listening for "inspection"...';
    }
  }
}
