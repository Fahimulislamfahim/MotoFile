import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'glass_card.dart';

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const PremiumAppBar({super.key, required this.title, this.actions, this.leading});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title, 
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: -0.5)
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
      actions: actions?.map((action) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: action,
      )).toList(),
      leading: leading ?? (Navigator.canPop(context) 
        ? Padding(
          padding: const EdgeInsets.all(8.0),
          child: GlassCard(
            padding: EdgeInsets.zero,
            borderRadius: 12,
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
        ) 
        : null
      ),
      backgroundColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
