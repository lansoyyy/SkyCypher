import 'package:flutter/material.dart';
import 'package:skycypher/utils/colors.dart' as app_colors;
import 'package:skycypher/screens/aircraft_selection_screen.dart';
import 'package:skycypher/screens/maintenance_log_screen.dart';
import 'package:skycypher/screens/aircraft_status_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            // Watermark background logo
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: 0.04,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 440,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            // Foreground content
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "YOU'RE CLEARED FOR ACTION,",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontFamily: 'Bold',
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Tap a module to start',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                        fontFamily: 'Medium',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Profile card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          _lighten(app_colors.secondary, .10),
                          _darken(app_colors.secondary, .06),
                        ],
                      ),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.18), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                _lighten(app_colors.secondary, .25),
                                _darken(app_colors.secondary, .15),
                              ],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              color: app_colors.primary,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Engr. Tricia Bermil',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontFamily: 'Bold',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Welcome back',
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.7),
                                  fontSize: 12,
                                  fontFamily: 'Medium',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Section title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      'Modules',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Bold',
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Feature grid (4 cards)
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      _FeatureButton(
                        icon: Icons.mic,
                        label: 'Voice Commands',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AircraftSelectionScreen(),
                            ),
                          );
                        },
                      ),
                      _FeatureButton(
                        icon: Icons.build,
                        label: 'Maintenance Logs',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MaintenanceLogScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _FeatureButton(
                    icon: Icons.flight,
                    label: 'Aircraft Status',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AircraftStatusScreen(),
                        ),
                      );
                    },
                  ),
                  Spacer(),

                  Center(
                    child: Text(
                      'SkyCyphers Inc.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontFamily: 'Regular',
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

class _FeatureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FeatureButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Card(
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _lighten(app_colors.secondary, .08),
                  _darken(app_colors.secondary, .06),
                ],
              ),
              border:
                  Border.all(color: Colors.white.withOpacity(0.18), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Left circular icon badge
                CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.12),
                  radius: 40,
                  child: Icon(icon, size: 48, color: Colors.black87),
                ),
                SizedBox(height: 16),
                // Centered label
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        height: 1.15,
                        fontFamily: 'Bold',
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helpers to lighten/darken colors for subtle gradients
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
