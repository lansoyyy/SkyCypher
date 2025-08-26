import 'package:flutter/material.dart';
import 'package:skycypher/utils/colors.dart' as app_colors;
import 'package:skycypher/screens/maintenance_log_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:skycypher/models/maintenance_log.dart';
import 'package:skycypher/services/maintenance_log_service.dart';

class MaintenanceLogScreen extends StatefulWidget {
  const MaintenanceLogScreen({super.key});

  @override
  State<MaintenanceLogScreen> createState() => _MaintenanceLogScreenState();
}

class _MaintenanceLogScreenState extends State<MaintenanceLogScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      app_colors.primary,
                      Color.lerp(app_colors.primary, app_colors.primary, 0.10)!,
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
                    opacity: 0.15,
                    child: Image.asset('assets/images/logo.png',
                        width: 440, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Row with back and add
                  Row(
                    children: [
                      _CircleButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Maintenance Log',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontFamily: 'Bold',
                          ),
                        ),
                      ),
                      _CircleButton(
                        icon: Icons.add,
                        onTap: () => _showAddLogDialog(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Tap a log to view details or add a new one.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontFamily: 'Medium',
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Maintenance logs list
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: MaintenanceLogService.getMaintenanceLogsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasData &&
                            snapshot.data!.docs.isNotEmpty) {
                          return ListView.builder(
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              DocumentSnapshot document =
                                  snapshot.data!.docs[index];
                              Map<String, dynamic> data =
                                  document.data() as Map<String, dynamic>;

                              // Create MaintenanceLog object from document data
                              final maintenanceLog =
                                  MaintenanceLog.fromDocument(
                                      data, document.id);

                              return _InfoCard(
                                rows: [
                                  'Component: ${data['component'] ?? 'N/A'}',
                                  'Date: ${data['date'] ?? 'N/A'}',
                                  'Location: ${data['location'] ?? 'N/A'}',
                                  'Inspected By: ${data['inspectedBy'] ?? 'N/A'}',
                                  'Aircraft: ${data['aircraft'] ?? 'N/A'}',
                                ],
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          MaintenanceLogDetailScreen(
                                              maintenanceLog: maintenanceLog),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        } else {
                          return const Center(
                            child: Text(
                              'No maintenance logs found.\nTap the + button to add one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Tip: Click the paper plane to see more information.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontFamily: 'Regular',
                        fontSize: 12,
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

  void _showAddLogDialog(BuildContext context) {
    // Controllers for text fields
    final componentController = TextEditingController();
    final locationController = TextEditingController();
    final inspectedByController = TextEditingController();
    final aircraftController = TextEditingController();
    final detailedInspectionController = TextEditingController();
    final reportedIssueController = TextEditingController();
    final actionTakenController = TextEditingController();

    // Date picker
    DateTime? selectedDate;
    final dateFormat = DateFormat('MMMM dd, yyyy');

    // Image picker
    File? selectedImage;

    void _pickImage() async {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // We need to access the setState of the dialog's StatefulBuilder
        // This is a bit tricky, so we'll handle it differently
      }
    }

    void _pickDate() async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      if (picked != null && picked != selectedDate) {
        // We need to access the setState of the dialog's StatefulBuilder
        // This is a bit tricky, so we'll handle it differently
      }
    }

    void _saveLog() async {
      try {
        await MaintenanceLogService.addMaintenanceLog(
          component: componentController.text,
          date: selectedDate != null ? dateFormat.format(selectedDate!) : '',
          location: locationController.text,
          inspectedBy: inspectedByController.text,
          aircraft: aircraftController.text,
          detailedInspection: detailedInspectionController.text,
          reportedIssue: reportedIssueController.text,
          actionTaken: actionTakenController.text,
          image: selectedImage,
        );

        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Maintenance log saved successfully.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: app_colors.secondary,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving maintenance log: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.8,
                  minWidth: 360,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'New Maintenance Log',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontFamily: 'Bold',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _LabeledField(
                                controller: componentController,
                                label: 'Component',
                                icon: Icons.build_outlined,
                              ),
                              // Date field with picker
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date',
                                      style: TextStyle(
                                        color: Colors.black.withOpacity(0.8),
                                        fontSize: 14,
                                        fontFamily: 'Medium',
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      readOnly: true,
                                      controller: TextEditingController(
                                          text: selectedDate != null
                                              ? dateFormat.format(selectedDate!)
                                              : ''),
                                      style: const TextStyle(
                                          fontFamily: 'Regular', fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: 'Select Date',
                                        prefixIcon: const Icon(
                                            Icons.event_outlined,
                                            color: Colors.black87),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.black
                                                  .withOpacity(0.2)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: app_colors.secondary,
                                              width: 1.5),
                                        ),
                                      ),
                                      onTap: () async {
                                        final DateTime? picked =
                                            await showDatePicker(
                                          context: context,
                                          initialDate:
                                              selectedDate ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                        );
                                        if (picked != null &&
                                            picked != selectedDate) {
                                          setState(() {
                                            selectedDate = picked;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              _LabeledField(
                                controller: locationController,
                                label: 'Location',
                                icon: Icons.place_outlined,
                              ),
                              _LabeledField(
                                controller: inspectedByController,
                                label: 'Inspected By',
                                icon: Icons.person_outline,
                              ),
                              _LabeledField(
                                controller: aircraftController,
                                label: 'Aircraft',
                                icon: Icons.flight_outlined,
                              ),
                              _LabeledField(
                                controller: detailedInspectionController,
                                label: 'Detailed Inspection',
                                maxLines: 3,
                                icon: Icons.description_outlined,
                              ),
                              _LabeledField(
                                controller: reportedIssueController,
                                label: 'Reported Issue',
                                maxLines: 3,
                                icon: Icons.report_problem_outlined,
                              ),
                              _LabeledField(
                                controller: actionTakenController,
                                label: 'Action Taken',
                                maxLines: 3,
                                icon: Icons.task_alt_outlined,
                              ),
                              // Image picker
                              if (selectedImage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Selected Image',
                                        style: TextStyle(
                                          color: Colors.black.withOpacity(0.8),
                                          fontSize: 14,
                                          fontFamily: 'Medium',
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        height: 100,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: Colors.black
                                                  .withOpacity(0.2)),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Image.file(
                                            selectedImage!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: app_colors.secondary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery);
                            if (image != null) {
                              setState(() {
                                selectedImage = File(image.path);
                              });
                            }
                          },
                          icon: const Icon(Icons.attach_file_rounded),
                          label: const Text(
                            'Attach Photo',
                            style: TextStyle(fontFamily: 'Bold'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontFamily: 'Bold'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: app_colors.secondary,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _saveLog,
                            child: const Text(
                              'Save',
                              style: TextStyle(fontFamily: 'Bold'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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

class _InfoCard extends StatelessWidget {
  final List<String> rows;
  final VoidCallback? onTap;
  const _InfoCard({required this.rows, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in rows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          line,
                          style: const TextStyle(
                            color: Colors.black,
                            fontFamily: 'Regular',
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Paper plane icon (tap for more)
              InkWell(
                onTap: onTap ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Opening more information...'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: app_colors.secondary,
                        ),
                      );
                    },
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(10),
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
                  child: const Icon(Icons.send_rounded,
                      color: Colors.black, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.2)),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final int maxLines;
  final IconData? icon;
  final TextEditingController? controller;

  const _LabeledField({
    required this.label,
    this.maxLines = 1,
    this.icon,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withOpacity(0.8),
              fontSize: 14,
              fontFamily: 'Medium',
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontFamily: 'Regular', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter $label',
              prefixIcon:
                  icon != null ? Icon(icon, color: Colors.black87) : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.black.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: app_colors.secondary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Local helpers to match app style
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
