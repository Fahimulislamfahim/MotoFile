import 'dart:ui';
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
    
    return Stack(
      children: [
        // Base Background
        Container(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA),
        ),
        
        // Animated Blob 1 (Top Right)
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryLight.withOpacity(0.25),
                  AppColors.primaryLight.withOpacity(0.0),
                ],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(1,1), end: const Offset(1.3,1.3), duration: 10.seconds)
           .move(begin: const Offset(0, 0), end: const Offset(-30, 30), duration: 8.seconds),
        ),
        
        // Animated Blob 2 (Bottom Left)
        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accentLight.withOpacity(0.2),
                  AppColors.accentLight.withOpacity(0.0),
                ],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .moveY(begin: 0, end: 50, duration: 8.seconds)
           .scale(begin: const Offset(1,1), end: const Offset(1.2,1.2), duration: 7.seconds),
        ),

        // Animated Blob 3 (Center - Subtle)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          left: MediaQuery.of(context).size.width * 0.2,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? Colors.purple : Colors.blue).withOpacity(0.15),
                  (isDark ? Colors.purple : Colors.blue).withOpacity(0.0),
                ],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .fadeIn(duration: 2.seconds)
           .moveX(begin: 0, end: 40, duration: 6.seconds),
        ),

        // Glassmorphism Blur (Removed for Performance)
        // Now using RadialGradients to simulate blur cleanly.

        // Content
        SafeArea(child: child),
      ],
    );
  }
}
