import 'package:flutter/material.dart';
import 'package:skycypher/utils/colors.dart' as app_colors;
import 'package:skycypher/models/maintenance_log.dart';

class MaintenanceLogDetailScreen extends StatelessWidget {
  final MaintenanceLog maintenanceLog;

  const MaintenanceLogDetailScreen({super.key, required this.maintenanceLog});

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
                  // Header with back
                  Row(
                    children: [
                      _CircleButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Logbook Entry #${maintenanceLog.id.substring(0, 8)}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontFamily: 'Bold',
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Aircraft Maintenance Log - Detailed Record',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontFamily: 'Medium',
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Main details card - Logbook style
                  Expanded(
                    child: Card(
                      elevation: 6,
                      shadowColor: Colors.black.withOpacity(0.25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.black.withOpacity(0.2)),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Logbook header
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: app_colors.primary.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'AIRCRAFT MAINTENANCE LOG',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Aircraft Information Section
                              _LogbookSection(
                                title: 'AIRCRAFT INFORMATION',
                                children: [
                                  _LogbookField(
                                    label: 'Aircraft Model',
                                    value: maintenanceLog.aircraftModel,
                                  ),
                                  _LogbookField(
                                    label: 'Registration Number',
                                    value: maintenanceLog.aircraftRegNumber,
                                  ),
                                  _LogbookField(
                                    label: 'Aircraft ID',
                                    value: maintenanceLog.aircraft,
                                  ),
                                  _LogbookField(
                                    label: 'Parts/Components',
                                    value: maintenanceLog.aircraftParts,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Maintenance Details Section
                              _LogbookSection(
                                title: 'MAINTENANCE DETAILS',
                                children: [
                                  _LogbookField(
                                    label: 'Maintenance Task',
                                    value: maintenanceLog.maintenanceTask,
                                  ),
                                  _LogbookField(
                                    label: 'Date & Time Started',
                                    value: maintenanceLog.dateTimeStarted,
                                  ),
                                  _LogbookField(
                                    label: 'Date & Time Ended',
                                    value: maintenanceLog.dateTimeEnded,
                                  ),
                                  _LogbookField(
                                    label: 'Location',
                                    value: maintenanceLog.location,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Work Performed Section
                              _LogbookSection(
                                title: 'WORK PERFORMED',
                                children: [
                                  _LogbookField(
                                    label: 'Component',
                                    value: maintenanceLog.component,
                                  ),
                                  _LogbookLongField(
                                    label: 'Detailed Inspection',
                                    value: maintenanceLog.detailedInspection,
                                  ),
                                  _LogbookLongField(
                                    label: 'Reported Issue',
                                    value: maintenanceLog.reportedIssue,
                                  ),
                                  _LogbookLongField(
                                    label: 'Action Taken',
                                    value: maintenanceLog.actionTaken,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Findings Section
                              _LogbookSection(
                                title: 'FINDINGS AND REMARKS',
                                children: [
                                  _LogbookLongField(
                                    label: 'Discrepancy',
                                    value: maintenanceLog.discrepancy,
                                  ),
                                  _LogbookLongField(
                                    label: 'Corrective Action',
                                    value: maintenanceLog.correctiveAction,
                                  ),
                                  _LogbookLongField(
                                    label: 'Component Remarks',
                                    value: maintenanceLog.componentRemarks,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Inspector Section
                              _LogbookSection(
                                title: 'INSPECTOR CERTIFICATION',
                                children: [
                                  _LogbookField(
                                    label: 'Inspected by',
                                    value: maintenanceLog.inspectedByFullName,
                                  ),
                                  _LogbookField(
                                    label: 'Date',
                                    value: maintenanceLog.date,
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Signature: _____________________    Date: ____/____/____',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Certificate Number: _____________________',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Photo section
                              if (maintenanceLog.imageUrl != null &&
                                  maintenanceLog.imageUrl!.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Supporting Documentation:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        maintenanceLog.imageUrl!,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            height: 200,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                color: Colors.grey,
                                                size: 40,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              else
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/images/Cessna 152.png',
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                            ],
                          ),
                        ),
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

class _LogbookSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _LogbookSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: app_colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: app_colors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _LogbookField extends StatelessWidget {
  final String label;
  final String value;

  const _LogbookField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogbookLongField extends StatelessWidget {
  final String label;
  final String value;

  const _LogbookLongField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
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
