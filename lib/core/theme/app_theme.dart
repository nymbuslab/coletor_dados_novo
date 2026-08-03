import 'package:flutter/material.dart';

/// Centraliza todo o design system do app — linguagem visual "Apple"
/// (ver `lib/assets/DESIGN-apple.md`): um único matiz de ação (azul) em três
/// tons contextuais, tipografia Inter com tracking negativo, botões-pílula,
/// cards de raio 18 sem sombra e superfícies claras (parchment/branco).
///
/// Use [AppTheme.light()] no MaterialApp e [AppColors] nas telas.
abstract class AppTheme {
  static const String fontFamily = 'Inter';

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.seed).copyWith(
      primary: AppColors.action,
      onPrimary: Colors.white,
      surface: AppColors.canvas,
      onSurface: AppColors.ink,
      error: AppColors.danger,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: _textTheme,
      appBarTheme: _appBarTheme,
      cardTheme: _cardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationTheme,
      chipTheme: _chipTheme,
      dividerTheme: const DividerThemeData(
        space: 1,
        thickness: 1,
        color: AppColors.divider,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar — barra clara, sem elevação (deixa de ser azul-cheia).
  // Momentos escuros (Splash/header da Home) definem cor localmente.
  // ---------------------------------------------------------------------------
  static const AppBarTheme _appBarTheme = AppBarTheme(
    centerTitle: true,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: AppColors.canvas,
    foregroundColor: AppColors.ink,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      fontFamily: fontFamily,
      color: AppColors.ink,
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.374,
    ),
    iconTheme: IconThemeData(color: AppColors.ink),
  );

  // ---------------------------------------------------------------------------
  // Card — raio 18, hairline 1px, sem sombra (chrome não tem elevação).
  // ---------------------------------------------------------------------------
  static const CardThemeData _cardTheme = CardThemeData(
    elevation: 0,
    margin: EdgeInsets.zero,
    color: AppColors.canvas,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
      side: BorderSide(color: AppColors.border),
    ),
  );

  // ---------------------------------------------------------------------------
  // Botões
  // ---------------------------------------------------------------------------
  // Primário: pílula Action Blue, texto branco. Anel de foco actionFocus 2px.
  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: const WidgetStatePropertyAll(AppColors.action),
      foregroundColor: const WidgetStatePropertyAll(Colors.white),
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      ),
      textStyle: const WidgetStatePropertyAll(_buttonTextStyle),
      overlayColor: const WidgetStatePropertyAll(Colors.white24),
      shape: WidgetStateProperty.resolveWith((states) {
        final focused = states.contains(WidgetState.focused);
        return StadiumBorder(
          side: focused
              ? const BorderSide(color: AppColors.actionFocus, width: 2)
              : BorderSide.none,
        );
      }),
    ),
  );

  // Secundário: pílula fantasma (borda action, texto action).
  static final OutlinedButtonThemeData _outlinedButtonTheme =
      OutlinedButtonThemeData(
    style: ButtonStyle(
      foregroundColor: const WidgetStatePropertyAll(AppColors.action),
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      ),
      textStyle: const WidgetStatePropertyAll(_buttonTextStyle),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      side: WidgetStateProperty.resolveWith((states) {
        final focused = states.contains(WidgetState.focused);
        return BorderSide(
          color: focused ? AppColors.actionFocus : AppColors.action,
          width: focused ? 2 : 1,
        );
      }),
    ),
  );

  // Link textual em Action Blue.
  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.action,
      textStyle: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.374,
      ),
    ),
  );

  static const TextStyle _buttonTextStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.374,
  );

  // ---------------------------------------------------------------------------
  // Input — pílula, hairline, foco actionFocus 2px.
  // ---------------------------------------------------------------------------
  static final InputDecorationTheme _inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.canvas,
    border: _pillBorder(const BorderSide(color: AppColors.border)),
    enabledBorder: _pillBorder(const BorderSide(color: AppColors.border)),
    focusedBorder:
        _pillBorder(const BorderSide(color: AppColors.actionFocus, width: 2)),
    errorBorder:
        _pillBorder(const BorderSide(color: AppColors.danger, width: 1.5)),
    focusedErrorBorder:
        _pillBorder(const BorderSide(color: AppColors.danger, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    labelStyle: const TextStyle(color: AppColors.inkMuted),
    hintStyle: TextStyle(color: AppColors.inkMuted.withValues(alpha: 0.7)),
  );

  static OutlineInputBorder _pillBorder(BorderSide side) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: side,
      );

  // ---------------------------------------------------------------------------
  // Chip — cápsula hairline sobre superfície clara.
  // ---------------------------------------------------------------------------
  static const ChipThemeData _chipTheme = ChipThemeData(
    labelStyle: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.224,
    ),
    backgroundColor: AppColors.canvas,
    side: BorderSide(color: AppColors.border),
    shape: StadiumBorder(),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  );

  // ---------------------------------------------------------------------------
  // Tipografia — Inter, cadência "Apple tight". Escada de peso 300/400/600/700
  // (sem 500). Corpo em 17px, títulos em 600 com tracking negativo.
  // ---------------------------------------------------------------------------
  static const TextTheme _textTheme = TextTheme(
    // Headlines / títulos de tela
    displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w600, height: 1.10, letterSpacing: -0.5),
    headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w600, height: 1.12, letterSpacing: -0.374),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.14, letterSpacing: -0.28),
    headlineSmall: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, height: 1.19, letterSpacing: -0.2),

    // Títulos de seção / cards
    titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, letterSpacing: -0.2),
    titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.374),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.224),

    // Corpo — 17px (o "17, não 16" da Apple)
    bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, height: 1.47, letterSpacing: -0.374),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.43, letterSpacing: -0.224),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: -0.12),

    // Labels / badges / captions
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.224),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: -0.12),
    labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: -0.08),
  );
}

/// Cores semânticas do app — linguagem "Apple" (ver `DESIGN-apple.md`).
///
/// **Um único matiz de ação (azul)** em três tons contextuais; nenhum segundo
/// matiz é usado como ação. success/warning/danger existem só para estados de
/// sistema, nunca como "click me". Use estas constantes em vez de `Colors.*`.
abstract class AppColors {
  // Matiz de ação (azul) — três tons contextuais
  static const Color action = Color(0xFF0066CC); // ação em superfície clara
  static const Color actionFocus = Color(0xFF0071E3); // foco / borda de selecionado
  static const Color actionOnDark = Color(0xFF2997FF); // ação em superfície escura

  // Semente do ColorScheme
  static const Color seed = action;

  // Cores por funcionalidade — mesma cor de ação; a função se distingue por
  // ícone + título, não por cor (mantidas para não quebrar call-sites).
  static const Color etiqueta = action;
  static const Color consulta = action;
  static const Color inventario = action;
  static const Color entrada = action;

  // Texto
  static const Color ink = Color(0xFF1D1D1F); // near-black ink
  static const Color inkMuted = Color(0xFF7A7A7A); // secundário / disabled

  // Superfícies
  static const Color canvas = Color(0xFFFFFFFF); // branco
  static const Color surfaceSubtle = Color(0xFFF5F5F7); // parchment
  static const Color dark = Color(0xFF272729); // tiles / splash / header

  // Hairlines / bordas
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFF0F0F0);

  // Estados de sistema (nunca como "ação")
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE65100);
  static const Color danger = Color(0xFFC62828);
  static const Color info = action; // "info" usa o azul de ação
}
