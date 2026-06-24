import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/program.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String? _authToken;
  bool _isLoading = true;
  List<Program> _favorites = [];
  String? _errorMessage;

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
    final url = prefs.getString('server_url') ?? 'http://192.168.1.4:5001';

    setState(() {
      _authToken = token;
    });

    if (token != null && token.isNotEmpty) {
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
    } else {
      setState(() {
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
          'My Notes',
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
              : _buildNotesList(),
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
                child: const Icon(Icons.edit_note, size: 36, color: AppColors.ink),
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
                'You are currently in Guest Mode. Please log in or create an account to write notes for your target master\'s programs.',
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

  Widget _buildNotesList() {
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
                  'No Favorites Saved',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Favorite programs first from the search results to start adding custom notes for them!',
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final p = _favorites[index];
        return NoteEditorCard(program: p);
      },
    );
  }
}

class NoteEditorCard extends StatefulWidget {
  final Program program;

  const NoteEditorCard({super.key, required this.program});

  @override
  State<NoteEditorCard> createState() => _NoteEditorCardState();
}

class _NoteEditorCardState extends State<NoteEditorCard> {
  final _ctrl = TextEditingController();
  bool _isSaving = false;
  String _saveStatus = 'Saved';
  Timer? _debounce;
  late final String _storageKey;

  @override
  void initState() {
    super.initState();
    _storageKey = 'note_${widget.program.university}_${widget.program.program}'
        .replaceAll(RegExp(r'\s+'), '_');
    _loadNote();
    _ctrl.addListener(_onTextChanged);
  }

  Future<void> _loadNote() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey) ?? '';
    setState(() {
      _ctrl.text = saved;
    });
  }

  void _onTextChanged() {
    setState(() {
      _saveStatus = 'Typing…';
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () async {
      setState(() {
        _isSaving = true;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, _ctrl.text);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveStatus = 'Auto-saved ✓';
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.removeListener(_onTextChanged);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Program Info Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.program.university,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.program.program,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  border: Border.all(color: AppColors.ink, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.program.deadline,
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Note field
          Text(
            'MY TASKS & NOTES',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.ink, width: 1.5),
            ),
            child: TextField(
              controller: _ctrl,
              maxLines: 4,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.ink,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. Talk to Prof. X about letters of rec, prepare draft statement of purpose…',
                hintStyle: GoogleFonts.dmSans(color: AppColors.muted.withValues(alpha: 0.7), fontSize: 13),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Save status feedback
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_isSaving)
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.ink,
                  ),
                ),
              if (_isSaving) const SizedBox(width: 6),
              Text(
                _saveStatus,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _saveStatus.contains('✓') ? const Color(0xFF2E7D32) : AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
