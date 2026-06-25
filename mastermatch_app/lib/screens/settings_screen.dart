import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlCtrl = TextEditingController();
  bool _testing = false;
  bool? _testResult; // null = not tested, true = success, false = fail

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _urlCtrl.text = prefs.getString('server_url') ?? 'https://mastermatch.onrender.com';
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final api = ApiService(baseUrl: _urlCtrl.text.trim());
    final ok = await api.testConnection();
    setState(() {
      _testing = false;
      _testResult = ok;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _urlCtrl.text.trim());
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar
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
                    'Settings',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.ink, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.ink,
                          offset: Offset(5, 5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label
                        Text(
                          'BACKEND URL',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // URL input
                        TextFormField(
                          controller: _urlCtrl,
                          decoration: const InputDecoration(
                            hintText: 'https://mastermatch.onrender.com',
                          ),
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Help text
                        Text(
                          'Enter your Mac\'s IP address and port, e.g. https://mastermatch.onrender.com',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.muted,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Test connection feedback
                        if (_testResult != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _testResult! ? AppColors.mintSoft : AppColors.pinkSoft,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _testResult! ? AppColors.mint : AppColors.pink,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _testResult! ? Icons.check_circle : Icons.cancel,
                                  size: 18,
                                  color: _testResult!
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFD32F2F),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _testResult!
                                      ? 'Connection successful!'
                                      : 'Could not reach the server.',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Buttons
                        Row(
                          children: [
                            // Test connection
                            Expanded(
                              child: GestureDetector(
                                onTap: _testing ? null : _testConnection,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: AppColors.ink, width: 1.5),
                                  ),
                                  alignment: Alignment.center,
                                  child: _testing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.ink,
                                          ),
                                        )
                                      : Text(
                                          'Test Connection',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Save
                            Expanded(
                              child: GestureDetector(
                                onTap: _save,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.ink,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: AppColors.ink, width: 1.5),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppColors.mint,
                                        offset: Offset(4, 4),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Save',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.white,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
