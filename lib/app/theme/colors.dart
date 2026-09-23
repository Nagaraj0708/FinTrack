import 'package:flutter/material.dart';

class AppColors {
  // ── Primary Palette ──────────────────────────────────────────────────────
  /// Signature premium forest‑green used on hero cards & primary CTAs
  static const Color primary = Color(0xFF1C4532);
  static const Color primaryMid = Color(0xFF276749);
  static const Color primaryLight = Color(0xFF48BB78);
  static const Color primaryGlow = Color(0xFF9AE6B4);

  // ── Accent ───────────────────────────────────────────────────────────────
  static const Color accent = Color(0xFF00C896); // Vivid mint for highlights
  static const Color accentGold = Color(0xFFF6C90E); // Premium badge gold

  // ── Background / Surface ─────────────────────────────────────────────────
  static const Color background = Color(0xFFF7F8FA); // Warm off-white canvas
  static const Color surface = Color(0xFFFFFFFF);    // Pure white cards
  static const Color surfaceElevated = Color(0xFFF0F4F0); // Tinted alt cards

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981); // Emerald income
  static const Color error   = Color(0xFFEF4444); // Vivid expense red
  static const Color warning = Color(0xFFF59E0B);

  // ── Typography ───────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F172A); // Slate-900
  static const Color textSecondary = Color(0xFF64748B); // Slate-500
  static const Color textMuted     = Color(0xFFCBD5E1); // Slate-300

  // ── Dark Mode ────────────────────────────────────────────────────────────
  static const Color backgroundDark       = Color(0xFF0A0F0D);
  static const Color surfaceDark          = Color(0xFF141A17);
  static const Color surfaceElevatedDark  = Color(0xFF1E2922);
  static const Color textPrimaryDark      = Color(0xFFF1F5F9);
  static const Color textSecondaryDark    = Color(0xFF94A3B8);

  // ── Compatibility aliases ─────────────────────────────────────────────────
  static const Color income  = success;
  static const Color expense = error;
  static const Color danger  = error;
  static const Color cardLight = surface;
  static const Color cardDark  = surfaceDark;
  static const Color textAccent = primaryLight;
}
