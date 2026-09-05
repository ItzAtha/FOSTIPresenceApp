import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app_constants.dart' show AppColors, AppSizes;

class LightMode {
  static ThemeData initialize() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      canvasColor: AppColors.bgLight,
      scaffoldBackgroundColor: AppColors.bgLight,
      dividerColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      iconTheme: const IconThemeData(color: AppColors.iconLight),
      radioTheme: const RadioThemeData(fillColor: WidgetStatePropertyAll(Colors.grey)),
      textTheme: (() {
        final textBase = Typography(platform: TargetPlatform.android).black
            .apply(bodyColor: AppColors.textLight, displayColor: AppColors.textLight);

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
        selectionColor: AppColors.secondary.withValues(alpha: 0.3),
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
        hintStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.8)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondary.withValues(alpha: 0.6), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondary.withValues(alpha: 0.8), width: 1.5),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.8), width: 1.5),
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondary.withValues(alpha: 0.8);
          }
          return null;
        }),
      ),
      cardTheme: const CardThemeData(
        elevation: 2.0,
        color: AppColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15.0))),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(6.0),
        constraints: const BoxConstraints(minHeight: 54.0),
        backgroundColor: const WidgetStatePropertyAll(AppColors.cardLight),
        hintStyle: WidgetStatePropertyAll(
          TextStyle(color: AppColors.textLight.withValues(alpha: 0.8)),
        ),
        textStyle: const WidgetStatePropertyAll(TextStyle(color: AppColors.textLight)),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStatePropertyAll(8.0),
          backgroundColor: WidgetStatePropertyAll(AppColors.cardLight),
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
      drawerTheme: const DrawerThemeData(elevation: 4.0, backgroundColor: AppColors.bgLight),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 8.0,
        showDragHandle: true,
        modalBackgroundColor: AppColors.bgLight,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.cardLight,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: AppColors.textLight,
        dayStyle: const TextStyle(color: AppColors.textLight),
        dayOverlayColor: WidgetStatePropertyAll(AppColors.secondary.withValues(alpha: 0.5)),
        todayBorder: const BorderSide(color: AppColors.secondary, width: 2.0),
        todayBackgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondary;
          }
          return null;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondary;
          }
          return null;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondary;
          }
          return null;
        }),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.secondary),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.secondary),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.cardLight,
        helpTextStyle: const TextStyle(color: AppColors.textLight, fontSize: 16.0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.largeRounded)),
        ),
        hourMinuteColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.secondary.withValues(alpha: 0.6)
              : const Color(0xFFD3D3CF),
        ),
        hourMinuteTextColor: AppColors.textLight,
        hourMinuteShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.mediumRounded)),
        ),
        dialBackgroundColor: const Color(0xFFD3D3CF),
        dialHandColor: AppColors.secondary.withValues(alpha: 0.9),
        dialTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.textDark;
          }
          return AppColors.textLight;
        }),
        entryModeIconColor: AppColors.secondary,
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.secondary),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.secondary),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(
            backgroundColor: AppColors.bgLight,
          ),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(
            backgroundColor: AppColors.bgLight,
          ),
        },
      ),
    );
  }
}
