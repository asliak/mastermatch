import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_request.dart';
import '../screens/calendar_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/profile_screen.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatefulWidget {
  final ProfileRequest currentProfile;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.currentProfile,
    required this.onEditProfile,
    required this.onLogout,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? _username;
  bool _isGuest = true;

  @override
  void initState() {
    super.initState();
    _loadAuthStatus();
  }

  Future<void> _loadAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final user = prefs.getString('username');
    setState(() {
      _username = user;
      _isGuest = token == null || token.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.ink, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              color: AppColors.mint,
              border: Border(
                bottom: BorderSide(color: AppColors.ink, width: 2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'master',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.ink, width: 1.5),
                      ),
                      child: Text(
                        'match',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Text(
                      '.',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // User Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isGuest ? AppColors.pinkSoft : AppColors.white,
                    border: Border.all(color: AppColors.ink, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isGuest ? Icons.person_outline : Icons.check_circle_outline,
                        size: 14,
                        color: _isGuest ? AppColors.ink : const Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isGuest ? 'Guest Mode' : 'Logged in: ${_username ?? "User"}',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.person_outline,
                  label: 'My Profile',
                  onTap: () {
                    Navigator.pop(context); // close drawer first
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(
                          currentProfile: widget.currentProfile,
                          onEditProfile: widget.onEditProfile,
                          onLogout: widget.onLogout,
                        ),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.favorite_border,
                  label: 'My Favorites',
                  onTap: () {
                    Navigator.pop(context); // close drawer first
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.edit_note_outlined,
                  label: 'Notes',
                  onTap: () {
                    Navigator.pop(context); // close drawer first
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotesScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.calendar_month_outlined,
                  label: 'Calendar',
                  onTap: () {
                    Navigator.pop(context); // close drawer first
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CalendarScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.ink, width: 1.5),
              ),
            ),
            child: Text(
              'EE 471 · FINAL PROJECT',
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ink, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.ink,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.ink),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
