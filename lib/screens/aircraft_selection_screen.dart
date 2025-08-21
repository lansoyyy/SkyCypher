import 'package:flutter/material.dart';
import 'package:skycypher/utils/colors.dart' as app_colors;

class AircraftSelectionScreen extends StatefulWidget {
  const AircraftSelectionScreen({super.key});

  @override
  State<AircraftSelectionScreen> createState() =>
      _AircraftSelectionScreenState();
}

class _AircraftSelectionScreenState extends State<AircraftSelectionScreen> {
  final TextEditingController _rpController = TextEditingController();

  final List<String> _models = const ['Cessna 152', 'Cessna 150'];

  String _selectedModel = 'Cessna 152';
  String? _rpNumber;

  bool get _isSelectedAvailable => _selectedModel != 'Cessna 150';

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

                  const SizedBox(height: 20),

                  // Dropdown like selector
                  _SelectionBar(
                    value: _selectedModel,
                    onChanged: (v) => setState(() => _selectedModel = v),
                    options: _models,
                  ),

                  const SizedBox(height: 12),

                  // Model cards
                  _AircraftCard(
                    title: 'Cessna 152',
                    assetPath: 'assets/images/Cessna 152.png',
                    available: true,
                    onEnterRP: () => _promptRP(context, 'Cessna 152'),
                  ),
                  const SizedBox(height: 10),
                  _AircraftCard(
                    title: 'Cessna 150 (NOT AVAILABLE)',
                    assetPath: 'assets/images/Cessna 150.png',
                    available: false,
                    onEnterRP: () => _promptRP(context, 'Cessna 150'),
                  ),

                  const Spacer(),

                  // Start button
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
                          side:
                              BorderSide(color: Colors.white.withOpacity(0.18)),
                        ),
                      ),
                      onPressed: (_isSelectedAvailable &&
                              (_rpNumber?.isNotEmpty ?? false))
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Starting inspection: $_selectedModel | RP: $_rpNumber'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: app_colors.secondary,
                                ),
                              );
                            }
                          : null,
                      child: const Text(
                        'START INSPECTION',
                        style: TextStyle(
                          fontFamily: 'Bold',
                          fontSize: 16,
                          letterSpacing: 0.8,
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

  Future<void> _promptRP(BuildContext context, String model) async {
    _rpController.text = _rpNumber ?? '';
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
            decoration: const InputDecoration(
              hintText: 'e.g. RP-C152',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedModel = model;
                  _rpNumber = _rpController.text.trim();
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
}

class _SelectionBar extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _SelectionBar({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _lighten(app_colors.secondary, .06),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
      ),
      child: Row(
        children: [
          const Text(
            'Aircraft Selection',
            style: TextStyle(
                color: Colors.black, fontFamily: 'Bold', fontSize: 18),
          ),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              dropdownColor: _lighten(app_colors.secondary, .12),
              style:
                  const TextStyle(color: Colors.black, fontFamily: 'Regular'),
              items: options
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(
                        e,
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontFamily: 'Bold'),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AircraftCard extends StatelessWidget {
  final String title;
  final String assetPath;
  final bool available;
  final VoidCallback onEnterRP;

  const _AircraftCard({
    required this.title,
    required this.assetPath,
    required this.available,
    required this.onEnterRP,
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
          color: Colors.white,
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
            // Title + RP button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Bold',
                      fontSize: 18,
                    ),
                  ),
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
                      child: const Text(
                        '"ENTER AIRCRAFT\nRP NUMBER"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
