import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'accent_colors.dart';
import 'app_palette.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(
    scheme:
        ColorScheme.fromSeed(
          seedColor: AppPalette.iris,
          brightness: Brightness.light,
        ).copyWith(
          surface: AppPalette.surfaceLight,
          surfaceContainerLowest: AppPalette.surfaceLight,
          surfaceContainerLow: AppPalette.canvasLight,
          outlineVariant: AppPalette.outlineLight,
          onSurface: AppPalette.ink,
          onSurfaceVariant: AppPalette.inkMuted,
        ),
    canvas: AppPalette.canvasLight,
    accents: AccentColors.light(),
    overlay: SystemUiOverlayStyle.dark,
  );

  static ThemeData dark() => _build(
    scheme:
        ColorScheme.fromSeed(
          seedColor: AppPalette.iris,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppPalette.irisDark,
          surface: AppPalette.surfaceDark,
          surfaceContainerLowest: AppPalette.canvasDark,
          surfaceContainerLow: AppPalette.surfaceDark,
          outlineVariant: AppPalette.outlineDark,
        ),
    canvas: AppPalette.canvasDark,
    accents: AccentColors.dark(),
    overlay: SystemUiOverlayStyle.light,
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required Color canvas,
    required AccentColors accents,
    required SystemUiOverlayStyle overlay,
  }) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final text = _textTheme(base.textTheme, scheme);

    return base.copyWith(
      scaffoldBackgroundColor: canvas,
      textTheme: text,
      extensions: [accents],
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        systemOverlayStyle: overlay.copyWith(
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.lg,
        ),
        border: _inputBorder(scheme.outlineVariant),
        enabledBorder: _inputBorder(scheme.outlineVariant),
        focusedBorder: _inputBorder(scheme.primary, width: 1.6),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 1.6),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        helperStyle: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: text.labelLarge,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: text.labelLarge),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        labelStyle: text.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: Insets.sm),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(Insets.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(text.labelSmall),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearMinHeight: 3,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    return base
        .copyWith(
          displaySmall: base.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            fontSize: 20,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          bodyMedium: base.bodyMedium?.copyWith(height: 1.45),
          bodySmall: base.bodySmall?.copyWith(height: 1.4),
          labelLarge: base.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }
}
