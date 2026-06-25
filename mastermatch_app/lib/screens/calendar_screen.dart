import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/program.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _FavoritesMonth {
  final Program program;
  final int monthIndex; // 1-12

  _FavoritesMonth({required this.program, required this.monthIndex});
}

class _CalendarScreenState extends State<CalendarScreen> {
  String? _authToken;
  bool _isLoading = true;
  List<_FavoritesMonth> _favoritesWithMonth = [];
  String? _errorMessage;

  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<String> _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

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
    });

    if (token != null && token.isNotEmpty) {
      try {
        final api = ApiService(baseUrl: url);
        final list = await api.getFavorites(token);
        final processed = <_FavoritesMonth>[];
        for (final p in list) {
          final mIdx = _getMonthIndex(p.deadline);
          processed.add(_FavoritesMonth(program: p, monthIndex: mIdx));
        }

        setState(() {
          _favoritesWithMonth = processed;
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

  int _getMonthIndex(String monthName) {
    final name = monthName.trim().toLowerCase();
    for (int i = 0; i < _months.length; i++) {
      if (_months[i].toLowerCase() == name) {
        return i + 1;
      }
    }
    return 1; // fallback to Jan
  }

  void _nextMonth() {
    setState(() {
      if (_currentMonth == 12) {
        _currentMonth = 1;
        _currentYear++;
      } else {
        _currentMonth++;
      }
    });
  }

  void _prevMonth() {
    setState(() {
      if (_currentMonth == 1) {
        _currentMonth = 12;
        _currentYear--;
      } else {
        _currentMonth--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = _authToken == null || _authToken!.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Application Calendar',
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
              : _buildCalendarView(),
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
                child: const Icon(Icons.calendar_month, size: 36, color: AppColors.ink),
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
                'You are currently in Guest Mode. Please log in or create an account to view application deadlines for your target universities.',
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

  Widget _buildCalendarView() {
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

    // Filter deadlines due in this specific month
    final currentMonthDeadlines = _favoritesWithMonth
        .where((item) => item.monthIndex == _currentMonth)
        .toList();

    // Calendar grid calculations
    final firstDay = DateTime(_currentYear, _currentMonth, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_currentYear, _currentMonth);
    final startWeekday = firstDay.weekday % 7; // Sun = 0, Mon = 1, etc.
    final totalCells = startWeekday + daysInMonth;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Swapper
          Container(
            decoration: AppTheme.cardDecoration,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _prevMonth,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.ink, width: 1.5),
                      color: AppColors.white,
                    ),
                    child: const Icon(Icons.chevron_left, size: 20, color: AppColors.ink),
                  ),
                ),
                Text(
                  '${_months[_currentMonth - 1]} $_currentYear',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                GestureDetector(
                  onTap: _nextMonth,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.ink, width: 1.5),
                      color: AppColors.white,
                    ),
                    child: const Icon(Icons.chevron_right, size: 20, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Calendar Grid Box
          Container(
            decoration: AppTheme.cardDecoration,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Weekdays header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _weekdays.map((w) {
                    return SizedBox(
                      width: 32,
                      child: Text(
                        w,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.muted,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.ink, thickness: 1.5),
                const SizedBox(height: 12),
                // Days Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: totalCells,
                  itemBuilder: (context, index) {
                    if (index < startWeekday) {
                      return const SizedBox.shrink();
                    }

                    final day = index - startWeekday + 1;
                    // Highlight the 15th as the representative deadline day for this month if there are deadlines
                    final isDeadlineDay = day == 15 && currentMonthDeadlines.isNotEmpty;

                    return Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDeadlineDay ? AppColors.pink : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isDeadlineDay
                            ? Border.all(color: AppColors.ink, width: 2)
                            : null,
                        boxShadow: isDeadlineDay
                            ? const [
                                BoxShadow(
                                  color: AppColors.ink,
                                  offset: Offset(2, 2),
                                  blurRadius: 0,
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        '$day',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: isDeadlineDay ? FontWeight.bold : FontWeight.normal,
                          color: AppColors.ink,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // List of deadlines in this month
          Text(
            'DEADLINES FOR ${_months[_currentMonth - 1].toUpperCase()}',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          if (currentMonthDeadlines.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                'No deadlines in this month.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
            )
          else
            ...currentMonthDeadlines.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: AppTheme.cardDecoration.copyWith(
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.ink,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.mintSoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.ink, width: 1.5),
                      ),
                      child: const Icon(Icons.school_outlined, size: 20, color: AppColors.ink),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.program.university,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.program.program,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.yellow,
                        border: Border.all(color: AppColors.ink, width: 1.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_months[_currentMonth - 1].substring(0, 3)} 15',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
