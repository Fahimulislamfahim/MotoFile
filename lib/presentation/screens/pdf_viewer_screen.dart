import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import 'package:share_plus/share_plus.dart';
import '../../data/daos/document_dao.dart';
import '../../core/services/notification_service.dart';

class PDFViewerScreen extends StatelessWidget {
  final String filePath;
  final String title;
  final int documentId;

  const PDFViewerScreen({
    super.key,
    required this.filePath,
    required this.title,
    required this.documentId,
  });

  Future<void> _deleteDocument(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document?'),
        content: const Text('This will permanently delete the file and cancel all reminders.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 1. Delete from DB
      await DocumentDao().delete(documentId);
      
      // 2. Cancel notifications
      await NotificationService().cancelNotifications(documentId);

      // 3. Delete file (optional, but good practice)
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting file: $e');
      }

      if (context.mounted) {
        Navigator.pop(context, true); // Return true to refresh home
      }
    }
  }

  Future<void> _shareDocument() async {
    final file = File(filePath);
    if (await file.exists()) {
      await Share.shareXFiles([XFile(filePath)], text: 'Here is my $title document.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareDocument,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteDocument(context),
          ),
        ],
      ),
      body: FutureBuilder<File>(
        future: File(filePath).exists().then((exists) => exists ? File(filePath) : throw Exception('File not found')),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return PDFView(
              filePath: filePath,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: true,
              pageFling: true,
              onError: (error) {
                debugPrint(error.toString());
              },
              onPageError: (page, error) {
                debugPrint('$page: ${error.toString()}');
              },
            );
          }
        },
      ),
    );
  }
}
