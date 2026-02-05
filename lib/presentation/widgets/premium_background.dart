import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_service.dart';

class PremiumBackground extends StatelessWidget {
  final Widget child;

  const PremiumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeService>(context).isDarkMode;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final orb1 = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final orb2 = isDark ? AppColors.accentDark : AppColors.accentLight;

    return Stack(
      children: [
        // Base Background
        Container(color: bg),

        // Animated Orb 1 (Top Left)
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: orb1.withOpacity(0.15),
              boxShadow: [
                BoxShadow(color: orb1.withOpacity(0.15), blurRadius: 100, spreadRadius: 50),
              ],
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scaleXY(begin: 1.0, end: 1.2, duration: 4.seconds, curve: Curves.easeInOut)
           .move(begin: const Offset(0, 0), end: const Offset(20, 20), duration: 5.seconds),
        ),

        // Animated Orb 2 (Bottom Right)
        Positioned(
          bottom: -100,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: orb2.withOpacity(0.15),
              boxShadow: [
                BoxShadow(color: orb2.withOpacity(0.15), blurRadius: 100, spreadRadius: 50),
              ],
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scaleXY(begin: 1.0, end: 1.3, duration: 6.seconds, curve: Curves.easeInOut)
           .move(begin: const Offset(0, 0), end: const Offset(-30, -30), duration: 7.seconds),
        ),

        // Content Layer
        SafeArea(child: child),
      ],
    );
  }
}
