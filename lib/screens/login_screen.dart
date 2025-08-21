import 'package:flutter/material.dart';
import 'package:skycypher/screens/welcome_splash_screen.dart';
import 'package:skycypher/utils/colors.dart' as app_colors;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  String? _userType;
  bool _obscure = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: app_colors.primary,
      body: SafeArea(
        child: Stack(
          children: [
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
            Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo
                        Align(
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Headline
                        Text(
                          'Ready to log your\nnext flight check?',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontFamily: 'Bold',
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Subheading
                        Text(
                          'Please enter your details:',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.85),
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Medium',
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Type of user label
                        Text(
                          'Type of user:',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontFamily: 'Medium',
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Dropdown
                        DropdownButtonFormField<String>(
                          value: _userType,
                          dropdownColor: app_colors.primary,
                          iconEnabledColor: Colors.white,
                          style: const TextStyle(
                              color: Colors.white, fontFamily: 'Regular'),
                          items: const [
                            DropdownMenuItem(
                                value: 'Pilot', child: Text('Pilot')),
                            DropdownMenuItem(
                                value: 'Mechanic', child: Text('Mechanic')),
                          ],
                          onChanged: (v) => setState(() => _userType = v),
                          validator: (v) =>
                              v == null ? 'Please select a user type' : null,
                          decoration: _fieldDecoration(
                            hint: 'Select',
                            prefixIcon:
                                const Icon(Icons.person, color: Colors.white),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Username label
                        Text(
                          'Username:',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontFamily: 'Medium',
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Username field
                        TextFormField(
                          controller: _usernameCtrl,
                          style: const TextStyle(
                              color: Colors.white, fontFamily: 'Regular'),
                          decoration: _fieldDecoration(
                            hint: null,
                            prefixIcon: const Icon(Icons.account_circle,
                                color: Colors.white),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Enter username'
                              : null,
                        ),

                        const SizedBox(height: 16),

                        // Password label
                        Text(
                          'Password:',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontFamily: 'Medium',
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Password field
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          style: const TextStyle(
                              color: Colors.white, fontFamily: 'Regular'),
                          decoration: _fieldDecoration(
                            hint: null,
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: Colors.white),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Enter password'
                              : null,
                        ),

                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (v) =>
                                  setState(() => _rememberMe = v ?? false),
                              activeColor: app_colors.secondary,
                              checkColor: Colors.black,
                              side: BorderSide(
                                  color: Colors.white.withOpacity(0.7)),
                            ),
                            const Text(
                              'Remember me',
                              style: TextStyle(
                                  color: Colors.white, fontFamily: 'Medium'),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Forgot password not implemented.'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: app_colors.secondary,
                                  ),
                                );
                              },
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(fontFamily: 'Bold'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Login button
                        Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 180,
                            child: ElevatedButton(
                              onPressed: _onLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: app_colors.secondary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: const StadiumBorder(),
                                textStyle: const TextStyle(
                                  fontFamily: 'Bold',
                                  fontSize: 18,
                                ),
                              ),
                              child: const Text('Log in'),
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Footer
                        Text(
                          'SkyCyphers Inc.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontFamily: 'Regular',
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
    );
  }

  InputDecoration _fieldDecoration(
      {String? hint, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70, fontFamily: 'Regular'),
      filled: true,
      fillColor: app_colors.secondary.withOpacity(0.6),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _onLogin() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // Placeholder: proceed to home after validation
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomeSplashScreen()),
    );
  }
}
