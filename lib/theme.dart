import 'package:flutter/material.dart';

// ── Brand colours ────────────────────────────────────────────────────────────
const Color kHighlight = Color(0xFF6C63FF);   // primary purple
const Color kAccentMid = Color(0xFF9B59B6);   // mid purple (gradient end)
const Color kAccentWarm = Color(0xFFFF6584);  // warm accent / error

// ── Theme wrapper ─────────────────────────────────────────────────────────────
class AppTheme {
  final bool isDark;

  const AppTheme({required this.isDark});

  bool get dark => isDark;

  // ── Page / scaffold backgrounds ──────────────────────────────────────────
  Color get page => isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF5F5FF);

  // ── Card surfaces ────────────────────────────────────────────────────────
  Color get card    => isDark ? const Color(0xFF1C1C2E) : Colors.white;
  Color get cardImg => isDark ? const Color(0xFF252538) : const Color(0xFFF0F0FF);

  // ── Borders ──────────────────────────────────────────────────────────────
  Color get border  => isDark ? const Color(0xFF2E2E45) : const Color(0xFFE8E8F0);

  // ── Text ─────────────────────────────────────────────────────────────────
  Color get textPrimary   => isDark ? Colors.white          : const Color(0xFF1A1A2E);
  Color get textSecondary => isDark ? const Color(0xFF9090B0) : const Color(0xFF6B6B8A);

  // ── Input fields ─────────────────────────────────────────────────────────
  Color get inputFill   => isDark ? const Color(0xFF1C1C2E) : const Color(0xFFF5F5FF);
  Color get inputBorder => isDark ? const Color(0xFF3A3A55) : const Color(0xFFD8D8EE);

  // ── Bottom nav bar ────────────────────────────────────────────────────────
  Color get navBar        => isDark ? const Color(0xFF14141F) : Colors.white;
  Color get navBarBorder  => isDark ? const Color(0xFF2A2A40) : const Color(0xFFE0E0F0);

  // ── Divider ───────────────────────────────────────────────────────────────
  Color get divider => isDark ? const Color(0xFF2E2E45) : const Color(0xFFEEEEF8);

  // ── Shimmer (skeleton loading) ────────────────────────────────────────────
  Color get shimmerBase      => isDark ? const Color(0xFF1E1E30) : const Color(0xFFE8E8F5);
  Color get shimmerHighlight => isDark ? const Color(0xFF2A2A42) : const Color(0xFFF5F5FF);

  // ── Status / semantic colours (same in both modes for legibility) ─────────
  Color get success => const Color(0xFF34A853);
  Color get warning => const Color(0xFFF59E0B);
  Color get error   => kAccentWarm;
  Color get info    => const Color(0xFF1a73e8);

  // ── Material ThemeData helper (optional — use if you have Material widgets)
  ThemeData toMaterialTheme() {
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: page,
      cardColor: card,
      dividerColor: divider,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: kHighlight,
        onPrimary: Colors.white,
        secondary: kAccentMid,
        onSecondary: Colors.white,
        error: kAccentWarm,
        onError: Colors.white,
        background: page,
        onBackground: textPrimary,
        surface: card,
        onSurface: textPrimary,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
      ),
    );
  }
}