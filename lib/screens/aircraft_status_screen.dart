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
  final _newRpController = TextEditingController();
  String? _selectedAircraftId;
  String? _selectedStatus;
  String? _editingRpNumber;

  final List<String> _statusOptions = const [
    'Available',
    'Under\nMaintenance',
    'Requires\nInspection',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize default aircraft data
    _initializeAircraftData();
  }

  @override
  void dispose() {
    _newRpController.dispose();
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
                    'Manage aircraft RP numbers and their statuses.',
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

                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildAircraftSection(cessna152, 'Cessna 152'),
                                const SizedBox(height: 24),
                                _buildAircraftSection(cessna150, 'Cessna 150'),
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

  Widget _buildAircraftSection(Aircraft? aircraft, String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aircraft header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: app_colors.secondary.withOpacity(0.9),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Bold',
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                if (aircraft != null && aircraft.rpEntries.isNotEmpty) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${aircraft.rpEntries.length} RP Entries',
                      style: const TextStyle(
                        fontFamily: 'Bold',
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Add new RP section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New RP Number',
                  style: TextStyle(
                    fontFamily: 'Bold',
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newRpController,
                        decoration: InputDecoration(
                          hintText: 'Enter RP Number (e.g., RP-C152-001)',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    SizedBox(
                      width: 120,
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        hint: const Text('Status'),
                        items: _statusOptions.map((String status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedStatus = newValue;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 5),
                    ElevatedButton(
                      onPressed: () {
                        if (_newRpController.text.isNotEmpty &&
                            _selectedStatus != null &&
                            aircraft != null) {
                          _addRpEntry(aircraft.id, title);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: app_colors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // RP Entries list
          if (aircraft != null && aircraft.rpEntries.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...aircraft.rpEntries
                .map((rpEntry) => _buildRpEntryTile(aircraft.id, rpEntry))
                .toList(),
          ] else ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                'No RP numbers added yet',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildRpEntryTile(String aircraftId, RpEntry rpEntry) {
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          rpEntry.rpNumber,
          style: const TextStyle(
            fontFamily: 'Bold',
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Added: ${_formatDate(rpEntry.addedAt)}',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: getStatusColor(rpEntry.status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: getStatusColor(rpEntry.status).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    getStatusIcon(rpEntry.status),
                    size: 16,
                    color: getStatusColor(rpEntry.status),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rpEntry.status,
                    style: TextStyle(
                      color: getStatusColor(rpEntry.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String result) {
                if (result == 'edit') {
                  _editRpEntry(aircraftId, rpEntry);
                } else if (result == 'delete') {
                  _deleteRpEntry(aircraftId, rpEntry.rpNumber);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Add a new RP entry
  void _addRpEntry(String aircraftId, String title) async {
    try {
      final rpEntry = RpEntry(
        name: title,
        rpNumber: _newRpController.text.trim(),
        status: _selectedStatus!,
        addedAt: DateTime.now(),
      );

      await AircraftService.addRpEntry(aircraftId, rpEntry);

      // Clear the form
      setState(() {
        _newRpController.clear();
        _selectedStatus = null;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('RP number added successfully.'),
            backgroundColor: app_colors.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding RP number: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Edit an existing RP entry
  void _editRpEntry(String aircraftId, RpEntry rpEntry) {
    // Set the form fields with the current values
    _newRpController.text = rpEntry.rpNumber;
    _selectedStatus = rpEntry.status;
    _editingRpNumber = rpEntry.rpNumber;
    _selectedAircraftId = aircraftId;

    // Show a snackbar with instructions
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Editing mode: Update the fields and click Add to save changes'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Delete an RP entry
  void _deleteRpEntry(String aircraftId, String rpNumber) async {
    try {
      await AircraftService.deleteRpEntry(aircraftId, rpNumber);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('RP number deleted successfully.'),
            backgroundColor: app_colors.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting RP number: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
