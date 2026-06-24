import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/program.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../screens/login_screen.dart';
import 'score_badge.dart';
import 'tuition_pill.dart';

class ResultCard extends StatefulWidget {
  final Program program;
  final int rank;
  final Color accentColor;
  final String? authToken;

  const ResultCard({
    super.key,
    required this.program,
    required this.rank,
    required this.accentColor,
    this.authToken,
  });

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.program.isFavorited;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    Future.delayed(Duration(milliseconds: widget.rank * 120), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(ResultCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.program.isFavorited != oldWidget.program.isFavorited) {
      setState(() {
        _isFavorited = widget.program.isFavorited;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _fieldTags {
    if (widget.program.fieldTags.isEmpty) return [];
    return widget.program.fieldTags
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .take(3)
        .toList();
  }

  String get _deadlineMonth {
    final dl = widget.program.deadline.trim();
    if (dl.isEmpty) return '';
    // Try to parse or just return as-is
    return dl;
  }

  Future<void> _launchUrl() async {
    final url = widget.program.url;
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.authToken == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            side: const BorderSide(color: AppColors.ink, width: 1.5),
          ),
          title: Text(
            'Account Required',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          content: Text(
            'You need to register or log in to bookmark your favorite master\'s programs.',
            style: GoogleFonts.dmSans(color: AppColors.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.ink, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: AppColors.mint, offset: Offset(2, 2)),
                ],
              ),
              child: TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final loggedIn = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(showBypass: false),
                    ),
                  );
                  if (loggedIn == true && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Successfully logged in! Run your search again to start saving favorites.',
                          style: GoogleFonts.dmSans(),
                        ),
                        backgroundColor: AppColors.ink,
                      ),
                    );
                  }
                },
                child: Text(
                  'Log In',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('server_url') ?? 'http://192.168.1.4:5001';
    final api = ApiService(baseUrl: serverUrl);

    setState(() {
      _isFavorited = !_isFavorited;
      widget.program.isFavorited = _isFavorited;
    });

    try {
      final newFavStatus = await api.toggleFavorite(
        widget.authToken!,
        widget.program.university,
        widget.program.program,
      );
      if (newFavStatus != _isFavorited) {
        setState(() {
          _isFavorited = newFavStatus;
          widget.program.isFavorited = _isFavorited;
        });
      }
    } catch (e) {
      setState(() {
        _isFavorited = !_isFavorited;
        widget.program.isFavorited = _isFavorited;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to toggle favorite: ${e.toString().replaceFirst('Exception: ', '')}',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: AppColors.ink,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(
              color: AppColors.ink,
              width: AppTheme.borderWidth,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.ink,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent strip
                Container(
                  width: 4,
                  color: widget.accentColor,
                ),
                // Main content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Rank
                              Text(
                                '#${widget.rank} MATCH',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted,
                                  letterSpacing: 1.5,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Program name
                              Text(
                                widget.program.program,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 16.8,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // University + location
                              Text(
                                '${widget.program.university} · ${widget.program.city}, ${widget.program.country}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.muted,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Meta pills
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  // Tuition
                                  TuitionPill(tuition: widget.program.tuition),
                                  // GPA
                                  if (widget.program.minGpa > 0)
                                    _PlainPill(
                                      label:
                                          'GPA ≥ ${widget.program.minGpa.toStringAsFixed(1)}',
                                    ),
                                  // Duration
                                  if (widget.program.duration > 0)
                                    _PlainPill(
                                      label: widget.program.duration == 1
                                          ? '1 yr'
                                          : '${widget.program.duration % 1 == 0 ? widget.program.duration.toInt().toString() : widget.program.duration.toStringAsFixed(1)} yrs',
                                    ),
                                  // Scholarship
                                  if (widget.program.scholarship)
                                    const _ColoredPill(
                                      label: 'Scholarship ✓',
                                      color: AppColors.yellow,
                                    ),
                                  // Deadline
                                  if (_deadlineMonth.isNotEmpty)
                                    _ColoredPill(
                                      label: 'Deadline: $_deadlineMonth',
                                      color: AppColors.pink,
                                    ),
                                  // Field tags
                                  ..._fieldTags.map(
                                    (tag) => _ColoredPill(
                                      label: tag,
                                      color: AppColors.sky,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Explanation
                              if (widget.program.explanation.isNotEmpty)
                                Text(
                                  widget.program.explanation,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.muted,
                                    height: 1.5,
                                  ),
                                ),
                              if (widget.program.explanation.isNotEmpty)
                                const SizedBox(height: 12),
                              // View program button
                              if (widget.program.url.isNotEmpty)
                                GestureDetector(
                                  onTap: _launchUrl,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(
                                          AppBorderRadius.pill),
                                      border: Border.all(
                                        color: AppColors.ink,
                                        width: AppTheme.borderWidth,
                                      ),
                                    ),
                                    child: Text(
                                      'View Program →',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Right: score badge & favorite toggle
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: _toggleFavorite,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _isFavorited ? AppColors.pinkSoft : AppColors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.ink, width: 1.5),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.ink,
                                      offset: Offset(1.5, 1.5),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isFavorited ? Icons.favorite : Icons.favorite_border,
                                  size: 18,
                                  color: _isFavorited ? const Color(0xFFD81B60) : AppColors.ink,
                                ),
                              ),
                            ),
                            const Spacer(),
                            ScoreBadge(score: widget.program.score),
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
    );
  }
}

/// A plain pill with transparent bg and muted border
class _PlainPill extends StatelessWidget {
  final String label;

  const _PlainPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppBorderRadius.pill),
        border: Border.all(
          color: AppColors.border,
          width: AppTheme.borderWidth,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
          height: 1.3,
        ),
      ),
    );
  }
}

/// A colored pill with specified background and ink border
class _ColoredPill extends StatelessWidget {
  final String label;
  final Color color;

  const _ColoredPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppBorderRadius.pill),
        border: Border.all(
          color: AppColors.ink,
          width: AppTheme.borderWidth,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
          height: 1.3,
        ),
      ),
    );
  }
}
