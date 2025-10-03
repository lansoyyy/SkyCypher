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
  // Track loading state
  bool _isLoading = true;
  // Store aircraft data
  List<Aircraft> _aircraftList = [];
  Aircraft? _selectedAircraft;
  String? _selectedRpNumber;
  String? _selectedRpStatus;

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
        final aircraft =
            Aircraft.fromDocument(doc.data() as Map<String, dynamic>, doc.id);
        aircraftList.add(aircraft);
      }

      setState(() {
        _aircraftList = aircraftList;
      });
    } catch (e) {
      print('Error fetching aircraft: $e');
    }
  }

  // Select an aircraft
  void _selectAircraft(Aircraft aircraft) {
    setState(() {
      _selectedAircraft = aircraft;
      // Reset RP selection when changing aircraft
      _selectedRpNumber = null;
      _selectedRpStatus = null;
    });
  }

  // Select an RP number

  @override
  void dispose() {
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
                      'Select an aircraft and RP number to begin.',
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

  int currentIndex = 0;
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
    final bool canStartInspection =
        _selectedRpNumber != null && _selectedRpStatus == 'Available';

    return Column(
      children: [
        // Model cards
        Expanded(
          child: ListView.builder(
            itemCount: _aircraftList.length,
            itemBuilder: (context, index) {
              final aircraft = _aircraftList[index];
              final isSelected = _selectedAircraft != null &&
                  _selectedAircraft!.id == aircraft.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected ? app_colors.secondary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    _AircraftCard(
                      title: aircraft.name,
                      assetPath: 'assets/images/${aircraft.name}.png',
                      available: aircraft.rpEntries.isEmpty ? false : true,
                      status: aircraft.rpEntries.isEmpty
                          ? 'Unavailable'
                          : aircraft.rpEntries.last.status,
                      isSelected: isSelected,
                      rpEntries: aircraft.rpEntries,
                      selectedRpNumber: _selectedRpNumber,
                      onRpSelected: (String rpNumber, String status) {
                        setState(() {
                          currentIndex = index;
                          _selectedRpNumber = rpNumber;
                          _selectedRpStatus = status;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Status indicator for selected RP
        if (_selectedRpNumber != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Text(
                  'Selected RP:',
                  style: TextStyle(
                    fontFamily: 'Bold',
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedRpNumber!,
                  style: const TextStyle(
                    fontFamily: 'Bold',
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                _buildStatusBadge(_selectedRpStatus ?? 'Unknown'),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

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
                    print(_aircraftList[currentIndex].name);
                    _showInspectionWarningDialog(
                        context, _aircraftList[currentIndex].name);
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

  Widget _buildStatusBadge(String status) {
    Color getStatusColor(String status) {
      switch (status) {
        case 'Available':
          return Colors.green;
        case 'Under Maintenance':
          return Colors.orange;
        case 'Requires Inspection':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    IconData getStatusIcon(String status) {
      switch (status) {
        case 'Available':
          return Icons.check_circle;
        case 'Under Maintenance':
          return Icons.build;
        case 'Requires Inspection':
          return Icons.warning;
        default:
          return Icons.help;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: getStatusColor(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: getStatusColor(status).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getStatusIcon(status),
            size: 16,
            color: getStatusColor(status),
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: getStatusColor(status),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showInspectionWarningDialog(
      BuildContext context, String title) async {
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
                      aircraftModel: title,
                      rpNumber: _selectedRpNumber!,
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
  final bool isSelected;
  final List<RpEntry> rpEntries;
  final String? selectedRpNumber;
  final Function(String, String) onRpSelected;

  const _AircraftCard({
    required this.title,
    required this.assetPath,
    required this.available,
    required this.status,
    required this.isSelected,
    required this.rpEntries,
    required this.selectedRpNumber,
    required this.onRpSelected,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                assetPath,
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Available RP Numbers:',
              style: TextStyle(
                fontFamily: 'Bold',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            if (rpEntries.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No RP numbers available for this aircraft',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: rpEntries.length,
                  itemBuilder: (context, index) {
                    final rpEntry = rpEntries[index];
                    final isRpSelected = selectedRpNumber == rpEntry.rpNumber;

                    return GestureDetector(
                      onTap: () =>
                          onRpSelected(rpEntry.rpNumber, rpEntry.status),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isRpSelected
                              ? app_colors.secondary
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isRpSelected
                                ? app_colors.secondary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'RP: ${rpEntry.rpNumber}',
                              style: TextStyle(
                                fontFamily: 'Bold',
                                color:
                                    isRpSelected ? Colors.white : Colors.black,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            _buildRpStatusIndicator(
                                rpEntry.status, isRpSelected),
                            const SizedBox(width: 2),
                            Text(
                              rpEntry.status,
                              style: TextStyle(
                                fontFamily: 'Medium',
                                color:
                                    isRpSelected ? Colors.white : Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRpStatusIndicator(String status, bool isSelected) {
    Color getStatusColor(String status, bool isSelected) {
      switch (status) {
        case 'Available':
          return isSelected ? Colors.white : Colors.green;
        case 'Under Maintenance':
          return isSelected ? Colors.white : Colors.orange;
        case 'Requires Inspection':
          return isSelected ? Colors.white : Colors.red;
        default:
          return isSelected ? Colors.white : Colors.grey;
      }
    }

    IconData getStatusIcon(String status) {
      switch (status) {
        case 'Available':
          return Icons.check;
        case 'Under Maintenance':
          return Icons.build;
        case 'Requires Inspection':
          return Icons.warning;
        default:
          return Icons.help;
      }
    }

    return Icon(
      getStatusIcon(status),
      size: 14,
      color: getStatusColor(status, isSelected),
    );
  }
}

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
