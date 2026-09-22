import 'package:flutter/material.dart';

/// Design tokens extracted directly from the Caffora Figma file
/// (mobile-light and mobile-dark frames). Keep these in sync with
/// the web app's `src/assets` tokens and the backend's seed palette —
/// all three clients should look identical.
class AppColors {
  AppColors._();

  // ---- Light theme ----
  static const Color lightBackground = Color(0xFFFAF6F0);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSearchFill = Color(0xFFF7F5F0);
  static const Color lightBorder = Color(0xFFEAE3D9);
  static const Color lightTextPrimary = Color(0xFF2E1E12);
  static const Color lightTextSecondary = Color(0xFF8C7A6B);
  static const Color lightAccent = Color(0xFFC85C40);
  static const Color lightAccentTint = Color(0xFFF5DFD9);
  static const Color lightSuccess = Color(0xFF498500);
  static const Color lightSuccessTint = Color(0xFFEAF2DF);
  static const Color lightWarning = Color(0xFFB58900);
  static const Color lightWarningTint = Color(0xFFFAF3DB);
  static const Color lightInfo = Color(0xFF3182CE);
  static const Color lightInfoTint = Color(0xFFEBF8FF);
  static const Color lightNeutralTint = Color(0xFFF7F5F0);

  // ---- Dark theme ----
  static const Color darkBackground = Color(0xFF120A05);
  static const Color darkSurface = Color(0xFF1E140E);
  static const Color darkBorder = Color(0xFF33251D);
  static const Color darkTextPrimary = Color(0xFFF7EFE9);
  static const Color darkTextSecondary = Color(0xFFB09F92);
  static const Color darkAccent = Color(0xFFD66C4D);
  // Dark-mode status/tint colors were not present in the fetched dark
  // frame; derived to preserve the same hue/role relationship as light
  // mode against the darker surface.
  static const Color darkAccentTint = Color(0xFF3A241D);
  static const Color darkSuccess = Color(0xFF7BC142);
  static const Color darkSuccessTint = Color(0xFF1E2A12);
  static const Color darkWarning = Color(0xFFE0B23C);
  static const Color darkWarningTint = Color(0xFF2E2712);
  static const Color darkInfo = Color(0xFF63B3ED);
  static const Color darkInfoTint = Color(0xFF122430);
  static const Color darkNeutralTint = Color(0xFF241811);

  // ---- Shared / brand-invariant ----
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}
