import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class GoogleSandboxDialog extends StatefulWidget {
  const GoogleSandboxDialog({super.key});

  @override
  State<GoogleSandboxDialog> createState() => _GoogleSandboxDialogState();
}

class _GoogleSandboxDialogState extends State<GoogleSandboxDialog> {
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final serverUrl = prefs.getString('server_url') ?? 'http://192.168.1.4:5001';
      final api = ApiService(baseUrl: serverUrl);

      final username = _usernameController.text.trim();
      final mockToken = 'sandbox-google-$username';

      final token = await api.loginWithGoogle(mockToken);

      // Save token and username locally (simulated Google authentication)
      await prefs.setString('auth_token', token);
      await prefs.setString('username', username);

      if (mounted) {
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              decoration: AppTheme.cardDecoration.copyWith(
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.ink,
                    offset: Offset(6, 6),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.yellow,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppBorderRadius.lg - 1.5),
                        topRight: Radius.circular(AppBorderRadius.lg - 1.5),
                      ),
                      border: Border(
                        bottom: BorderSide(color: AppColors.ink, width: 1.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.g_mobiledata_rounded, size: 36, color: AppColors.ink),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Google Sign-In',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.ink, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sandbox Mode Enabled',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Enter your preferred username to authenticate with the local server over Google Sandbox OAuth simulation.',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.muted,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
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
                                  const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.dmSans(
                                        color: AppColors.ink,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            'GOOGLE USERNAME / EMAIL',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _usernameController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'e.g. asli',
                              suffixText: '@gmail.com',
                              suffixStyle: GoogleFonts.dmSans(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: GoogleFonts.dmSans(fontSize: 14),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Username is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.dmSans(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  decoration: AppTheme.pillButtonDecoration(
                                    shadowColor: AppColors.mint,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _isLoading ? null : _signIn,
                                      borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        child: Center(
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: AppColors.white,
                                                  ),
                                                )
                                              : Text(
                                                  'Sign In',
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
    );
  }
}
