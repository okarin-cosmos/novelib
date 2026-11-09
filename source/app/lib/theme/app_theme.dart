import 'package:flutter/material.dart';

abstract final class AppColors {
  static const accent = Color(0xFF42BFAE);
  static const accentBlue = Color(0xFF438FD0);
  static const accentWarm = Color(0xFFE0A82E);
  static const danger = Color(0xFFD85F70);
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.canvas,
    required this.sidebar,
    required this.panel,
    required this.panelLight,
    required this.selected,
    required this.chip,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.textFaint,
  });

  final Color canvas;
  final Color sidebar;
  final Color panel;
  final Color panelLight;
  final Color selected;
  final Color chip;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color textFaint;

  static const dark = AppPalette(
    canvas: Color(0xFF0D121B),
    sidebar: Color(0xFF111824),
    panel: Color(0xFF161F2D),
    panelLight: Color(0xFF1D293A),
    selected: Color(0xFF243248),
    chip: Color(0xFF1A2636),
    border: Color(0xFF2A3749),
    text: Color(0xFFF0F4F7),
    textMuted: Color(0xFF9BAABD),
    textFaint: Color(0xFF68788C),
  );

  static const light = AppPalette(
    canvas: Color(0xFFF4F7FB),
    sidebar: Color(0xFFEAF0F7),
    panel: Color(0xFFFFFFFF),
    panelLight: Color(0xFFF0F4F9),
    selected: Color(0xFFD9E7F5),
    chip: Color(0xFFE2EAF3),
    border: Color(0xFFC7D3E1),
    text: Color(0xFF172230),
    textMuted: Color(0xFF52657A),
    textFaint: Color(0xFF74869A),
  );

  @override
  AppPalette copyWith({
    Color? canvas,
    Color? sidebar,
    Color? panel,
    Color? panelLight,
    Color? selected,
    Color? chip,
    Color? border,
    Color? text,
    Color? textMuted,
    Color? textFaint,
  }) => AppPalette(
    canvas: canvas ?? this.canvas,
    sidebar: sidebar ?? this.sidebar,
    panel: panel ?? this.panel,
    panelLight: panelLight ?? this.panelLight,
    selected: selected ?? this.selected,
    chip: chip ?? this.chip,
    border: border ?? this.border,
    text: text ?? this.text,
    textMuted: textMuted ?? this.textMuted,
    textFaint: textFaint ?? this.textFaint,
  );

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panelLight: Color.lerp(panelLight, other.panelLight, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get appColors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}

abstract final class AppTheme {
  static ThemeData get dark => _create(Brightness.dark, AppPalette.dark);
  static ThemeData get light => _create(Brightness.light, AppPalette.light);

  static ThemeData _create(Brightness brightness, AppPalette palette) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: brightness,
      surface: palette.panel,
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.canvas,
      focusColor: AppColors.accent.withValues(alpha: .18),
      fontFamilyFallback: const ['Yu Gothic UI', 'Meiryo UI', 'Segoe UI'],
      extensions: [palette],
      textTheme: TextTheme(
        headlineLarge: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(fontSize: 13, color: palette.text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.panel,
        hintStyle: TextStyle(color: palette.textFaint, fontSize: 12),
        prefixIconColor: palette.textMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.panelLight,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: TextStyle(color: palette.text, fontSize: 11),
      ),
      dividerColor: palette.border,
    );
  }
}
