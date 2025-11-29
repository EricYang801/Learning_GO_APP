import 'package:flutter/material.dart';

/// 應用程式顏色常數
class AppColors {
  AppColors._(); // 防止實例化

  // iOS 主要藍色
  static const accent = Color(0xFF007AFF);

  // 主色系
  static const primary = Color(0xFFFFD54F); // soft yellow

  // 柔和背景色
  static const softBlue = Color(0xFFD9ECFF);
  static const softCyan = Color(0xFFE4F7F4);
  static const softOrange = Color(0xFFFFEFE2);
  static const softGray = Color(0xFFF0F1F3);
  static const softRed = Color(0xFFFFEBEE);
  static const lightBlue = Color(0xFFD6E6FF);

  // 功能色
  static const green = Color(0xFF1DB954);
  static const gold = Color(0xFFFFC107);
  static const error = Color(0xFFE53935);

  // 文字色
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textHint = Color(0xFFBDBDBD);
}

/// 共用的輸入框圓角
const double kFieldRadius = 12;

/// 共用輸入框樣式
InputDecoration inputDecoration({
  String? hint,
  EdgeInsetsGeometry? contentPadding,
  String? errorText,
}) {
  final base = OutlineInputBorder(
    borderRadius: BorderRadius.circular(kFieldRadius),
    borderSide: BorderSide(color: Colors.grey[400]!),
  );
  final focused = OutlineInputBorder(
    borderRadius: BorderRadius.circular(kFieldRadius),
    borderSide: BorderSide(color: Colors.grey[500]!, width: 1.2),
  );
  return InputDecoration(
    hintText: hint,
    errorText: errorText,
    filled: true,
    fillColor: Colors.grey[100],
    isDense: true,
    contentPadding:
        contentPadding ??
        const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    enabledBorder: base,
    focusedBorder: focused,
    border: base,
  );
}
