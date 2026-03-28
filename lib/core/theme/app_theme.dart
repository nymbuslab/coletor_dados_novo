import 'package:flutter/material.dart';

/// Centraliza todo o design system do app.
/// Use [AppTheme.light()] no MaterialApp e [AppColors] nas telas.
abstract class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme,
      appBarTheme: _appBarTheme(colorScheme),
      cardTheme: _cardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      chipTheme: _chipTheme(colorScheme),
      dividerTheme: const DividerThemeData(space: 1, thickness: 1),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------
  static AppBarTheme _appBarTheme(ColorScheme cs) => AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        titleTextStyle: TextStyle(
          color: cs.onPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(color: cs.onPrimary),
      );

  // ---------------------------------------------------------------------------
  // Card
  // ---------------------------------------------------------------------------
  static const CardThemeData _cardTheme = CardThemeData(
    elevation: 2,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );

  // ---------------------------------------------------------------------------
  // Buttons
  // ---------------------------------------------------------------------------
  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      elevation: 1,
    ),
  );

  static final OutlinedButtonThemeData _outlinedButtonTheme =
      OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      side: const BorderSide(width: 1.5),
    ),
  );

  // ---------------------------------------------------------------------------
  // Input
  // ---------------------------------------------------------------------------
  static InputDecorationTheme _inputDecorationTheme(ColorScheme cs) =>
      InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
      );

  // ---------------------------------------------------------------------------
  // Chip
  // ---------------------------------------------------------------------------
  static ChipThemeData _chipTheme(ColorScheme cs) => ChipThemeData(
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      );

  // ---------------------------------------------------------------------------
  // Typography
  // ---------------------------------------------------------------------------
  static const TextTheme _textTheme = TextTheme(
    // Títulos de tela / headlines
    headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),

    // Títulos de seção / cards
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.15),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),

    // Corpo de texto
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),

    // Labels / badges / captions
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
  );
}

/// Cores semânticas do app.
/// Use estas constantes nas telas em vez de [Colors.*] hardcoded.
abstract class AppColors {
  // Cor semente do ColorScheme principal
  static const Color seed = Color(0xFF6D3BD9); // roxo vibrante

  // Paleta da marca
  static const Color navy     = Color(0xFF0A1240); // azul muito escuro
  static const Color darkBlue = Color(0xFF172573); // azul escuro
  static const Color midBlue  = Color(0xFF295FA6); // azul médio
  static const Color cyan     = Color(0xFF48B0D9); // azul claro/ciano

  // Cores por funcionalidade (usar como backgroundColor de AppBar, botões, badges)
  static const Color etiqueta   = Color(0xFF48B0D9); // ciano
  static const Color consulta   = Color(0xFF295FA6); // azul médio
  static const Color inventario = Color(0xFF172573); // azul escuro
  static const Color entrada    = Color(0xFF0A1240); // navy

  // Semânticas gerais
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE65100);
  static const Color danger  = Color(0xFFC62828);
  static const Color info    = Color(0xFF6D3BD9);

  // Superfícies neutras
  static const Color surfaceSubtle = Color(0xFFF5F5F5);
  static const Color border        = Color(0xFFE0E0E0);
}
