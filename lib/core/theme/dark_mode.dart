import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../app_constants.dart' show AppColors, AppSizes;

class DarkMode {
  static ThemeData initialize() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      canvasColor: AppColors.bgDark,
      scaffoldBackgroundColor: AppColors.bgDark,
      dividerColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      iconTheme: const IconThemeData(color: AppColors.iconDark),
      radioTheme: const RadioThemeData(fillColor: WidgetStatePropertyAll(Color(0x80F5F6FA))),
      textTheme: (() {
        final textBase = Typography(
          platform: TargetPlatform.android,
        ).black.apply(bodyColor: AppColors.textDark, displayColor: AppColors.textDark);

        return textBase.copyWith(
          displaySmall: textBase.displaySmall?.copyWith(
            fontSize: AppSizes.xxlTextSize,
            fontWeight: FontWeight.bold,
          ),
          titleSmall: textBase.titleSmall?.copyWith(
            fontSize: AppSizes.mlTextSize,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: textBase.titleMedium?.copyWith(
            fontSize: AppSizes.lTextSize,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: textBase.titleLarge?.copyWith(
            fontSize: AppSizes.xlTextSize,
            fontWeight: FontWeight.bold,
          ),
          labelLarge: textBase.labelLarge?.copyWith(
            fontSize: AppSizes.mTextSize,
            fontWeight: FontWeight.normal,
          ),
          labelMedium: textBase.labelMedium?.copyWith(
            fontSize: AppSizes.smTextSize,
            fontWeight: FontWeight.normal,
          ),
          labelSmall: textBase.labelSmall?.copyWith(
            fontSize: AppSizes.sTextSize,
            fontWeight: FontWeight.normal,
          ),
        );
      }()),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.secondary,
        selectionColor: AppColors.secondary.withValues(alpha: 0.4),
        selectionHandleColor: AppColors.secondary,
      ),
      elevatedButtonTheme: const ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(200.0, 40.0)),
          backgroundColor: WidgetStatePropertyAll(AppColors.primary),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(180.0, 40.0)),
          overlayColor: WidgetStatePropertyAll(AppColors.secondary.withValues(alpha: 0.1)),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.secondary)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        border: const OutlineInputBorder(),
        hintStyle: TextStyle(color: AppColors.textDark.withValues(alpha: 0.8)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondary.withValues(alpha: 0.6), width: 1.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondary, width: 1.5),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: AppColors.secondary, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondary;
          }
          return null;
        }),
      ),
      cardTheme: const CardThemeData(
        elevation: 4.0,
        color: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15.0))),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(8.0),
        constraints: const BoxConstraints(minHeight: 54.0),
        backgroundColor: const WidgetStatePropertyAll(AppColors.cardDark),
        hintStyle: WidgetStatePropertyAll(
          TextStyle(color: AppColors.textDark.withValues(alpha: 0.8)),
        ),
        textStyle: const WidgetStatePropertyAll(TextStyle(color: AppColors.textDark)),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStatePropertyAll(16.0),
          backgroundColor: WidgetStatePropertyAll(AppColors.cardDark),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        elevation: 4.0,
        selectedColor: AppColors.secondary,
        backgroundColor: AppColors.secondary.withValues(alpha: 0.5),
        checkmarkColor: Colors.white,
        side: const BorderSide(color: Color(0xFF006462), width: 1.5),
      ),
      drawerTheme: const DrawerThemeData(elevation: 8.0, backgroundColor: AppColors.bgDark),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 12.0,
        showDragHandle: true,
        modalBackgroundColor: AppColors.bgDark,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(
            backgroundColor: AppColors.bgDark,
          ),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(backgroundColor: AppColors.bgDark),
        },
      ),
    );
  }
}
