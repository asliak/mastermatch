import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_request.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileRequest currentProfile;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.currentProfile,
    required this.onEditProfile,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _authToken;
  String? _username;
  bool _isLoading = true;
  int _favoritesCount = 0;
  int _notesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAuthAndStats();
  }

  Future<void> _loadAuthAndStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final user = prefs.getString('username');
    final url = prefs.getString('server_url') ?? 'https://mastermatch.onrender.com';

    setState(() {
      _authToken = token;
      _username = user;
    });

    // Count notes in local storage
    final noteKeys = prefs.getKeys().where((k) => k.startsWith('note_'));
    int noteCount = 0;
    for (final key in noteKeys) {
      if (prefs.getString(key)?.trim().isNotEmpty == true) {
        noteCount++;
      }
    }

    setState(() {
      _notesCount = noteCount;
    });

    // Count favorites from backend if logged in
    if (token != null && token.isNotEmpty) {
      try {
        final api = ApiService(baseUrl: url);
        final list = await api.getFavorites(token);
        setState(() {
          _favoritesCount = list.length;
        });
      } catch (e) {
        debugPrint('Error fetching favorites count for profile: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = _authToken == null || _authToken!.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink, width: 1.5),
              color: AppColors.white,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.arrow_back, size: 16, color: AppColors.ink),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.ink))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // User Avatar Header
                  _buildUserHeader(isGuest),
                  const SizedBox(height: 20),

                  // Statistics Box
                  _buildStatsSection(isGuest),
                  const SizedBox(height: 20),

                  // Profile Summary Card
                  _buildProfileDetailsCard(),
                  const SizedBox(height: 24),

                  // Edit & Logout Controls
                  _buildActionButtons(isGuest),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildUserHeader(bool isGuest) {
    final displayName = isGuest ? 'Guest Explorer' : (_username ?? 'User');
    final avatarLetter = displayName.substring(0, 1).toUpperCase();

    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isGuest ? AppColors.pink : AppColors.mint,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.ink,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              avatarLetter,
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isGuest ? AppColors.pinkSoft : AppColors.mintSoft,
                    border: Border.all(color: AppColors.ink, width: 1.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isGuest ? 'LOCAL SYNC ONLY' : 'CLOUD SYNC ENABLED',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(bool isGuest) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: AppTheme.cardDecoration.copyWith(
              boxShadow: const [
                BoxShadow(
                  color: AppColors.ink,
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                Text(
                  isGuest ? '—' : '$_favoritesCount',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'FAVORITES',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            decoration: AppTheme.cardDecoration.copyWith(
              boxShadow: const [
                BoxShadow(
                  color: AppColors.ink,
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                Text(
                  isGuest ? '—' : '$_notesCount',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'WRITTEN NOTES',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetailsCard() {
    final p = widget.currentProfile;
    final hasDetails = p.field.isNotEmpty || p.gpa > 0 || p.interests.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACADEMIC PROFILE',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.ink, thickness: 1.5),
          const SizedBox(height: 14),
          if (!hasDetails)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No profile details submitted yet. Use the editor to define your GPA, budget, and targets.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.muted,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            )
          else ...[
            _buildDetailItem('FIELD OF STUDY', p.field.isEmpty ? 'Not selected' : p.field),
            _buildDetailItem('GPA SCORE', p.gpa > 0 ? '${p.gpa} / 4.0' : 'Not specified'),
            _buildDetailItem('MAX TUITION BUDGET', p.budget < 999999 ? '\$${p.budget.toInt()} USD/year' : 'Any budget'),
            _buildDetailItem('SPECIFIC INTERESTS', p.interests.isEmpty ? 'None listed' : p.interests),
            _buildDetailItem('CAREER GOALS', p.careerGoals.isEmpty ? 'None listed' : p.careerGoals),
            _buildDetailItem('PREFERRED COUNTRIES', p.countries.isEmpty ? 'Any country' : p.countries.join(', ')),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isGuest) {
    return Column(
      children: [
        // Edit Profile Button
        GestureDetector(
          onTap: () {
            Navigator.pop(context); // close ProfileScreen
            widget.onEditProfile(); // trigger edit scroll
          },
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: AppTheme.pillButtonDecoration(
              backgroundColor: AppColors.ink,
              shadowColor: AppColors.mint,
            ),
            child: Text(
              'Edit Profile Details →',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        if (!isGuest) ...[
          const SizedBox(height: 16),
          // Logout Button
          GestureDetector(
            onTap: () {
              Navigator.pop(context); // close ProfileScreen
              widget.onLogout(); // trigger logout
            },
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: AppTheme.pillButtonDecoration(
                backgroundColor: AppColors.pinkSoft,
                shadowColor: AppColors.border,
              ),
              child: Text(
                'Log Out',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
