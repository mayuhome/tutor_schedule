import 'package:flutter/material.dart';

// iOS System Colors
class IosColors {
  static Color systemBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? const Color(0xFFF2F2F7)
          : const Color(0xFF000000);

  static Color secondaryBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF1C1C1E);

  static Color tertiaryBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? const Color(0xFFF2F2F7)
          : const Color(0xFF2C2C2E);

  static Color separator(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? const Color(0xFFC6C6C8).withValues(alpha: 0.6)
          : const Color(0xFF38383A);

  static Color label(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? const Color(0xFF000000)
          : const Color(0xFFFFFFFF);

  static Color secondaryLabel(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? const Color(0xFF3C3C43).withValues(alpha: 0.6)
          : const Color(0xFFEBEBF5).withValues(alpha: 0.6);

  static Color tertiaryLabel(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? const Color(0xFF3C3C43).withValues(alpha: 0.3)
          : const Color(0xFFEBEBF5).withValues(alpha: 0.3);

  // iOS Tint Colors
  static const systemBlue = Color(0xFF007AFF);
  static const systemGreen = Color(0xFF34C759);
  static const systemOrange = Color(0xFFFF9500);
  static const systemRed = Color(0xFFFF3B30);
  static const systemPurple = Color(0xFFAF52DE);
  static const systemPink = Color(0xFFFF2D55);
  static const systemTeal = Color(0xFF5AC8FA);
  static const systemIndigo = Color(0xFF5856D6);
  static const systemYellow = Color(0xFFFFCC00);
  static const systemGray = Color(0xFF8E8E93);

  static const List<Color> tints = [
    systemBlue,
    systemGreen,
    systemOrange,
    systemRed,
    systemPurple,
    systemPink,
    systemTeal,
    systemIndigo,
  ];
}

class AppColors {
  static const primary = IosColors.systemBlue;
  static const primaryLight = Color(0xFF5AC8FA);
  static const primaryDark = Color(0xFF0055CC);

  static const success = IosColors.systemGreen;
  static const warning = IosColors.systemOrange;
  static const error = IosColors.systemRed;
  static const info = IosColors.systemTeal;

  static Color ratingColor(int rating) {
    return switch (rating) {
      1 => IosColors.systemRed,
      2 => IosColors.systemOrange,
      3 => IosColors.systemYellow,
      4 => IosColors.systemGreen,
      5 => const Color(0xFF30B050),
      _ => IosColors.systemGray,
    };
  }

  static const subjectColors = [
    IosColors.systemBlue,
    IosColors.systemPurple,
    IosColors.systemPink,
    IosColors.systemOrange,
    IosColors.systemGreen,
    IosColors.systemRed,
    IosColors.systemTeal,
    IosColors.systemIndigo,
  ];

  static Color subjectColor(String subject) {
    final index = subject.hashCode.abs() % subjectColors.length;
    return subjectColors[index];
  }
}
