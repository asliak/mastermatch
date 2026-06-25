import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/program.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/result_card.dart';
import 'login_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String? _authToken;
  String? _serverUrl;
  bool _isLoading = true;
  List<Program> _favorites = [];
  String? _errorMessage;

  final List<Color> _accentColors = [
    AppColors.mint,
    AppColors.pink,
    AppColors.sky,
    AppColors.yellow,
    AppColors.peach,
  ];

  @override
  void initState() {
    super.initState();
    _loadAuthAndFetch();
  }

  Future<void> _loadAuthAndFetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = prefs.getString('server_url') ?? 'https://mastermatch.onrender.com';

    setState(() {
      _authToken = token;
      _serverUrl = url;
    });

    if (token != null && token.isNotEmpty) {
      await _fetchFavorites(token, url);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchFavorites(String token, String url) async {
    try {
      final api = ApiService(baseUrl: url);
      final list = await api.getFavorites(token);
      setState(() {
        _favorites = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = _authToken == null || _authToken!.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'My Favorites',
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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.ink),
            )
          : isGuest
              ? _buildGuestView()
              : _buildFavoritesList(),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          decoration: AppTheme.cardDecoration,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.pinkSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ink, width: 1.5),
                ),
                child: const Icon(Icons.favorite_border, size: 36, color: AppColors.ink),
              ),
              const SizedBox(height: 20),
              Text(
                'Account Required',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You are currently in Guest Mode. Please log in or create an account to bookmark programs and sync them to your profile.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () async {
                  final loggedIn = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(showBypass: false),
                    ),
                  );
                  if (loggedIn == true) {
                    _loadAuthAndFetch();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                  decoration: AppTheme.pillButtonDecoration(shadowColor: AppColors.mint),
                  child: Text(
                    'Log In / Register',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesList() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error: $_errorMessage',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: Colors.red),
          ),
        ),
      );
    }

    if (_favorites.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            decoration: AppTheme.cardDecoration,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.mintSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.ink, width: 1.5),
                  ),
                  child: const Icon(Icons.star_outline, size: 36, color: AppColors.ink),
                ),
                const SizedBox(height: 20),
                Text(
                  'No Favorites Yet',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Go find some programs and tap the heart icon to save them to your list!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.ink,
      backgroundColor: AppColors.white,
      onRefresh: () => _fetchFavorites(_authToken!, _serverUrl!),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final p = _favorites[index];
          return ResultCard(
            program: p,
            rank: index + 1,
            accentColor: _accentColors[index % _accentColors.length],
            authToken: _authToken,
          );
        },
      ),
    );
  }
}
