import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'glass_card.dart';
import '../../core/theme/app_colors.dart';

class DocumentListTile extends StatelessWidget {
  final String title;
  final DateTime? expiryDate;
  final String status;
  final VoidCallback onTap;

  const DocumentListTile({
    super.key,
    required this.title,
    required this.expiryDate,
    required this.status,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'Valid': return AppColors.success;
      case 'Expiring': return AppColors.warning;
      case 'Expired': return AppColors.error;
      default: return AppColors.textSecondaryLight;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case 'Valid': return Icons.check_circle_outline;
      case 'Expiring': return Icons.warning_amber_rounded;
      case 'Expired': return Icons.error_outline;
      default: return Icons.add_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        borderRadius: 32, // Roundish
        child: Row(
          children: [
            // Status Icon with Glow
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(24), // Keep icon container slightly less round or match? Let's go 24.
                border: Border.all(color: _getStatusColor().withOpacity(0.2)),
              ),
              child: Icon(
                _getStatusIcon(),
                color: _getStatusColor(),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Title and Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  if (expiryDate != null)
                    Text(
                      'Expires: ${DateFormat('MMM dd, yyyy').format(expiryDate!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                    )
                  else
                    Text(
                      status == 'Missing' ? 'Tap to add' : 'No expiry date',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                ],
              ),
            ),
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(40), // Stadium
                border: Border.all(
                  color: _getStatusColor().withOpacity(0.3),
                ),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: _getStatusColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0),
    );
  }
}
