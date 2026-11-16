import 'package:flutter/material.dart';

/// 앱 전체 색. 의뢰인 피그마(알음알음 앱 디자인_ver1)에서 뽑은 값이다.
/// 색을 바꿀 때는 이 파일만 고치면 모든 화면에 반영된다.
abstract final class AppColors {
  static const pri = Color(0xFF2B50D9);
  static const priLight = Color(0xFFEEF2FF);
  static const priMid = Color(0xFFDCE4FF);

  static const ink = Color(0xFF151A23);
  static const ink2 = Color(0xFF4B5563);
  static const ink3 = Color(0xFF6B7280);
  static const ink4 = Color(0xFF9CA3AF);

  static const line = Color(0xFFE3E6EB);
  static const line2 = Color(0xFFD7DBE2);
  static const fill = Color(0xFFF1F3F6);
  static const bg = Color(0xFFF5F6F8);
  static const paper = Colors.white;

  static const amber = Color(0xFFFFC24D);
  static const amberLight = Color(0xFFFFF1D6);
  static const amberText = Color(0xFF8A4B00);
  static const star = Color(0xFFE08A00);

  static const green = Color(0xFF1C7C4A);
  static const greenLight = Color(0xFFE6F4EC);
  static const greenDark = Color(0xFF0F5C46);

  static const red = Color(0xFFC8361D);
  static const redLight = Color(0xFFFDECEA);

  static const purple = Color(0xFF6A2C91);
  static const purpleLight = Color(0xFFEBDCF3);
}

/// 둥근 모서리. 피그마 기준 카드 18, 입력칸·버튼 12~14.
abstract final class AppRadius {
  static const card = 18.0;
  static const button = 14.0;
  static const input = 12.0;
}

ThemeData buildAppTheme() {
  const font = 'Pretendard';
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: font,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.pri, primary: AppColors.pri, surface: AppColors.paper),
    scaffoldBackgroundColor: AppColors.paper,
    splashFactory: NoSplash.splashFactory,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink, fontFamily: font),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      titleTextStyle: TextStyle(fontFamily: font, fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: AppColors.paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      hintStyle: const TextStyle(color: AppColors.ink4, fontSize: 16),
      border: _outline(AppColors.line2),
      enabledBorder: _outline(AppColors.line2),
      focusedBorder: _outline(AppColors.pri),
      errorBorder: _outline(AppColors.red),
      focusedErrorBorder: _outline(AppColors.red),
      errorStyle: const TextStyle(color: AppColors.red, fontSize: 13, fontWeight: FontWeight.w600),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.ink,
      behavior: SnackBarBehavior.floating,
      contentTextStyle: TextStyle(fontFamily: font, fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.white),
    ),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: AppColors.paper, surfaceTintColor: Colors.transparent, showDragHandle: true),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.paper, surfaceTintColor: Colors.transparent),
    datePickerTheme: const DatePickerThemeData(backgroundColor: AppColors.paper, surfaceTintColor: Colors.transparent, headerForegroundColor: AppColors.ink),
  );
}

OutlineInputBorder _outline(Color c) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(AppRadius.input),
  borderSide: BorderSide(color: c, width: 1.5),
);

/// 화면 제목 · 섹션 제목 · 본문 크기. 피그마 1배 기준.
abstract final class AppText {
  static const h1 = TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.3);
  static const h2 = TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.5);
  static const title = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.4);
  static const body = TextStyle(fontSize: 15, height: 1.55);
  static const lead = TextStyle(fontSize: 15, color: AppColors.ink2, height: 1.55);
  static const label = TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700);
  static const small = TextStyle(fontSize: 13, color: AppColors.ink3);
}
