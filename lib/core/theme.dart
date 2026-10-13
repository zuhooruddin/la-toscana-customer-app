import 'package:flutter/material.dart';

/// Brand colours, matching the website (la-toscana-website/src/app/globals.css + reference-design.css).
/// White on tomato meets WCAG AA.
class Brand {
  static const tomato = Color(0xFFD41423);
  static const tomatoDark = Color(0xFFB9101D);
  static const tomatoDeep = Color(0xFF7A1F1A);
  static const tomatoSoft = Color(0xFFFBECEB);
  static const basil = Color(0xFF2F8F4E);
  static const basilDark = Color(0xFF226B3A);
  static const basilSoft = Color(0xFFE6F3EA);
  static const gold = Color(0xFFC9A24B);
  static const cream = Color(0xFFFAF7F1);
  static const cream2 = Color(0xFFF4ECE0);
  static const surfaceWarm = Color(0xFFFFFCF7);
  static const charcoal = Color(0xFF1E1B18);
  static const muted = Color(0xFF706B64);
  static const hint = Color(0xFF8C8279);
  static const border = Color(0xFFECE2D3);
  static const divider = Color(0xFFF1E8DB);
  static const warning = Color(0xFF8A5A00);
  static const warningSoft = Color(0xFFFFF4DC);
  static const green = Color(0xFF133A2A);

  static const display = 'Playfair';
  static const body = 'Manrope';

  /// Soft warm shadow used by cards (website --shadow).
  static const shadow = [
    BoxShadow(color: Color(0x082A1511), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x0A2A1511), blurRadius: 16, offset: Offset(0, 6)),
  ];
  static const shadowPrimary = [
    BoxShadow(color: Color(0x47D41423), blurRadius: 16, offset: Offset(0, 6)),
  ];

  /// Website hero gradient (--hero-gradient).
  static const heroGradient = LinearGradient(
    colors: [Color(0xFF241512), Color(0xFF5E1C17), tomato],
    stops: [0, 0.45, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Section heading in the display face.
  static const h1 = TextStyle(
    fontFamily: display,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.12,
    color: charcoal,
  );
  static const h2 = TextStyle(
    fontFamily: display,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.15,
    color: charcoal,
  );
  static const h3 = TextStyle(
    fontFamily: display,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: charcoal,
  );
  static const price = TextStyle(
    color: tomato,
    fontWeight: FontWeight.w800,
    fontSize: 15,
  );
}

ThemeData buildTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Brand.tomato,
        primary: Brand.tomato,
        onPrimary: Colors.white,
        secondary: Brand.basil,
        surface: Colors.white,
        onSurface: Brand.charcoal,
        error: Brand.tomatoDark,
      ).copyWith(
        outline: Brand.border,
        outlineVariant: Brand.divider,
        surfaceTint: Colors.transparent,
      );
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: Brand.body,
  );
  return base.copyWith(
    scaffoldBackgroundColor: Brand.cream,
    textTheme: base.textTheme
        .apply(bodyColor: Brand.charcoal, displayColor: Brand.charcoal)
        .copyWith(
          headlineLarge: Brand.h1.copyWith(fontSize: 32),
          headlineMedium: Brand.h1,
          headlineSmall: Brand.h2,
          titleLarge: Brand.h2.copyWith(fontSize: 21),
          bodyLarge: const TextStyle(fontFamily: Brand.body, fontSize: 16, height: 1.5, color: Brand.charcoal),
          bodyMedium: const TextStyle(fontFamily: Brand.body, fontSize: 14, height: 1.45, color: Brand.charcoal),
          bodySmall: const TextStyle(fontFamily: Brand.body, fontSize: 12, height: 1.4, color: Brand.charcoal),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Brand.cream,
      foregroundColor: Brand.charcoal,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      titleSpacing: 20,
      shadowColor: Color(0x33663B10),
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: Brand.display,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Brand.charcoal,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Brand.border),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Brand.divider, thickness: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Brand.tomato,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE9E1D7),
        disabledForegroundColor: Brand.hint,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: rounded,
        textStyle: const TextStyle(
          fontFamily: Brand.body,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Brand.tomatoDark,
        backgroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        side: const BorderSide(color: Brand.border),
        shape: rounded,
        textStyle: const TextStyle(
          fontFamily: Brand.body,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Brand.tomatoDark,
        textStyle: const TextStyle(
          fontFamily: Brand.body,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: Brand.charcoal,
        minimumSize: const Size(48, 48),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: Brand.hint),
      labelStyle: const TextStyle(color: Brand.muted),
      floatingLabelStyle: const TextStyle(
        color: Brand.tomatoDark,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: Brand.muted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Brand.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Brand.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Brand.tomato, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Brand.tomatoDark),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: Brand.tomato,
      side: const BorderSide(color: Brand.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: const TextStyle(
        fontFamily: Brand.body,
        fontWeight: FontWeight.w600,
        color: Brand.charcoal,
      ),
      secondaryLabelStyle: const TextStyle(
        fontFamily: Brand.body,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Brand.tomato : Colors.white,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? Colors.white : Brand.charcoal,
        ),
        iconColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : Brand.muted,
        ),
        side: const WidgetStatePropertyAll(BorderSide(color: Brand.border)),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontFamily: Brand.body, fontWeight: FontWeight.w700),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(48, 46)),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Brand.tomato : null,
      ),
      side: const BorderSide(color: Brand.hint, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Brand.tomato : Brand.hint,
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Brand.tomato : null,
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Brand.muted,
      titleTextStyle: TextStyle(
        fontFamily: Brand.body,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Brand.charcoal,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Brand.tomato,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Brand.charcoal,
      contentTextStyle: const TextStyle(
        fontFamily: Brand.body,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titleTextStyle: Brand.h2,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: Brand.tomatoSoft,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? Brand.tomato : Brand.muted,
          size: 24,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: Brand.body,
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          color: s.contains(WidgetState.selected) ? Brand.tomato : Brand.muted,
        ),
      ),
    ),
    badgeTheme: const BadgeThemeData(
      backgroundColor: Brand.tomato,
      textColor: Colors.white,
    ),
  );
}
