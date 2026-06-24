import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ScoreBadge extends StatelessWidget {
  final double score;

  const ScoreBadge({
    super.key,
    required this.score,
  });

  Color get _backgroundColor {
    if (score >= 70) return AppColors.mint;
    if (score >= 50) return AppColors.yellow;
    return AppColors.pink;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: _backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.ink,
          width: AppTheme.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.ink,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${score.toInt()}%',
            style: GoogleFonts.playfairDisplay(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            'MATCH',
            style: GoogleFonts.dmSans(
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
              letterSpacing: 1.2,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
