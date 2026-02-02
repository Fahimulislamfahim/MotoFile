import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DocumentCardView extends StatelessWidget {
  final String title;
  final DateTime? expiryDate;
  final String status;
  final VoidCallback onTap;

  const DocumentCardView({
    super.key,
    required this.title,
    required this.expiryDate,
    required this.status,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'Valid':
        return Colors.green;
      case 'Expiring':
        return Colors.orange;
      case 'Expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getDocumentIcon() {
    if (title.contains('License')) return Icons.badge;
    if (title.contains('Registration')) return Icons.app_registration;
    if (title.contains('Tax')) return Icons.receipt_long;
    if (title.contains('Insurance')) return Icons.shield;
    return Icons.description;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.04),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0.7),
                      ],
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Icon and Status
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                  Theme.of(context).primaryColor.withValues(alpha: 0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              _getDocumentIcon(),
                              color: Theme.of(context).primaryColor,
                              size: 32,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getStatusColor().withValues(alpha: 0.4),
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
                      const SizedBox(height: 20),
                      // Title
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                      ),
                      const SizedBox(height: 12),
                      // Expiry Date
                      if (expiryDate != null)
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Expires: ${DateFormat('MMM dd, yyyy').format(expiryDate!)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
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
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              status == 'Missing' ? 'Tap to add document' : 'No expiry date',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      // Action Button
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor.withValues(alpha: 0.2),
                              Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              status == 'Missing' ? Icons.add : Icons.visibility,
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
