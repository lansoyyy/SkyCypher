import 'package:flutter/material.dart';
import 'package:skycypher/utils/colors.dart' as app_colors;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skycypher/models/aircraft.dart';
import 'package:skycypher/services/aircraft_service.dart';

class AircraftStatusScreen extends StatefulWidget {
  const AircraftStatusScreen({super.key});

  @override
  State<AircraftStatusScreen> createState() => _AircraftStatusScreenState();
}

class _AircraftStatusScreenState extends State<AircraftStatusScreen> {
  final _rp152Controller = TextEditingController();
  final _rp150Controller = TextEditingController();

  String? _status152;
  String? _status150;

  final List<String> _statusOptions = const [
    'Available',
    'Under Maintenance',
    'Requires Inspection',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize default aircraft data
    _initializeAircraftData();
  }

  @override
  void dispose() {
    _rp152Controller.dispose();
    _rp150Controller.dispose();
    super.dispose();
  }

  // Initialize aircraft data
  void _initializeAircraftData() async {
    try {
      await AircraftService.initializeDefaultAircraft();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing aircraft data: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              // Background gradient (within padded area)
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
              // Watermark logo
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: 0.12,
                      child: Image.asset('assets/images/logo.png',
                          width: 440, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CircleButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Aircraft Status',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontFamily: 'Bold',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Update aircraft RP and status.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontFamily: 'Medium',
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: AircraftService.getAircraftStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Error: ${snapshot.error}'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _initializeAircraftData,
                                  child: const Text('Retry Initialization'),
                                ),
                              ],
                            ),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasData) {
                          // Create a map of aircraft data for easy access
                          final aircraftMap = <String, Aircraft>{};
                          for (var doc in snapshot.data!.docs) {
                            try {
                              final aircraft = Aircraft.fromDocument(
                                  doc.data() as Map<String, dynamic>, doc.id);
                              aircraftMap[doc.id] = aircraft;
                            } catch (e) {
                              // Handle any parsing errors
                              debugPrint('Error parsing aircraft data: $e');
                            }
                          }

                          // Get specific aircraft
                          final cessna152 = aircraftMap['cessna_152'];
                          final cessna150 = aircraftMap['cessna_150'];

                          // Update controllers and status values
                          if (cessna152 != null) {
                            _rp152Controller.text = cessna152.rpNumber ?? '';
                            _status152 = cessna152.status;
                          } else {
                            // Reset if no data
                            _rp152Controller.text = '';
                            _status152 = null;
                          }

                          if (cessna150 != null) {
                            _rp150Controller.text = cessna150.rpNumber ?? '';
                            _status150 = cessna150.status;
                          } else {
                            // Reset if no data
                            _rp150Controller.text = '';
                            _status150 = null;
                          }

                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                AircraftStatusCard(
                                  title: cessna152?.name ?? 'Cessna 152',
                                  aircraftImageAsset:
                                      'assets/images/Cessna 152.png',
                                  rpController: _rp152Controller,
                                  statusValue: _status152,
                                  onStatusChanged: (v) => _updateAircraftStatus(
                                      'cessna_152', v, _rp152Controller.text),
                                  onRpChanged: (rp) => _updateAircraftRp(
                                      'cessna_152',
                                      _status152 ?? 'Available',
                                      rp ?? ''),
                                  statusOptions: _statusOptions,
                                  availableNote: cessna152?.note,
                                ),
                                const SizedBox(height: 16),
                                AircraftStatusCard(
                                  title: cessna150?.name ?? 'Cessna 150',
                                  aircraftImageAsset:
                                      'assets/images/Cessna 150.png',
                                  rpController: _rp150Controller,
                                  statusValue: _status150,
                                  onStatusChanged: (v) => _updateAircraftStatus(
                                      'cessna_150', v, _rp150Controller.text),
                                  onRpChanged: (rp) => _updateAircraftRp(
                                      'cessna_150',
                                      _status150 ?? 'Available',
                                      rp ?? ''),
                                  statusOptions: _statusOptions,
                                  availableNote: cessna150?.note,
                                ),
                              ],
                            ),
                          );
                        } else {
                          return const Center(
                            child: Text('No aircraft data found.'),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Update aircraft status in Firebase
  void _updateAircraftStatus(
      String aircraftId, String? status, String rpNumber) async {
    try {
      if (status != null) {
        final aircraft = Aircraft(
          id: aircraftId,
          name: aircraftId == 'cessna_152' ? 'Cessna 152' : 'Cessna 150',
          rpNumber: rpNumber,
          status: status,
          isAvailable: status == 'Available',
          note: aircraftId == 'cessna_150' ? 'Currently not available' : null,
          updatedAt: DateTime.now(),
        );

        await AircraftService.updateAircraft(aircraft);

        setState(() {
          if (aircraftId == 'cessna_152') {
            _status152 = status;
          } else {
            _status150 = status;
          }
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Aircraft status updated successfully.'),
              backgroundColor: app_colors.secondary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating aircraft status: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Update aircraft RP number in Firebase
  void _updateAircraftRp(
      String aircraftId, String status, String rpNumber) async {
    try {
      final aircraft = Aircraft(
        id: aircraftId,
        name: aircraftId == 'cessna_152' ? 'Cessna 152' : 'Cessna 150',
        rpNumber: rpNumber,
        status: status,
        isAvailable: status == 'Available',
        note: aircraftId == 'cessna_150' ? 'Currently not available' : null,
        updatedAt: DateTime.now(),
      );

      await AircraftService.updateAircraft(aircraft);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aircraft RP number updated successfully.'),
            backgroundColor: app_colors.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating aircraft RP number: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class AircraftStatusCard extends StatelessWidget {
  final String title;
  final String aircraftImageAsset;
  final TextEditingController rpController;
  final String? statusValue;
  final void Function(String?)? onStatusChanged;
  final List<String> statusOptions;
  final String? availableNote;
  final void Function(String)? onRpChanged;

  const AircraftStatusCard({
    super.key,
    required this.title,
    required this.aircraftImageAsset,
    required this.rpController,
    required this.statusValue,
    required this.onStatusChanged,
    required this.statusOptions,
    this.availableNote,
    this.onRpChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Bold',
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: availableNote == null
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        availableNote == null
                            ? Icons.check_circle
                            : Icons.error_outline,
                        size: 14,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        availableNote == null ? 'Available' : 'Not Available',
                        style: const TextStyle(
                          fontFamily: 'Bold',
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        aircraftImageAsset,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: rpController,
                        decoration: InputDecoration(
                          hintText: 'Enter Aircraft RP Number',
                          prefixIcon:
                              const Icon(Icons.tag, color: Colors.black87),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.black.withOpacity(0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: app_colors.secondary, width: 1.5),
                          ),
                        ),
                        style: const TextStyle(fontFamily: 'Regular'),
                        onChanged: onRpChanged,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: statusValue,
                        decoration: InputDecoration(
                          hintText: 'Select Status',
                          prefixIcon: const Icon(Icons.check_circle_outline,
                              color: Colors.black87),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.black.withOpacity(0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: app_colors.secondary, width: 1.5),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_drop_down),
                        items: [
                          for (final opt in statusOptions)
                            DropdownMenuItem(
                              value: opt,
                              child: Text(
                                opt,
                                style: const TextStyle(
                                    fontFamily: 'Bold', fontSize: 12),
                              ),
                            )
                        ],
                        onChanged: onStatusChanged,
                      ),
                      if (availableNote != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          availableNote!,
                          style: TextStyle(
                            fontFamily: 'Regular',
                            color: Colors.black.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
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
          border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
        ),
        child: Icon(icon, color: Colors.black, size: 28),
      ),
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
