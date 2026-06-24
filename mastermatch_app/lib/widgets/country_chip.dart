import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CountryChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback? onTap;

  const CountryChip({
    super.key,
    required this.label,
    required this.value,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mint : AppColors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.pill),
          border: Border.all(
            color: isSelected ? AppColors.ink : AppColors.border,
            width: AppTheme.borderWidth,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: AppColors.ink,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            color: AppColors.ink,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
