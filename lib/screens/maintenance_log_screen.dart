import 'package:flutter/material.dart';
import 'package:skycypher/utils/colors.dart' as app_colors;
import 'package:skycypher/screens/maintenance_log_detail_screen.dart';

class MaintenanceLogScreen extends StatelessWidget {
  const MaintenanceLogScreen({super.key});

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

                  // First info card
                  _InfoCard(
                    rows: const [
                      'Component: Hydraulic Fluid Leak – Left Main Gear',
                      'Date: July 26, 2025',
                      'Location: Hangar 3 – Mactan-Cebu International Airport',
                      'Inspected By: Engr. Tricia Bermil',
                      'Aircraft:  CESSNA 152 (RP - N3978P)',
                    ],
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MaintenanceLogDetailScreen(),
                        ),
                      );
                    },
                  ),

                  const Spacer(),

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
    showDialog(
      context: context,
      builder: (dialogContext) {
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
                        children: const [
                          _LabeledField(
                              label: 'Component', icon: Icons.build_outlined),
                          _LabeledField(
                              label: 'Date', icon: Icons.event_outlined),
                          _LabeledField(
                              label: 'Location', icon: Icons.place_outlined),
                          _LabeledField(
                              label: 'Inspected By',
                              icon: Icons.person_outline),
                          _LabeledField(
                              label: 'Aircraft', icon: Icons.flight_outlined),
                          _LabeledField(
                              label: 'Detailed Inspection',
                              maxLines: 3,
                              icon: Icons.description_outlined),
                          _LabeledField(
                              label: 'Reported Issue',
                              maxLines: 3,
                              icon: Icons.report_problem_outlined),
                          _LabeledField(
                              label: 'Action Taken',
                              maxLines: 3,
                              icon: Icons.task_alt_outlined),
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Attachment picker not implemented.'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: app_colors.secondary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.attach_file_rounded),
                      label: const Text(
                        'Attach Photo (placeholder)',
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
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Maintenance log saved (placeholder).'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: app_colors.secondary,
                            ),
                          );
                        },
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
  const _LabeledField({required this.label, this.maxLines = 1, this.icon});

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
