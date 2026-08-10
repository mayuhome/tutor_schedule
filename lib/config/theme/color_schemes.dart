import 'package:flutter/material.dart';

class AppColors {
  // 主色调
  static const primary = Color(0xFF2563EB);
  static const primaryLight = Color(0xFF60A5FA);
  static const primaryDark = Color(0xFF1D4ED8);

  // 功能色
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // 评分颜色
  static Color ratingColor(int rating) {
    return switch (rating) {
      1 => const Color(0xFFEF4444),
      2 => const Color(0xFFF97316),
      3 => const Color(0xFFF59E0B),
      4 => const Color(0xFF84CC16),
      5 => const Color(0xFF10B981),
      _ => Colors.grey,
    };
  }

  // 科目颜色
  static const subjectColors = [
    Color(0xFF2563EB), // 蓝
    Color(0xFF7C3AED), // 紫
    Color(0xFFEC4899), // 粉
    Color(0xFFF59E0B), // 黄
    Color(0xFF10B981), // 绿
    Color(0xFFEF4444), // 红
    Color(0xFF06B6D4), // 青
    Color(0xFF8B5CF6), // 靛
  ];

  static Color subjectColor(String subject) {
    final index = subject.hashCode.abs() % subjectColors.length;
    return subjectColors[index];
  }
}
