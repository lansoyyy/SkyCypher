import 'package:flutter/material.dart';
import 'package:skycypher/utils/colors.dart' as app_colors;

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
  void dispose() {
    _rp152Controller.dispose();
    _rp150Controller.dispose();
    super.dispose();
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
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          AircraftStatusCard(
                            title: 'Cessna 152',
                            aircraftImageAsset: 'assets/images/Cessna 152.png',
                            rpController: _rp152Controller,
                            statusValue: _status152,
                            onStatusChanged: (v) =>
                                setState(() => _status152 = v),
                            statusOptions: _statusOptions,
                            availableNote: null,
                          ),
                          const SizedBox(height: 16),
                          AircraftStatusCard(
                            title: 'Cessna 150 (NOT AVAILABLE)',
                            aircraftImageAsset: 'assets/images/Cessna 150.png',
                            rpController: _rp150Controller,
                            statusValue: _status150,
                            onStatusChanged: (v) =>
                                setState(() => _status150 = v),
                            statusOptions: _statusOptions,
                            availableNote: 'Currently not available',
                          ),
                        ],
                      ),
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
}

class AircraftStatusCard extends StatelessWidget {
  final String title;
  final String aircraftImageAsset;
  final TextEditingController rpController;
  final String? statusValue;
  final void Function(String?) onStatusChanged;
  final List<String> statusOptions;
  final String? availableNote;

  const AircraftStatusCard({
    super.key,
    required this.title,
    required this.aircraftImageAsset,
    required this.rpController,
    required this.statusValue,
    required this.onStatusChanged,
    required this.statusOptions,
    this.availableNote,
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
