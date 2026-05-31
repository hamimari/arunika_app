import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    height: 1.2,
  );

  static TextStyle get heading => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    height: 1.3,
  );

  static TextStyle get subheading => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    height: 1.4,
  );

  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
    height: 1.5,
  );

  static TextStyle get body => GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textMedium,
    height: 1.5,
  );

  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
    height: 1.4,
  );

  static TextStyle get button => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    height: 1.2,
    letterSpacing: 0.3,
  );

  static TextStyle get buttonSmall => GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.2,
  );

  static TextStyle get label => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.navInactive,
    height: 1.2,
  );

  static TextStyle get labelActive => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.navActive,
    height: 1.2,
  );
}
