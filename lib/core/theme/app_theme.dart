import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppTheme {
  static const primary = Color(0xFF155EEF);
  static const secondary = Color(0xFF087650);
  static const accent = Color(0xFF55B7FF);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFA43842);
  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF14243A)
      : const Color(0xFFEEF4FF);
  static Color warningText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFFFDE98)
      : const Color(0xFF865017);
  static Color dangerText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFFFC1C9)
      : danger;
  static Color warningSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF59431E)
      : const Color(0xFFFFF0D8);
  static Color dangerSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF623344)
      : const Color(0xFFFBE9E8);
  static TextStyle? pageTitle(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontSize: MediaQuery.textScalerOf(context).scale(14) > 21 ? 23 : 31,
      );
  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);
  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
        ).copyWith(
          primary: dark ? accent : primary,
          onPrimary: dark ? const Color(0xFF072744) : Colors.white,
          primaryContainer: dark
              ? const Color(0xFF204F7D)
              : const Color(0xFFDCEBFF),
          onPrimaryContainer: dark
              ? const Color(0xFFF0F7FF)
              : const Color(0xFF104DB5),
          secondary: dark ? const Color(0xFF54E2AD) : secondary,
          onSecondary: dark ? const Color(0xFF073B2B) : Colors.white,
          secondaryContainer: dark
              ? const Color(0xFF1B5145)
              : const Color(0xFFDCF8EA),
          onSecondaryContainer: dark
              ? const Color(0xFFDEFFF1)
              : const Color(0xFF075D42),
          surface: dark ? const Color(0xFF263C57) : Colors.white,
          surfaceDim: dark ? const Color(0xFF14243A) : const Color(0xFFE6EFFD),
          surfaceBright: dark ? const Color(0xFF344F70) : Colors.white,
          surfaceContainerLowest: dark ? const Color(0xFF0C192B) : Colors.white,
          surfaceContainerLow: dark
              ? const Color(0xFF20334D)
              : const Color(0xFFF8FAFF),
          surfaceContainer: dark
              ? const Color(0xFF263C57)
              : const Color(0xFFEEF4FF),
          surfaceContainerHigh: dark
              ? const Color(0xFF2D4665)
              : const Color(0xFFEBF2FD),
          surfaceContainerHighest: dark
              ? const Color(0xFF344F70)
              : const Color(0xFFE6EFFD),
          surfaceTint: Colors.transparent,
          onSurface: dark ? const Color(0xFFFFFFFF) : const Color(0xFF12243D),
          onSurfaceVariant: dark
              ? const Color(0xFFD9E8FC)
              : const Color(0xFF415877),
          outline: dark ? const Color(0xFF93AED1) : const Color(0xFF687E9D),
          outlineVariant: dark
              ? const Color(0xFF56789F)
              : const Color(0xFFBCD0EB),
          inverseSurface: dark
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF12243D),
          onInverseSurface: dark
              ? const Color(0xFF12243D)
              : const Color(0xFFFFFFFF),
          inversePrimary: dark ? primary : accent,
          error: dark ? const Color(0xFFFFC1C9) : danger,
          onError: dark ? const Color(0xFF623344) : Colors.white,
          errorContainer: dark
              ? const Color(0xFF623344)
              : const Color(0xFFFBE9E8),
          onErrorContainer: dark ? const Color(0xFFFFC1C9) : danger,
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'DM Sans',
    );
    final text = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontSize: 31,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
        height: 1.16,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -.6,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -.35,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -.2,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.4),
      bodySmall: base.textTheme.bodySmall?.copyWith(height: 1.4),
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: scheme.surface,
      textTheme: text,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(scheme.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
    );
  }
}
