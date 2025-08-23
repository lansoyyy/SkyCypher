import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skycypher/utils/colors.dart' as app_colors;

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

  bool _isListening = false;
  bool _isProcessing = false;
  String _currentCommand = '';
  String _lastRecognizedText = 'Say "Start inspection" to begin';

  // Inspection checklist
  final List<InspectionItem> _inspectionItems = [
    InspectionItem(
      id: 'exterior',
      title: 'Exterior Inspection',
      description: 'Check fuselage, wings, and control surfaces',
      commands: ['exterior check', 'check exterior', 'fuselage inspection'],
    ),
    InspectionItem(
      id: 'engine',
      title: 'Engine Inspection',
      description: 'Check engine oil, fuel, and components',
      commands: ['engine check', 'check engine', 'engine inspection'],
    ),
    InspectionItem(
      id: 'cockpit',
      title: 'Cockpit Inspection',
      description: 'Check instruments, controls, and electrical systems',
      commands: ['cockpit check', 'check cockpit', 'cockpit inspection'],
    ),
    InspectionItem(
      id: 'tires',
      title: 'Landing Gear & Tires',
      description: 'Check tires, brakes, and landing gear',
      commands: ['tire check', 'check tires', 'landing gear inspection'],
    ),
    InspectionItem(
      id: 'fuel',
      title: 'Fuel System',
      description: 'Check fuel quantity, quality, and leaks',
      commands: ['fuel check', 'check fuel', 'fuel inspection'],
    ),
  ];

  @override
  void initState() {
    super.initState();

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

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _startListening() {
    setState(() {
      _isListening = true;
      _currentCommand = '';
      _lastRecognizedText = 'Listening...';
    });

    HapticFeedback.heavyImpact();
    _pulseController.repeat(reverse: true);
    _waveController.repeat();

    // Simulate voice recognition
    _simulateVoiceRecognition();
  }

  void _stopListening() {
    setState(() {
      _isListening = false;
      _isProcessing = true;
    });

    _pulseController.stop();
    _waveController.stop();

    // Simulate processing
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _lastRecognizedText = _currentCommand.isEmpty
              ? 'No command recognized. Try again.'
              : 'Command processed: $_currentCommand';
        });
        _processCommand(_currentCommand);
      }
    });
  }

  void _simulateVoiceRecognition() {
    final commands = [
      'Start inspection',
      'Exterior check complete',
      'Engine inspection done',
      'Cockpit systems good',
      'Tires and landing gear OK',
      'Fuel system checked',
      'Complete inspection',
    ];

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (_isListening && mounted) {
        setState(() {
          _currentCommand =
              commands[DateTime.now().millisecond % commands.length];
          _lastRecognizedText = 'Recognized: "$_currentCommand"';
        });
      }
    });
  }

  void _processCommand(String command) {
    final lowerCommand = command.toLowerCase();

    for (var item in _inspectionItems) {
      for (var cmd in item.commands) {
        if (lowerCommand.contains(cmd.toLowerCase())) {
          setState(() {
            item.isCompleted = true;
            item.completedAt = DateTime.now();
          });
          HapticFeedback.lightImpact();
          break;
        }
      }
    }

    if (lowerCommand.contains('complete') || lowerCommand.contains('finish')) {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final completedItems =
        _inspectionItems.where((item) => item.isCompleted).length;
    final totalItems = _inspectionItems.length;

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
                onTap: () => Navigator.of(context).pop(),
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
            'Use voice commands to complete inspection checklist',
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
                // Voice button
                GestureDetector(
                  onTapDown: (_) => _startListening(),
                  onTapUp: (_) => _stopListening(),
                  onTapCancel: () => _stopListening(),
                  child: AnimatedBuilder(
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
                      ? 'Hold to speak, release to process'
                      : 'Press and hold the microphone to give voice commands',
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
                ...(_inspectionItems
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
    final completed = _inspectionItems.where((item) => item.isCompleted).length;
    final total = _inspectionItems.length;
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
