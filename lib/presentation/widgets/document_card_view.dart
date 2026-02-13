import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'glass_card.dart';
import '../../core/theme/app_colors.dart';

class DocumentCardView extends StatelessWidget {
  final String title;
  final DateTime? expiryDate;
  final String status;
  final VoidCallback onTap;
  final Duration animationDelay;

  const DocumentCardView({
    super.key,
    required this.title,
    required this.expiryDate,
    required this.status,
    required this.onTap,
    this.animationDelay = Duration.zero,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'Valid': return AppColors.success;
      case 'Expiring': return AppColors.warning;
      case 'Expired': return AppColors.error;
      default: return AppColors.textSecondaryLight;
    }
  }

  IconData _getDocumentIcon() {
    if (title.contains('License')) return Icons.badge_outlined;
    if (title.contains('Registration')) return Icons.app_registration;
    if (title.contains('Tax')) return Icons.receipt_long_outlined;
    if (title.contains('Insurance')) return Icons.shield_outlined;
    return Icons.description_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(24),
        borderRadius: 32, // More roundish
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Icon and Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
                  ),
                  child: Icon(
                    _getDocumentIcon(),
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor().withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
            ),
            const SizedBox(height: 12),
            // Expiry Date
            if (expiryDate != null)
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: Theme.of(context).primaryColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Expires: ${DateFormat('MMM dd, yyyy').format(expiryDate!)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Icon(
                    status == 'Missing' ? Icons.add_circle_outline : Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).dividerColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status == 'Missing' ? 'Tap to add document' : 'No expiry date',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            // Action Button (Full Width, Stylish)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.2),
                    Theme.of(context).primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    status == 'Missing' ? Icons.add : Icons.visibility_outlined,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status == 'Missing' ? 'Add Document' : 'View Document',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

      ).animate(delay: animationDelay).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
    );
  }
}
