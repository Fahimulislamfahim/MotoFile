import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart'; // Assuming google_fonts is available based on implementation plan/common usage, if not I'll stick to standard theme. Pubspec showed google_fonts.
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_service.dart';
import '../widgets/glass_card.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late ConfettiController _confettiController;
  int _versionTapCount = 0;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _handleVersionTap() {
    setState(() {
      _versionTapCount++;
    });
    if (_versionTapCount == 7) {
      _confettiController.play();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎉 You found the easter egg! You are awesome! 🎉'),
          backgroundColor: AppColors.primaryLight,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
      _versionTapCount = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeService>(context).isDarkMode;
    final primaryColor = AppColors.primaryLight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. Premium Animated Background
          const _AnimatedBackground(),

          // 2. Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Profile Image with Breathing Glow
                    _buildProfileSection(context, isDark),
                    
                    const SizedBox(height: 40),

                    // Developer Card (Expandable)
                    _buildDeveloperCard(context, isDark),

                    const SizedBox(height: 24),

                    // Tech Stack
                    _buildTechStack(context, isDark),

                    const SizedBox(height: 40),

                    // App Info & Easter Egg
                    GestureDetector(
                      onTap: _handleVersionTap,
                      child: Column(
                        children: [
                          Text(
                            'MotoFile',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: isDark ? Colors.white : const Color(0xFF2D3436),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Version 1.0.0 (Build 1)',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '© 2026 Crafted with ❤️',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 800.ms),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // 3. Confetti Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, bool isDark) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow layer
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withOpacity(0.4),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .blur(begin: const Offset(20, 20), end: const Offset(40, 40), duration: 2.seconds)
             .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 2.seconds),

            // Image container
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/developer.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, _, __) => Container(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
                    child: Icon(Icons.person_rounded, size: 60, color: AppColors.primaryLight),
                  ),
                ),
              ),
            ),
          ],
        ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
        
        const SizedBox(height: 24),
        
        Text(
          'Fahimul Islam Fahim',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF2D3436),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
        
        Text(
          'Flutter Developer & UI Designer',
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: AppColors.primaryLight,
            fontWeight: FontWeight.w500,
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),
      ],
    );
  }

  Widget _buildDeveloperCard(BuildContext context, bool isDark) {
    return GlassCard(
      borderRadius: 32,
      padding: EdgeInsets.zero,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.code_rounded, color: AppColors.primaryLight),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About the Developer',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black45,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Crafting Digital Experiences',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            
            // Expandable Content
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const SizedBox(height: 24),
                  Divider(color: isDark ? Colors.white12 : Colors.black12),
                  const SizedBox(height: 16),
                  Text(
                    "Passionate about building beautiful, functional, and performant mobile applications. MotoFile is a testament to the power of Flutter and clean design.",
                    style: TextStyle(
                      height: 1.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSocialButton(context, Icons.code, 'GitHub'),
                      _buildSocialButton(context, Icons.link, 'LinkedIn'),
                      _buildSocialButton(context, Icons.language, 'Web'),
                    ],
                  ),
                ],
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(BuildContext context, IconData icon, String label) {
    final isDark = Provider.of<ThemeService>(context).isDarkMode;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey[100],
            shape: BoxShape.circle,
            border: Border.all(color: isDark ? Colors.white24 : Colors.grey[300]!),
          ),
          child: Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildTechStack(BuildContext context, bool isDark) {
    final techs = ['Flutter', 'Dart', 'Provider', 'SQLite', 'Google Fonts', 'Animate'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'POWERED BY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: techs.map((tech) => _buildTechChip(context, tech)).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildTechChip(BuildContext context, String label) {
    final isDark = Provider.of<ThemeService>(context).isDarkMode;
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white.withOpacity(0.9) : AppColors.primaryLight,
        ),
      ),
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeService>(context).isDarkMode;
    // Premium Mesh Gradient effect using heavy blurs and moving blobs
    return Stack(
      children: [
        Container(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA)),
        
        // Blobs
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight.withOpacity(0.3),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .moveX(begin: 0, end: 50, duration: 4.seconds)
           .scale(begin: const Offset(1,1), end: const Offset(1.2,1.2), duration: 5.seconds),
        ),
        
        Positioned(
          bottom: 100,
          left: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentLight.withOpacity(0.3),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .moveY(begin: 0, end: 50, duration: 6.seconds)
           .scale(begin: const Offset(1,1), end: const Offset(1.3,1.3), duration: 7.seconds),
        ),

        // Blur Overlay
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }
}
