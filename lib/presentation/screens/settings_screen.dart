import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/theme_service.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white54,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? Colors.white : Colors.black87),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. Premium Background (Mesh Gradient)
          const _SettingsBackground(),

          // 2. Content
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildSectionHeader(context, 'Appearance', delay: 100),
                const SizedBox(height: 16),
                GlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: 24,
                  child: Column(
                    children: [
                      _buildSettingTile(
                        context,
                        icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        title: 'App Theme',
                        subtitle: isDark ? 'Dark Mode' : 'Light Mode',
                        trailing: Switch.adaptive(
                          value: isDark,
                          onChanged: (value) => themeService.toggleTheme(),
                          activeColor: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                const SizedBox(height: 32),
                _buildSectionHeader(context, 'Notifications', delay: 300),
                const SizedBox(height: 16),
                GlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: 24,
                  child: Column(
                    children: [
                      _buildSettingTile(
                        context,
                        icon: Icons.notifications_active_rounded,
                        title: 'Push Notifications',
                        subtitle: _notificationsEnabled ? 'Enabled' : 'Disabled',
                        trailing: Switch.adaptive(
                          value: _notificationsEnabled,
                          onChanged: (value) {
                            setState(() => _notificationsEnabled = value);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Notifications ${value ? 'enabled' : 'disabled'}'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.black87,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          activeColor: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 32),
                _buildSectionHeader(context, 'General', delay: 500),
                const SizedBox(height: 16),
                GlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: 24,
                  child: Column(
                    children: [
                      _buildSettingTile(
                        context,
                        icon: Icons.language_rounded,
                        title: 'Language',
                        subtitle: 'English (US)',
                        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? Colors.white24 : Colors.black26),
                        onTap: () {},
                      ),
                      Divider(height: 1, indent: 60, color: isDark ? Colors.white10 : Colors.black12),
                      _buildSettingTile(
                        context,
                        icon: Icons.cloud_sync_rounded,
                        title: 'Cloud Backup',
                        subtitle: 'Last synced: Just now',
                        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? Colors.white24 : Colors.black26),
                        onTap: () {},
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                const SizedBox(height: 32),
                _buildSectionHeader(context, 'About', delay: 700),
                const SizedBox(height: 16),
                GlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: 24,
                  child: Column(
                    children: [
                      _buildSettingTile(
                        context,
                        icon: Icons.info_outline_rounded,
                        title: 'Version',
                        subtitle: '1.0.1 (Premium Build)',
                      ),
                      Divider(height: 1, indent: 60, color: isDark ? Colors.white10 : Colors.black12),
                      _buildSettingTile(
                        context,
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? Colors.white24 : Colors.black26),
                        onTap: () {},
                      ),
                      Divider(height: 1, indent: 60, color: isDark ? Colors.white10 : Colors.black12),
                      _buildSettingTile(
                        context,
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? Colors.white24 : Colors.black26),
                        onTap: () {},
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),
                
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Made with ❤️ by Fahimul Islam',
                    style: TextStyle(
                      color: isDark ? Colors.white30 : Colors.black26,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ).animate().fadeIn(delay: 1.seconds),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {required int delay}) {
    final isDark = Provider.of<ThemeService>(context).isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.5,
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: -0.1);
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Provider.of<ThemeService>(context).isDarkMode;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsBackground extends StatelessWidget {
  const _SettingsBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeService>(context).isDarkMode;
    return Stack(
      children: [
        // Base
        Container(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA),
        ),
        
        // Blobs
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight.withOpacity(0.15),
              boxShadow: [
                BoxShadow(color: AppColors.primaryLight.withOpacity(0.1), blurRadius: 100),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(1,1), end: const Offset(1.2,1.2), duration: 10.seconds),
        ),
        
        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentLight.withOpacity(0.1),
              boxShadow: [
                BoxShadow(color: AppColors.accentLight.withOpacity(0.05), blurRadius: 80),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .moveY(begin: 0, end: 30, duration: 8.seconds),
        ),

        // Blur
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }
}
