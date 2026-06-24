import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/google_sandbox_dialog.dart';
import 'register_screen.dart';
import 'settings_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool showBypass;

  const LoginScreen({super.key, this.showBypass = true});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final serverUrl = prefs.getString('server_url') ?? 'http://192.168.1.4:5001';
      final api = ApiService(baseUrl: serverUrl);

      final token = await api.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      // Save token and username locally
      await prefs.setString('auth_token', token);
      await prefs.setString('username', _usernameController.text.trim());

      if (mounted) {
        // Return true to indicate successful login
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
                  if (!widget.showBypass) ...[
                    GestureDetector(
                      onTap: () => Navigator.pop(context, false),
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
                  ],
                  Text(
                    'mastermatch.',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: const Icon(Icons.settings_outlined, size: 18, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
            // Login Card Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
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
                          // Decorative Top Bar
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: 12,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: AppColors.sky,
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
                                    'Welcome back!',
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
                                      hintText: 'Enter your username',
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
                                  // Password
                                  _buildLabel('PASSWORD'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      hintText: '••••••••',
                                    ),
                                    style: GoogleFonts.dmSans(fontSize: 15),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return 'Password is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 28),
                                  // Log In Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: Container(
                                      decoration: AppTheme.pillButtonDecoration(
                                        shadowColor: AppColors.mint,
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _isLoading ? null : _login,
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
                                                      'Log In →',
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
                                  // Google Sign-In Button
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
                                            final navigator = Navigator.of(context);
                                            final success = await showDialog<bool>(
                                              context: context,
                                              builder: (_) => const GoogleSandboxDialog(),
                                            );
                                            if (success == true && mounted) {
                                              navigator.pop(true);
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
                                                  'Continue with Google',
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
                                          "Don't have an account? ",
                                          style: GoogleFonts.dmSans(
                                            color: AppColors.muted,
                                            fontSize: 14,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () async {
                                            final navigator = Navigator.of(context);
                                            final registered = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const RegisterScreen(),
                                              ),
                                            );
                                            if (registered == true && mounted) {
                                              navigator.pop(true);
                                            }
                                          },
                                          child: Text(
                                            'Sign up',
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
                                  if (widget.showBypass) ...[
                                    const SizedBox(height: 20),
                                    const Divider(color: AppColors.ink, thickness: 1.5),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Container(
                                        decoration: AppTheme.pillButtonDecoration(
                                          shadowColor: AppColors.border,
                                        ).copyWith(
                                          color: AppColors.white,
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.pop(context, false);
                                            },
                                            borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              child: Center(
                                                child: Text(
                                                  'Continue without registering →',
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppColors.ink,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
