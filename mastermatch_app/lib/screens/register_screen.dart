import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/google_sandbox_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final serverUrl = prefs.getString('server_url') ?? 'https://mastermatch.onrender.com';
      final api = ApiService(baseUrl: serverUrl);

      final token = await api.register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Save token and username locally
      await prefs.setString('auth_token', token);
      await prefs.setString('username', _usernameController.text.trim());

      if (mounted) {
        // Return true to indicate successful registration
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.ink, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: const Icon(Icons.arrow_back, size: 18, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'mastermatch.',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Register Card Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      decoration: AppTheme.cardDecoration.copyWith(
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.ink,
                            offset: Offset(5, 5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Decorative Top Bar (Pink Accent)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: 12,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: AppColors.pink,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(22),
                                  topRight: Radius.circular(22),
                                ),
                                border: Border(
                                  bottom: BorderSide(color: AppColors.ink, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create account',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.ink,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  if (_errorMessage != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.pinkSoft,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.pink, width: 1.5),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: GoogleFonts.dmSans(
                                                color: AppColors.ink,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                  // Username
                                  _buildLabel('USERNAME'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: const InputDecoration(
                                      hintText: 'Choose a username',
                                    ),
                                    style: GoogleFonts.dmSans(fontSize: 15),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Username is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                  // Email
                                  _buildLabel('EMAIL (OPTIONAL)'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      hintText: 'you@example.com',
                                    ),
                                    style: GoogleFonts.dmSans(fontSize: 15),
                                  ),
                                  const SizedBox(height: 18),
                                  // Password
                                  _buildLabel('PASSWORD'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Choose a password',
                                    ),
                                    style: GoogleFonts.dmSans(fontSize: 15),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return 'Password is required';
                                      }
                                      if (val.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                  // Confirm Password
                                  _buildLabel('CONFIRM PASSWORD'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Re-enter password',
                                    ),
                                    style: GoogleFonts.dmSans(fontSize: 15),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return 'Password confirmation is required';
                                      }
                                      if (val != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 28),
                                  // Sign Up Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: Container(
                                      decoration: AppTheme.pillButtonDecoration(
                                        shadowColor: AppColors.mint,
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _isLoading ? null : _register,
                                          borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            child: Center(
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2.5,
                                                        color: AppColors.white,
                                                      ),
                                                    )
                                                  : Text(
                                                      'Sign Up →',
                                                      style: GoogleFonts.dmSans(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w500,
                                                        color: AppColors.white,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  // OR Divider
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Divider(color: AppColors.border, thickness: 1.5),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          'OR',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ),
                                      const Expanded(
                                        child: Divider(color: AppColors.border, thickness: 1.5),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  // Google Sign-Up Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: Container(
                                      decoration: AppTheme.pillButtonDecoration(
                                        backgroundColor: AppColors.white,
                                        shadowColor: AppColors.yellow,
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () async {
                                            final success = await showDialog<bool>(
                                              context: context,
                                              builder: (_) => const GoogleSandboxDialog(),
                                            );
                                            if (success == true && mounted) {
                                              Navigator.pop(context, true);
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 20,
                                                  height: 20,
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.ink,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    'G',
                                                    style: GoogleFonts.dmSans(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w900,
                                                      color: AppColors.white,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Sign Up with Google',
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.ink,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Already have an account? ",
                                          style: GoogleFonts.dmSans(
                                            color: AppColors.muted,
                                            fontSize: 14,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pop(context); // Go back to login screen
                                          },
                                          child: Text(
                                            'Log in',
                                            style: GoogleFonts.dmSans(
                                              color: AppColors.ink,
                                              fontWeight: FontWeight.w600,
                                              decoration: TextDecoration.underline,
                                              fontSize: 14,
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
                        ],
                      ),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
        color: AppColors.muted,
      ),
    );
  }
}
