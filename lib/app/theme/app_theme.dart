import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      canvasColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkInfo,
        surface: AppColors.darkSurface,
        error: AppColors.darkError,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: AppColors.darkTextPrimary,
        onError: Colors.white,
      ),
      textTheme: AppTypography.darkTextTheme,
      dividerColor: AppColors.darkBorder,
      cardTheme: CardThemeData(
        color: AppColors.darkPanel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(
            color: AppColors.darkBorder,
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceAlt,
        labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
        hintStyle: const TextStyle(color: AppColors.darkTextMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 1.2),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.darkSidebar,
        selectedIconTheme: IconThemeData(color: AppColors.darkPrimary),
        unselectedIconTheme: IconThemeData(color: AppColors.darkTextSecondary),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: AppColors.darkTextSecondary,
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: AppColors.darkSidebarActive,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.darkSurfaceAlt,
        side: const BorderSide(color: AppColors.darkBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      dataTableTheme: const DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(AppColors.darkSurfaceAlt),
        dividerThickness: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
    );
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      canvasColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightInfo,
        surface: AppColors.lightSurface,
        error: AppColors.lightError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
        onError: Colors.white,
      ),
      textTheme: AppTypography.lightTextTheme,
      dividerColor: AppColors.lightBorder,
      cardTheme: CardThemeData(
        color: AppColors.lightPanel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(
            color: AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        labelStyle: const TextStyle(color: AppColors.lightTextSecondary),
        hintStyle: const TextStyle(color: AppColors.lightTextMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.2),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.lightSidebar,
        selectedIconTheme: IconThemeData(color: AppColors.lightPrimary),
        unselectedIconTheme: IconThemeData(color: AppColors.lightTextSecondary),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: AppColors.lightTextSecondary,
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: AppColors.lightSidebarActive,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBg,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.lightSurfaceAlt,
        side: const BorderSide(color: AppColors.lightBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      dataTableTheme: const DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(AppColors.lightSurfaceAlt),
        dividerThickness: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
    );
  }
}