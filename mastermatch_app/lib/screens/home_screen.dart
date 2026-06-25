import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/program.dart';
import '../models/profile_request.dart';
import '../services/api_service.dart';
import '../widgets/country_chip.dart';
import '../widgets/result_card.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Form state
  String _selectedField = '';
  final _gpaController = TextEditingController();
  final _budgetController = TextEditingController();
  final _interestsController = TextEditingController();
  final _careerGoalsController = TextEditingController();
  final Set<String> _selectedCountries = {};

  // App state
  bool _isLoading = false;
  List<Program>? _results;
  String _serverUrl = 'https://mastermatch.onrender.com';
  String? _authToken;
  String? _username;

  final ScrollController _scrollController = ScrollController();

  void _scrollToProfile() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // Bouncing dots animation
  late final AnimationController _dotsController;

  static const _fields = [
    'Electrical & Electronics Engineering',
    'Computer Science & AI',
    'Communications Engineering',
    'Data Science',
    'Robotics & Embedded Systems',
    'Biomedical Engineering',
    'Energy & Power Systems',
  ];

  static const _countries = [
    {'label': '🇩🇪 Germany', 'value': 'Germany'},
    {'label': '🇳🇱 Netherlands', 'value': 'Netherlands'},
    {'label': '🇸🇪 Sweden', 'value': 'Sweden'},
    {'label': '🇫🇮 Finland', 'value': 'Finland'},
    {'label': '🇨🇭 Switzerland', 'value': 'Switzerland'},
    {'label': '🇬🇧 UK', 'value': 'UK'},
    {'label': '🇨🇦 Canada', 'value': 'Canada'},
    {'label': '🇺🇸 USA', 'value': 'USA'},
    {'label': '🇮🇹 Italy', 'value': 'Italy'},
    {'label': '🇸🇬 Singapore', 'value': 'Singapore'},
    {'label': '🇦🇺 Australia', 'value': 'Australia'},
    {'label': '🇩🇰 Denmark', 'value': 'Denmark'},
    {'label': '🇵🇱 Poland', 'value': 'Poland'},
    {'label': '🇨🇿 Czech Republic', 'value': 'Czech Republic'},
    {'label': '🇭🇺 Hungary', 'value': 'Hungary'},
    {'label': '🇪🇪 Estonia', 'value': 'Estonia'},
    {'label': '🇪🇸 Spain', 'value': 'Spain'},
    {'label': '🇷🇸 Serbia', 'value': 'Serbia'},
    {'label': '🇨🇾 Cyprus', 'value': 'Cyprus'},
  ];

  static const _accentColors = [
    AppColors.mint,
    AppColors.pink,
    AppColors.sky,
    AppColors.yellow,
    AppColors.peach,
  ];

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
    _loadSettingsAndAuth();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialLogin();
    });
  }

  @override
  void dispose() {
    _gpaController.dispose();
    _budgetController.dispose();
    _interestsController.dispose();
    _careerGoalsController.dispose();
    _dotsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsAndAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('server_url') ?? 'https://mastermatch.onrender.com';
    final token = prefs.getString('auth_token');
    final user = prefs.getString('username');
    
    setState(() {
      _serverUrl = url;
      _authToken = token;
      _username = user;
    });

    if (token != null) {
      await _fetchProfile(token);
    }
  }

  Future<void> _fetchProfile(String token) async {
    try {
      final api = ApiService(baseUrl: _serverUrl);
      final profile = await api.getProfile(token);
      
      setState(() {
        _selectedField = profile.field;
        _gpaController.text = profile.gpa > 0 ? profile.gpa.toString() : '';
        _budgetController.text = profile.budget < 999999 ? profile.budget.toInt().toString() : '';
        _interestsController.text = profile.interests;
        _careerGoalsController.text = profile.careerGoals;
        _selectedCountries.clear();
        _selectedCountries.addAll(profile.countries);
      });
    } catch (e) {
      // If token expired or invalid, clear token
      if (e.toString().contains('401') || e.toString().contains('403')) {
        await _logout();
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('username');
    setState(() {
      _authToken = null;
      _username = null;
      _results = null;
    });
    _checkInitialLogin();
  }

  Future<void> _checkInitialLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      if (mounted) {
        final loggedIn = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(showBypass: true),
          ),
        );
        if (loggedIn == true) {
          _loadSettingsAndAuth();
        } else {
          setState(() {
            _authToken = null;
            _username = null;
          });
        }
      }
    }
  }

  Future<void> _runMatch() async {
    setState(() {
      _isLoading = true;
      _results = null;
    });

    try {
      final api = ApiService(baseUrl: _serverUrl);
      final profile = ProfileRequest(
        field: _selectedField,
        gpa: double.tryParse(_gpaController.text) ?? 0,
        budget: double.tryParse(_budgetController.text) ?? 999999,
        interests: _interestsController.text,
        careerGoals: _careerGoalsController.text,
        countries: _selectedCountries.toList(),
      );

      // Auto-save profile if authenticated
      if (_authToken != null) {
        try {
          await api.saveProfile(_authToken!, profile);
        } catch (e) {
          debugPrint("Error auto-saving profile: $e");
        }
      }

      final results = await api.match(profile, token: _authToken);
      setState(() {
        _results = results;
        _isLoading = false;
      });

      // Scroll to results
      if (results.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted && _resultsKey.currentContext != null) {
          Scrollable.ensureVisible(
            _resultsKey.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  final _resultsKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        currentProfile: ProfileRequest(
          field: _selectedField,
          gpa: double.tryParse(_gpaController.text) ?? 0,
          budget: double.tryParse(_budgetController.text) ?? 999999,
          interests: _interestsController.text,
          careerGoals: _careerGoalsController.text,
          countries: _selectedCountries.toList(),
        ),
        onEditProfile: _scrollToProfile,
        onLogout: _logout,
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── APP BAR ─────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: false,
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'master',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'match',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Text(
                    '.',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                  border: Border.all(color: AppColors.border, width: 1.5),
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
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 22),
                color: AppColors.muted,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                  _loadSettingsAndAuth();
                },
              ),
            ],
          ),

          // ── CONTENT ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHero(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildFormCard(),
                ),
                if (_isLoading) _buildLoading(),
                if (_results != null) _buildResults(),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // HERO SECTION
  // ════════════════════════════════════════════════════════
  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      child: Column(
        children: [
          // Eyebrow badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppBorderRadius.pill),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '✦',
                  style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.ink),
                ),
                const SizedBox(width: 8),
                Text(
                  "FIND YOUR MASTER'S PROGRAM ABROAD",
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Title
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'the ',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    height: 1.05,
                    letterSpacing: -1.5,
                  ),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'smarter',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        height: 1.05,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ),
                ),
                TextSpan(
                  text: ' way\nto find your\n',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    height: 1.05,
                    letterSpacing: -1.5,
                  ),
                ),
                TextSpan(
                  text: 'dream program.',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: AppColors.ink,
                    height: 1.05,
                    letterSpacing: -1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Tell us about yourself — your GPA, interests, and goals. We\'ll match you with programs you actually qualify for.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w300,
                color: AppColors.muted,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // FORM CARD
  // ════════════════════════════════════════════════════════
  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: AppTheme.cardDecoration.copyWith(
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(5, 5), blurRadius: 0),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card title & Auth Status
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Your Profile',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                          border: Border.all(color: AppColors.ink, width: 1.5),
                        ),
                        child: Text(
                          'STEP 1 OF 1',
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.8,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _authToken != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            border: Border.all(color: AppColors.ink, width: 1.5),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Synced ✓',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 1.5,
                                height: 10,
                                color: AppColors.border,
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: _logout,
                                child: Text(
                                  'Logout',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : GestureDetector(
                          onTap: () async {
                            final loggedIn = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(showBypass: false),
                              ),
                            );
                            if (loggedIn == true) {
                              _loadSettingsAndAuth();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              border: Border.all(color: AppColors.border, width: 1.5),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              'Log in to sync',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.muted,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_authToken != null && _username != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Welcome, $_username! Your preferences are saved automatically.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.muted,
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Field of Study
            _buildLabel('FIELD OF STUDY'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedField.isEmpty ? null : _selectedField,
              hint: Text(
                'Select a field…',
                style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w300, color: AppColors.muted),
              ),
              decoration: const InputDecoration(),
              items: _fields.map((f) => DropdownMenuItem(
                value: f,
                child: Text(f, style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w300)),
              )).toList(),
              onChanged: (v) => setState(() => _selectedField = v ?? ''),
              dropdownColor: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 18),

            // GPA & Budget
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('GPA (OUT OF 4.0)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _gpaController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(hintText: 'e.g. 3.2'),
                        style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('MAX TUITION (USD/YR)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _budgetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'Any budget'),
                        style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Interests
            _buildLabel('SPECIFIC INTERESTS'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _interestsController,
              decoration: const InputDecoration(hintText: 'e.g. machine learning, 5G, signal processing'),
              style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 18),

            // Career Goals
            _buildLabel('CAREER GOALS'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _careerGoalsController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. I want to work in AI research or join a tech company in Europe after graduation…',
              ),
              style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 18),

            // Countries
            Row(
              children: [
                _buildLabel('PREFERRED COUNTRIES'),
                const SizedBox(width: 6),
                Text(
                  '— leave blank for any',
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _countries.map((c) {
                final isSelected = _selectedCountries.contains(c['value']);
                return CountryChip(
                  label: c['label']!,
                  value: c['value']!,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCountries.remove(c['value']);
                      } else {
                        _selectedCountries.add(c['value']!);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: AppTheme.pillButtonDecoration(shadowColor: AppColors.mint),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _runMatch,
                    borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Find My Programs →',
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
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // LOADING
  // ════════════════════════════════════════════════════════
  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _dotsController,
                builder: (_, child) {
                  final progress = (_dotsController.value + i * 0.15) % 1.0;
                  final dy = -10.0 * (progress < 0.5 ? (progress * 2) : (2 - progress * 2));
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Transform.translate(
                      offset: Offset(0, dy),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.ink,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing your profile…',
            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // RESULTS
  // ════════════════════════════════════════════════════════
  Widget _buildResults() {
    final results = _results!;

    return Padding(
      key: _resultsKey,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (results.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Your Matches ✦',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Text(
                    '${results.length} program${results.length != 1 ? 's' : ''} found',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...results.asMap().entries.map((entry) {
              final i = entry.key;
              final program = entry.value;
              return ResultCard(
                program: program,
                rank: i + 1,
                accentColor: _accentColors[i % _accentColors.length],
                authToken: _authToken,
              );
            }),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    'No matches found',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try relaxing your GPA, budget, or country filters.',
                    style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ],
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
