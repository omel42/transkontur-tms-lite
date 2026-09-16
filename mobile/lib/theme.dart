import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF071521);
  static const inkSoft = Color(0xFF152633);
  static const acid = Color(0xFFC8FF3D);
  static const cyan = Color(0xFF70E7EC);
  static const paper = Color(0xFFF4F6F2);
  static const line = Color(0xFFDCE3DE);
  static const muted = Color(0xFF77838B);
  static const green = Color(0xFF197B54);
  static const orange = Color(0xFFF29A45);
  static const blue = Color(0xFF566BD7);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.acid,
    primary: AppColors.ink,
    secondary: AppColors.acid,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.paper,
    fontFamily: 'Arial',
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: 36,
        height: 1.03,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        color: AppColors.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 25,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: -.7,
        color: AppColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -.25,
        color: AppColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.42,
        color: AppColors.inkSoft,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.38,
        color: AppColors.inkSoft,
      ),
      bodySmall: TextStyle(fontSize: 12, height: 1.35, color: AppColors.muted),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
      hintStyle: const TextStyle(color: Color(0xFFA0AAA8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

String money(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(' ');
    out.write(digits[i]);
  }
  return '${negative ? '−' : ''}$out ₽';
}

String weight(double value) =>
    value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
