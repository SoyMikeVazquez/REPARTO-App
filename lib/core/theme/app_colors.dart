import 'package:flutter/material.dart';

/// Paleta de colores idéntica a la plataforma web de reparto.mx
class RepartoColors {
  // Brand Colors
  static const Color primaryRed = Color(0xFFE53E3E);
  static const Color primaryRedHover = Color(0xFFC53030);
  static const Color primaryRedLight = Color(0xFFFFF5F5);
  static const Color primaryRedGlow = Color(0x66E53E3E);

  // Dark Theme
  static const Color darkBg = Color(0xFF090A0F);
  static const Color darkBgSecondary = Color(0xFF0D1220);
  static const Color darkCard = Color(0xFF12131A);
  static const Color darkCardElevated = Color(0xFF1A1C26);
  static const Color darkBorder = Color(0x14FFFFFF); // 8% white
  static const Color darkBorderActive = Color(0x4DE53E3E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light Theme
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF8FAFC);
  static const Color lightCardElevated = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Order & Route Statuses
  static const Color statusPending = Color(0xFFF59E0B); // Amber
  static const Color statusPendingBg = Color(0x1AF59E0B);
  static const Color statusPreparing = Color(0xFFFB923C); // Orange
  static const Color statusPreparingBg = Color(0x1AFB923C);
  static const Color statusReady = Color(0xFF8B5CF6); // Violet
  static const Color statusReadyBg = Color(0x1A8B5CF6);
  static const Color statusInRoute = Color(0xFF38BDF8); // Sky Blue
  static const Color statusInRouteBg = Color(0x1A38BDF8);
  static const Color statusDelivered = Color(0xFF10B981); // Emerald Green
  static const Color statusDeliveredBg = Color(0x1A10B981);
  static const Color statusCanceled = Color(0xFFEF4444); // Red
  static const Color statusCanceledBg = Color(0x1AEF4444);

  // Accents & Badges
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color mapLine = Color(0xFFE53E3E);
  static const Color mapWaypoint = Color(0xFF38BDF8);
}
