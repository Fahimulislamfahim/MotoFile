import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/theme_service.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/premium_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/premium_app_bar.dart';

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

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const PremiumAppBar(title: 'Settings'),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            _buildSectionHeader(context, 'Appearance'),
            const SizedBox(height: 12),
            GlassCard(
              padding: EdgeInsets.zero,
              borderRadius: 20,
              child: _buildSettingTile(
                context,
                icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                title: 'Theme',
                subtitle: isDark ? 'Dark Mode' : 'Light Mode',
                trailing: Switch.adaptive(
                  value: isDark,
                  onChanged: (value) {
                    themeService.toggleTheme();
                  },
                  activeColor: AppColors.primaryLight,
                ),
              ),
            ).animate().fadeIn().slideX(),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Notifications'),
            const SizedBox(height: 12),
            GlassCard(
              padding: EdgeInsets.zero,
              borderRadius: 20,
              child: _buildSettingTile(
                context,
                icon: Icons.notifications_active_rounded,
                title: 'Push Notifications',
                subtitle: _notificationsEnabled ? 'Enabled' : 'Disabled',
                trailing: Switch.adaptive(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Notifications ${value ? 'enabled' : 'disabled'}')),
                    );
                  },
                  activeColor: AppColors.primaryLight,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideX(),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'About'),
            const SizedBox(height: 12),
            GlassCard(
              padding: EdgeInsets.zero,
              borderRadius: 20,
              child: Column(
                children: [
                  _buildSettingTile(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: 'App Version',
                    subtitle: '1.0.0 (Premium Build)',
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
                  _buildSettingTile(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () {},
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
                  _buildSettingTile(
                    context,
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () {},
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms).slideX(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.primaryLight,
        fontWeight: FontWeight.bold,
        fontSize: 16,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: AppColors.primaryLight,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
