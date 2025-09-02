import 'package:flutter/material.dart';
import 'package:skycypher/utils/colors.dart' as app_colors;
import 'package:skycypher/screens/voice_inspection_screen.dart';
import 'package:skycypher/models/aircraft.dart';
import 'package:skycypher/services/aircraft_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AircraftSelectionScreen extends StatefulWidget {
  const AircraftSelectionScreen({super.key});

  @override
  State<AircraftSelectionScreen> createState() =>
      _AircraftSelectionScreenState();
}

class _AircraftSelectionScreenState extends State<AircraftSelectionScreen> {
  final TextEditingController _rpController = TextEditingController();

  // Track loading state
  bool _isLoading = true;
  // Store aircraft data
  List<Aircraft> _aircraftList = [];
  Aircraft? _selectedAircraft;
  String? _rpNumber;

  @override
  void initState() {
    super.initState();
    // Initialize default aircraft data in Firestore if needed
    _initializeAircraft();
  }

  // Initialize aircraft data
  Future<void> _initializeAircraft() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Initialize default aircraft if they don't exist
      await AircraftService.initializeDefaultAircraft();

      // Fetch aircraft data
      await _fetchAircraft();
    } catch (e) {
      print('Error initializing aircraft: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch aircraft data from Firestore
  Future<void> _fetchAircraft() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('aircraft').get();

      List<Aircraft> aircraftList = [];
      for (var doc in snapshot.docs) {
        aircraftList.add(
            Aircraft.fromDocument(doc.data() as Map<String, dynamic>, doc.id));
      }

      setState(() {
        _aircraftList = aircraftList;
        // Select the first available aircraft by default, or the first aircraft if none are available
      });
    } catch (e) {
      print('Error fetching aircraft: $e');
    }
  }

  // Select an aircraft
  void _selectAircraft(Aircraft aircraft) {
    setState(() {
      _selectedAircraft = aircraft;

      // If the aircraft has an RP number in the database, use it
      if (aircraft.rpNumber?.isNotEmpty == true) {
        _rpNumber = aircraft.rpNumber;
      }
      // If not and we don't have an RP number set yet, prompt for it
      else if (_rpNumber?.isEmpty ?? true) {
        // Schedule the prompt after the current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _promptRP(context, aircraft);
        });
      }
    });
  }

  @override
  void dispose() {
    _rpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient layer
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      app_colors.primary,
                      Color.lerp(
                          app_colors.primary, app_colors.secondary, 0.10)!,
                    ],
                  ),
                ),
              ),
            ),
            // Subtle watermark logo
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: 0.04,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 500,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              _lighten(app_colors.secondary, .25),
                              _darken(app_colors.secondary, .15),
                            ],
                          ),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.18), width: 1),
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.black, size: 28),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Title
                  const Center(
                    child: Text(
                      'Choose Aircraft for\nInspection',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.1,
                        fontFamily: 'Bold',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Select an aircraft and enter RP to begin.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                        fontFamily: 'Medium',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Loading indicator or content
                  _isLoading
                      ? const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Expanded(
                          child: _buildAircraftContent(),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAircraftContent() {
    if (_aircraftList.isEmpty) {
      return Center(
        child: Text(
          'No aircraft available.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 16,
          ),
        ),
      );
    }

    // Check if START INSPECTION button should be shown
    final bool canStartInspection = _selectedAircraft?.isAvailable == true &&
        (_rpNumber?.isNotEmpty ?? false);

    return Column(
      children: [
        // Header for aircraft list
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _lighten(app_colors.secondary, .06),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
          ),
          child: Row(
            children: [
              const Text(
                'Available Aircraft',
                style: TextStyle(
                    color: Colors.black, fontFamily: 'Bold', fontSize: 18),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_aircraftList.where((a) => a.isAvailable).length}/${_aircraftList.length}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontFamily: 'Bold',
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Model cards
        Expanded(
          child: ListView.builder(
            itemCount: _aircraftList.length,
            itemBuilder: (context, index) {
              final aircraft = _aircraftList[index];
              final isSelected = _selectedAircraft?.id == aircraft.id;

              return GestureDetector(
                onTap: aircraft.isAvailable
                    ? () {
                        _selectAircraft(aircraft);
                      }
                    : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? app_colors.secondary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      _AircraftCard(
                        title: aircraft.name,
                        assetPath: 'assets/images/${aircraft.name}.png',
                        available: aircraft.isAvailable,
                        status: aircraft.status,
                        rpNumber: aircraft.rpNumber ?? '',
                        isSelected: isSelected,
                        onEnterRP: () => _promptRP(context, aircraft),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Start button - make it always visible but conditionally enabled
        SizedBox(
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _lighten(app_colors.secondary, .12),
              foregroundColor: Colors.black,
              elevation: 6,
              shadowColor: Colors.black.withOpacity(0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.white.withOpacity(0.18)),
              ),
            ),
            onPressed: canStartInspection
                ? () {
                    _showInspectionWarningDialog(context);
                  }
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'START INSPECTION',
                  style: TextStyle(
                    fontFamily: 'Bold',
                    fontSize: 16,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _promptRP(BuildContext context, Aircraft aircraft) async {
    // Set a default RP number if it's empty in the database
    _rpController.text = aircraft.rpNumber?.isNotEmpty == true
        ? aircraft.rpNumber!
        : _rpNumber ?? '';

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _lighten(app_colors.secondary, .12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Enter Aircraft RP Number',
            style: const TextStyle(fontFamily: 'Bold'),
          ),
          content: TextField(
            controller: _rpController,
            style: const TextStyle(fontFamily: 'Regular'),
            decoration: InputDecoration(
              hintText: 'e.g. RP-C152',
              hintStyle:
                  const TextStyle(color: Colors.black54, fontFamily: 'Regular'),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.black.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.black.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.black.withOpacity(0.45)),
              ),
              prefixIcon: const Icon(Icons.tag, color: Colors.black87),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _lighten(app_colors.secondary, .12),
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                setState(() {
                  _selectedAircraft = aircraft;
                  _rpNumber = _rpController.text.trim();

                  // If RP is empty, set a default value to enable the button
                  if (_rpNumber?.isEmpty ?? true) {
                    _rpNumber = 'RP-${aircraft.name.replaceAll(' ', '')}';
                  }
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showInspectionWarningDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _lighten(app_colors.secondary, .12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Inspection Checklist Notice',
            style: TextStyle(fontFamily: 'Bold'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The voice commands for the task list are based on our research and may not exactly match your aircraft\'s official handbook.',
                style: TextStyle(fontFamily: 'Regular'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please refer to your aircraft\'s official handbook for the most accurate and complete inspection procedures.',
                style: TextStyle(fontFamily: 'Bold'),
              ),
              const SizedBox(height: 16),
              const Text(
                'This is a guidance tool only and should not replace proper training and official documentation.',
                style: TextStyle(fontFamily: 'Regular'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _lighten(app_colors.secondary, .12),
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to voice inspection screen
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        VoiceInspectionScreen(
                      aircraftModel: _selectedAircraft!.name,
                      rpNumber: _rpNumber!,
                    ),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          )),
                          child: child,
                        ),
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                );
              },
              child: const Text('PROCEED'),
            ),
          ],
        );
      },
    );
  }
}

class _AircraftCard extends StatelessWidget {
  final String title;
  final String assetPath;
  final bool available;
  final String status;
  final String rpNumber;
  final bool isSelected;
  final VoidCallback onEnterRP;

  const _AircraftCard({
    required this.title,
    required this.assetPath,
    required this.available,
    required this.status,
    required this.rpNumber,
    required this.onEnterRP,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.1)),
          color:
              isSelected ? _lighten(app_colors.secondary, 0.35) : Colors.white,
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Plane image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                assetPath,
                width: 80,
                height: 54,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            // Title + badge + RP button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Bold',
                            fontSize: 18,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: available
                              ? Colors.green.withOpacity(0.15)
                              : Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: (available ? Colors.green : Colors.red)
                                  .withOpacity(0.6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              available ? Icons.check_circle : Icons.block,
                              size: 14,
                              color: available ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status,
                              style: TextStyle(
                                color: available
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                                fontSize: 11,
                                fontFamily: 'Medium',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (rpNumber.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'RP: $rpNumber',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.7),
                        fontSize: 13,
                        fontFamily: 'Medium',
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        backgroundColor: _lighten(app_colors.secondary, .12),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side:
                              BorderSide(color: Colors.black.withOpacity(0.25)),
                        ),
                      ),
                      onPressed: available ? onEnterRP : null,
                      child: Text(
                        rpNumber.isEmpty
                            ? 'No Aircraft RP Number'
                            : 'Change RP Number',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: 'Medium', fontSize: 12, height: 1.1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Local helpers (copy of lighten/darken used elsewhere)
Color _lighten(Color color, [double amount = .1]) {
  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
  return hslLight.toColor();
}

Color _darken(Color color, [double amount = .1]) {
  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return hslDark.toColor();
}
