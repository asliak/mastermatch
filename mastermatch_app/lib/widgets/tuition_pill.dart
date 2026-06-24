import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TuitionPill extends StatelessWidget {
  final double tuition;

  const TuitionPill({
    super.key,
    required this.tuition,
  });

  Color get _backgroundColor {
    if (tuition == 0) return AppColors.mint;
    if (tuition < 5000) return AppColors.mint;
    if (tuition < 20000) return AppColors.sky;
    return Colors.transparent;
  }

  Color get _borderColor {
    if (tuition >= 20000) return AppColors.muted;
    return AppColors.ink;
  }

  String get _label {
    if (tuition == 0) return 'Free tuition 🎉';
    return '\$${_formatNumber(tuition)}/yr';
  }

  String _formatNumber(double value) {
    final intVal = value.toInt();
    if (intVal >= 1000) {
      return _addCommas(intVal.toString());
    }
    return intVal.toString();
  }

  String _addCommas(String number) {
    final result = StringBuffer();
    int count = 0;
    for (int i = number.length - 1; i >= 0; i--) {
      count++;
      result.write(number[i]);
      if (count % 3 == 0 && i != 0) {
        result.write(',');
      }
    }
    return result.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.pill),
        border: Border.all(
          color: _borderColor,
          width: AppTheme.borderWidth,
        ),
      ),
      child: Text(
        _label,
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
