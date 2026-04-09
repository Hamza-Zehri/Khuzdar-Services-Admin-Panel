import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class AdminTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        background: AppColors.background,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(color: AppColors.textPrimary),
        displayMedium: GoogleFonts.poppins(color: AppColors.textPrimary),
        titleLarge: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        titleMedium: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.poppins(color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.poppins(color: AppColors.textPrimary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: MaterialStateProperty.all(AppColors.background),
        dataRowColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.hovered)) {
            return AppColors.primary.withOpacity(0.05);
          }
          return AppColors.surface;
        }),
        headingTextStyle: GoogleFonts.poppins(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
