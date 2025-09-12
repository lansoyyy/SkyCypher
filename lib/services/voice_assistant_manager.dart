import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:skycypher/screens/voice_inspection_screen.dart';
import 'package:skycypher/screens/aircraft_selection_screen.dart';
import 'package:skycypher/screens/maintenance_log_screen.dart';
import 'package:skycypher/screens/aircraft_status_screen.dart';

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

  // Timer for continuous listening check
  Timer? _listeningCheckTimer;

  // Timer for preventing too frequent restarts
  DateTime _lastListenAttempt = DateTime.now();

  // Counter to prevent infinite retries
  int _errorRetryCount = 0;
  static const int MAX_ERROR_RETRIES = 3;

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
    print('Showing voice assistant dialog...');
    if (_overlayEntry != null) {
      print('Dialog already visible');
      return;
    }

    _dialogContext = context;
    _overlayEntry = OverlayEntry(
      builder: (context) => VoiceAssistantDialog(
        manager: this,
        onClose: _dismissDialog,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    print('Dialog inserted into overlay');

    // Start periodic check for continuous listening
    _startListeningCheck();
  }

  /// Start periodic check for continuous listening
  void _startListeningCheck() {
    _listeningCheckTimer?.cancel();
    _listeningCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_overlayEntry != null && !_isListening && _isInitialized) {
        // Restart listening if dialog is open but not listening
        listen();
      }
    });
  }

  /// Dismiss the voice assistant dialog
  void _dismissDialog() {
    _listeningCheckTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _dialogContext = null;
    _isSelectingAircraft = false;
    _isEnteringRpNumber = false;
    _selectedAircraft = '';
    _rpNumber = '';
    _errorRetryCount = 0; // Reset error counter when dialog is closed
  }

  /// Dismiss the dialog externally
  void dismissDialog() {
    _dismissDialog();
  }

  /// Initialize speech recognition
  Future<bool> initialize() async {
    print('Initializing speech recognition...');
    _speech = stt.SpeechToText();
    try {
      bool available = await _speech!.initialize(
        onError: (error) => _onSpeechError(error),
        onStatus: (status) => _onSpeechStatus(status),
        finalTimeout: const Duration(seconds: 30), // Longer final timeout
      );
      _isInitialized = available;
      _statusMessage =
          available ? 'Ready to listen' : 'Speech service not available';
      print('Speech recognition initialized: $available');
      _updateDialogState();
      return available;
    } catch (e) {
      print('Speech recognition initialization error: $e');
      _isInitialized = false;
      _statusMessage = 'Initialization failed: $e';
      _updateDialogState();
      return false;
    }
  }

  /// Start listening for speech
  void listen() async {
    print('Attempting to start listening...');

    // Prevent too frequent restarts (at least 1 second between attempts)
    final now = DateTime.now();
    if (now.difference(_lastListenAttempt).inMilliseconds < 1000) {
      print('Throttling listen attempt, too soon since last attempt');
      return;
    }
    _lastListenAttempt = now;

    if (_isListening || _speech == null) {
      print(
          'Cannot start listening - isListening: $_isListening, speech null: ${_speech == null}');
      return;
    }

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

    // Double-check initialization
    if (!_isInitialized) {
      print('Speech service still not initialized');
      return;
    }

    _isListening = true;
    _statusMessage = 'Listening...';
    _errorRetryCount = 0; // Reset error counter on successful listen attempt
    _updateDialogState();

    print('Starting speech recognition...');
    try {
      _speech!.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          print('Recognized text: $_recognizedText');
          print('Confidence: ${result.confidence}');
          _updateDialogState();

          // Process the command if confidence is high enough
          if (result.confidence > 0.5) {
            _processCommand(_recognizedText);
          } else {
            print('Low confidence result: ${result.confidence}');
          }
        },
        listenFor: const Duration(seconds: 30), // Listen for longer periods
        pauseFor: const Duration(seconds: 5), // Allow longer pauses
        localeId: 'en_US',
      );
    } catch (e) {
      print('Error starting speech recognition: $e');
      _isListening = false;
      _statusMessage = 'Error starting recognition: $e';
      _updateDialogState();
    }
  }

  /// Stop listening
  void stop() {
    if (!_isListening || _speech == null) return;

    try {
      _speech!.stop();
      _isListening = false;
      _statusMessage = 'Processing...';
      _updateDialogState();
      print('Stopped speech recognition');
    } catch (e) {
      print('Error stopping speech recognition: $e');
    }
  }

  /// Process recognized command
  void _processCommand(String command) {
    final lowerCommand = command.toLowerCase().trim();
    print('Processing command: $command');

    // Add to command history
    _commandHistory.add(VoiceCommand(
      text: command,
      confidence: 0.8, // Placeholder value
      timestamp: DateTime.now(),
    ));

    // Check for inspection command - navigate directly to aircraft selection
    // This will match "inspection", "inspections", or "start inspection" anywhere in the spoken sentence
    if (lowerCommand.contains('inspection') ||
        lowerCommand.contains('start inspection')) {
      print('Recognized inspection command');
      // Stop listening before navigating
      stop();
      _dismissDialog();
      if (_dialogContext != null && _dialogContext!.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_dialogContext != null && _dialogContext!.mounted) {
            Navigator.push(
              _dialogContext!,
              MaterialPageRoute(
                builder: (context) => const AircraftSelectionScreen(),
              ),
            );
          }
        });
      }
      return;
    }

    // Check for maintenance command - navigate directly to maintenance log screen
    // This will match "maintenance" anywhere in the spoken sentence
    if (lowerCommand.contains('maintenance')) {
      print('Recognized maintenance command');
      // Stop listening before navigating
      stop();
      _dismissDialog();
      if (_dialogContext != null && _dialogContext!.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_dialogContext != null && _dialogContext!.mounted) {
            Navigator.push(
              _dialogContext!,
              MaterialPageRoute(
                builder: (context) => const MaintenanceLogScreen(),
              ),
            );
          }
        });
      }
      return;
    }

    // Check for status command - navigate directly to aircraft status screen
    // This will match "status" anywhere in the spoken sentence
    if (lowerCommand.contains('status')) {
      print('Recognized status command');
      // Stop listening before navigating
      stop();
      _dismissDialog();
      if (_dialogContext != null && _dialogContext!.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_dialogContext != null && _dialogContext!.mounted) {
            Navigator.push(
              _dialogContext!,
              MaterialPageRoute(
                builder: (context) => const AircraftStatusScreen(),
              ),
            );
          }
        });
      }
      return;
    }
  }

  /// Handle speech recognition errors
  void _onSpeechError(dynamic error) {
    print('Speech recognition error: $error');
    _statusMessage = 'Error: $error';
    _isListening = false;

    // Check if the error is permanent
    bool isPermanent = false;
    String errorMsg = '';

    // Handle different error types
    if (error is Map) {
      isPermanent = error['permanent'] == true;
      errorMsg = error['msg']?.toString() ?? 'Unknown error';
    } else {
      errorMsg = error.toString();
      // For string errors, we'll assume they're permanent if they contain certain keywords
      isPermanent = errorMsg.contains('error_busy') ||
          errorMsg.contains('permanent: true');
    }

    print('Error details - Message: $errorMsg, Permanent: $isPermanent');

    // Check retry count
    if (_errorRetryCount >= MAX_ERROR_RETRIES) {
      print('Max retry count reached, not attempting to restart');
      _statusMessage = 'Speech service unavailable. Please try again later.';
      _errorRetryCount = 0; // Reset for next time
      _updateDialogState();
      return;
    }

    // Special handling for speech timeout - even if marked as permanent, we might want to retry
    if (errorMsg.contains('error_speech_timeout') && _overlayEntry != null) {
      print('Handling timeout error - will restart listening');
      _errorRetryCount++;
      _statusMessage = 'Listening timeout. Ready to try again.';
      // Restart listening after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_overlayEntry != null && !_isListening) {
          print(
              'Retrying speech recognition after timeout (attempt $_errorRetryCount)');
          listen();
        }
      });
    }
    // For permanent errors (other than timeout), don't try to restart automatically
    else if (isPermanent) {
      print('Permanent error encountered, not restarting automatically');
      _statusMessage = 'Speech service error. Please try again.';
      _errorRetryCount = 0; // Reset counter for permanent errors
    }
    // If it's a busy error, we might want to retry after a delay
    else if (errorMsg.contains('error_busy') && _overlayEntry != null) {
      print('Handling busy error - will retry in 1 second');
      _errorRetryCount++;
      // Don't immediately restart, wait a bit
      Future.delayed(const Duration(seconds: 1), () {
        if (_overlayEntry != null && !_isListening) {
          print(
              'Retrying speech recognition after busy error (attempt $_errorRetryCount)');
          listen();
        }
      });
    }
    // For other temporary errors, we can try to restart
    else if (_overlayEntry != null) {
      print('Temporary error, will retry');
      _errorRetryCount++;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_overlayEntry != null && !_isListening) {
          print(
              'Retrying speech recognition after temporary error (attempt $_errorRetryCount)');
          listen();
        }
      });
    }

    _updateDialogState();
  }

  /// Handle speech recognition status changes
  void _onSpeechStatus(String status) {
    print('Speech recognition status: $status');
    // Update status message based on recognition status
    switch (status) {
      case 'listening':
        _statusMessage = 'Listening...';
        break;
      case 'notListening':
        _statusMessage = 'Not listening';
        // Automatically restart listening if it stops unexpectedly
        if (_isListening) {
          _isListening = false;
          print('Speech recognition stopped unexpectedly, scheduling restart');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_overlayEntry != null) {
              // Only restart if dialog is still open
              // Add a delay to prevent rapid restart loops
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_overlayEntry != null && !_isListening) {
                  print('Restarting speech recognition after unexpected stop');
                  listen();
                }
              });
            }
          });
        }
        break;
      case 'done':
        _statusMessage = 'Done processing';
        _isListening = false;
        // When done, we might want to restart listening for continuous use
        print('Speech recognition done, scheduling restart');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_overlayEntry != null) {
            // Add a delay to prevent rapid restart loops
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_overlayEntry != null && !_isListening) {
                print('Restarting speech recognition after done state');
                listen();
              }
            });
          }
        });
        break;
      default:
        _statusMessage = 'Status: $status';
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
    } else {
      return 'Say "inspection", "start inspection", "maintenance", or "status"...';
    }
  }
}
